extends ShieldProbe
## Radio probe 47: the Surveyor's flight plan. Frontier Ag's crop survey
## passes over Port Morgan every lap, its route swinging round the port lap
## by lap. Tuned to it, the radio reads its speed, altitude and how long
## until it's over Port Morgan, and that's when it is; it reads again only
## once survey_report_every has gone by, from over the horizon too. Hearing
## it is Flight Plan. Under clear skies.


func run() -> void:
	await load_storm(0.0)
	world.counts_deeds = true
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var sky := Radio.constellation_of(world)
	var orbit: Satellite = sky.orbits[Airdrop.SURVEYOR]
	var port: Vector3 = world.shape.history.landmark(&"port_morgan").p

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
		var at := lap * orbit.period
		tracks.append(orbit.at(at).cross(orbit.at(at + 1.0)).normalized())
	print("nearest Port Morgan each lap: %s°; its route turns %.0f° a lap" % [
		nearest.map(func(d: float) -> String: return "%.2f" % d), rad_to_deg(tracks[0].angle_to(tracks[1]))])
	check(nearest.max() < 0.2, "over Port Morgan every lap")
	check(rad_to_deg(tracks[0].angle_to(tracks[1])) > 20.0, "its route swings round the port lap by lap")

	# Its flight plan, and the time it gives.
	var p := radio.point_at(world.world_x(radio.global_position.x), world.world_z(radio.global_position.z))
	var up := _first(world.time, func(u: float) -> bool:
		return sky.on_air(Airdrop.SURVEYOR, u) and orbit.seen_from(p, u).elevation > deg_to_rad(20.0))
	world.time = up
	radio.on = true
	radio.frequency = sky.carrier(Airdrop.SURVEYOR, up)
	await physics_frames(5)
	print("tuned to it: \"%s\"" % radio.said)
	check(radio.channel == Radio.SURVEY and radio.said.contains("Port Morgan in"), "it reads its flight plan")
	check(get_node(^"/root/Profile").did(&"flight_plan"), "hearing it is Flight Plan")
	var eta := orbit.until_through(world.time)
	var off := rad_to_deg(orbit.at(world.time + eta).normalized().angle_to(port))
	print("over Port Morgan in %.0f s: %.2f° off it then" % [eta, off])
	check(off < 0.1, "over Port Morgan when it says")
	var count := radio.spoken_count
	world.time += world.tuning.survey_report_every * 0.5
	radio.frequency = sky.carrier(Airdrop.SURVEYOR, world.time)
	await physics_frames(3)
	var early := radio.spoken_count
	world.time += world.tuning.survey_report_every * 0.5 + 1.0
	radio.frequency = sky.carrier(Airdrop.SURVEYOR, world.time)
	await physics_frames(3)
	print("read %d times by halfway, %d once its time came" % [early - count, radio.spoken_count - count])
	check(early == count and radio.spoken_count == count + 1, "it reads again only once its time comes")


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 3.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += 5.0
	check(false, "found a moment")
	return from
