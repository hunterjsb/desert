extends ShieldProbe
## Radio probe 13: the relay hangs beside Tu. It's at Zan and Tu's L1, so from
## where a run begins it stands a few degrees off Tu all day and never sets,
## looping slowly round its point. On shortwave it repeats Port Morgan Tower,
## so a radio far from the port hears the weather there on a wire; on FM it
## sends the port's music down, as Hunter tied it. At night, sunlit, it shows
## in the sky. From the far side, where Tu never shows, it never does either.

## The clock is read this often, s.
const STEP := 20.0
## It stays within this many degrees of Tu's middle from the start.
const BESIDE := 15.0


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter", &"fm_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(3)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var relay := Radio.relay_of(world)
	var tu := Sphere.point(0.0, deg_to_rad(Tuning.current().tu_longitude_degrees))
	var a_day := Tuning.current().day_minutes * 60.0
	var lowest := INF
	var widest := 0.0
	var moved := 0.0
	var t := 0.0
	while t < a_day:
		lowest = minf(lowest, relay.seen_from(p, t).elevation)
		widest = maxf(widest, rad_to_deg((relay.at(t) - p).normalized().angle_to(tu)))
		moved = maxf(moved, rad_to_deg((relay.at(t) - p).normalized().angle_to((relay.at(0.0) - p).normalized())))
		t += STEP
	print("over a day: at least %.0f° up, at most %.1f° off Tu, looping %.1f° round" % [rad_to_deg(lowest), widest, moved])
	check(lowest > 0.0 and widest < BESIDE, "from the start it stays beside Tu all day and never sets")
	check(moved > 1.0, "looping slowly round its point")

	var reel := Scenarios.standing(world, &"antenna_reel", [], [10.0, 2.0]) as AntennaReel
	reel.freeze = true
	reel.clip(radio)
	radio.channel = Radio.WEATHER
	await physics_frames(60)
	print("on shortwave at %.0f kHz: \"%s\"" % [radio.frequency, radio.said])
	check(radio.tuned_to() == &"relay" and radio.said.contains("Port Morgan Tower"),
		"on shortwave it repeats Port Morgan Tower")
	while radio.band != Radio.FM_BAND and radio.switch_band():
		pass
	radio.fm_mhz = radio.fm_of(Fm.RELAY)
	await physics_frames(10)
	print("on FM at %.1f MHz: %s, on air %s" % [radio.fm_mhz, radio.tuned_to(), radio.on_air()])
	check(radio.tuned_to() == Fm.RELAY and radio.channel == Radio.MUSIC and radio.on_air() != null,
		"on FM it sends the port's music down")

	var day := world.weather.day
	world.time = _first(0.0, func(u: float) -> bool:
		return not day.is_day(u, world.moon.longitude) and relay.sunlit(u, day.sun_toward(u)))
	await physics_frames(3)
	var lit: float = world.weather.sky.material.get_shader_parameter("relay_light")
	check(lit > 0.0, "at night, sunlit, it shows in the sky")

	var far := Sphere.point(0.0, deg_to_rad(Tuning.current().tu_longitude_degrees + 180.0))
	var seen := 0
	t = 0.0
	while t < a_day:
		seen += int(relay.seen_from(far, t).elevation > 0.0)
		t += STEP
	check(seen == 0, "from the far side it's never up")


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 3.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += STEP
	check(false, "found a moment")
	return from
