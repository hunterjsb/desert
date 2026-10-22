extends WeatherProbe
## Radio probe 47: the deliveryship's schedule. Frontier Ag's deliveryship
## passes over Port Morgan every lap, its route swinging round the port lap
## by lap. Port Morgan Tower, on FM beside the port, reads as you tune in the
## deliveryship's altitude, speed and how long until it's over Port Morgan,
## and that's when it is; it reads again only for its next pass, news, not on a
## timer. Hearing it is Flight Plan.

## How far from the port's middle the radio stands, m.
const NEAR := 800.0


func run() -> void:
	await load_weather()
	world.counts_deeds = true
	world.player.set_physics_process(false)
	var sky := Radio.constellation_of(world)
	var orbit: Satellite = sky.orbits[Airdrop.DELIVERYSHIP]
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
	radio.fm_mhz = radio.fm_of(Fm.TOWER)
	# Any weather news first, then the schedule.
	var profile := get_node(^"/root/Profile")
	for i in 900:
		await physics_frames(1)
		if profile.did(&"flight_plan"):
			break
	var spoken := radio.spoken_count
	print("tuned to the tower: \"%s\", %d read" % [radio.said, spoken])
	check(radio.channel == Radio.WEATHER and spoken > 0, "tuned in, the tower reads the deliveryship's schedule")
	check(profile.did(&"flight_plan"), "hearing it is Flight Plan")
	var eta := orbit.until_through(world.time)
	var off := rad_to_deg(orbit.at(world.time + eta).normalized().angle_to(port))
	print("over Port Morgan in %.0f s: %.2f° off it then" % [eta, off])
	check(off < 0.1, "over Port Morgan when it says")
	# Only with news: a new pass, once this one's gone over.
	var count := radio.spoken_count
	world.time += eta * 0.5
	await _read_out(radio)
	var early := radio.spoken_count
	world.time += eta * 0.5 + 20.0
	await _read_out(radio)
	print("read %d times before the pass, %d after it" % [early - count, radio.spoken_count - count])
	check(early == count and radio.spoken_count == count + 1, "it reads again only for its next pass")


## Physics frames until what it's reading is done, or a while.
func _read_out(radio: Radio) -> void:
	for i in 600:
		await physics_frames(1)
		if radio._lines.is_empty():
			break
