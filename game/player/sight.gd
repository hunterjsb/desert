class_name Sight
extends RefCounted
## What your look meets, set as the hands' look_*: what a ray from your eyes
## hits within reach, helped to a small loose thing near your aim, a knot in a
## ring's hole, a part fitted out of sight under a frame or a line's drawn
## strand; and how near your line of sight passes to what your hands look over.

## Empty-handed, your line of sight passing this near a part fitted under a
## device looks at it, m: standing, it's out of sight under the frame. A look
## at the frame itself counts only this low on it, and only in this lower share
## of its height, so a thin frame like a chassis piece is still itself by its
## top and the upper half of its edges.
const UNDER := 0.15
const UNDER_SHARE := 0.5
## The small thing your aim settled on stays the one until another is this much
## nearer your aim, so a wavering aim doesn't flicker between them.
const STICKY := 0.7

## The point on a box your line of sight passes nearest, as gap_to last found it.
var aim := Vector3.ZERO
var _hands: Hands
var _player: Player
var _tuning := Tuning.current()
## The small loose thing your aim settled on.
var _picked: RigidBody3D


func _init(hands: Hands, player: Player) -> void:
	_hands = hands
	_player = player


func look() -> void:
	var hands := _hands
	hands.look_part = null
	hands.look_device = null
	hands.look_socket = null
	hands.look_line = null
	hands.look_sand = false
	hands.look_work = null
	hands.look_wreck = null
	hands.look_scrap = null
	hands.look_bed = false
	hands.look_fixture = null
	var eye := _player.camera.global_transform
	hands.sight_from = eye.origin
	hands.sight_to = eye.origin - eye.basis.z * _tuning.reach
	var ray := PhysicsRayQueryParameters3D.create(hands.sight_from, hands.sight_to)
	ray.exclude = hands._exclusions()
	var hit := hands.get_world_3d().direct_space_state.intersect_ray(ray)
	var hit_device := hit.get("collider") as Device
	var hit_shape: Node = hit_device.shape_owner_get_owner(hit_device.shape_find_owner(hit.shape)) if hit_device != null else null
	var hit_socket := _outermost(hit_device.socket_of(hit_shape)) if hit_device != null else null
	# A visible fitted part must not be replaced by its carryable host.
	if hit.is_empty() or not hit.collider is Part:
		_assist(eye, hit_device if hit_socket != null and hit_socket.part != null else null)
	if hit.is_empty():
		if hands.look_part == null and hands.look_device == null:
			_under()
			_ground_line()
		return
	hands.sight_to = hit.position
	hands.look_point = hit.position
	hands.look_normal = hit.normal
	var body: Object = hit.collider
	hands.look_sand = Hands._sand(hit)
	if body is CollisionObject3D and body.has_meta(&"fixture"):
		hands.look_fixture = body
	if body is CollisionObject3D and body.has_meta(&"wreckage"):
		hands.look_wreck = body.get_meta(&"wreckage")
		if body.has_meta(&"work"):
			hands.look_work = body
		elif body is StaticBody3D:
			hands.look_scrap = body
	elif body is StaticBody3D and not hands.look_sand and _player.world != null:
		# A structure's boxes are its chunk's ground: on a wreck's, its shell.
		hands.look_wreck = _player.world.salvage.wreckage_near(hit.position)
	hands.look_bed = _is_bed(hit)
	if hands.look_part != null or hands.look_device != null:
		# Assisted: the small thing you aimed near, not the sand under it.
		return
	if body is RigidBody3D and body.has_meta(&"boom_mast"):
		# The spar is articulated, but taking it still removes its fitted sail.
		hands.look_device = body.get_meta(&"boom_mast") as Mast
		hands.look_socket = hands.look_device._sail_socket()
	elif body is Part:
		hands.look_part = body
	elif body is Device:
		hands.look_device = body
		hands.look_socket = hit_socket
		if hands.held == null:
			_near_tie(hit.position)
		if hands.look_socket == null and not _low_on(hands.look_device, hit_shape as CollisionShape3D, hit.position):
			return
	if hands.look_part == null and hands.look_socket == null:
		_under()
	if hands.look_part == null and hands.look_device == null:
		_ground_line()


## The drawn strand is pickable without colliders along every moving segment.
func _ground_line() -> void:
	var hands := _hands
	if hands.held != null or hands.grasp.body != null:
		return
	var from := hands.sight_from
	var to := hands.sight_to
	var best := _tuning.pick_assist
	for child in _player.world.content.get_children():
		var line := child as Line
		if line == null or not line.recoverable():
			continue
		var points := line.rope.strand.points
		for i in range(1, points.size()):
			var closest := Geometry3D.get_closest_points_between_segments(from, to, points[i - 1], points[i])
			var gap := closest[0].distance_to(closest[1])
			if gap >= best:
				continue
			var ray := PhysicsRayQueryParameters3D.create(from, closest[1])
			ray.exclude = hands._exclusions()
			var hit := hands.get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and hit.position.distance_to(closest[1]) > RopeStrand.RADIUS * 2.0:
				continue
			best = gap
			hands.look_line = line
			hands.look_point = closest[1]


## A ring's hole has no collider: aim near its visible end to take the knot.
func _near_tie(hit_at: Vector3) -> void:
	var hands := _hands
	var device := hands.look_device
	var from := hands.sight_from
	var best := _tuning.pick_assist
	for socket in device.sockets():
		if socket.kind != &"tie" or socket.part == null:
			continue
		# A hook's hole needs help; a stake's own frame must still come up whole.
		if not socket.has_meta(&"socket") or not (socket.get_meta(&"socket") as Socket).part is RopeHook:
			continue
		var at := device.global_transform * socket.position
		if at.distance_to(from) > _tuning.reach or at.distance_to(from) > hit_at.distance_to(from) + best:
			continue
		var gap := Geometry3D.get_closest_point_to_segment(at, from, hands.sight_to).distance_to(at)
		if gap >= best or (from - at).dot(device.global_basis * socket.outward()) <= 0.0:
			continue
		var tip := Line._tip(socket.part) if socket.part.has_meta(&"tip") else null
		var target := tip.global_position if tip != null else at
		var ray := PhysicsRayQueryParameters3D.create(from, target)
		ray.exclude = hands._exclusions()
		var seen := hands.get_world_3d().direct_space_state.intersect_ray(ray)
		if not seen.is_empty():
			if seen.collider != device:
				continue
			var met := device.shape_owner_get_owner(device.shape_find_owner(seen.shape)) as Node
			if _outermost(device.socket_of(met)) != socket:
				continue
		best = gap
		hands.look_socket = socket


## Whether a look meets a frame low enough to mean what's fitted under it.
func _low_on(device: Device, frame: CollisionShape3D, point: Vector3) -> bool:
	if frame == null or frame.shape == null:
		return true
	var box := frame.transform * Catalog.bounds(frame.shape)
	var up := (device.global_transform.affine_inverse() * point).y - box.position.y
	return up <= minf(UNDER, box.size.y * UNDER_SHARE)


## Empty-handed, what a look at a device's frame, or just past one, finds under
## it: the part fitted facing down that your line of sight passes nearest.
func _under() -> void:
	var hands := _hands
	if hands.held != null:
		return
	var best: Socket = null
	var nearest := UNDER
	var among: Array = [hands.look_device] if hands.look_device != null \
		else _player.world.content.get_children() + _player.world.salvage.near(hands.sight_from)
	for child in among:
		var device := child as Device
		if device == null or device.host() != null or device.has_meta(&"buried") or far(device):
			continue
		for each in device.sockets():
			if each.part == null or (device.global_basis * each.outward()).y > -0.7:
				continue
			var d := gap_to(device.global_transform, Hands._shapes_box(each.fitted))
			if d < nearest:
				nearest = d
				best = each
	if best != null:
		hands.look_device = best.get_parent() as Device
		hands.look_socket = best


## A box of a ruin's that's a bed.
static func _is_bed(hit: Dictionary) -> bool:
	var body := hit.collider as StaticBody3D
	if body == null:
		return false
	var shape := body.shape_owner_get_owner(body.shape_find_owner(hit.shape)) as Node
	return shape != null and shape.has_meta(&"bed")


## How far along your look it meets something, out to `distance`, m, or INF.
func meets(distance: float) -> float:
	var eye := _player.camera.global_transform
	var ray := PhysicsRayQueryParameters3D.create(eye.origin, eye.origin - eye.basis.z * distance)
	ray.exclude = _hands._exclusions()
	var hit := _hands.get_world_3d().direct_space_state.intersect_ray(ray)
	return INF if hit.is_empty() else eye.origin.distance_to(hit.position)


## A distant planting aim must not become a waist tie just because its
## sand is past reach, or past the ground whose collision is streamed.
func sand_beyond_reach() -> bool:
	var eye := _player.camera.global_transform
	if eye.basis.z.y > 0.0:
		return true
	var ray := PhysicsRayQueryParameters3D.create(eye.origin, eye.origin - eye.basis.z * _player.camera.far)
	ray.exclude = _hands._exclusions()
	var hit := _hands.get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and Hands._sand(hit)


## Last on, first off: aimed at a hook with a line tied to it, it's the line's
## end you take, and the hook once it's bare.
static func _outermost(socket: Socket) -> Socket:
	if socket == null or socket.part == null:
		return socket
	if socket.part is RopeTip and RopeBundle.members(socket.part).size() > 1:
		return socket
	for node in socket.fitted:
		var added := node as Socket
		if added != null and added.part != null:
			return _outermost(added)
	return socket


## Aiming at the sand near a small loose thing takes it, so a battery lying
## there needs no pixel-perfect aim: the nearest your aim among those you can
## see, and the one it settled on until another is clearly nearer.
func _assist(eye: Transform3D, except_body: RigidBody3D = null) -> void:
	var hands := _hands
	if hands.held != null:
		_picked = null
		return
	var forward := -eye.basis.z
	var space := hands.get_world_3d().direct_space_state
	var best: RigidBody3D = null
	var best_score := INF
	var kept := INF
	if not is_instance_valid(_picked):
		_picked = null
	for child in _player.world.content.get_children() + _player.world.salvage.near(eye.origin):
		var body := child as RigidBody3D
		if body == null or body == except_body or not (body is Part or (body is Device and (body as Device).carryable)):
			continue
		var box := Hands._box_of(body)
		var size := box.size.length() * 0.5
		if size * 2.0 > _tuning.pick_small:
			continue
		var middle := body.global_transform * box.get_center()
		var along := (middle - eye.origin).dot(forward)
		if along <= 0.0 or along > _tuning.reach:
			continue
		var score := (middle - eye.origin - forward * along).length() / (size + _tuning.pick_assist)
		if score > 1.0 or score >= best_score and body != _picked:
			continue
		var ray := PhysicsRayQueryParameters3D.create(eye.origin, middle)
		ray.exclude = hands._exclusions()
		var seen := space.intersect_ray(ray)
		if not seen.is_empty() and seen.collider != body:
			continue
		if body == _picked:
			kept = score
		if score < best_score:
			best_score = score
			best = body
	if best != _picked and kept <= 1.0 and best_score > kept * STICKY:
		best = _picked
	_picked = best
	if best is Part:
		hands.look_part = best
	elif best is Device:
		hands.look_device = best


## The devices your hands look over: yours in the world, the finds round
## you, whatever stands on a deck, which keeps its own sockets, and the Walker.
func near() -> Array[Device]:
	var found: Array[Device] = []
	for child in _player.world.content.get_children() + _player.world.salvage.near(_hands.sight_from) \
			+ Walker.near(_player.world):
		var device := child as Device
		if device != null:
			found.append(device)
			_on_decks(device, found)
	return found


static func _on_decks(device: Device, found: Array[Device]) -> void:
	for each in device.mounted():
		if each.on_deck():
			found.append(each)
			_on_decks(each, found)


## Whether a device is past what your hands work on from your eyes: a deck
## by its nearest piece, since its far end can lie well past its first.
func far(device: Device) -> bool:
	var from := _hands.sight_from
	var nearest := device.global_position.distance_to(from)
	var deck := device as Chassis
	if deck != null:
		for piece in deck.joined:
			nearest = minf(nearest, (deck.global_transform * piece.pose().origin).distance_to(from))
	return nearest > _tuning.reach + 2.0


## How near your line of sight passes to a box in a frame, m; aim is the
## point on it that passes nearest.
func gap_to(frame: Transform3D, box: AABB) -> float:
	var inverse := frame.affine_inverse()
	var a := inverse * _hands.sight_from
	var b := inverse * _hands.sight_to
	# The distance to a box along a line has one valley: close in on it.
	var lo := 0.0
	var hi := 1.0
	for i in 24:
		var one := lerpf(lo, hi, 1.0 / 3.0)
		var two := lerpf(lo, hi, 2.0 / 3.0)
		if outside(a.lerp(b, one), box) <= outside(a.lerp(b, two), box):
			hi = two
		else:
			lo = one
	var nearest := a.lerp(b, (lo + hi) * 0.5)
	aim = frame * nearest
	return outside(nearest, box)


## How far a point is outside a box in the same frame.
static func outside(local: Vector3, box: AABB) -> float:
	return local.distance_to(local.clamp(box.position, box.end))
