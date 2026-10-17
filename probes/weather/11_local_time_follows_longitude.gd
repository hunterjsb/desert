extends WeatherProbe
## Wind & storms probe 11: local time follows longitude. Where a run begins the
## clock is the one it began on. A quarter of the way round to the east it's
## six hours later, and the drawn sun, the light solar reads, the air's warmth
## and a radio's day music all follow; a quarter round to the west it's six
## hours earlier, and night.


func run() -> void:
	await load_weather()
	world.time_warp = 0.0
	var day := world.weather.day
	var spawn := world.moon.longitude
	check(is_equal_approx(day.time_of_day(0.0, spawn), world.tuning.start_time_of_day),
		"where a run begins it's the hour the run began on")
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	while radio.channel != Radio.MUSIC:
		radio.interact(world.player)
	var at := world.player.global_position
	# A clear morning where a run begins: noon to the east, past midnight to the west.
	world.time = find_time(func(t: float) -> bool:
		return absf(day.time_of_day(t, spawn) - 0.3) < 0.01 and player_storm_at(t) == 0.0)
	var seen := {}
	for way: Array in [["here", 0.0], ["east", PI / 2.0], ["west", -PI / 2.0]]:
		world.moon.longitude = spawn + way[1]
		await physics_frames(2)
		var drawn: Vector3 = world.weather.sky.material.get_shader_parameter("sun_dir")
		seen[way[0]] = {"hour": day.time_of_day(world.time, world.moon.longitude), "sun": drawn.y,
			"light": world.weather.felt_light(at), "warmth": world.weather.field_temperature(at),
			"music": radio.track() == Sounds.RADIO_DAY}
	world.moon.longitude = spawn
	print("local time: %s" % seen)
	check(is_equal_approx(seen.east.hour, fposmod(seen.here.hour + 0.25, 1.0))
		and is_equal_approx(seen.west.hour, fposmod(seen.here.hour - 0.25, 1.0)), "east is six hours on, west six back")
	check(seen.east.sun > 0.9 and seen.here.sun > 0.0 and seen.west.sun < 0.0, "the drawn sun follows")
	check(seen.east.light > seen.here.light and seen.here.light > 0.0 and seen.west.light == 0.0, "and the light")
	check(seen.east.warmth > seen.here.warmth and seen.here.warmth > seen.west.warmth, "and the warmth")
	check(seen.east.music and seen.here.music and not seen.west.music, "and the radio's day music")
