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
			if _put(world, body, Transform3D(facing, at), reserved, gap):
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
