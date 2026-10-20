class_name LedgeVault
extends RefCounted
## A short, swept climb follows the ledge rather than kicking its rigid body.

var active := false
var last_step := Vector3.ZERO
var _player: Player
var _support: Node3D
var _points: Array[Vector3] = []
var _elapsed := 0.0
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
	if _sweep(start, up).get_collision_count() > 0:
		return false
	if _sweep(start + up, ahead).get_collision_count() > 0:
		return false
	var down := _sweep(start + up + ahead, -up - Vector3.UP * _tuning.vault_clearance)
	if down.get_collision_count() == 0 or down.get_collision_normal().y < cos(_player.floor_max_angle):
		return false
	# A capsule can rest against an edge with its feet still outside the top.
	var query := PhysicsRayQueryParameters3D.create(start + up + ahead, start + ahead - Vector3.UP * _tuning.vault_clearance,
		_player.collision_mask, [_player.get_rid()])
	var top := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if top.is_empty() or top.collider != down.get_collider() or top.normal.y < cos(_player.floor_max_angle):
		return false
	var landing := start + up + ahead + down.get_travel()
	var rise := landing.y - start.y
	if rise <= _tuning.vault_clearance or rise > _tuning.vault_height + _tuning.vault_clearance:
		return false
	_support = down.get_collider() as Node3D
	if _support == null:
		return false
	_points.clear()
	for point: Vector3 in [start, start + up, start + up + ahead, landing]:
		_points.append(_support.to_local(point))
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
	_elapsed = minf(_elapsed + delta, _tuning.vault_seconds)
	var progress := _elapsed / _tuning.vault_seconds
	var segment := mini(2, int(progress * 3.0))
	var along := smoothstep(0.0, 1.0, progress * 3.0 - segment)
	var target := _support.to_global(_points[segment].lerp(_points[segment + 1], along))
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
	if _elapsed >= _tuning.vault_seconds:
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
