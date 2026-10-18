extends WeatherProbe
## Wind & storms probe 17: a burst booms, heard after it's seen as thunder is
## after lightning. From 3 km and from 12 km off the rift's live vent, a burst's
## boom comes as long after it began as sound takes to come that far, never
## before; further off it's quieter and duller; it comes from the vent's way;
## and a jump in time past it plays nothing late.

## Its arrival may be read this late, s: a few ticks.
const SLACK := 0.1


func run() -> void:
	await load_weather(1234, true)
	var vent := await beside_vent(3000.0)
	var rumbles := world.weather.rumbles
	var geology := world.shape.history.geology
	var onset := 600.0
	var booms := []
	for metres: float in [3000.0, 12000.0]:
		onset = geology.next_burst(vent, onset + 1.0)
		if metres > 3000.0:
			var here := Vector2(world.player_world_x(), world.player_world_z())
			var root := world.shape.sites.anchor().place(vent.p)
			var out := Vector2(signf(here.x - root.x), 0.0)
			teleport(here.x + out.x * (metres - 3000.0), here.y)
			await settle(true)
		var r := geology.radius
		var by := Sphere.angle(Sphere.point(world.moon.latitude, world.moon.longitude), vent.p) * r
		# Sound's speed is the air's temperature's, so read it about then.
		world.time = onset + by / 353.0
		var arrives := onset + by / rumbles.speed()
		world.time = arrives - 0.5
		world.time_warp = 1.0
		var early := false
		var boom := {}
		for i in 120:
			await get_tree().physics_frame
			for each: Dictionary in rumbles.heard:
				if each.source == vent.id and absf(each.at - arrives) < 5.0:
					boom = each
			if not boom.is_empty():
				break
		for each: Dictionary in rumbles.heard:
			if each.source == vent.id and each.at >= onset and each.at < arrives - 0.001:
				early = true
		print("%.0f m off: heard %.2f s after it began, sound takes %.2f; %.1f dB, %.0f Hz" % [by, boom.get("at", NAN) - onset,
			by / rumbles.speed(), boom.get("volume_db", NAN), boom.get("cutoff_hz", NAN)])
		check(not boom.is_empty() and not early and boom.at - arrives < SLACK,
			"from %.0f km it's heard as long after as sound takes to come" % (by / 1000.0))
		if boom.is_empty():
			return
		var way := world.shape.sites.anchor().place(vent.p) - Vector2(world.player_world_x(), world.player_world_z())
		check(rad_to_deg(absf(way.normalized().angle_to(boom.toward))) < 2.0, "it comes from the vent's way")
		booms.append(boom)
	check(booms[1].volume_db < booms[0].volume_db - 9.0 and booms[1].cutoff_hz < booms[0].cutoff_hz * 0.5,
		"further off it's quieter and duller")

	var heard := rumbles.heard.size()
	var next := geology.next_burst(vent, onset + 1.0)
	world.time = next + 600.0
	await physics_frames(10)
	check(rumbles.heard.size() == heard, "a jump in time past a boom plays nothing late")
