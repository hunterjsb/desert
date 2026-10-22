class_name PreflightCargo
extends RefCounted
## Physical ship stores share ordinary catalog bodies and saved arrival identities.

const GEOMETRY_EPS := 0.0001
const CLOSURES := [&"roof_a", &"roof_b", &"hatch"]
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
	var missing := _structure_readiness(world, ship)
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


## Automatic closing may move retained lids, never reconstruct dismantled supports.
static func _structure_readiness(world: World, ship: SurveyorShip) -> PackedStringArray:
	if ship.pod == null or not is_instance_valid(ship.pod.deck):
		return PackedStringArray(["Repair the pod floor"])
	var root := ship.pod.deck
	if not root.is_inside_tree() or root.deck != null or _carried(world, root):
		return PackedStringArray(["Set down the pod"])
	for role: StringName in [&"floor_a", &"floor_b", &"frame_a", &"frame_b"]:
		if not is_instance_valid(ship.pod_parts.get(role)):
			return PackedStringArray(["Repair the pod support"])
	var a := ship.pod_parts[&"floor_a"] as Chassis
	var b := ship.pod_parts[&"floor_b"] as Chassis
	if not (a == root or a.deck == root and root.joined.has(a)) \
		or not (b == root or b.deck == root and root.joined.has(b)) \
		or not (a.pose().affine_inverse() * b.pose()).is_equal_approx(Transform3D(Basis.IDENTITY, Vector3.RIGHT * Chassis.WIDTH)):
		return PackedStringArray(["Repair the pod floor"])
	for index in 2:
		var frame := ship.pod_parts[&"frame_a" if index == 0 else &"frame_b"] as Frame
		var floor := a if index == 0 else b
		if frame == null or not is_instance_valid(frame.socket) or frame.socket.get_parent() != root \
			or root.own_piece(frame.socket) != floor \
			or not frame.socket.transform.is_equal_approx(Stick.pose_on(root, floor, Chassis.TOP, Vector2.ZERO, 0.0, frame)):
			return PackedStringArray(["Repair the pod frame"])
	for role: StringName in PodShell.PANELS:
		if not is_instance_valid(ship.pod_parts.get(role)):
			return PackedStringArray(["Replace the pod " + str(role).replace("_", " ")])
		var panel := ship.pod_parts[role] as Chassis
		var spec: Array = PodShell.PANELS[role]
		var frame := ship.pod_parts[&"frame_a" if spec[0].x == 0 else &"frame_b"] as Frame
		var face := frame.faces().get(spec[1]) as Socket
		if panel == null or not is_instance_valid(face) or face.get_parent() != root:
			return PackedStringArray(["Repair the pod shell"])
		var roof := role in [&"roof_a", &"roof_b"]
		var seats := _roof_faces(ship) if roof else [face]
		if panel.deck == root and root.joined.has(panel) and seats.has(panel.joined_at):
			continue
		if not role in CLOSURES:
			return PackedStringArray(["Repair the pod shell"])
		var name := "front roof" if role == &"roof_a" else "rear roof" if role == &"roof_b" else "hatch"
		if _carried(world, panel):
			return PackedStringArray(["Set down the pod " + name])
		if not panel.joined.is_empty():
			return PackedStringArray(["Separate joined panels from the " + name])
		if panel.deck != null or panel.host() != null:
			var destination := "either pod frame's top face" if roof else "the pod front frame's left face"
			return PackedStringArray(["Take the " + name + " off " + _mount_name(ship, panel)
				+ "; fit it on " + destination])
		if panel.get_parent() != world.content:
			return PackedStringArray(["Set down the pod " + name])
		var needed := 1
		if roof:
			needed = 0
			for roof_role: StringName in [&"roof_a", &"roof_b"]:
				var other := ship.pod_parts.get(roof_role) as Chassis
				if not is_instance_valid(other) or other.deck != root or not seats.has(other.joined_at):
					needed += 1
		# Every loose roof needs its own clear face; two cannot share one opening.
		if seats.filter(func(seat: Socket) -> bool: return seat.is_open()).size() < needed:
			return PackedStringArray(["Clear a pod frame's top face for the " + name] if roof
				else ["Clear the pod front frame's left face for the hatch"])
	return PackedStringArray()


static func _roof_faces(ship: SurveyorShip) -> Array:
	return [(ship.pod_parts[&"frame_a"] as Frame).faces()[&"top"],
		(ship.pod_parts[&"frame_b"] as Frame).faces()[&"top"]]


## Name the physical attachment, so a refusal points at something the player can change.
static func _mount_name(ship: SurveyorShip, panel: Chassis) -> String:
	if panel.deck == ship.pod.deck:
		for role: StringName in [&"frame_a", &"frame_b"]:
			var frame := ship.pod_parts[role] as Frame
			for side: StringName in frame.faces():
				if frame.faces()[side] == panel.joined_at:
					return "the pod " + ("front" if role == &"frame_a" else "rear") + " frame's " + str(side) + " face"
		return "the edge of the pod floor"
	if panel.deck != null:
		return "another chassis (" + panel.deck.label + ")"
	var host := panel.host()
	if host == ship.pod.deck:
		var socket := host.seat_of(panel)
		var piece := (host as Chassis).own_piece(socket)
		for role: StringName in ship.pod_parts:
			if ship.pod_parts[role] == piece:
				var side := "top" if socket.out.dot(piece.pose().basis.y) > 0.0 else "underside"
				var name := "front floor" if role == &"floor_a" else "rear floor" if role == &"floor_b" else str(role).replace("_", " ")
				return "the " + side + " of the pod " + name
	return "the " + host.label if host != null else "its attachment"


## Refusal is read-only. The controller commits its phase only after this succeeds.
static func seal(world: World, ship: SurveyorShip, state: Dictionary, profile: Dictionary) -> Dictionary:
	if state.get("preflight", {}).get("launched", false):
		return state
	if not readiness(world, ship).is_empty() or not _valid_profile(world, profile) or not _valid_point(state.get("landing_point")):
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
	# Identical roofs may already occupy each other's original seats.
	for role: StringName in [&"roof_a", &"roof_b"]:
		var roof := ship.pod_parts[role] as Chassis
		if roof.deck == null:
			for face: Socket in _roof_faces(ship):
				if face.is_open():
					ship.pod.deck.join(roof, face)
					break
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


static func _valid_point(point: Variant) -> bool:
	return point is Vector3 and point.is_finite() and is_equal_approx(point.length_squared(), 1.0)


static func _valid_profile(world: World, profile: Dictionary) -> bool:
	if not world.tuning.surveyor_preflight.profiles.has(profile.get("id", &"")):
		return false
	for key in ["outer_survival", "frame_survival", "extra_survival", "usable_min"]:
		if profile.has(key):
			var value: Variant = profile[key]
			if not (value is float or value is int) or not is_finite(float(value)) or value < 0.0 or value > 1.0:
				return false
	for key in ["device_durability", "chassis_durability"]:
		if profile.has(key):
			var span: Variant = profile[key]
			if not span is Vector2 or not span.is_finite() or minf(span.x, span.y) < 0.0 or maxf(span.x, span.y) > 1.0:
				return false
	for key in ["descent_s", "entry_s"]:
		if profile.has(key):
			var value: Variant = profile[key]
			if not (value is float or value is int) or not is_finite(float(value)) or value < 0.0:
				return false
	return true


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
