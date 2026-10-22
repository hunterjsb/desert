extends WeatherProbe
## Radio probe 47: the drone's schedule. Frontier Ag's crop-survey drone
## passes over Port Morgan every lap, its route swinging round the port lap
## by lap. Port Morgan Control Tower, on FM beside the port, reads aloud how
## long until it's over the port, and that's when it is; it reads again only
## once survey_report_every has gone by. Hearing it is Flight Plan.

## How far from the port's middle the radio stands, m.
const NEAR := 800.0


func run() -> void:
	await load_weather()
	world.counts_deeds = true
	world.player.set_physics_process(false)
	var sky := Radio.constellation_of(world)
	var orbit: Satellite = sky.orbits[Airdrop.SURVEYOR]
	var history := world.shape.history
	var port: Vector3 = history.landmark(&"port_morgan").p

	# Over Port Morgan every lap, its route turning round the port.
	var nearest := []
	var tracks := []
	for lap in 3:
		var best := INF
		var t := lap * orbit.period
		while t < (lap + 1) * orbit.period:
			best = minf(best, orbit.at(t).normalized().angle_to(port))
			t += 1.0
		nearest.append(rad_to_deg(best))
		var start := lap * orbit.period
		tracks.append(orbit.at(start).cross(orbit.at(start + 1.0)).normalized())
	print("nearest Port Morgan each lap: %s°; its route turns %.0f° a lap" % [
		nearest.map(func(d: float) -> String: return "%.2f" % d), rad_to_deg(tracks[0].angle_to(tracks[1]))])
	check(nearest.max() < 0.2, "over Port Morgan every lap")
	check(rad_to_deg(tracks[0].angle_to(tracks[1])) > 20.0, "its route swings round the port lap by lap")

	# The tower's schedule, beside the port on FM, and the time it gives.
	var at := Sphere.toward(port, Sphere.bearing(port, history.sub_tu), NEAR / history.radius)
	world.travel(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)), 0.0)
	await settle()
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"fm_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.switch_band()
	radio.on = true
	radio.fm_mhz = Fm.stations(Radio.gods_of(world), world.run_seed, Tuning.current()).filter(
		func(each: Dictionary) -> bool: return each.id == Fm.TOWER)[0].mhz
	await physics_frames(5)
	print("tuned to the tower: \"%s\"" % radio.said)
	check(radio.channel == Radio.SURVEY and radio.spoken_count > 0, "the tower reads its schedule aloud")
	check(get_node(^"/root/Profile").did(&"flight_plan"), "hearing it is Flight Plan")
	var eta := orbit.until_through(world.time)
	var off := rad_to_deg(orbit.at(world.time + eta).normalized().angle_to(port))
	print("over Port Morgan in %.0f s: %.2f° off it then" % [eta, off])
	check(off < 0.1, "over Port Morgan when it says")
	var count := radio.spoken_count
	world.time += world.tuning.survey_report_every * 0.5
	await physics_frames(3)
	var early := radio.spoken_count
	world.time += world.tuning.survey_report_every * 0.5 + 1.0
	await physics_frames(3)
	print("read %d times by halfway, %d once its time came" % [early - count, radio.spoken_count - count])
	check(early == count and radio.spoken_count == count + 1, "it reads again only once its time comes")
