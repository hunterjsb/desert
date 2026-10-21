extends ShieldProbe
## Radio probe 13: the relay hangs beside Tu. It's at Zan and Tu's L1, so from
## where a run begins it stands a few degrees off Tu all day and never sets,
## looping slowly round its point. On the FM band it sends the port's music,
## clean, and a storm over you doesn't touch it. At night, sunlit, it shows
## in the sky. From the far side, where Tu never shows, it never does either.

## The clock is read this often, s.
const STEP := 20.0
## It stays within this many degrees of Tu's middle from the start.
const BESIDE := 15.0


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"fm_converter"], [0.0, 2.0]) as Radio
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

	radio.switch_band()
	radio.on = true
	radio.fm_mhz = _relay_mhz()
	await physics_frames(3)
	var clear := radio.receive_fm(x, z, world.time)
	weather_everywhere(0.8)
	await physics_frames(3)
	var stormy := radio.receive_fm(x, z, world.time)
	print("on FM: %.1f dB clear, %.1f dB under a storm" % [clear.margin, stormy.margin])
	check(clear.id == &"relay" and clear.quiet >= Radio.WHOLE and stormy.quiet >= Radio.WHOLE,
		"on FM it sends the music clean, a storm over you or not")
	weather_everywhere(0.0)

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


## The relay's frequency on the FM band.
func _relay_mhz() -> float:
	for each in Fm.stations(Radio.gods_of(world), world.run_seed, Tuning.current()):
		if each.id == &"relay":
			return each.mhz
	return NAN


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 3.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += STEP
	check(false, "found a moment")
	return from
