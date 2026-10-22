extends WeatherProbe
## Radio probe 74: each printed frequency meets the production needle on its
## real band, including the shortwave endpoint and the FM edge offset.


func run() -> void:
	check(RadioBandLooks.SW.high * 1000.0 == Shortwave.HIGHEST,
		"the printed shortwave endpoint reaches the receiver's highest frequency")
	await load_weather()
	world.player.set_physics_process(false)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"fm_converter", &"sw_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	for band: StringName in Radio.BANDS:
		check(radio.band == band, "the receiver reaches the next printed band")
		var marks := RadioBandLooks.ticks(RadioBandLooks.of(band))
		for mark: Dictionary in marks:
			if str(mark.label).is_empty():
				continue
			var printed := float(mark.label)
			if band == Radio.FM_BAND:
				radio.fm_mhz = printed
			else:
				radio.frequency = printed * (1000.0 if band == Radio.SW_BAND else 1.0)
			radio.shown_khz = radio._needle_khz()
			radio._show_dial()
			var tick_x: float = Radio.BAND_WIDTH * 0.89 * (mark.fraction - 0.5)
			check(absf(radio.needle.position.x - tick_x) < 0.0001,
				"%s %s: the needle meets its printed tick" % [band, mark.label])
		if band != Radio.SW_BAND:
			check(radio.switch_band(), "the fitted converter switches the real band")
