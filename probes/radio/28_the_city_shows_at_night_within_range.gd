extends WeatherProbe
## Radio probe 28: the living city shows only within range, at night. Two km
## from it at midnight its lights are lit; at noon there nothing of it shows;
## at midnight from past its chatter's range, nothing; and come within
## city_douse_m, its lights go out.
## Time limit: 300 s.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var lights: CityLights = world.get_children().filter(func(n: Node) -> bool: return n is CityLights)[0]
	var city := Radio.gods_of(world).city
	var day := world.weather.day
	var length := world.tuning.day_minutes * 60.0
	var t := world.time
	while city.moving(t) or absf(day.time_of_day(t, Sphere.longitude(city.at(t))) - 0.0) > 0.01:
		t += 5.0
	for each: Array in [[2000.0, t, true, "two km off at midnight"], [2000.0, t + length * 0.5, false, "two km off at noon"],
			[world.tuning.city_heard_m.y + 1500.0, t, false, "past its chatter's range at midnight"],
			[world.tuning.city_douse_m * 0.6, t, false, "within its dousing at midnight"]]:
		var at := Sphere.toward(city.at(each[1]), 0.0, each[0] / world.shape.history.radius)
		world.travel(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)), 0.0)
		world.time = each[1]
		world.time_warp = 0.0
		await settle(true)
		await physics_frames(3)
		print("%s: shown %.2f" % [each[3], lights.shown])
		check((lights.shown > 0.9 and lights.visible) if each[2] else (lights.shown == 0.0 and not lights.visible),
			"%s: %s" % [each[3], "its lights" if each[2] else "nothing"])
