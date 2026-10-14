class_name Catalog
extends RefCounted
## Every device frame and part the skeleton knows, built in code as grey boxes
## with their sockets in defined spots. Salvage (Stage 8) will find them; until
## then the test kit scenario drops a set round you.

## Socket kinds, with the colour of the tell that marks a free one.
const KINDS := {
	&"battery": Color(0.95, 0.75, 0.2),
	&"ring": Color(0.85, 0.85, 0.85),
	&"bottom": Color(0.3, 0.7, 0.95),
	&"top": Color(0.4, 0.9, 0.5),
	&"plant_small": Color(0.55, 0.85, 0.3),
	&"plant_large": Color(0.35, 0.65, 0.2),
}

## Parts: the socket kind they fit, weight, size (z is how far they stand out
## from their socket), colour and what they give a device.
const PARTS := {
	&"battery": {"kind": &"battery", "label": "Battery", "mass": 4.0, "size": Vector3(0.22, 0.14, 0.12),
		"color": Color(0.2, 0.2, 0.22), "stats": {"capacity_wh": 100.0}},
	&"big_battery": {"kind": &"battery", "label": "Big battery", "mass": 9.0, "size": Vector3(0.26, 0.18, 0.18),
		"color": Color(0.15, 0.15, 0.3), "stats": {"capacity_wh": 300.0}},
	&"hook": {"kind": &"ring", "label": "Rope hook", "mass": 0.5, "size": Vector3(0.08, 0.08, 0.1),
		"color": Color(0.6, 0.6, 0.65), "stats": {"hooks": 1}},
	&"hover_tray": {"kind": &"bottom", "label": "Hover tray", "mass": 6.0, "size": Vector3(0.7, 0.7, 0.08),
		"color": Color(0.25, 0.45, 0.6), "stats": {"lift_kg": 80.0}},
	&"solar_panel": {"kind": &"top", "label": "Solar panel", "mass": 5.0, "size": Vector3(0.8, 0.6, 0.04),
		"color": Color(0.1, 0.15, 0.35), "stats": {"solar_w": 60.0, "catch": 0.08}},
	&"lamp": {"kind": &"top", "label": "Lamp", "mass": 1.0, "size": Vector3(0.12, 0.12, 0.25),
		"color": Color(0.95, 0.9, 0.6), "stats": {"light_w": 5.0}},
	&"seedling": {"kind": &"plant_small", "label": "Seedling", "mass": 0.3, "size": Vector3(0.1, 0.1, 0.18),
		"color": Color(0.3, 0.7, 0.2), "stats": {"plants": 1}},
	&"sapling": {"kind": &"plant_large", "label": "Sapling", "mass": 1.2, "size": Vector3(0.18, 0.18, 0.4),
		"color": Color(0.2, 0.55, 0.15), "stats": {"plants": 1}},
}

## Frames: their box, weight, wind catch and sockets as [kind, position, outward].
const DEVICES := {
	&"crate_frame": {"label": "Crate frame", "size": Vector3(0.8, 0.5, 0.8), "mass": 15.0, "catch": 0.05,
		"sockets": [
			[&"battery", Vector3(0.0, 0.0, 0.4), Vector3.BACK],
			[&"ring", Vector3(0.4, 0.0, 0.0), Vector3.RIGHT],
			[&"ring", Vector3(-0.4, 0.0, 0.0), Vector3.LEFT],
			[&"bottom", Vector3(0.0, -0.25, 0.0), Vector3.DOWN],
			[&"top", Vector3(0.0, 0.25, 0.0), Vector3.UP],
		]},
	&"planter": {"label": "Planter", "size": Vector3(1.0, 0.35, 0.6), "mass": 10.0, "catch": 0.06,
		"sockets": [
			[&"plant_small", Vector3(-0.3, 0.175, -0.12), Vector3.UP],
			[&"plant_small", Vector3(-0.3, 0.175, 0.12), Vector3.UP],
			[&"plant_small", Vector3(0.0, 0.175, 0.0), Vector3.UP],
			[&"plant_large", Vector3(0.3, 0.175, 0.0), Vector3.UP],
			[&"battery", Vector3(-0.5, 0.0, 0.0), Vector3.LEFT],
			[&"ring", Vector3(0.0, 0.0, 0.3), Vector3.BACK],
			[&"ring", Vector3(0.0, 0.0, -0.3), Vector3.FORWARD],
			[&"bottom", Vector3(0.0, -0.175, 0.0), Vector3.DOWN],
		]},
}


static func part(id: StringName) -> Part:
	var spec: Dictionary = PARTS[id]
	var made := Part.new()
	made.kind = spec.kind
	made.label = spec.label
	made.mass = spec.mass
	made.stats = spec.stats.duplicate()
	var size: Vector3 = spec.size
	# Standing out from its socket along +Z.
	_add_box(made, size, Vector3(0.0, 0.0, size.z * 0.5), spec.color)
	return made


static func device(id: StringName) -> Device:
	var spec: Dictionary = DEVICES[id]
	var made := Device.new()
	made.label = spec.label
	made.frame_mass = spec.mass
	made.frame_catch = spec.catch
	_add_box(made, spec.size, Vector3.ZERO, Color(0.55, 0.55, 0.55))
	for entry: Array in spec.sockets:
		var socket := Socket.new()
		socket.kind = entry[0]
		var outward: Vector3 = entry[2]
		socket.transform = Transform3D(_facing(outward), entry[1])
		var tell := MeshInstance3D.new()
		var plate := BoxMesh.new()
		plate.size = Vector3(0.1, 0.1, 0.01)
		var look := StandardMaterial3D.new()
		look.albedo_color = KINDS[socket.kind]
		look.emission_enabled = true
		look.emission = KINDS[socket.kind] * 0.3
		plate.material = look
		tell.mesh = plate
		tell.position = Vector3(0.0, 0.0, 0.005)
		socket.add_child(tell)
		socket.marker = tell
		made.add_child(socket)
	return made


## A basis whose +Z points along outward.
static func _facing(outward: Vector3) -> Basis:
	var up := Vector3.UP if absf(outward.dot(Vector3.UP)) < 0.9 else Vector3.BACK
	return Basis.looking_at(-outward, up)


static func _add_box(body: CollisionObject3D, size: Vector3, at: Vector3, color: Color) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	var look := StandardMaterial3D.new()
	look.albedo_color = color
	cube.material = look
	mesh.mesh = cube
	mesh.position = at
	body.add_child(mesh)
