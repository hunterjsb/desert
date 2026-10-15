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
	&"port": Color(1.0, 0.5, 0.1),
	&"tie": Color(0.42, 0.31, 0.2),
	&"water": Color(0.3, 0.6, 1.0),
}

## Parts: the socket kind they fit, weight, size (z is how far they stand out
## from their socket), colour and what they give a device. A "tie" is the ring
## a part adds while it's fitted, where a line's end snaps on.
const PARTS := {
	&"battery": {"kind": &"battery", "label": "Battery", "mass": 4.0, "size": Vector3(0.22, 0.14, 0.12),
		"color": Color(0.2, 0.2, 0.22), "stats": {"capacity_wh": 100.0}},
	&"big_battery": {"kind": &"battery", "label": "Big battery", "mass": 9.0, "size": Vector3(0.26, 0.18, 0.18),
		"color": Color(0.15, 0.15, 0.3), "stats": {"capacity_wh": 300.0}},
	&"hook": {"kind": &"ring", "label": "Rope hook", "mass": 0.5, "size": Vector3(0.08, 0.08, 0.1),
		"color": Color(0.6, 0.6, 0.65), "stats": {"hooks": 1}, "tie": Vector3(0.0, 0.0, 0.16)},
	&"hover_tray": {"kind": &"bottom", "label": "Hover tray", "mass": 6.0, "size": Vector3(0.7, 0.7, 0.08),
		"color": Color(0.25, 0.45, 0.6), "stats": {"lift_kg": 80.0}},
	&"solar_panel": {"kind": &"top", "label": "Solar panel", "mass": 5.0, "size": Vector3(0.8, 0.6, 0.04),
		"color": Color(0.1, 0.15, 0.35), "stats": {"solar_w": 60.0}},
	&"lamp": {"kind": &"top", "label": "Lamp", "mass": 1.0, "size": Vector3(0.12, 0.12, 0.25),
		"color": Color(0.95, 0.9, 0.6), "stats": {"light_w": 5.0}},
	&"seedling": {"kind": &"plant_small", "label": "Seedling", "mass": 0.3, "size": Vector3(0.1, 0.1, 0.18),
		"color": Color(0.3, 0.7, 0.2), "stats": {"plants": 1}},
	&"sapling": {"kind": &"plant_large", "label": "Sapling", "mass": 1.2, "size": Vector3(0.18, 0.18, 0.4),
		"color": Color(0.2, 0.55, 0.15), "stats": {"plants": 1}},
	&"plug": {"kind": &"port", "label": "Cable plug", "mass": 0.2, "size": Vector3(0.06, 0.06, 0.09),
		"color": Color(1.0, 0.5, 0.1), "stats": {}},
	&"strong_plug": {"kind": &"port", "label": "Strong cable plug", "mass": 0.3, "size": Vector3(0.07, 0.07, 0.1),
		"color": Color(0.7, 0.15, 0.1), "stats": {}},
	&"rope_end": {"kind": &"tie", "label": "Rope end", "mass": 0.3, "size": Vector3(0.05, 0.05, 0.08),
		"color": Color(0.3, 0.22, 0.14), "stats": {}},
	# Nothing takes a coil: picked up, it gives you its first end.
	&"coil": {"kind": &"coil", "label": "Rope coil", "mass": 1.5, "size": Vector3(0.34, 0.34, 0.07),
		"color": Color(0.42, 0.31, 0.2), "stats": {}},
	# Sealed water, and sealed food, which no socket takes: they live in your slots.
	&"canister": {"kind": &"water", "label": "Water canister", "mass": 2.4, "size": Vector3(0.12, 0.12, 0.26),
		"color": Color(0.55, 0.62, 0.68), "stats": {}},
	&"ration": {"kind": &"food", "label": "Ration", "mass": 0.5, "size": Vector3(0.16, 0.1, 0.06),
		"color": Color(0.45, 0.42, 0.25), "stats": {}},
}

static var _tells := {}

## Frames: their box, weight, wind catch and sockets as [kind, position, outward].
const DEVICES := {
	&"crate_frame": {"label": "Crate frame", "size": Vector3(0.8, 0.5, 0.8), "mass": 15.0,
		"sockets": [
			[&"battery", Vector3(0.0, 0.0, 0.4), Vector3.BACK],
			[&"ring", Vector3(0.4, 0.0, 0.0), Vector3.RIGHT],
			[&"ring", Vector3(-0.4, 0.0, 0.0), Vector3.LEFT],
			[&"bottom", Vector3(0.0, -0.25, 0.0), Vector3.DOWN],
			[&"top", Vector3(0.0, 0.25, 0.0), Vector3.UP],
			[&"port", Vector3(0.25, 0.1, -0.4), Vector3.FORWARD],
		]},
	&"planter": {"label": "Planter", "size": Vector3(1.0, 0.35, 0.6), "mass": 10.0,
		"sockets": [
			[&"plant_small", Vector3(-0.3, 0.175, -0.12), Vector3.UP],
			[&"plant_small", Vector3(-0.3, 0.175, 0.12), Vector3.UP],
			[&"plant_small", Vector3(0.0, 0.175, 0.0), Vector3.UP],
			[&"plant_large", Vector3(0.3, 0.175, 0.0), Vector3.UP],
			[&"battery", Vector3(-0.5, 0.0, 0.0), Vector3.LEFT],
			[&"ring", Vector3(0.0, 0.0, 0.3), Vector3.BACK],
			[&"ring", Vector3(0.0, 0.0, -0.3), Vector3.FORWARD],
			[&"bottom", Vector3(0.0, -0.175, 0.0), Vector3.DOWN],
			[&"port", Vector3(0.5, 0.0, 0.0), Vector3.RIGHT],
		]},
	# Put a panel on top and a battery in front, and it charges the battery in the sun.
	&"charger": {"label": "Charger", "size": Vector3(0.45, 0.25, 0.35), "mass": 5.0,
		"sockets": [
			[&"battery", Vector3(0.0, 0.0, 0.175), Vector3.BACK],
			[&"top", Vector3(0.0, 0.125, 0.0), Vector3.UP],
			[&"port", Vector3(0.225, 0.0, 0.0), Vector3.RIGHT],
		]},
	# Strongest in a storm, and only while planted on the sand; built to stand
	# out in one, so the weather wears it four times slower.
	&"turbine": {"label": "Wind turbine", "size": Vector3(0.5, 0.3, 0.5), "mass": 18.0,
		"stats": {"turbine_w": 200.0, "toughness": 4.0}, "mast": 1.6,
		"sockets": [
			[&"battery", Vector3(0.0, 0.0, 0.25), Vector3.BACK],
			[&"port", Vector3(0.25, 0.0, 0.0), Vector3.RIGHT],
		]},
	# Pulls water out of the air into the canister fitted in it, best in the cold of the night.
	&"condenser": {"label": "Condenser", "size": Vector3(0.6, 0.7, 0.6), "mass": 14.0, "condenser": true,
		"sockets": [
			[&"water", Vector3(0.0, -0.1, 0.3), Vector3.BACK],
			[&"battery", Vector3(0.3, -0.1, 0.0), Vector3.RIGHT],
			[&"top", Vector3(0.0, 0.35, 0.0), Vector3.UP],
			[&"port", Vector3(-0.3, 0.1, 0.0), Vector3.LEFT],
			[&"ring", Vector3(-0.3, -0.15, 0.0), Vector3.LEFT],
			[&"bottom", Vector3(0.0, -0.35, 0.0), Vector3.DOWN],
		]},
	# The base shield: small and light, F switches it, and its bubble keeps
	# out wind and storm wherever it goes.
	&"shield": {"label": "Shield generator", "size": Vector3(0.4, 0.42, 0.4), "mass": 6.0, "shield": true,
		"sockets": [
			[&"battery", Vector3(0.0, -0.05, 0.2), Vector3.BACK],
			[&"ring", Vector3(-0.2, -0.05, 0.0), Vector3.LEFT],
			[&"bottom", Vector3(0.0, -0.21, 0.0), Vector3.DOWN],
			[&"port", Vector3(0.2, -0.05, 0.0), Vector3.RIGHT],
		]},
}


static func part(id: StringName) -> Part:
	var spec: Dictionary = PARTS[id]
	var made: Part = Battery.new() if spec.kind == &"battery" \
		else (Supply.new() if Supply.HOLDS.has(spec.kind) else Part.new())
	made.kind = spec.kind
	made.label = spec.label
	made.mass = spec.mass
	made.stats = spec.stats.duplicate()
	var size: Vector3 = spec.size
	# Standing out from its socket along +Z.
	_add_box(made, size, Vector3(0.0, 0.0, size.z * 0.5), spec.color)
	if made is Battery:
		# Found full, for now; salvage will find them at any charge.
		made.charge_wh = made.capacity()
		made.light = ChargeLight.make(Vector3(size.x * 0.7, 0.02, 0.01))
		made.light.position = Vector3(0.0, size.y * 0.3, size.z + 0.005)
		made.add_child(made.light)
		made.show_charge()
	if made is Supply:
		made.light = ChargeLight.make(Vector3(size.x * 0.7, 0.02, 0.01))
		made.light.position = Vector3(0.0, size.y * 0.5 + 0.005, size.z * 0.6)
		made.add_child(made.light)
		made.seal()
	if spec.kind == &"tie":
		# A line's end is small and gets dragged over the dunes at the wind's
		# speed: swept, so it can't step through the sand in a tick.
		made.continuous_cd = true
	if spec.has("tie"):
		_add_tie(made, spec.tie, Vector3.BACK)
	if spec.kind == &"coil":
		# It lies flat, so the wind meets its edge, not its face.
		made.set_meta(&"wind_catch", Tuning.current().wind_catch_per_m2 * size.x * size.z)
		# Drawn as a coil lying on its back, not the box it's held by.
		for child in made.get_children():
			if child is MeshInstance3D:
				var torus := TorusMesh.new()
				torus.inner_radius = 0.09
				torus.outer_radius = 0.17
				torus.material = (child.mesh as BoxMesh).material
				child.mesh = torus
				child.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	if made.stats.get("light_w", 0.0) > 0.0:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.85, 0.6)
		lamp.omni_range = 7.0
		lamp.position = Vector3(0.0, 0.0, size.z + 0.1)
		# Dark until a powered device runs it.
		lamp.visible = false
		made.add_child(lamp)
	return made


## A cable and its two plugs, dropped together at a place; both plugs go loose
## in the world as parts and the cable draws the wire between them. A strong
## cable is also a rope, holding what it's plugged into.
static func cable(world: World, at: Vector3, strong := false) -> Cable:
	var made: Cable = StrongCable.new() if strong else Cable.new()
	world.content.add_child(made)
	for side in [-0.2, 0.2]:
		var plug := part(&"strong_plug" if strong else &"plug")
		world.content.add_child(plug)
		plug.global_position = at + Vector3(side, 0.05, 0.0)
		made.plugs.append(plug)
	if strong:
		(made as StrongCable).bind(world)
	return made


## A stake, loose: a spike with an eye on top whose tie socket faces up, so a
## line's end snaps on from wherever you stand.
static func stake() -> Stake:
	var made := Stake.new()
	made.label = "Stake"
	made.frame_mass = 2.0
	made.carryable = true
	# A spike of iron: nothing in it the weather wears out.
	made.frame_stats = {"toughness": INF}
	made.holding = Tuning.current().stake_holding
	_add_box(made, Vector3(0.06, Stake.LENGTH, 0.06), Vector3.ZERO, Color(0.3, 0.27, 0.24))
	_add_tie(made, Stake.RING, Vector3.UP)
	made.ring = RopeEnd.make(made, Stake.RING, false)
	return made


## A tie socket facing `outward`, with the ring you see there.
static func _add_tie(body: Node3D, at: Vector3, outward: Vector3) -> void:
	var tie := Socket.new()
	tie.kind = &"tie"
	tie.transform = Transform3D(_facing(outward), at)
	body.add_child(tie)
	var ring := RopeEnd.ring_mesh()
	# Stood across its socket, so a line's end reads as clipped through it.
	ring.transform = Transform3D(_facing(outward) * Basis(Vector3.UP, PI / 2.0), at)
	body.add_child(ring)


static func device(id: StringName) -> Device:
	var spec: Dictionary = DEVICES[id]
	var made: Device = ShieldGenerator.new() if spec.get("shield", false) \
		else (Condenser.new() if spec.get("condenser", false) else Device.new())
	made.label = spec.label
	made.frame_mass = spec.mass
	made.frame_stats = spec.get("stats", {}).duplicate()
	var size: Vector3 = spec.size
	_add_box(made, size, Vector3.ZERO, Color(0.55, 0.55, 0.55))
	if spec.has("mast"):
		_add_mast(made, size, spec.mast)
	if spec.sockets.any(func(e: Array) -> bool: return e[0] == &"battery"):
		made.charge_light = ChargeLight.make(Vector3(0.05, 0.05, 0.05))
		made.charge_light.position = Vector3(size.x * 0.5 - 0.05, size.y * 0.5 + 0.025, size.z * 0.5 - 0.05)
		made.add_child(made.charge_light)
	for entry: Array in spec.sockets:
		var socket := Socket.new()
		socket.kind = entry[0]
		var outward: Vector3 = entry[2]
		socket.transform = Transform3D(_facing(outward), entry[1])
		var tell := MeshInstance3D.new()
		tell.mesh = _tell(socket.kind)
		tell.position = Vector3(0.0, 0.0, 0.005)
		socket.add_child(tell)
		socket.marker = tell
		made.add_child(socket)
	return made


## The flat tell a free socket of a kind shows, one shared by every socket of
## that kind: nothing ever changes one.
static func _tell(kind: StringName) -> BoxMesh:
	if not _tells.has(kind):
		var plate := BoxMesh.new()
		plate.size = Vector3(0.1, 0.1, 0.01)
		var look := StandardMaterial3D.new()
		look.albedo_color = KINDS[kind]
		look.emission_enabled = true
		look.emission = KINDS[kind] * 0.3
		plate.material = look
		_tells[kind] = plate
	return _tells[kind]


## The turbine's mast and blades: something to see turn into the wind, not to touch.
static func _add_mast(device: Device, base: Vector3, height: float) -> void:
	var mast := MeshInstance3D.new()
	var pole := CylinderMesh.new()
	pole.top_radius = 0.03
	pole.bottom_radius = 0.04
	pole.height = height
	mast.mesh = pole
	mast.position = Vector3(0.0, base.y * 0.5 + height * 0.5, 0.0)
	device.add_child(mast)
	var blades := MeshInstance3D.new()
	var vane := BoxMesh.new()
	vane.size = Vector3(1.2, 0.08, 0.02)
	blades.mesh = vane
	blades.position = Vector3(0.0, base.y * 0.5 + height, 0.06)
	device.add_child(blades)


## A basis whose +Z points along outward.
static func _facing(outward: Vector3) -> Basis:
	var up := Vector3.UP if absf(outward.dot(Vector3.UP)) < 0.9 else Vector3.BACK
	return Basis.looking_at(-outward, up)


## A shape's bounds in its own frame. Everything here is built of boxes,
## whose bounds are their size; anything else asks its debug mesh, which
## stalls the main thread on the render thread the first time, a whole frame.
static func bounds(shape: Shape3D) -> AABB:
	var box := shape as BoxShape3D
	if box != null:
		return AABB(-box.size * 0.5, box.size)
	return shape.get_debug_mesh().get_aabb()


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
