class_name PodShell
extends RefCounted
## A reclined Surveyor capsule assembled from ordinary recoverable deck parts.
## This layout prototype does not replace a kit or decide which equipment survives.

const PANELS := {
	&"roof_a": [Vector2i(0, 0), &"top"],
	&"roof_b": [Vector2i(1, 0), &"top"],
	&"side_front_a": [Vector2i(0, 0), &"front"],
	&"side_front_b": [Vector2i(1, 0), &"front"],
	&"side_back_a": [Vector2i(0, 0), &"back"],
	&"side_back_b": [Vector2i(1, 0), &"back"],
	&"hatch": [Vector2i(0, 0), &"left"],
	&"tail": [Vector2i(1, 0), &"right"],
}
const VIEWPORTS: Array[StringName] = [&"tail", &"side_front_a", &"side_front_b", &"side_back_a", &"side_back_b", &"roof_a", &"roof_b"]
## Behind the seat the shield and camp cell stand side by side at the back of the cargo space.
const STORES_X := -0.25
## Landed, your feet stop just short of the shield's front.
const FEET_X := STORES_X + 0.19
static var _armor: ArrayMesh
static var _heatshield: ArrayMesh

static func layout(survives: Dictionary = {}) -> Array:
	var steps: Array = [[&"piece", Vector2i(1, 0)]]
	for i in 2:
		if survives.get(&"frame_a" if i == 0 else &"frame_b", true):
			steps.append([&"frame", Vector2i(i, 0)])
	for role: StringName in PANELS:
		var frame: StringName = &"frame_a" if PANELS[role][0].x == 0 else &"frame_b"
		if survives.get(role, true) and survives.get(frame, true):
			steps.append([&"wall", PANELS[role][0], PANELS[role][1]])
	return steps


## Named roles refer to real pieces, so later damage and teardown keep their identity.
static func build(parent: Node, pose: Transform3D, survives: Dictionary = {}) -> Rig:
	var rig := Rig.build(parent, layout(survives))
	var deck := rig.deck
	rig.named[&"floor_a"] = deck
	rig.named[&"floor_b"] = Rig.piece(deck, Vector2i(1, 0))
	for cell in [Vector2i(0, 0), Vector2i(1, 0)]:
		var floor := Rig.piece(deck, cell)
		for socket in deck.stuck():
			if socket.part is Frame and deck.own_piece(socket) == floor:
				rig.named[&"frame_a" if cell.x == 0 else &"frame_b"] = socket.part
	for role: StringName in PANELS:
		var seat := Rig.face_of(deck, PANELS[role][0], PANELS[role][1])
		for panel in deck.joined:
			if panel.joined_at == seat:
				rig.named[role] = panel
				restore_skin(panel, &"viewport" if role in VIEWPORTS else &"armor")
	for role in [&"floor_a", &"floor_b"]:
		restore_skin(rig.named[role], &"heatshield")
	deck.global_transform = pose
	return rig


## Saved role skins follow the same real panel through joining and teardown.
static func restore_skin(body: Chassis, kind: StringName = &"") -> void:
	if kind == &"":
		kind = body.get_meta(&"pod_skin", &"")
	# Old materializers explicitly request armor; the same tail keeps its window.
	if kind == &"armor" and (body.get_meta(&"arrival_uid", &"") == &"tail"
		or body.get_meta(&"pod_skin", &"") == &"viewport"):
		kind = &"viewport"
	if kind == &"viewport":
		_restore_aperture(body)
		return
	if not kind in [&"armor", &"heatshield"]:
		return
	body.set_meta(&"pod_skin", kind)
	var deck := body.deck if body.deck != null else body
	for child in deck.get_children():
		if child is MeshInstance3D and child.get_meta(&"pod_skin", &"") == kind \
			and child.get_meta(&"piece", deck) == body:
			child.set_instance_shader_parameter(&"age", Paint.age_for(body, deck.durability))
			return
	var view := MeshInstance3D.new()
	view.mesh = _armor_mesh() if kind == &"armor" else _heatshield_mesh()
	view.set_meta(&"pod_skin", kind)
	if body != deck:
		view.set_meta(&"piece", body)
	deck.add_child(view)
	view.transform = body.pose()
	view.set_instance_shader_parameter(&"age", Paint.age_for(body, deck.durability))


static func _armor_mesh() -> ArrayMesh:
	if _armor != null:
		return _armor
	var b := Paint.Pieces.new(-Chassis.THICK * 0.5)
	var bone := Paint.coat(Paint.BONE, 0.05, 0.75)
	var gun := Paint.coat(Paint.GUNMETAL)
	var black := Paint.coat(Paint.BLACK)
	var liner := Paint.coat(Paint.BLACK, 1.0, 0.0, 0.85, 0.02)
	var yellow := Paint.coat(Paint.YELLOW)
	var teal := Paint.coat(Paint.TEAL)
	# Thin skins leave the real chassis perimeter, hooks and mounting faces readable.
	b.box(Vector3(0.74, 0.012, 0.74), Vector3(0, 0.068, 0), bone, 0.012)
	b.box(Vector3(0.16, 0.016, 0.60), Vector3(0.245, 0.079, 0), teal, 0.006)
	b.box(Vector3(0.33, 0.018, 0.18), Vector3(-0.125, 0.080, -0.15), gun, 0.007)
	for z in [-0.205, -0.17, -0.135, -0.10]:
		b.box(Vector3(0.23, 0.005, 0.013), Vector3(-0.125, 0.092, z), black, 0.002)
	for x in [-0.29, 0.29]:
		for z in [-0.29, 0.29]:
			b.box(Vector3(0.075, 0.022, 0.09), Vector3(x, 0.082, z), gun, 0.008)
			b.box(Vector3(0.030, 0.009, 0.054), Vector3(x, 0.098, z), yellow, 0.004)
	# The inner face stays dark, with a visible thermal liner rather than another outer skin.
	b.box(Vector3(0.77, 0.010, 0.77), Vector3(0, -0.067, 0), liner, 0.010)
	for x in [-0.26, 0.0, 0.26]:
		b.box(Vector3(0.012, 0.008, 0.66), Vector3(x, -0.076, 0), gun, 0.002)
	_armor = b.commit()
	return _armor


static func _heatshield_mesh() -> ArrayMesh:
	if _heatshield != null:
		return _heatshield
	var b := Paint.Pieces.new(-0.09)
	var black := Paint.coat(Paint.BLACK, 0.0, 0.9)
	var scar := Paint.coat(Paint.RUST, 0.1, 0.9)
	b.box(Vector3(0.88, 0.025, 0.88), Vector3(0, -0.077, 0), black, 0.02)
	for x in [-0.29, 0.0, 0.29]:
		for z in [-0.29, 0.0, 0.29]:
			b.box(Vector3(0.275, 0.010, 0.275), Vector3(x, -0.094, z), black, 0.008)
	b.box(Vector3(0.85, 0.008, 0.04), Vector3(0, -0.103, 0.27), scar, 0.002)
	_heatshield = b.commit()
	return _heatshield


## Close the actual retained panels; no replacement chassis is constructed.
## In orbit nothing has been out in the weather: age 0 is the wear shader's sealed look.
## Landing puts back each surface's own age, which then builds with time on the sand.
static func seal_weather(bodies: Array, sealed: bool) -> void:
	var seen := {}
	for body: Variant in bodies:
		if not is_instance_valid(body):
			continue
		for view: Node in [body] + (body as Node).find_children("*", "GeometryInstance3D", true, false):
			if not view is GeometryInstance3D or seen.has(view):
				continue
			seen[view] = true
			var geometry := view as GeometryInstance3D
			if sealed:
				if not geometry.has_meta(&"ground_age"):
					var age: Variant = geometry.get_instance_shader_parameter(&"age")
					geometry.set_meta(&"ground_age", 1.0 if age == null else age)
				geometry.set_instance_shader_parameter(&"age", 0.0)
			elif geometry.has_meta(&"ground_age"):
				geometry.set_instance_shader_parameter(&"age", geometry.get_meta(&"ground_age"))
				geometry.remove_meta(&"ground_age")


static func reseal(rig: Rig) -> void:
	for role: StringName in PANELS:
		var panel := rig.named.get(role) as Chassis
		if is_instance_valid(panel) and panel.deck == null and panel != rig.deck:
			var face := Rig.face_of(rig.deck, PANELS[role][0], PANELS[role][1])
			if face != null and face.is_open():
				rig.deck.join(panel, face)


## Upgrade the actual retained panel, never replace its body or attachment.
static func ensure_aperture(parts: Dictionary) -> void:
	for role: StringName in VIEWPORTS:
		var panel := parts.get(role) as Chassis
		if is_instance_valid(panel):
			restore_skin(panel, &"viewport")


static func seat_pose() -> Transform3D:
	return Transform3D(Basis.looking_at(Vector3.RIGHT, Vector3.UP), Vector3(0.5, 0.07, 0))


## The impact throws you prone over the seat onto the open front floor, the
## length of you ahead of the shield and cell, facing the burst end.
static func landed_pose(rules: Tuning) -> Transform3D:
	var pose := seat_pose()
	pose.origin.x = FEET_X + rules.posture_prone_length
	return pose


static func view_aperture_pose() -> Transform3D:
	return Transform3D(Basis.looking_at(Vector3.RIGHT, Vector3.UP), Vector3(1.56, 0.56, 0))


static func view_aperture_size() -> Vector2:
	return Vector2(PodApertureLooks.OPENING.y, PodApertureLooks.OPENING.x)


static func flight_interior(parts: Dictionary = {}) -> PodInterior:
	return PodInterior.build(parts)


static func _restore_aperture(body: Chassis) -> void:
	body.set_meta(&"pod_skin", &"viewport")
	body.frame_view.mesh = PodApertureLooks.frame()
	var deck := body.deck if body.deck != null else body
	# The old opaque liner must go too, including skins restored before joining.
	for child in deck.get_children():
		if child is MeshInstance3D and child.get_meta(&"piece", deck) == body \
			and child.has_meta(&"pod_skin") and child.get_meta(&"pod_skin") != &"viewport":
			body._own.erase(child)
			deck.remove_child(child)
			child.free()
	for face in [-1.0, 1.0]:
		var found := false
		for child in deck.get_children():
			if child is MeshInstance3D and child.get_meta(&"piece", deck) == body \
				and child.get_meta(&"pod_pane", 0.0) == face:
				found = true
		if found:
			continue
		var pane := MeshInstance3D.new()
		pane.mesh = PodApertureLooks.glass()
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pane.set_meta(&"pod_skin", &"viewport")
		pane.set_meta(&"pod_pane", face)
		if body != deck:
			pane.set_meta(&"piece", body)
		deck.add_child(pane)
		pane.transform = body.pose() * Transform3D(Basis.IDENTITY, Vector3(0, face * 0.05, 0))
