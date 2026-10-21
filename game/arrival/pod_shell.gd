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
static var _armor: ArrayMesh
static var _heatshield: ArrayMesh

static func layout() -> Array:
	var steps: Array = [[&"piece", Vector2i(1, 0)],
		[&"frame", Vector2i(0, 0)], [&"frame", Vector2i(1, 0)]]
	for role: StringName in PANELS:
		steps.append([&"wall", PANELS[role][0], PANELS[role][1]])
	return steps


## Named roles refer to real pieces, so later damage and teardown keep their identity.
static func build(parent: Node, pose: Transform3D) -> Rig:
	var rig := Rig.build(parent, layout())
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
				_trim(deck, panel, _armor_mesh(), "PodArmor")
	for role in [&"floor_a", &"floor_b"]:
		_trim(deck, rig.named[role], _heatshield_mesh(), "PodHeatshield")
	deck.global_transform = pose
	return rig


static func _trim(deck: Chassis, owner: Chassis, mesh: Mesh, name: String) -> void:
	var view := MeshInstance3D.new()
	view.name = name
	view.mesh = mesh
	view.set_meta(&"pod_skin", true)
	# Chassis.detach moves nodes marked with their owning piece, including this skin.
	if owner != deck:
		view.set_meta(&"piece", owner)
	deck.add_child(view)
	view.transform = owner.pose()
	view.set_instance_shader_parameter(&"wear", 0.26)


static func _armor_mesh() -> ArrayMesh:
	if _armor != null:
		return _armor
	var b := Paint.Pieces.new(-Chassis.THICK * 0.5)
	var bone := Paint.coat(Paint.BONE, 0.05, 0.75)
	var gun := Paint.coat(Paint.GUNMETAL)
	var black := Paint.coat(Paint.BLACK)
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
	b.box(Vector3(0.77, 0.010, 0.77), Vector3(0, -0.067, 0), black, 0.010)
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
