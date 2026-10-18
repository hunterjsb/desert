extends ShieldProbe
## Radio probe 13: the relay carries the music. A run begins with the relay
## satellite passing over where it began, so the music comes in clean. Some
## time later it has set, and the music channel is only static, the song on
## silently until it rises again. Rising it nears, and its carrier slides
## up; setting, it draws away and slides down. A storm over you garbles it as
## it does any god. At night, over the horizon and in the sun's light, it
## shows in the sky as a bright point; set, it doesn't.

## The clock is searched this often, s.
const STEP := 5.0


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	while radio.channel != Radio.MUSIC:
		radio.interact(world.player)
	await physics_frames(3)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var over := radio.receive_relay(x, z, world.time)
	print("at the start: the relay %.0f° up, clean %.2f, music at %.1f dB, \"%s\"" % [rad_to_deg(over.elevation),
		over.clean, radio.music.volume_db, radio.said])
	check(over.elevation > deg_to_rad(60.0) and over.clean > 0.9 and radio.said == "",
		"a run begins with the relay overhead and the music clean")

	var relay := Radio.relay_of(world)
	var p := radio.point_at(x, z)
	var set_at := _first(world.time, func(t: float) -> bool: return relay.seen_from(p, t).elevation < -0.05)
	var rise_at := _first(set_at, func(t: float) -> bool: return relay.seen_from(p, t).elevation > 0.1)
	var up := 0
	var t := 0.0
	while t < 6.0 * 3600.0:
		up += int(relay.seen_from(p, t).elevation > 0.0)
		t += 30.0
	print("it sets at %.0f s and rises again at %.0f s; over the horizon %.0f%% of six hours" % [set_at, rise_at,
		100.0 * up * 30.0 / (6.0 * 3600.0)])
	check(set_at < rise_at and rise_at - set_at < 4.0 * relay.period, "it sets, and rises again")
	world.time = set_at
	await physics_frames(3)
	print("set: music at %.1f dB, \"%s\"" % [radio.music.volume_db, radio.said])
	check(radio.track() != null and radio.music.volume_db < -40.0 and radio.said.ends_with("static"),
		"set, the music channel is static, the song on silently")
	var rising: float = radio.receive_relay(x, z, rise_at + 20.0).warp
	var setting: float = radio.receive_relay(x, z, set_at - 20.0).warp
	print("its carrier rising %+.2f kHz, setting %+.2f kHz" % [rising, setting])
	check(rising > 0.1 and setting < -0.1, "rising its carrier slides up, setting down")

	world.time = 0.0
	weather_everywhere(0.8)
	var stormy := radio.receive_relay(x, z, 0.0)
	print("under a storm: clean %.2f, storm %.2f" % [stormy.clean, stormy.storm])
	check(stormy.storm > 0.5 and stormy.clean < over.clean - 0.4, "a storm over you garbles it")
	weather_everywhere(0.0)

	# At night, up and sunlit, it shows; set, it doesn't.
	var day := world.weather.day
	var lon := world.moon.longitude
	var lat := world.moon.latitude
	var shows := _first(0.0, func(t: float) -> bool:
		return not day.is_day(t, lon) and relay.seen_from(p, t).elevation > 0.5 and relay.sunlit(t, day.sun_toward(t)))
	world.time = shows
	await physics_frames(3)
	var lit: float = world.weather.sky.material.get_shader_parameter("relay_light")
	var dir: Vector3 = world.weather.sky.material.get_shader_parameter("relay_dir")
	print("at night (%.0f s): it shows at %.2f, %.0f° up" % [shows, lit, rad_to_deg(asin(dir.y))])
	check(lit > 0.0 and dir.y > 0.4, "at night, over you and sunlit, it shows in the sky")
	world.time = _first(shows, func(t: float) -> bool: return relay.seen_from(p, t).elevation < -0.05)
	await physics_frames(3)
	check(world.weather.sky.material.get_shader_parameter("relay_light") == 0.0, "set, it doesn't")
	check(lat == world.moon.latitude, "you never moved")


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 3.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += STEP
	check(false, "found a moment")
	return from
