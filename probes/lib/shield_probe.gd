class_name ShieldProbe
extends DeviceProbe
## For shield probes: a storm that's the same everywhere and never passes,
## shield generators set down in it, and a camp of catalog devices.

## The camp, as [catalog id, metres east, metres south of its middle, parts]:
## a floating chassis, a planter, a chassis with its panel, a planted turbine.
const CAMP := [
	[&"chassis", 2.6, 0.0, [&"battery", &"hover_tray", &"hook"]],
	[&"planter", -2.6, 0.6, [&"battery", &"root_tuber", &"root_tuber", &"vat_fungus"]],
	[&"chassis", 0.4, 2.8, [&"battery", &"solar_panel"]],
	[&"turbine", 0.2, -2.8, [&"battery"]],
]


## The world with a storm of one intensity everywhere (0 clear skies, 1 the
## worst) that never passes, and a steady wind of `wind` m/s with no gusts.
## The storm pass's map, which the senses read, is drawn from this first field.
func load_storm(intensity: float, wind := 0.0) -> void:
	weather_everywhere(intensity, wind)
	await load_world(1234, false)
	world.player.set_physics_process(false)
	for i in 600:
		if world.weather.map.ready:
			break
		await get_tree().process_frame
	check(world.weather.map.ready, "the storm map is ready")


## Sets the tuning for a uniform storm and wind, and gives a loaded world a
## fresh field built from it.
func weather_everywhere(intensity: float, wind := 0.0) -> void:
	var tuning := Tuning.current()
	tuning.storm_ramp = 0.04
	if intensity <= 0.0:
		tuning.storm_threshold = 2.0
	elif intensity >= 1.0:
		tuning.storm_threshold = -2.0
	else:
		# A ramp far wider than the field's swing levels it out at intensity.
		tuning.storm_ramp = 1000.0
		tuning.storm_threshold = -intensity * 1000.0
	tuning.prevailing_speed = wind
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	tuning.gust_strength = 0.0
	tuning.gust_storm_strength = 0.0
	if world != null:
		world.weather.field = WeatherField.new(world.run_seed, tuning)


## A shield generator on a plate on the sand at a place, a chassis with a
## full battery stuck beside it, standing open at once if `running`.
func shield_at(at: Vector3, running := true, kind := &"shield") -> ShieldGenerator:
	var plate := Catalog.device(&"chassis") as Chassis
	world.content.add_child(plate)
	plate.global_position = Vector3(at.x, world.height_under(at) + Chassis.THICK * 0.5 + 0.01, at.z)
	var made := Catalog.device(kind) as ShieldGenerator
	Stick.put(plate, plate, Chassis.TOP, Vector2.ZERO, 0.0, made)
	Stick.put(plate, plate, Chassis.TOP, Vector2(0.32, 0.32), 0.0, Catalog.part(&"battery"))
	if running:
		made.stand(true)
	return made


## The camp round a place on the sand, every piece fitted out.
func camp_at(middle: Vector3) -> Array[Device]:
	var made: Array[Device] = []
	for entry: Array in CAMP:
		var device := Catalog.device(entry[0])
		world.content.add_child(device)
		var at := middle + Vector3(entry[1], 0.0, entry[2])
		var size: Vector3 = Catalog.DEVICES[entry[0]].size
		device.global_position = Vector3(at.x, world.height_under(at) + size.y * 0.5 + 0.05, at.z)
		for id: StringName in entry[3]:
			fit_part(device, id)
		made.append(device)
	return made


## A turbine standing on the sand at a place, staked still: a gale slides a
## loose one.
func turbine_at(at: Vector3) -> Device:
	var made := Catalog.device(&"turbine")
	world.content.add_child(made)
	made.global_position = Vector3(at.x, world.height_under(at) + Catalog.DEVICES[&"turbine"].size.y * 0.5 + 0.02, at.z)
	made.freeze = true
	return made


## A place on the sand `ahead` m east of the player.
func ahead(metres: float) -> Vector3:
	var p := world.player.global_position + Vector3(metres, 0.0, 0.0)
	return Vector3(p.x, world.height_under(p), p.z)


## Runs world time on by `seconds`, at `warp` times the physics, itself k
## times faster than real time; each() is called after every tick.
func live(seconds: float, warp := 10.0, each := Callable(), k := 10) -> void:
	var ticks := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = ticks * k
	Engine.time_scale = k
	Engine.max_physics_steps_per_frame = k + 4
	world.time_warp = warp
	for i in roundi(seconds / warp * ticks):
		await get_tree().physics_frame
		if each.is_valid():
			each.call()
	world.time_warp = 0.0
	Engine.physics_ticks_per_second = ticks
	Engine.time_scale = 1.0
	Engine.max_physics_steps_per_frame = 8


## Calls each() last thing every drawn frame, after everything has moved and
## the storm pass has been told where the bubbles are.
class EndOfFrame extends Node:
	var each: Callable

	func _ready() -> void:
		process_priority = 1000

	func _process(_delta: float) -> void:
		each.call()
