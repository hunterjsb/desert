class_name SurveyorRecovery
extends RefCounted
## Lands the sealed pod's surviving bodies once. Taking them remains the normal hands action.

## The impact bursts the front frame off with the tail you watched the fall through.
## The seat faces that open floor, so the way out is straight ahead, under open sky,
## and nothing the impact places may close it. The frame lands as recoverable debris.
const BURST := &"frame_b"

## Parts seated off-tree, joined panels and carried cargo still retain their roles.
static func named(world: World) -> Dictionary:
	var out := {}
	var seen := {}
	var next: Array = world.content.get_children() + world.player.suit.carried
	while not next.is_empty():
		var node := next.pop_back() as Node
		if not is_instance_valid(node) or seen.has(node.get_instance_id()):
			continue
		seen[node.get_instance_id()] = true
		if node.has_meta(&"arrival_uid"):
			out[StringName(node.get_meta(&"arrival_uid"))] = node
		next.append_array(node.get_children())
		if node is Device:
			next.append_array(node.parts())
			next.append_array(node.mounted())
		if node is Chassis:
			next.append_array(node.pieces())
	return out


## Impact wear lands on the real body; charge and contents stay as they were packed.
static func _apply(body: RigidBody3D, state: Dictionary) -> void:
	if body is Device and state.has("durability"):
		body.durability = state.durability
		body.show_wear()


static func bounds_of(body: RigidBody3D) -> AABB:
	return body.shape_bounds() if body is Device else Hands._box_of(body)


static func _spill(world: World, body: RigidBody3D, facing: Basis, origin: Vector3, reserved: Array[AABB], gap: float, clearance: float, rules: Tuning) -> bool:
	var local := Transform3D(facing, Vector3.ZERO) * bounds_of(body)
	var pitch := maxf(local.size.x, local.size.z) + gap
	var columns := maxi(1, rules.arrival_spill_columns)
	var ahead := PodShell.landed_pose(rules).origin.x + Chassis.WIDTH * 0.6
	# Thrown clear on both sides of the way out and ahead of where you lie, so you see them crawling out.
	for i in rules.arrival_spill_attempts:
		var side := 1.0 if i % 2 == 0 else -1.0
		var k := i / 2
		var offset := Vector3(ahead + (k / columns) * pitch, 0, side * (Chassis.WIDTH * 0.5 + gap + pitch * (0.5 + k % columns)))
		var at := origin + facing * offset
		var high := -INF
		for x in [local.position.x, local.end.x]:
			for z in [local.position.z, local.end.z]:
				high = maxf(high, world.height_under(at + Vector3(x, 0, z)))
		at.y = high - local.position.y + clearance
		if _put(world, body, Transform3D(facing, at), reserved, gap):
			return true
	return false


static func _put(world: World, body: RigidBody3D, pose: Transform3D, reserved: Array[AABB], gap: float) -> bool:
	var box := pose * bounds_of(body)
	if not world.terrain.has_collision_at(world.world_x(box.position.x), world.world_z(box.position.z)) \
		or not world.terrain.has_collision_at(world.world_x(box.end.x), world.world_z(box.end.z)):
		return false
	if reserved.any(func(other: AABB) -> bool: return other.intersects(box.grow(0.005))):
		return false
	if Stick.clear(body, pose, world.player) != "":
		return false
	world.teleport(body, pose)
	reserved.append(box.grow(gap * 0.5))
	return true


## Crowded ground still gets its gear: dropped beside the pod, away from the way out.
static func _drop(world: World, body: RigidBody3D, at: Vector3) -> void:
	world.teleport(body, Transform3D(Basis.IDENTITY, at + Vector3.UP * (1.0 + bounds_of(body).size.y)))


## Moves the surviving saved bodies, never grants replacement gear. It waits only for the
## landing ground; anything that cannot be found or placed is let go, never a held run.
static func land(world: World, state: Dictionary) -> Dictionary:
	var objects := named(world)
	if state.get("materialized", false):
		return objects
	var at: Vector2 = state.get("landing_world", Vector2(world.player_world_x(), world.player_world_z()))
	if not world.terrain.has_collision_at(at.x, at.y):
		return {}
	var survived := {}
	for entry: Dictionary in state.structure + state.equipment:
		survived[StringName(entry.uid)] = entry.survives
	var loose_ends := {}
	# A line has one cargo identity but two original bodies. Neither may be
	# destroyed with a lost carrier while the line itself survives impact.
	for entry: Dictionary in state.equipment:
		var primary := objects.get(StringName(entry.uid)) as RigidBody3D
		if not entry.survives or not is_instance_valid(primary) or not primary.has_meta(&"line"):
			continue
		var line := primary.get_meta(&"line") as Line
		if not is_instance_valid(line) or line.state != Line.State.LAID:
			continue
		for k in line.ends.size():
			var end := line.ends[k]
			var parent_uid := PreflightCargo.parent_uid(end)
			if parent_uid != &"" and not survived.get(parent_uid, false):
				_unseat(end)
				if end != primary:
					loose_ends[PreflightCargo.end_key(entry.uid, k)] = end
	# Detach survivors before removing a parent lost in impact.
	for entry: Dictionary in state.equipment:
		var body := objects.get(StringName(entry.uid)) as RigidBody3D
		if entry.survives and is_instance_valid(body):
			var parent_uid := PreflightCargo.parent_uid(body)
			if parent_uid != &"" and not survived.get(parent_uid, false):
				_unseat(body)
	var floor := objects.get(&"floor_a") as Chassis
	if not is_instance_valid(floor):
		state.materialized = true
		world.arrival_nodes = objects
		return objects
	var deck := floor.deck if floor.deck != null else floor
	# Panels come off whole, also when their frame is lost or burst.
	for role: StringName in PodShell.PANELS:
		var panel := objects.get(role) as Chassis
		if is_instance_valid(panel) and panel.deck != null:
			panel.deck.detach(panel)
	for entry: Dictionary in state.structure + state.equipment:
		var uid := StringName(entry.uid)
		var body := objects.get(uid) as RigidBody3D
		if not entry.survives:
			if is_instance_valid(body):
				_unseat(body)
				if body.get_parent() != null:
					body.get_parent().remove_child(body)
				body.queue_free()
			objects.erase(uid)
		elif is_instance_valid(body):
			_apply(body, entry.get("state", {}))
	var facing := Basis(Vector3.UP, float(state.get("heading", 0.0)))
	var origin := Vector3(world.engine_x(at.x), 0, world.engine_z(at.y))
	var height := -INF
	for x in [-0.65, 1.65]:
		for z in [-0.8, 0.8]:
			height = maxf(height, world.height_under(origin + facing * Vector3(x, 0, z)))
	var rules := world.tuning
	origin.y = height + Chassis.THICK * 0.5 + rules.arrival_landing_clearance_m
	var pose := Transform3D(facing, origin)
	world.teleport(deck, pose * floor.pose().affine_inverse())
	deck.freeze = false
	deck.linear_velocity = Vector3.ZERO
	deck.angular_velocity = Vector3.ZERO
	var burst := objects.get(BURST) as Frame
	if is_instance_valid(burst) and burst.socket != null:
		_unseat(burst)
	# Surviving panels rejoin whatever frame still stands.
	for role: StringName in PodShell.PANELS:
		if not objects.has(role):
			continue
		var panel := objects[role] as Chassis
		var frame := Rig.face_of(deck, PodShell.PANELS[role][0], PodShell.PANELS[role][1])
		if frame != null:
			deck.join(panel, frame)
	var route := _recovery_route(world)
	# The impact frees fittings across the occupant's route, not their saved identities.
	for entry: Dictionary in state.equipment:
		var body := objects.get(StringName(entry.uid)) as RigidBody3D
		if not entry.survives or not is_instance_valid(body):
			continue
		if route.intersects(PreflightCargo.bounds_in(body, pose)):
			var fitting := _pod_attachment(body, deck)
			if fitting != null:
				_unseat(fitting)
		if not body.has_meta(&"line"):
			continue
		var line := body.get_meta(&"line") as Line
		if not is_instance_valid(line) or line.state != Line.State.LAID:
			continue
		for i in line.ends.size():
			var end := line.ends[i]
			if not route.intersects(PreflightCargo.bounds_in(end, pose)):
				continue
			var fitting := _pod_attachment(end, deck)
			if fitting != null:
				_unseat(fitting)
				if end != body and end.socket == null:
					loose_ends[PreflightCargo.end_key(entry.uid, i)] = end
	var gap := rules.arrival_spill_gap_m
	var clearance := rules.arrival_landing_clearance_m
	var reserved: Array[AABB] = []
	reserved.append(pose * route)
	var exit_world: Vector2 = state.get("exit_world", at + Vector2(rules.arrival_exit_offset_m, 0).rotated(-float(state.get("heading", 0.0))))
	var exit_at := Vector3(world.engine_x(exit_world.x), world.height_at(exit_world.x, exit_world.y), world.engine_z(exit_world.y))
	reserved.append((Transform3D(Basis.IDENTITY, exit_at) * Hands._shapes_box(world.player.get_children())).grow(gap))
	var aside := origin + facing * Vector3(0.5, 0.0, -(Chassis.WIDTH + 1.0))
	for shape in deck.get_children():
		if shape is CollisionShape3D and shape.shape != null:
			reserved.append(shape.global_transform * Catalog.bounds(shape.shape))
	var placements := {}
	var poses: Dictionary = state.preflight.get("cargo_poses", {})
	for entry: Dictionary in state.structure + state.equipment:
		var uid := StringName(entry.uid)
		if not objects.has(uid):
			continue
		var body := objects[uid] as RigidBody3D
		if body is Chassis and (body == deck or body.deck != null) or body is Part and body.socket != null or body is Device and body.host() != null:
			placements[uid] = &"fitted"
			continue
		var desired: Transform3D = pose * poses.get(uid, Transform3D.IDENTITY)
		var inside := false
		if state.preflight.loaded_uids.has(uid):
			inside = _put(world, body, desired, reserved, gap)
		if not inside and not _spill(world, body, facing, origin, reserved, gap, clearance, rules):
			_drop(world, body, aside)
		body.freeze = false
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		placements[uid] = &"pod" if inside else &"spill"
	for key: StringName in loose_ends:
		var end := loose_ends[key] as RigidBody3D
		var desired: Transform3D = pose * poses[key]
		if not _put(world, end, desired, reserved, gap) and not _spill(world, end, facing, origin, reserved, gap, clearance, rules):
			_drop(world, end, aside)
		end.freeze = false
		end.linear_velocity = Vector3.ZERO
		end.angular_velocity = Vector3.ZERO
	PodShell.seal_weather(objects.values(), false)
	for panel in deck.pieces():
		PodShell.restore_skin(panel)
	state.placements = placements
	state.materialized = true
	world.arrival_nodes = objects
	return objects


static func _unseat(body: RigidBody3D) -> void:
	if body is Part and body.socket != null:
		var socket: Socket = body.socket
		var host := socket.get_parent() as Device
		if host != null:
			host.take(socket)
			if host is Chassis:
				# Restored joined pieces also index their fitted frame's faces. Once
				# unseated those nodes belong to the removed part, before it is freed.
				for piece in host.joined:
					piece._own = piece._own.filter(func(node: Node3D) -> bool: return is_instance_valid(node) and node.get_parent() == host)
	elif body is Device and body.host() != null:
		var host: Device = body.host()
		host.dismount(host.seat_of(body))


## Cargo cannot settle where the occupant lies, feet to head, or in their crawl out over the burst end.
static func _recovery_route(world: World) -> AABB:
	var lie := PodShell.landed_pose(world.tuning).origin
	var radius := world.player.posture.standing.radius + world.player.safe_margin
	var back := PodShell.FEET_X
	var out := 1.5 * Chassis.WIDTH + Chassis.THICK + radius * 2.0
	return AABB(Vector3(back, lie.y, lie.z - radius),
		Vector3(out - back, world.player.posture.height(&"prone") + world.player.safe_margin, radius * 2.0))


## Break the assembly's pod fitting, retaining its own batteries and other internals.
static func _pod_attachment(body: RigidBody3D, deck: Chassis) -> RigidBody3D:
	var member := body
	while is_instance_valid(member):
		var parent: RigidBody3D
		if member is Part and member.socket != null:
			parent = member.socket.get_parent() as RigidBody3D
		elif member is Device:
			parent = member.host()
		if parent == deck:
			return member
		member = parent
	return null
