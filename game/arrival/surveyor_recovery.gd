class_name SurveyorRecovery
extends RefCounted
## Materialize resolved survivors once. Taking them remains the normal hands action.

static func materialize(world: World, state: Dictionary) -> Dictionary:
	var existing := named(world)
	if state.get("materialized", false) or not existing.is_empty():
		return existing
	if not state.has("landing_world") or not state.has("structure") or not state.has("equipment"):
		return {}
	var survivors := {}
	for entry: Dictionary in state.structure:
		survivors[StringName(entry.uid)] = bool(entry.survives)
	if not survivors.get(&"floor_a", false) or not survivors.get(&"floor_b", false):
		return {}
	var at: Vector2 = state.landing_world
	if not world.terrain.has_collision_at(at.x, at.y):
		return {}
	var rules := world.tuning.surveyor_arrival
	var gap := float(rules.get("spill_gap_m", 0.18))
	var clearance := float(rules.get("landing_clearance_m", 0.04))
	var heading := float(state.get("heading", 0.0))
	var facing := Basis(Vector3.UP, heading)
	var origin := Vector3(world.engine_x(at.x), 0.0, world.engine_z(at.y))
	var height := -INF
	for x in [-Chassis.WIDTH * 0.5 - Chassis.THICK, Chassis.WIDTH * 1.5 + Chassis.THICK]:
		for z in [-Chassis.WIDTH * 0.5 - Chassis.THICK, Chassis.WIDTH * 0.5 + Chassis.THICK]:
			height = maxf(height, world.height_under(origin + facing * Vector3(x, 0, z)))
	origin.y = height + Chassis.THICK * 0.5 + clearance
	var before := {}
	for child in world.content.get_children():
		before[child.get_instance_id()] = true
	var rig := PodShell.build(world.content, Transform3D(facing, origin), survivors)
	var objects := rig.named.duplicate()
	var reserved: Array[AABB] = []
	# The actual capsule reserves a clear player footprint at the controller's exit.
	var exit_world: Vector2 = state.get("exit_world", at + Vector2(-3.2, 0).rotated(-heading))
	var exit_at := Vector3(world.engine_x(exit_world.x), world.height_at(exit_world.x, exit_world.y), world.engine_z(exit_world.y))
	reserved.append((Transform3D(Basis.IDENTITY, exit_at) * Hands._shapes_box(world.player.get_children())).grow(gap))
	for shape in rig.deck.get_children():
		if shape is CollisionShape3D and shape.shape != null:
			reserved.append(shape.global_transform * Catalog.bounds(shape.shape))
	var placements := {}
	# Roof and end hatch become real loose recovery panels before the player stands.
	for role in [&"roof_a", &"hatch"]:
		if objects.has(role):
			var panel := rig.deck.detach(objects[role])
			if not _spill(world, panel, facing, origin, reserved, gap, clearance, rules):
				return _abort(world, before)
			placements[role] = &"opened"
	for entry: Dictionary in state.structure:
		if not entry.survives:
			continue
		var uid := StringName(entry.uid)
		var body: RigidBody3D = objects.get(uid)
		if body == null:
			body = Catalog.part(entry.id) if Catalog.PARTS.has(entry.id) else Catalog.device(entry.id)
			world.content.add_child(body)
			objects[uid] = body
			if not _spill(world, body, facing, origin, reserved, gap, clearance, rules):
				return _abort(world, before)
			placements[uid] = &"spill"
		else:
			placements.get_or_add(uid, &"joined")
		body.set_meta(&"arrival_uid", uid)
		_apply(body, entry.get("state", {}))
		if body is Chassis:
			PodShell.restore_skin(body, &"heatshield" if uid in [&"floor_a", &"floor_b"] else &"armor")
	# A joined deck shares the least sound of its real structural pieces.
	for panel in rig.deck.joined:
		rig.deck.durability = minf(rig.deck.durability, panel.durability)
	rig.deck.show_wear()
	for panel in rig.deck.pieces():
		PodShell.restore_skin(panel)
	var equipment := {}
	for entry: Dictionary in state.equipment:
		if not entry.survives:
			continue
		var uid := StringName(entry.uid)
		var body: RigidBody3D
		if entry.id == &"stake":
			body = Catalog.stake()
		elif entry.id == &"coil":
			body = Line.make(world, entry.state.metres).coil
		else:
			body = Catalog.part(entry.id) if Catalog.PARTS.has(entry.id) else Catalog.device(entry.id)
		if body.get_parent() == null:
			world.content.add_child(body)
		body.global_position = origin + Vector3.UP * Frame.TALL * 4.0
		body.set_meta(&"arrival_uid", uid)
		_apply(body, entry.get("state", {}))
		objects[uid] = body
		equipment[uid] = entry
	if objects.has(&"board") and objects.has(&"board_cell"):
		var board := objects[&"board"] as Device
		for socket in board.sockets():
			if socket.kind == &"battery" and socket.is_open():
				board.fit(objects[&"board_cell"], socket)
				placements[&"board_cell"] = &"fitted"
				break
	var order: Array = state.get("cargo_order", equipment.keys())
	for uid: StringName in order:
		if not equipment.has(uid) or placements.has(uid):
			continue
		var body := objects[uid] as RigidBody3D
		var turn := facing * Basis(Vector3.UP, PI * 0.5) if uid == &"board" else facing
		if _stow(world, body, turn, rig.deck, reserved, gap, clearance):
			placements[uid] = &"pod"
		elif _spill(world, body, turn, origin, reserved, gap, clearance, rules):
			placements[uid] = &"spill"
		else:
			return _abort(world, before)
	state["placements"] = placements
	state["materialized"] = true
	return objects


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


static func _apply(body: RigidBody3D, state: Dictionary) -> void:
	if body is Device and state.has("durability"):
		body.durability = state.durability
		body.show_wear()
	if body is Battery and state.has("charge_fraction"):
		body.charge_wh = body.capacity() * state.charge_fraction
		body.show_charge()
	if body is Supply and state.has("fill_fraction"):
		body.drain(body.amount * (1.0 - state.fill_fraction))


static func _box(body: RigidBody3D) -> AABB:
	return body.shape_bounds() if body is Device else Hands._box_of(body)


static func _stow(world: World, body: RigidBody3D, facing: Basis, deck: Chassis, reserved: Array[AABB], gap: float, clearance: float) -> bool:
	var local := Transform3D(facing, Vector3.ZERO) * _box(body)
	for x in [-0.2, 0.2, 0.8, 1.2]:
		for z in [-0.22, 0.22, 0.0]:
			var at := deck.global_transform * Vector3(x, 0, z)
			at.y = deck.global_position.y + Chassis.THICK * 0.5 - local.position.y + clearance
			var pose := Transform3D(facing, at)
			var inside := AABB(Vector3(-0.45, Chassis.THICK * 0.5, -0.45), Vector3(1.9, Frame.TALL - Chassis.THICK, 0.9))
			if not inside.encloses((deck.global_transform.affine_inverse() * pose) * _box(body)):
				continue
			if _put(world, body, pose, reserved, gap):
				return true
	return false


static func _spill(world: World, body: RigidBody3D, facing: Basis, origin: Vector3, reserved: Array[AABB], gap: float, clearance: float, rules: Dictionary) -> bool:
	var local := Transform3D(facing, Vector3.ZERO) * _box(body)
	var pitch := maxf(local.size.x, local.size.z) + gap
	var columns := maxi(1, int(rules.get("spill_columns", 5)))
	for i in int(rules.get("spill_attempts", 80)):
		var offset := Vector3((i % columns - columns / 2) * pitch, 0, (i / columns + 1) * pitch + Chassis.WIDTH * 0.5 + gap)
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
	var box := pose * _box(body)
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


static func _abort(world: World, before: Dictionary) -> Dictionary:
	for child in world.content.get_children():
		if is_instance_valid(child) and not before.has(child.get_instance_id()):
			world.content.remove_child(child)
			child.free()
	return {}


## A preflight landing moves the surviving saved bodies, never grants replacement gear.
static func land_preflight(world: World, state: Dictionary) -> Dictionary:
	var objects := named(world)
	if state.get("materialized", false):
		return objects
	if not state.get("preflight", {}).get("launched", false) or not state.has("landing_world"):
		return {}
	var at: Vector2 = state.landing_world
	if not world.terrain.has_collision_at(at.x, at.y):
		return {}
	for entry: Dictionary in state.structure + state.equipment:
		if entry.survives and not is_instance_valid(objects.get(StringName(entry.uid))):
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
			var parent_uid := PreflightCargo._parent_uid(end)
			if parent_uid != &"" and not survived.get(parent_uid, false):
				_unseat(end)
				if end != primary:
					loose_ends[PreflightCargo.end_key(entry.uid, k)] = end
	# Detach survivors before removing a parent lost in impact.
	for entry: Dictionary in state.equipment:
		var body := objects.get(StringName(entry.uid)) as RigidBody3D
		if entry.survives and is_instance_valid(body):
			var parent_uid := PreflightCargo._parent_uid(body)
			if parent_uid != &"" and not survived.get(parent_uid, false):
				_unseat(body)
	var floor := objects[&"floor_a"] as Chassis
	var deck := floor.deck if floor.deck != null else floor
	# The opened roof and hatch are the same real panels, also if a frame is lost.
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
	var rules := world.tuning.surveyor_arrival
	origin.y = height + Chassis.THICK * 0.5 + float(rules.get("landing_clearance_m", 0.04))
	var pose := Transform3D(facing, origin)
	world.teleport(deck, pose * floor.pose().affine_inverse())
	deck.freeze = false
	deck.linear_velocity = Vector3.ZERO
	deck.angular_velocity = Vector3.ZERO
	# Keep surviving enclosure panels joined, except the actual exit roof and hatch.
	for role: StringName in PodShell.PANELS:
		if role in [&"roof_a", &"hatch"] or not objects.has(role):
			continue
		var panel := objects[role] as Chassis
		var frame := Rig.face_of(deck, PodShell.PANELS[role][0], PodShell.PANELS[role][1])
		if frame != null:
			deck.join(panel, frame)
	var route := _recovery_route(world)
	# The impact frees fittings across the occupant's route, not their saved identities.
	for entry: Dictionary in state.equipment:
		var body := objects.get(StringName(entry.uid)) as RigidBody3D
		if entry.survives and is_instance_valid(body) and route.intersects(PreflightCargo.bounds_in(body, pose)):
			_unseat(body)
	var gap := float(rules.get("spill_gap_m", 0.18))
	var clearance := float(rules.get("landing_clearance_m", 0.04))
	var reserved: Array[AABB] = []
	reserved.append(pose * route)
	var exit_world: Vector2 = state.get("exit_world", at + Vector2(-3.2, 0).rotated(-float(state.get("heading", 0.0))))
	var exit_at := Vector3(world.engine_x(exit_world.x), world.height_at(exit_world.x, exit_world.y), world.engine_z(exit_world.y))
	reserved.append((Transform3D(Basis.IDENTITY, exit_at) * Hands._shapes_box(world.player.get_children())).grow(gap))
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
			return {}
		body.freeze = false
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		placements[uid] = &"pod" if inside else &"spill"
	for key: StringName in loose_ends:
		var end := loose_ends[key] as RigidBody3D
		var desired: Transform3D = pose * poses[key]
		if not _put(world, end, desired, reserved, gap) and not _spill(world, end, facing, origin, reserved, gap, clearance, rules):
			return {}
		end.freeze = false
		end.linear_velocity = Vector3.ZERO
		end.angular_velocity = Vector3.ZERO
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


## Cargo cannot settle in the occupant's crawl route through the opened hatch.
static func _recovery_route(world: World) -> AABB:
	var capsule := world.player.posture.standing
	var seat := PodShell.seat_pose().origin
	var margin := world.player.safe_margin
	var radius := capsule.radius + margin
	var hatch := -Chassis.WIDTH * 0.5 - Chassis.THICK - radius
	return AABB(Vector3(hatch, seat.y, seat.z - radius),
		Vector3(seat.x + radius - hatch, world.player.posture.height(&"prone") + margin, radius * 2.0))
