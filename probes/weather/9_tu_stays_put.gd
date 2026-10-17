extends WeatherProbe
## Wind & storms probe 9: Tu stays put. Through a whole day where a run begins,
## the Tu the sky draws never strays from where it started by more than the
## day's nod, though it does nod, while the sun goes round the sky. On the far
## side Tu never rises, and casts no light.

const STEPS := 240


func run() -> void:
	await load_weather()
	world.time_warp = 0.0
	var day := world.weather.day
	var sky := world.weather.sky
	var seconds := world.tuning.day_minutes * 60.0
	var drawn := func(t: float) -> Vector3:
		world.time = t
		await physics_frames(2)
		return sky.material.get_shader_parameter("tu_dir")
	var first: Vector3 = await drawn.call(0.0)
	var strayed := 0.0
	var swept := 0.0
	var sun_was := day.sun_direction(0.0, world.moon.latitude, world.moon.longitude)
	for i in range(1, STEPS + 1):
		var t := seconds * i / STEPS
		var tu: Vector3 = await drawn.call(t)
		strayed = maxf(strayed, rad_to_deg(tu.angle_to(first)))
		var sun := day.sun_direction(t, world.moon.latitude, world.moon.longitude)
		swept += rad_to_deg(sun.angle_to(sun_was))
		sun_was = sun
	var nod := rad_to_deg(Vector2(DayCycle.LIBRATION_LONGITUDE, DayCycle.LIBRATION_LATITUDE).length()) * 2.0
	print("Tu strayed %.2f° over the day, the nod allowing %.2f°; the sun swept %.0f°" % [strayed, nod, swept])
	check(strayed > 0.2 and strayed <= nod, "Tu stays put but for its nod (%.2f° of %.2f°)" % [strayed, nod])
	check(swept > 350.0, "while the sun goes round the sky (%.0f°)" % swept)

	var r := sin(day.tu_radius())
	var highest := -INF
	var lit := 0.0
	for place: Vector2 in [Vector2(0.0, 180.0), Vector2(45.0, 150.0), Vector2(-60.0, 230.0)]:
		world.moon.place(place.x, world.tuning.tu_longitude_degrees + place.y)
		for i in 24:
			var tu: Vector3 = await drawn.call(seconds * i / 24.0)
			highest = maxf(highest, tu.y)
			lit = maxf(lit, sky.tu_seen)
	check(highest < -r and lit == 0.0,
		"the far side never sees Tu, nor its light (its top %.1f° up at most)" % rad_to_deg(asin(highest + r)))
