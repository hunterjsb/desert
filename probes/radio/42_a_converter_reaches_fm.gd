extends WeatherProbe
## Radio probe 42: the FM band is reached through a converter. Without one, a
## radio's band switch does nothing; with one in its side it switches to FM,
## its dial reads MHz and use sweeps to Port Morgan's station; the converter
## taken off, it's back on the AM dial where it was.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.frequency = 262.0
	await physics_frames(2)
	check(not radio.switch_band() and radio.band == Radio.AM_BAND, "without a converter the band stays AM")
	Scenarios.fill(world, radio, [&"fm_converter"])
	check(radio.has_fm(), "the converter fits the radio's side")
	check(radio.switch_band() and radio.band == Radio.FM_BAND, "with one it switches to FM")
	radio.interact(world.player)
	var port: float = Fm.stations(Radio.gods_of(world), world.run_seed, Tuning.current())[0].mhz
	check(is_equal_approx(radio.fm_mhz, port) and radio.tuned_to() == &"port_fm",
		"use sweeps to the port's station (%.1f MHz, %.1f)" % [radio.fm_mhz, port])
	check(str(radio.stats().tuned) == "%.1f MHz" % port, "its dial reads MHz: %s" % radio.stats().tuned)
	var seat: Socket = radio.sockets().filter(func(each: Socket) -> bool: return each.kind == &"radio_mod")[0]
	radio.take(seat).free()
	await physics_frames(2)
	check(radio.band == Radio.AM_BAND and radio.frequency == 262.0, "the converter off, it's back on AM where it was")
