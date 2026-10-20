extends WeatherProbe
## Radio probe 17: the relay at night. The "night" scenario stands you on a
## clear night facing the relay satellite beside Tu: it's in the sun's light,
## low enough over the horizon to be in view straight ahead, and the sky draws
## it. Hung at L1, it holds its place while the stars turn past it.


func run() -> void:
	await load_weather()
	Scenarios.apply(world, Scenarios.by_key("night"))
	await physics_frames(10)
	var day := world.weather.day
	var sun := day.sun_direction(world.time, world.moon.latitude, world.moon.longitude)
	var material := world.weather.sky.material
	var lit: float = material.get_shader_parameter("relay_light")
	var dir: Vector3 = material.get_shader_parameter("relay_dir")
	var ahead := -world.player.camera.global_basis.z
	var off := rad_to_deg(Vector2(ahead.x, ahead.z).angle_to(Vector2(dir.x, dir.z)))
	print("night at %.0f s: the sun %.0f° down; the relay %.0f° up, %.0f° off ahead, shown at %.2f" % [world.time,
		-rad_to_deg(asin(sun.y)), rad_to_deg(asin(dir.y)), off, lit])
	check(sun.y < 0.0, "it's night")
	check(lit > 0.0, "the sky draws the relay")
	check(absf(off) < 5.0 and dir.y > sin(deg_to_rad(5.0)) and dir.y < sin(deg_to_rad(55.0)),
		"over the horizon, straight ahead")
	# Against the stars, which turn once a day: it all but holds still.
	world.time += 5.0
	await physics_frames(3)
	var later: Vector3 = material.get_shader_parameter("relay_dir")
	var rate := rad_to_deg(dir.angle_to(later)) / 5.0
	var stars := 360.0 / (tuning_day() * 60.0)
	print("it moves across the sky at %.3f°/s; the stars at most %.2f°/s" % [rate, stars])
	check(rate < stars * 0.5, "it holds its place while the stars turn past it")


func tuning_day() -> float:
	return Tuning.current().day_minutes
