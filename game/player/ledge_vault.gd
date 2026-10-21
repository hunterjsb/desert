class_name LedgeVault
extends RefCounted
## A short, swept climb follows the ledge rather than kicking its rigid body.

var active := false
## Body presentation follows the same swept climb, never moves the player itself.
var height := 0.0
var progress: float:
	get:
		return smoothstep(0.0, 1.0, _elapsed / _duration) if _duration > 0.0 else 0.0
var last_step := Vector3.ZERO
var _player: Player
var _support: Node3D
var _points: Array[Vector3] = []
var _curves: Array = []
var _parameters: Array[float] = []
var _elapsed := 0.0
var _duration := 0.0
var _distances: Array[float] = []
var _used := false
var _last := Vector3.ZERO
var _origin := Vector2i.ZERO
var _drag_offset := Vector3.ZERO
var _carry := Vector2.ZERO
var _tuning := Tuning.current()


func _init(player: Player) -> void:
	_player = player


func grounded() -> void:
	_used = false


func cancel() -> void:
	if active:
		_player.velocity = release_velocity()
	active = false
	_support = null
	_points.clear()


## Ending or saving the climb keeps travel, not the scripted hand-over-hand pace.
func release_velocity() -> Vector3:
	var motion := Vector3(_carry.x, 0.0, _carry.y)
	var body := _support as RigidBody3D if is_instance_valid(_support) else null
	if body != null:
		motion += body.linear_velocity + body.angular_velocity.cross(_player.global_position - body.global_position)
	return motion


func begin(direction: Vector2) -> bool:
	if _used or direction == Vector2.ZERO or _player.stamina < _tuning.vault_stamina:
		return false
	var start := _player.global_position
	var ahead := Vector3(direction.x, 0.0, direction.y) * _tuning.vault_reach
	var wall := _sweep(start, ahead)
	if wall.get_collision_count() == 0:
		return false
	var normal := wall.get_collision_normal()
	if normal.y >= cos(_player.floor_max_angle) or normal.dot(ahead.normalized()) > -0.5:
		return false
	var up := Vector3.UP * (_tuning.vault_height + _tuning.vault_clearance)
	# Find the actual top before checking how far this capsule must lift.
	var query := PhysicsRayQueryParameters3D.create(start + up + ahead, start + ahead - Vector3.UP * _tuning.vault_clearance,
		_player.collision_mask, [_player.get_rid()])
	var top := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if top.is_empty() or top.normal.y < cos(_player.floor_max_angle):
		return false
	var rise: float = top.position.y - start.y
	if rise < _tuning.vault_min_height or rise > _tuning.vault_height:
		return false
	var lift := Vector3.UP * (rise + _tuning.vault_lift_margin)
	if _sweep(start, lift).get_collision_count() > 0 or _sweep(start + lift, ahead).get_collision_count() > 0:
		return false
	var down := _sweep(start + lift + ahead, -lift - Vector3.UP * _tuning.vault_clearance)
	if down.get_collision_count() == 0 or down.get_collision_normal().y < cos(_player.floor_max_angle) \
			or top.collider != down.get_collider():
		return false
	var landing := start + lift + ahead + down.get_travel()
	_support = down.get_collider() as Node3D
	if _support == null:
		return false
	var curves := _round_corners([start, start + lift, start + lift + ahead, landing])
	var path: Array[Vector3] = []
	_parameters.clear()
	for i in curves.size():
		var curve: Array = curves[i]
		var steps := 1 if i % 2 == 0 else 16
		for sample in range(0 if i == 0 else 1, steps + 1):
			var t := float(sample) / steps
			path.append(_curve_point(curve, t))
			_parameters.append(i + t)
	for i in range(1, path.size()):
		if _sweep(path[i - 1], path[i] - path[i - 1]).get_collision_count() > 0:
			return false
	_points.clear()
	_curves.clear()
	for curve: Array in curves:
		var local: Array[Vector3] = []
		for point: Vector3 in curve:
			local.append(_support.to_local(point))
		_curves.append(local)
	_distances.assign([0.0])
	for point: Vector3 in path:
		if not _points.is_empty():
			_distances.append(_distances[-1] + point.distance_to(_support.to_global(_points[-1])))
		_points.append(_support.to_local(point))
	height = rise
	var nominal := _tuning.vault_height + _tuning.vault_reach + 2.0 * _tuning.vault_lift_margin
	_duration = _tuning.vault_seconds * _distances[-1] / nominal
	_elapsed = 0.0
	_last = start
	_origin = _player.world.origin_chunk
	_drag_offset = Vector3.ZERO
	last_step = Vector3.ZERO
	_carry = _player.own
	_player.stamina -= _tuning.vault_stamina
	_used = true
	active = true
	return true


func step(delta: float) -> void:
	var shift := _player.world.origin_chunk - _origin
	_last -= Vector3(shift.x, 0.0, shift.y) * _player.world.tuning.chunk_size
	_origin = _player.world.origin_chunk
	if not is_instance_valid(_support) or not Controls.playing() \
			or _player.vitals.wounds.stunned() or _player.global_position.distance_to(_last) > _tuning.vault_reach:
		cancel()
		return
	var first := _elapsed == 0.0
	_elapsed = minf(_elapsed + delta, _duration)
	var travel := progress * _distances[-1]
	var segment := 0
	while segment < _points.size() - 2 and travel > _distances[segment + 1]:
		segment += 1
	var along := inverse_lerp(_distances[segment], _distances[segment + 1], travel)
	var parameter := lerpf(_parameters[segment], _parameters[segment + 1], along)
	var curve := mini(floori(parameter), _curves.size() - 1)
	var target := _support.to_global(_curve_point(_curves[curve], parameter - curve))
	var drag: Vector3 = _player.get_meta(&"rope_drag", Vector3.ZERO)
	_drag_offset += drag * delta
	var move := target + _drag_offset - _player.global_position
	var before := _player.global_position
	var collision: KinematicCollision3D
	if first:
		# Clear the previous floor flag on takeoff; later sweeps don't update it.
		_player.velocity = move / delta
		_player.move_and_slide()
		collision = _player.get_last_slide_collision()
	else:
		collision = _player.move_and_collide(move)
	last_step = _player.global_position - before
	_last = _player.global_position
	_player.velocity = move / delta
	_player.mode = "vault"
	if collision != null and collision.get_normal().y < cos(_player.floor_max_angle):
		cancel()
		_player.velocity.y = minf(_player.velocity.y, 0.0)
		return
	if _player.global_position.distance_to(target) > _tuning.vault_clearance * 3.0:
		cancel()
		return
	if _elapsed >= _duration:
		# Establish the actual floor through CharacterBody's usual platform tracking.
		_player.velocity = Vector3.DOWN * _tuning.vault_settle_speed
		var snap := _player.floor_snap_length
		_player.floor_snap_length = minf(snap, _tuning.vault_clearance * 2.0)
		_player.move_and_slide()
		_player.apply_floor_snap()
		_player.floor_snap_length = snap
		_player.own = _carry
		_player.velocity = Vector3(_carry.x, 0.0, _carry.y)
		if _player.is_on_floor():
			Deeds.done(_player.world, &"up_and_over")
		cancel()


func _sweep(at: Vector3, motion: Vector3) -> PhysicsTestMotionResult3D:
	var parameters := PhysicsTestMotionParameters3D.new()
	parameters.from = Transform3D(_player.global_basis, at)
	parameters.motion = motion
	parameters.margin = _tuning.vault_clearance
	var result := PhysicsTestMotionResult3D.new()
	PhysicsServer3D.body_test_motion(_player.get_rid(), parameters, result)
	return result


## Tangents meet above the top; the curved path never cuts through its edge.
func _round_corners(corners: Array[Vector3]) -> Array:
	var curves: Array = []
	var last := corners[0]
	for i in [1, 2]:
		var before := corners[i - 1] - corners[i]
		var after := corners[i + 1] - corners[i]
		var radius := minf(_tuning.vault_lift_margin - _tuning.vault_clearance,
			minf(before.length(), after.length()) * 0.5)
		var entry := corners[i] + before.normalized() * maxf(radius, 0.0)
		var leave := corners[i] + after.normalized() * maxf(radius, 0.0)
		curves.append([last, last.lerp(entry, 0.5), entry])
		curves.append([entry, corners[i], leave])
		last = leave
	curves.append([last, last.lerp(corners[-1], 0.5), corners[-1]])
	return curves


func _curve_point(curve: Array, t: float) -> Vector3:
	return curve[0].lerp(curve[1], t).lerp(curve[1].lerp(curve[2], t), t)
