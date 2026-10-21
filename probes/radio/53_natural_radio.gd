extends WeatherProbe
## Radio probe 53: natural radio. At the bottom of the AM dial a radio on its
## ferrite rod alone hears nothing; on an antenna reel's wire the moon's own sferics come
## through, ticking faster as a storm nears; and gear drawing power in its pool
## hums over them.

## How far off the reel stands, m; where the storm stands, far and near, m.
const OUT := 10.5
const FAR := 20000.0
const NEAR := 2000.0


## A field with one storm in it, kilometres across as storms are, where the probe puts it.
class OneStorm extends WeatherField:
	var at := Vector2(INF, INF)

	func storm_at(x: float, z: float, _t: float) -> float:
		return 1.0 if Vector2(x, z).distance_to(at) < 1500.0 else 0.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	radio.frequency = 10.0
	var field := OneStorm.new(world.run_seed, Tuning.current())
	world.weather.field = field
	await physics_frames(70)
	check(radio.natural == 0.0, "on its rod alone it hears none of it")
	var reel := Scenarios.standing(world, &"antenna_reel", [], [0.0, 2.0]) as AntennaReel
	reel.freeze = true
	reel.global_position = radio.global_position + Vector3(OUT, 0.0, 0.0)
	reel.clip(radio)
	await physics_frames(70)
	var clear := radio.natural
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	field.at = Vector2(x + FAR, z)
	var far := Natural.rate(Natural.storms(field, x, z, world.time, Tuning.current()), Tuning.current())
	field.at = Vector2(x + NEAR, z)
	var near := Natural.rate(Natural.storms(field, x, z, world.time, Tuning.current()), Tuning.current())
	print("on %.1f m of wire: %.2f through; sferics %.1f/s with a storm %d km off, %.1f/s %d km off" % [radio.wire.x,
		clear, far, roundi(FAR / 1000.0), near, roundi(NEAR / 1000.0)])
	check(clear >= Radio.WHOLE, "on a long wire it comes through")
	check(near > far * 2.0, "its sferics tick faster as a storm nears")
	var console := Scenarios.standing(world, &"console", [], [1.5, 2.0]) as Device
	Scenarios.wire(world, radio, console)
	await physics_frames(70)
	print("a Console drawing %.1f W in its pool: %.2f through, hum %.2f" % [console.demand_w(world.time), radio.natural,
		radio.hum_level])
	check(radio.hum_level > 0.0 and radio.natural < clear * 0.8, "gear drawing in its pool hums over it")
