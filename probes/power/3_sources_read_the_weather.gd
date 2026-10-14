extends DeviceProbe
## Power probe 3: sources read the felt weather. Solar follows the day, the
## night, storms and latitude; a planted turbine makes little in a calm and the
## most in a storm, and nothing while it's being moved. (Inside a wind shield
## it makes nothing: that waits for the shield, Stage 6.)


func run() -> void:
	await load_world(1234, false)
	var field := world.weather.field
	var day := world.weather.day
	var x := world.player_world_x()
	var z := world.player_world_z()
	var panel := spawn_device(&"charger", 2.0, 0.2, false)
	fit_part(panel, &"solar_panel")
	var turbine := spawn_device(&"turbine", -2.0, 0.2, false)
	await physics_frames(60)
	# Staked, as a planted turbine will be: a gale slides a loose one on the sand.
	turbine.freeze = true
	turbine.linear_velocity = Vector3.ZERO
	var at := func(hour: float, stormy: bool) -> float:
		var t := 0.0
		while t < 3.0 * 24.0 * 3600.0:
			if absf(day.time_of_day(t) - hour) < 0.004 and (field.raw_storm_at(x, z, t) > 0.0) == stormy \
					and (not stormy or field.storm_at(x, z, t) == 1.0):
				return t
			t += 5.0
		return NAN
	var solar := {}
	for when: Array in [["noon", 0.5, false], ["morning", 0.33, false], ["night", 0.9, false], ["storm noon", 0.5, true]]:
		world.time = at.call(when[1], when[2])
		await get_tree().physics_frame
		solar[when[0]] = panel.production_w()
	world.time = at.call(0.5, false)
	world.moon.latitude = deg_to_rad(60.0)
	await get_tree().physics_frame
	solar["60 north"] = panel.production_w()
	world.moon.latitude = 0.0
	print("solar: %s" % solar)
	check(solar["noon"] > solar["morning"] and solar["morning"] > 0.0, "solar climbs with the sun")
	check(solar["night"] == 0.0, "and makes nothing at night")
	check(solar["storm noon"] < solar["noon"] * 0.35, "a storm takes most of it")
	check(absf(solar["60 north"] / solar["noon"] - 0.5) < 0.05, "at 60 degrees the noon sun gives half")

	var calm := 1e9
	var gale := 0.0
	var t := 0.0
	while t < 2.0 * 24.0 * 3600.0:
		var wind := field.wind_at(world.world_x(turbine.global_position.x), world.world_z(turbine.global_position.z), t).length()
		if wind < 8.0 and calm > 1e8:
			calm = t
		if wind > 25.0 and gale == 0.0:
			gale = t
		t += 10.0
	var output := {}
	for when: Array in [["calm", calm], ["gale", gale]]:
		world.time = when[1]
		await get_tree().physics_frame
		output[when[0]] = turbine.production_w()
	turbine.freeze = false
	turbine.linear_velocity = Vector3(1.0, 0.0, 0.0)
	output["carried"] = turbine.production_w()
	print("turbine: %s" % output)
	check(output["gale"] > output["calm"] * 10.0, "a turbine makes the most in a storm")
	check(output["carried"] == 0.0, "and nothing while it's moving")
