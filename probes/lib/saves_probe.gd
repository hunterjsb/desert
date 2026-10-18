class_name SavesProbe
extends ShieldProbe
## For save probes: a camp running mid-storm, a minute of it written down,
## and a fresh world on the same seed to resume a save into.

## The storm, how hard the wind drives it, and its gusts, as the tuning has them.
const STORM := 0.8
const WIND := 11.0
## The camp round where you stand, m east: a shield with its bubble up, a
## planter growing inside it, a floating crate outside on two lines to
## stakes upwind with a light shield seated on it, and a stake beside you
## with a line to your waist.
const SHIELD_AT := 1.5
const PLANTER_AT := -2.0
const FLOATER_AT := 10.0
const STAKES_UPWIND := 3.5
const WAIST_STAKE_AT := -1.0

var saves: Node
var shield: ShieldGenerator
var planter: Planter
var floater: Device


## The world mid-storm with the camp set up and running `settle_seconds`.
func load_camp(settle_seconds := 10.0) -> void:
	saves = get_node("/root/Saves")
	var tuning := Tuning.current()
	weather_everywhere(STORM, WIND)
	tuning.gust_strength = 0.25
	tuning.gust_storm_strength = 0.5
	await load_world(1234, false)
	var player := world.player
	# However long the ground took to build, you start the camp fresh.
	player.vitals.fresh()
	var here := player.global_position
	var downwind := world.weather.field_wind(here).normalized()
	var east := Vector3.RIGHT
	shield = shield_at(here + east * SHIELD_AT)
	planter = Catalog.device(&"planter") as Planter
	world.content.add_child(planter)
	var at := here + east * PLANTER_AT + Vector3.BACK * 1.5
	planter.global_position = Vector3(at.x, world.height_under(at) + 0.2, at.z)
	for id: StringName in [&"battery", &"root_tuber", &"root_tuber", &"vat_fungus"]:
		fit_part(planter, id)
	planter.tank_l = tuning.planter_tank_litres * 0.75
	for plant in planter.plants():
		plant.set_growth(0.3)
	at = here + east * FLOATER_AT
	floater = Catalog.device(&"crate_frame")
	world.content.add_child(floater)
	floater.global_position = Vector3(at.x, world.height_under(at) + tuning.hover_height, at.z)
	for id: StringName in [&"hover_tray", &"battery", &"hook", &"hook"]:
		fit_part(floater, id)
	# A light shield seated on it, running on the crate's power.
	var seated := Catalog.device(&"light_shield") as ShieldGenerator
	for socket in floater.sockets():
		if socket.kind == seated.kind and socket.is_open():
			floater.mount(seated, socket)
			break
	seated.stand(true)
	floater.global_position.y += floater.rest_height() - tuning.hover_height
	for side: float in [-1.5, 1.5]:
		var spot: Vector3 = at - downwind * STAKES_UPWIND + downwind.cross(Vector3.UP) * side
		var stake := Catalog.stake()
		world.content.add_child(stake)
		stake.drive(spot, world.height_under(spot))
		Line.between(world, floater.free_tie(stake.global_position), stake.free_tie(floater.global_position), 0.6)
	await _waist_line(here + east * WAIST_STAKE_AT + Vector3.FORWARD * 1.0)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	cell.global_position = player.global_position + Vector3.UP
	player.hands.hold(cell)
	await fast_forward(settle_seconds)
	check(shield.running() and world.weather.field_storm(floater.global_position) > 0.5
		and world.weather.felt_storm(planter.global_position) == 0.0, "the camp runs mid-storm")


## A coil taken up, its first end put on a stake, the rest tied at your waist.
func _waist_line(spot: Vector3) -> void:
	var player := world.player
	var stake := Catalog.stake()
	world.content.add_child(stake)
	stake.drive(spot, world.height_under(spot))
	var line := Line.make(world, world.tuning.rope_coil_length)
	line.coil.global_position = player.global_position + Vector3.UP
	player.hands.hold(line.coil)
	await physics_frames(2)
	var first: Part = player.hands.stow()
	stake.fit(first, stake.free_tie(player.global_position))
	await physics_frames(2)
	check(player.waist.take_from_hands(), "the line's other end goes on your waist")
	await physics_frames(2)
	check(line.state == Line.State.LAID and world.ropes.at_waist(line.rope), "a line runs from a stake to your waist")


## A fresh world on the same seed, the old one gone, settled as a menu would leave it.
func fresh_world() -> void:
	var seed_was := world.run_seed
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	world = WORLD_SCENE.instantiate()
	world.run_seed = seed_was
	add_child(world)
	await settle()


## Resumes the save on disk into a fresh world, waiting until it's all back.
func resume() -> bool:
	await fresh_world()
	await get_tree().physics_frame
	if not saves.restore(world):
		return false
	if saves.restoring:
		await saves.restored
	return true


## What a minute of the camp looks like, a line a second: where each thing
## of yours stands, world metres, and every number it carries.
func minute(seconds := 60) -> Array[Dictionary]:
	var trace: Array[Dictionary] = []
	var ticks := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = ticks * 10
	Engine.time_scale = 10
	Engine.max_physics_steps_per_frame = 14
	for s in seconds:
		await physics_frames(ticks)
		trace.append(reading())
	Engine.physics_ticks_per_second = ticks
	Engine.time_scale = 1.0
	Engine.max_physics_steps_per_frame = 8
	return trace


func reading() -> Dictionary:
	var out := {"time": world.time, "places": {}, "numbers": {}}
	var player := world.player
	out.places["you"] = _place(player)
	var n := 0
	var bodies: Array = []
	bodies.append_array(world.devices())
	bodies.append_array(world.content.get_children().filter(func(b: Node) -> bool: return b is Part))
	for body: RigidBody3D in bodies:
		if not body.has_meta(&"catalog"):
			continue
		var name := "%s#%d" % [body.get_meta(&"catalog"), n]
		n += 1
		out.places[name] = _place(body)
		var device := body as Device
		if device != null:
			out.numbers[name + " durability"] = device.durability
			if device.battery() != null:
				out.numbers[name + " Wh"] = device.battery().charge_wh
			if device is ShieldGenerator:
				out.numbers[name + " running"] = 1.0 if device.running() else 0.0
			if device is Planter:
				out.numbers[name + " tank"] = device.tank_l
				var plants := (device as Planter).plants()
				for k in plants.size():
					out.numbers[name + " growth %d" % k] = plants[k].growth
		elif body is Battery:
			out.numbers[name + " Wh"] = body.charge_wh
	for i in world.ropes.ropes.size():
		var rope := world.ropes.ropes[i]
		out.numbers["line %d m" % i] = rope.length
		out.numbers["line %d sustained N" % i] = rope.sustained
	out.numbers["health"] = player.vitals.health
	out.numbers["hunger"] = player.vitals.hunger
	out.numbers["thirst"] = player.vitals.thirst
	out.numbers["stamina"] = player.stamina
	out.numbers["held"] = 1.0 if player.hands.held != null else 0.0
	out.numbers["at waist"] = player.waist.tied.size()
	return out


func _place(node: Node3D) -> Vector3:
	return Vector3(world.world_x(node.global_position.x), node.global_position.y, world.world_z(node.global_position.z))


## How far apart two traces get: the furthest any thing stands from itself,
## m, and the most any number differs, as a share of it past 1 (a bar, a
## watt-hour, a line's load in newtons alike), by name.
static func apart(a: Array[Dictionary], b: Array[Dictionary]) -> Dictionary:
	var out := {"metres": 0.0, "where": "", "number": 0.0, "which": "", "missing": ""}
	if a.size() != b.size():
		out.missing = "%d seconds against %d" % [a.size(), b.size()]
		return out
	for i in a.size():
		if absf(a[i].time - b[i].time) > 1e-6:
			out.missing = "the clocks differ at %d s" % i
		for key: String in a[i].places:
			if not b[i].places.has(key):
				out.missing = key
				continue
			var d: float = a[i].places[key].distance_to(b[i].places[key])
			if d > out.metres:
				out.metres = d
				out.where = "%s at %d s" % [key, i + 1]
		for key: String in a[i].numbers:
			if not b[i].numbers.has(key):
				out.missing = key
				continue
			var d := absf(a[i].numbers[key] - b[i].numbers[key]) / maxf(absf(a[i].numbers[key]), 1.0)
			if d > out.number:
				out.number = d
				out.which = "%s at %d s" % [key, i + 1]
		for key: String in b[i].places.keys() + b[i].numbers.keys():
			if not a[i].places.has(key) and not a[i].numbers.has(key):
				out.missing = key
	return out
