class_name PreflightCargo
extends RefCounted
## Physical ship stores share ordinary catalog bodies and saved arrival identities.

const GEOMETRY_EPS := 0.00001
const REQUIRED := [&"water", &"food", &"shield", &"camp_cell"]


static func stage(world: World, ship: SurveyorShip, state: Dictionary) -> Dictionary:
	var named := SurveyorRecovery.named(world)
	var preflight: Dictionary = state.get("preflight", {})
	if preflight.get("staged", false):
		return named
	var counting := world.counts_deeds
	world.counts_deeds = false
	for role: StringName in ship.pod_parts:
		var body: Node = ship.pod_parts[role]
		body.set_meta(&"arrival_uid", role)
		if body is RigidBody3D:
			body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		named[role] = body
	var made: Array[RigidBody3D] = []
	for spec: Array in SurveyorManifest.EQUIPMENT:
		var uid: StringName = spec[0]
		if named.has(uid):
			continue
		var body: RigidBody3D
		if spec[1] == &"coil":
			body = Line.make(world, world.tuning.surveyor_arrival.rope_m).coil
		elif spec[1] == &"stake":
			body = Catalog.stake()
		else:
			body = Catalog.part(spec[1]) if Catalog.PARTS.has(spec[1]) else Catalog.device(spec[1])
		if body.get_parent() == null:
			world.content.add_child(body)
		body.set_meta(&"arrival_uid", uid)
		# New stores wait away from the work surface until assigned their real seats.
		world.teleport(body, ship.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 4, 0)))
		named[uid] = body
		made.append(body)
	var board := named[&"board"] as Device
	var cell := named[&"board_cell"] as Part
	if cell.socket == null:
		for socket in board.sockets():
			if socket.kind == &"battery" and socket.is_open():
				board.fit(cell, socket)
				break
	var deck := ship.pod.deck
	if (named[&"shield"] as Device).host() == null:
		Stick.put(deck, ship.pod_parts[&"floor_a"], Chassis.TOP, Vector2(-0.2, 0.2), 0.0, named[&"shield"])
	if (named[&"camp_cell"] as Part).socket == null:
		Stick.put(deck, ship.pod_parts[&"floor_a"], Chassis.TOP, Vector2(-0.2, -0.2), 0.0, named[&"camp_cell"])
	var reserved: Array[AABB] = [seat_bounds(world, ship)]
	for role: StringName in [&"shield", &"camp_cell"]:
		reserved.append(bounds_in(named[role], ship.global_transform))
	for pair: Array in [[&"water", Vector3(1.13, 0.0, 0.2)], [&"food", Vector3(1.13, 0.0, -0.2)]]:
		var body := named[pair[0]] as RigidBody3D
		var box := SurveyorRecovery._box(body)
		var pose := ship.pod_pose * Transform3D(Basis.IDENTITY, pair[1] + Vector3(-box.get_center().x, Chassis.THICK * 0.5 - box.position.y, -box.get_center().z))
		world.teleport(body, ship.global_transform * pose)
		reserved.append(pose * box)
	var cargo: Array[RigidBody3D] = []
	for spec: Array in SurveyorManifest.EQUIPMENT:
		if not spec[0] in REQUIRED and spec[0] != &"board_cell":
			cargo.append(named[spec[0]])
	cargo.sort_custom(func(a: RigidBody3D, b: RigidBody3D) -> bool: return SurveyorRecovery._box(a).get_volume() > SurveyorRecovery._box(b).get_volume())
	var rack_boxes: Array[AABB] = []
	for body in cargo:
		if not _rack(world, ship, body, rack_boxes):
			world.counts_deeds = counting
			return {}
	preflight.staged = true
	state.preflight = preflight
	world.arrival_nodes = named
	world.counts_deeds = counting
	return named


## Full collision geometry counts; looking at an item or holding it over the pod does not.
static func loaded(world: World, ship: SurveyorShip) -> Array[StringName]:
	var found: Array[StringName] = []
	var named := SurveyorRecovery.named(world)
	var seat := seat_bounds(world, ship)
	for spec: Array in SurveyorManifest.EQUIPMENT:
		var uid: StringName = spec[0]
		var body := named.get(uid) as RigidBody3D
		if not is_instance_valid(body) or _carried(world, body) or not _whole_line(world, ship, body):
			continue
		var box := bounds_in(body, ship.global_transform)
		if box.get_volume() > 0.0 and not seat.intersects(box) and (ship.cargo_bounds.grow(GEOMETRY_EPS).encloses(box) or _external(world, ship, body, box)):
			found.append(uid)
	return found


static func readiness(world: World, ship: SurveyorShip) -> PackedStringArray:
	var missing := PackedStringArray()
	var aboard := loaded(world, ship)
	var named := SurveyorRecovery.named(world)
	for uid: StringName in REQUIRED:
		if not aboard.has(uid) or not ship.cargo_bounds.grow(GEOMETRY_EPS).encloses(bounds_in(named[uid], ship.global_transform)):
			missing.append("Load " + str(uid).replace("_", " "))
		elif named[uid] is Supply and named[uid].amount <= 0.0:
			missing.append("Refill " + str(uid))
		elif named[uid] is Battery and named[uid].charge_wh <= 0.0:
			missing.append("Charge the camp cell")
	return missing


## Refusal is read-only. The controller commits its phase only after this succeeds.
static func seal(world: World, ship: SurveyorShip, state: Dictionary, profile: Dictionary) -> Dictionary:
	if state.get("preflight", {}).get("launched", false):
		return state
	if not readiness(world, ship).is_empty() or profile.is_empty() or not state.has("landing_point"):
		return {}
	var named := SurveyorRecovery.named(world)
	var selected := loaded(world, ship)
	var descriptors: Array[Dictionary] = []
	var poses := {}
	var body_states := {}
	var pod_world := ship.global_transform * ship.pod_pose
	for uid: StringName in selected:
		var body: RigidBody3D = named[uid]
		var entry := {"uid": uid, "id": body.get_meta(&"catalog"), "parent": _parent_uid(body)}
		if body is Device:
			entry.durability = body.durability
		descriptors.append(entry)
	for uid: StringName in named:
		var body: RigidBody3D = named[uid]
		if body.is_inside_tree():
			body_states[uid] = {"freeze": body.freeze, "collision_layer": body.collision_layer, "collision_mask": body.collision_mask}
	var resolved := SurveyorManifest.resolve_loaded(world.run_seed, state.landing_point, descriptors, profile)
	var out := state.duplicate(true)
	out.merge(resolved, true)
	var preflight: Dictionary = out.preflight
	preflight.loaded_uids = selected
	preflight.cargo_poses = poses
	preflight.body_states = body_states
	preflight.profile = profile.duplicate(true)
	preflight.launched = true
	# The exact retained panels close through ordinary real chassis joins.
	var counting := world.counts_deeds
	world.counts_deeds = false
	PodShell.reseal(ship.pod)
	world.counts_deeds = counting
	for uid: StringName in named:
		var body: RigidBody3D = named[uid]
		poses[uid] = pod_world.affine_inverse() * body_pose(body)
	for uid: StringName in selected:
		var body: RigidBody3D = named[uid]
		if body.has_meta(&"line"):
			var line := body.get_meta(&"line") as Line
			if is_instance_valid(line) and line.state == Line.State.LAID:
				for i in line.ends.size():
					poses[end_key(uid, i)] = pod_world.affine_inverse() * body_pose(line.ends[i])
	for uid: StringName in named:
		var body: RigidBody3D = named[uid]
		if body.is_inside_tree() and (selected.has(uid) or ship.pod_parts.has(uid)):
			body.freeze = true
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
	return out


static func land(world: World, state: Dictionary) -> Dictionary:
	return SurveyorRecovery.land_preflight(world, state)


static func _whole_line(world: World, ship: SurveyorShip, body: RigidBody3D) -> bool:
	if not body.has_meta(&"line"):
		return true
	var line := body.get_meta(&"line") as Line
	if not is_instance_valid(line) or line.state == Line.State.COILED:
		return true
	if line.state != Line.State.LAID:
		return false
	for end in line.ends:
		if _carried(world, end) or end.socket == null or not _pod_attachment(ship, end):
			return false
	if is_instance_valid(line.rope.through) and not _pod_attachment(ship, line.rope.through.holder):
		return false
	return true


static func _pod_attachment(ship: SurveyorShip, body: Node) -> bool:
	var on := body
	while on != null:
		for spec: Array in SurveyorManifest.STRUCTURE:
			if ship.pod_parts.get(spec[0]) == on:
				return true
		if on is Part and on.socket != null:
			on = on.socket.get_parent()
		else:
			on = on.host() if on is Device else null
	return false


static func _external(world: World, ship: SurveyorShip, body: RigidBody3D, box: AABB) -> bool:
	var on: Node = body.socket.get_parent() if body is Part and body.socket != null else body.get_parent()
	while on != null:
		if _pod_attachment(ship, on):
			var rules: Variant = world.tuning.get("surveyor_preflight")
			if not rules is Dictionary:
				return false
			var envelope: AABB = ship.pod_pose * rules.external_cargo_bounds
			return envelope.grow(GEOMETRY_EPS).encloses(box)
		on = on.host() if on is Device else null
	return false


static func end_key(uid: StringName, index: int) -> StringName:
	return StringName("%s:end:%d" % [uid, index])


static func body_pose(body: RigidBody3D) -> Transform3D:
	if body is Part and body.socket != null:
		var socket: Socket = body.socket
		return (socket.get_parent() as Node3D).global_transform * socket.transform
	if body is Chassis and body.deck != null:
		return body.deck.global_transform * body.pose()
	return body.global_transform


static func bounds_in(body: RigidBody3D, frame: Transform3D) -> AABB:
	var shapes: Array = body.socket.fitted if body is Part and body.socket != null else body.get_children()
	var result := AABB()
	var first := true
	for node in shapes:
		if node is CollisionShape3D and node.shape != null and node.is_inside_tree():
			var box: AABB = (frame.affine_inverse() * node.global_transform) * Catalog.bounds(node.shape)
			result = box if first else result.merge(box)
			first = false
	return result


static func seat_bounds(world: World, ship: SurveyorShip) -> AABB:
	var capsule := (world.player.get_node("Body") as CollisionShape3D).shape as CapsuleShape3D
	var radius := capsule.radius
	return AABB(ship.pod_seat_at.position + Vector3(-radius, 0, -radius), Vector3(radius * 2.0, world.tuning.posture_prone_height, radius * 2.0))


static func _carried(world: World, body: RigidBody3D) -> bool:
	var owner := body
	while owner != null:
		if world.player.hands.held == owner or world.player.hands.grasp.body == owner or world.player.suit.carried.has(owner) or world.player.waist.holds(owner):
			return true
		if owner is Part and owner.socket != null:
			owner = owner.socket.get_parent() as RigidBody3D
		elif owner is Device:
			owner = owner.host()
		else:
			break
	return false


static func _parent_uid(body: RigidBody3D) -> StringName:
	var parent: Node
	var socket: Socket
	if body is Part and body.socket != null:
		socket = body.socket
		parent = socket.get_parent()
	elif body is Device and body.host() != null:
		parent = body.host()
		socket = (parent as Device).seat_of(body)
	if parent is Chassis and socket != null:
		parent = (parent as Chassis).own_piece(socket)
	return parent.get_meta(&"arrival_uid", &"") if parent != null else &""


static func _rack(world: World, ship: SurveyorShip, body: RigidBody3D, occupied: Array[AABB]) -> bool:
	var shape := SurveyorRecovery._box(body)
	var pitch: float = world.tuning.surveyor_preflight.rack_pitch_m
	var gap: float = world.tuning.surveyor_preflight.cargo_gap_m
	for shelf in [ship.shelf_poses[0], ship.shelf_poses[3]]:
		for yaw in [0.0, PI * 0.5]:
			var turn := Basis(Vector3.UP, yaw)
			var local: AABB = Transform3D(turn, Vector3.ZERO) * shape
			for zi in ceili(ship.rack_bounds.size.z / pitch):
				for xi in ceili(ship.rack_bounds.size.x / pitch):
					var at := Vector3(ship.rack_bounds.position.x - local.position.x + xi * pitch, shelf.origin.y - local.position.y, ship.rack_bounds.position.z - local.position.z + zi * pitch)
					var pose := Transform3D(turn, at)
					var box := pose * shape
					if not ship.rack_bounds.encloses(box) or occupied.any(func(other: AABB) -> bool: return other.grow(gap).intersects(box)):
						continue
					world.teleport(body, ship.global_transform * pose)
					occupied.append(box)
					return true
	return false
