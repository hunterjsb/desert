class_name Catalog
extends RefCounted
## Every device frame and part the skeleton knows, built in code as boxes
## with their sockets in defined spots, and drawn in B's paint (Dress). Salvage
## finds them, and the test kit scenario drops a set round you.

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
	&"mod": Color(0.75, 0.35, 0.7),
	&"food": Color(0.8, 0.7, 0.35),
	&"rack": Color(0.95, 0.35, 0.3),
	&"deck": Color(0.55, 0.45, 0.95),
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
	# Half a crate's top, so two ride side by side.
	&"solar_panel": {"kind": &"top", "label": "Solar panel", "mass": 5.0, "size": Vector3(0.8, 0.4, 0.04),
		"color": Color(0.1, 0.15, 0.35), "stats": {"solar_w": 60.0}},
	&"lamp": {"kind": &"top", "label": "Lamp", "mass": 1.0, "size": Vector3(0.12, 0.12, 0.25),
		"color": Color(0.95, 0.9, 0.6), "stats": {"light_w": 5.0}},
	# Crops, sown in a planter's slots: "crop" names their tuning numbers, and
	# a harvest comes out as their "food". One that "regrows" fruits again when picked.
	&"carrot": {"kind": &"plant_small", "label": "Carrot", "mass": 0.3, "size": Vector3(0.1, 0.1, 0.18),
		"color": Color(0.3, 0.7, 0.2), "ripe": Color(0.95, 0.5, 0.1), "stats": {"plants": 1},
		"crop": &"carrot", "food": &"carrots"},
	&"fungus": {"kind": &"plant_large", "label": "Fungus", "mass": 1.2, "size": Vector3(0.18, 0.18, 0.4),
		"color": Color(0.4, 0.36, 0.3), "ripe": Color(0.9, 0.85, 0.7), "stats": {"plants": 1},
		"crop": &"fungus", "food": &"fungus_caps", "regrows": true},
	# Fits a planter's mod mount: ripe crops go into the planter's own storage.
	&"harvester": {"kind": &"mod", "label": "Harvester", "mass": 1.5, "size": Vector3(0.22, 0.14, 0.1),
		"color": Color(0.5, 0.3, 0.45), "stats": {"harvester": 1}},
	&"plug": {"kind": &"port", "label": "Cable plug", "mass": 0.2, "size": Vector3(0.06, 0.06, 0.09),
		"color": Color(1.0, 0.5, 0.1), "stats": {}},
	&"strong_plug": {"kind": &"port", "label": "Strong cable plug", "mass": 0.3, "size": Vector3(0.07, 0.07, 0.1),
		"color": Color(0.7, 0.15, 0.1), "stats": {}},
	# A hose's end fits a water socket as a canister does, and fitted it "adds"
	# one of its own on top, [kind, position, outward], so a canister or
	# another hose goes on there too.
	&"hose_end": {"kind": &"water", "label": "Hose end", "mass": 0.3, "size": Vector3(0.08, 0.08, 0.12),
		"color": Paint.HOSE, "stats": {}, "adds": [&"water", Vector3(0.0, 0.055, 0.075), Vector3.UP]},
	&"rope_end": {"kind": &"tie", "label": "Rope end", "mass": 0.3, "size": Vector3(0.05, 0.05, 0.08),
		"color": Color(0.3, 0.22, 0.14), "stats": {}},
	# Nothing takes a coil: picked up, it gives you its first end.
	&"coil": {"kind": &"coil", "label": "Rope coil", "mass": 1.5, "size": Vector3(0.34, 0.34, 0.07),
		"color": Color(0.42, 0.31, 0.2), "stats": {}},
	# Sealed water, and sealed food, which only a survival kit's slot takes:
	# they live in your slots.
	&"canister": {"kind": &"water", "label": "Water canister", "mass": 2.4, "size": Vector3(0.12, 0.12, 0.26),
		"color": Color(0.55, 0.62, 0.68), "stats": {}},
	&"ration": {"kind": &"food", "label": "Ration", "mass": 0.5, "size": Vector3(0.16, 0.1, 0.06),
		"color": Color(0.45, 0.42, 0.25), "stats": {}},
	# What a harvest gives: food like a ration, holding the harvest's kcal.
	&"carrots": {"kind": &"food", "label": "Carrots", "mass": 0.6, "size": Vector3(0.16, 0.1, 0.08),
		"color": Color(0.95, 0.5, 0.1), "stats": {}},
	&"fungus_caps": {"kind": &"food", "label": "Fungus caps", "mass": 0.4, "size": Vector3(0.14, 0.1, 0.08),
		"color": Color(0.85, 0.8, 0.65), "stats": {}},
}

## Frames: their box, weight, wind catch and sockets as [kind, position, outward].
## Those marked "deck" stand on a chassis piece's deck mount too.
const DEVICES := {
	# Two batteries, a ring on every side, a tray under it and two top mounts,
	# so a panel rides beside a lamp or a shield. The first battery sits in the
	# middle of its back, so a crate with one hangs level on its lines. A board
	# is longer than the crate, so its rack runs along the top of the left side,
	# away from the charge light, the board standing proud of it to clear the
	# ring below. Last in the list, so older saves keep their sockets.
	&"crate_frame": {"label": "Crate frame", "size": Vector3(0.8, 0.5, 0.8), "mass": 15.0, "deck": true,
		"sockets": [
			[&"battery", Vector3(0.0, 0.0, 0.4), Vector3.BACK],
			[&"ring", Vector3(0.4, 0.0, 0.0), Vector3.RIGHT],
			[&"ring", Vector3(-0.4, 0.0, 0.0), Vector3.LEFT],
			[&"bottom", Vector3(0.0, -0.25, 0.0), Vector3.DOWN],
			[&"top", Vector3(0.0, 0.25, -0.2), Vector3.UP],
			[&"port", Vector3(0.25, 0.1, -0.4), Vector3.FORWARD],
			[&"battery", Vector3(-0.15, 0.0, -0.4), Vector3.FORWARD],
			[&"ring", Vector3(0.0, 0.15, 0.4), Vector3.BACK],
			[&"ring", Vector3(0.25, -0.1, -0.4), Vector3.FORWARD],
			[&"top", Vector3(0.0, 0.25, 0.2), Vector3.UP],
			[&"rack", Vector3(-0.4, 0.17, 0.0), Vector3.LEFT],
		]},
	# Its own water tank, fed from its water socket, and a mod mount on its
	# back for a harvester. The water socket is last, so older saves keep their sockets.
	&"planter": {"label": "Planter", "size": Vector3(1.0, 0.35, 0.6), "mass": 10.0, "planter": true,
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
			[&"mod", Vector3(0.3, 0.0, 0.3), Vector3.BACK],
			[&"water", Vector3(-0.3, 0.0, 0.3), Vector3.BACK],
		]},
	# Put a panel on top and a battery in front, and it charges the battery in the sun.
	&"charger": {"label": "Charger", "size": Vector3(0.45, 0.25, 0.35), "mass": 5.0, "deck": true,
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
	&"condenser": {"label": "Condenser", "size": Vector3(0.6, 0.7, 0.6), "mass": 14.0, "condenser": true, "deck": true,
		"sockets": [
			[&"water", Vector3(0.0, -0.1, 0.3), Vector3.BACK],
			[&"battery", Vector3(0.3, -0.1, 0.0), Vector3.RIGHT],
			[&"top", Vector3(0.0, 0.35, 0.0), Vector3.UP],
			[&"port", Vector3(-0.3, 0.1, 0.0), Vector3.LEFT],
			[&"ring", Vector3(-0.3, -0.15, 0.0), Vector3.LEFT],
			[&"bottom", Vector3(0.0, -0.35, 0.0), Vector3.DOWN],
		]},
	# The base shield: small and light, use switches it, and its bubble keeps
	# out wind and storm wherever it goes, a crate's top mount included.
	&"shield": {"label": "Shield generator", "size": Vector3(0.4, 0.42, 0.4), "mass": 6.0, "shield": true,
		"fits": &"top", "deck": true,
		"sockets": [
			[&"battery", Vector3(0.0, -0.05, 0.2), Vector3.BACK],
			[&"ring", Vector3(-0.2, -0.05, 0.0), Vector3.LEFT],
			[&"bottom", Vector3(0.0, -0.21, 0.0), Vector3.DOWN],
			[&"port", Vector3(0.2, -0.05, 0.0), Vector3.RIGHT],
		]},
	# The light shield you start with: a smaller bubble that lets a little of
	# the wind through, built light enough that the light panel keeps it going.
	&"light_shield": {"label": "Light shield generator", "size": Vector3(0.3, 0.32, 0.3), "mass": 4.0, "shield": true,
		"fits": &"top", "deck": true, "stats": {"radius_m": 4.0, "clear_w": 2.0, "storm_w": 20.0, "wind_block": 0.85},
		"sockets": [
			[&"battery", Vector3(0.0, -0.04, 0.15), Vector3.BACK],
			[&"ring", Vector3(-0.15, -0.04, 0.0), Vector3.LEFT],
			[&"bottom", Vector3(0.0, -0.16, 0.0), Vector3.DOWN],
			[&"port", Vector3(0.15, -0.04, 0.0), Vector3.RIGHT],
		]},
	# The light solar panel you start with, half a found panel's watts on half
	# a crate's top, so it rides beside a shield: seat it, set it down, cable
	# it in, pick it up again. Lying flat, the wind meets its edge.
	&"light_panel": {"label": "Light solar panel", "size": Vector3(0.8, 0.05, 0.4), "mass": 5.0, "carryable": true,
		"fits": &"top", "stats": {"solar_w": 30.0, "face_m2": 0.04},
		"sockets": [
			[&"port", Vector3(0.4, 0.0, 0.0), Vector3.RIGHT],
		]},
	# Music, the weather station and beacons, a channel a use. Carried, set
	# down or seated on a top mount, it runs on its battery or what it sits on.
	&"radio": {"label": "Radio", "size": Vector3(0.32, 0.22, 0.16), "mass": 2.5, "radio": true, "fits": &"top",
		"carryable": true,
		"sockets": [
			[&"battery", Vector3(0.0, -0.02, -0.08), Vector3.FORWARD],
			[&"port", Vector3(0.16, -0.035, -0.01), Vector3.RIGHT],
		]},
	# A sealed case of what keeps you going: a canister, a ration and seeds.
	&"survival_kit": {"label": "Survival kit", "size": Vector3(0.5, 0.25, 0.35), "mass": 3.0, "carryable": true,
		"sockets": [
			[&"water", Vector3(-0.13, 0.0, 0.175), Vector3.BACK],
			[&"food", Vector3(0.13, 0.0, 0.175), Vector3.BACK],
			[&"plant_small", Vector3(-0.15, 0.125, 0.0), Vector3.UP],
			[&"plant_small", Vector3(0.0, 0.125, 0.0), Vector3.UP],
			[&"plant_large", Vector3(0.15, 0.125, 0.0), Vector3.UP],
		]},
	# Just for you: it runs on its own battery, at its nose, and nothing ties
	# to it, so it tows nothing. Its port charges it from a cable, and a crate's
	# rack from the camp. Found buried on end, nose down. Lying flat, the wind
	# meets its edge.
	&"board": {"label": "Hoverboard", "size": Vector3(0.36, 0.08, 1.3), "mass": 7.0, "board": true, "on_end": true,
		"carryable": true, "fits": &"rack", "stats": {"face_m2": 0.1},
		"sockets": [
			[&"battery", Vector3(0.0, 0.04, -0.5), Vector3.UP],
			[&"port", Vector3(0.0, 0.0, 0.65), Vector3.BACK],
		]},
	# A piece of a bigger floater: a flat frame a little wider than a crate,
	# a ring on each edge where the next piece joins or a hook goes, its own
	# tray under it and one device standing on top. No battery, no port: the
	# power comes from what stands on it. Lying flat, the wind meets its edge.
	# Found buried on edge, as the dunes would leave a sheet that wide.
	&"chassis": {"label": "Chassis piece", "size": Vector3(1.0, 0.12, 1.0), "mass": 9.0, "chassis": true,
		"carryable": true, "on_end": true, "stats": {"face_m2": 0.12},
		"sockets": [
			[&"ring", Vector3(0.5, 0.0, 0.0), Vector3.RIGHT],
			[&"ring", Vector3(-0.5, 0.0, 0.0), Vector3.LEFT],
			[&"ring", Vector3(0.0, 0.0, 0.5), Vector3.BACK],
			[&"ring", Vector3(0.0, 0.0, -0.5), Vector3.FORWARD],
			[&"bottom", Vector3(0.0, -0.06, 0.0), Vector3.DOWN],
			[&"deck", Vector3(0.0, 0.06, 0.0), Vector3.UP],
		]},
}


static func part(id: StringName) -> Part:
	var spec: Dictionary = PARTS[id]
	# A hose's end fits where water goes but holds none itself.
	var made: Part = Battery.new() if spec.kind == &"battery" \
		else (Supply.new() if Supply.HOLDS.has(spec.kind) and id != Hose.END \
		else (Plant.new() if spec.has("crop") else Part.new()))
	made.kind = spec.kind
	made.label = spec.label
	made.mass = spec.mass
	# What a save knows it by.
	made.set_meta(&"catalog", id)
	made.stats = spec.stats.duplicate()
	var size: Vector3 = spec.size
	# Standing out from its socket along +Z.
	_add_box(made, size, Vector3(0.0, 0.0, size.z * 0.5), spec.color, Dress.part(id, size))
	Paint.show_age(made, Paint.age_of(&"", 1.0))
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
	if made is Plant:
		(made as Plant).sow(spec.crop, spec.food, spec.color, spec.ripe)
	if spec.kind == &"tie":
		# A line's end is small and gets dragged over the dunes at the wind's
		# speed: swept, so it can't step through the sand in a tick.
		made.continuous_cd = true
	if spec.has("tie"):
		_add_tie(made, spec.tie, Vector3.BACK)
	if spec.has("adds"):
		var adds := Socket.new()
		adds.kind = spec.adds[0]
		adds.transform = Transform3D(_facing(spec.adds[2]), spec.adds[1])
		made.add_child(adds)
	if spec.kind == &"coil":
		# It lies flat, so the wind meets its edge, not its face.
		made.set_meta(&"wind_catch", Tuning.current().wind_catch_per_m2 * size.x * size.z)
	if made.stats.get("light_w", 0.0) > 0.0:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.85, 0.6)
		lamp.omni_range = 7.0
		lamp.position = Vector3(0.0, 0.0, size.z + 0.1)
		# Dark until a powered device runs it.
		lamp.visible = false
		made.add_child(lamp)
	return made


## Food holding this many kcal: a harvest, picked or dropped onto you.
static func food(id: StringName, kcal: float) -> Supply:
	var made := part(id) as Supply
	made.seal(kcal)
	return made


## A cable and its two plugs, dropped together at a place; both plugs go loose
## in the world as parts and the cable draws the wire between them. A strong
## cable is also a rope, holding what it's plugged into. Given its first plug,
## a found one, it makes only the second, beside it.
static func cable(world: World, at: Vector3, strong := false, first: Part = null) -> Cable:
	var made: Cable = StrongCable.new() if strong else Cable.new()
	_lay(world, made, at, &"strong_plug" if strong else &"plug", first)
	if strong:
		(made as StrongCable).bind(world)
	return made


## A hose and its two ends, dropped together as a cable is, a rope like a
## strong cable.
static func hose(world: World, at: Vector3, first: Part = null) -> Hose:
	var made := Hose.new()
	_lay(world, made, at, Hose.END, first)
	made.bind(world)
	return made


static func _lay(world: World, made: Cable, at: Vector3, end: StringName, first: Part) -> void:
	world.content.add_child(made)
	for side in [-0.2, 0.2]:
		var plug := first if first != null and made.plugs.is_empty() else part(end)
		if plug.get_parent() == null:
			world.content.add_child(plug)
			plug.global_position = at + Vector3(side, 0.05, 0.0)
			if first != null:
				plug.global_position.y = world.height_under(plug.global_position) + 0.05
		made.plugs.append(plug)


## A stake, loose: a spike with an eye on top whose tie socket faces up, so a
## line's end snaps on from wherever you stand.
static func stake() -> Stake:
	var made := Stake.new()
	made.set_meta(&"catalog", &"stake")
	made.label = "Stake"
	made.frame_mass = 2.0
	made.carryable = true
	# A spike of iron: nothing in it the weather wears out.
	made.frame_stats = {"toughness": INF}
	made.holding = Tuning.current().stake_holding
	var spike := Vector3(0.06, Stake.LENGTH, 0.06)
	made.frame_view = _add_box(made, spike, Vector3.ZERO, Color(0.3, 0.27, 0.24), Dress.frame(&"stake", spike))
	_add_tie(made, Stake.RING, Vector3.UP)
	made.ring = RopeEnd.make(made, Stake.RING, false)
	made.show_wear()
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
		else (Condenser.new() if spec.get("condenser", false) \
		else (Planter.new() if spec.get("planter", false) \
		else (Hoverboard.new() if spec.get("board", false) \
		else (Radio.new() if spec.get("radio", false) \
		else (Chassis.new() if spec.get("chassis", false) else Device.new())))))
	made.set_meta(&"catalog", id)
	made.label = spec.label
	made.frame_mass = spec.mass
	made.frame_stats = spec.get("stats", {}).duplicate()
	made.kind = spec.get("fits", &"")
	made.stands_on_deck = spec.get("deck", false)
	if spec.get("carryable", false):
		made.carryable = true
	var size: Vector3 = spec.size
	made.frame_view = _add_box(made, size, Vector3.ZERO, Color(0.55, 0.55, 0.55), Dress.frame(id, size, spec.get("mast", 0.0)))
	if spec.has("mast"):
		made.rotor = Rotor.new()
		made.rotor.mesh = Dress.rotor(id)
		made.rotor.position = Vector3(0.0, size.y * 0.5 + spec.mast, 0.0)
		made.add_child(made.rotor)
	if spec.sockets.any(func(e: Array) -> bool: return e[0] == &"battery"):
		made.charge_light = ChargeLight.make(Vector3(0.05, 0.05, 0.05))
		# High on its right side, where nothing on its top mounts covers it.
		made.charge_light.position = Vector3(size.x * 0.5 + 0.025, size.y * 0.5 - 0.05, size.z * 0.5 - 0.05)
		made.add_child(made.charge_light)
	for entry: Array in spec.sockets:
		var socket := Socket.new()
		socket.kind = entry[0]
		var outward: Vector3 = entry[2]
		socket.transform = Transform3D(_facing(outward), entry[1])
		var tell := MeshInstance3D.new()
		tell.mesh = Dress.tell(socket.kind)
		# Its tab glows a little, so a free socket reads at dusk.
		tell.set_instance_shader_parameter(&"lit", 1.0)
		socket.add_child(tell)
		socket.marker = tell
		made.add_child(socket)
	made.show_wear()
	return made


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


## Its box, and what you see of it: its painted look, in the body's own
## frame, or a grey box where it has none yet.
static func _add_box(body: CollisionObject3D, size: Vector3, at: Vector3, color: Color, look: Mesh = null) -> MeshInstance3D:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	if look != null:
		mesh.mesh = look
	else:
		var cube := BoxMesh.new()
		cube.size = size
		var flat := StandardMaterial3D.new()
		flat.albedo_color = color
		cube.material = flat
		mesh.mesh = cube
		mesh.position = at
	body.add_child(mesh)
	return mesh
