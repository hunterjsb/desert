extends WeatherProbe
## Radio probe 12: the clear-skies scenario. It stands you on a clear day with
## the next storm 9 to 14 minutes off and a radio on, tuned to the weather
## station: there's nothing to report, so its clear-skies song plays, and the
## forecast still names the storm on its way. Once the storm comes within
## radio_calm_minutes, the next reading breaks the song off for the report.


func run() -> void:
	await load_weather()
	Scenarios.apply(world, Scenarios.by_key("clear_skies"))
	var dropped := await _landed()
	check(dropped.size() == 2 and dropped[0] is Radio, "it sets a radio and a shield in front of you")
	if dropped.is_empty():
		return
	var radio: Radio = dropped[0]
	await physics_frames(10)
	var t := world.time
	var due: float = radio.reading.change - t
	print("on air %s, the storm due in %.0f s: \"%s\"" % [radio.on_air(), due, radio.said])
	check(radio.tuned_to() == &"walker", "tuned to the weather station")
	check(due >= 540.0 - 10.0 and due <= 840.0 + 10.0, "the next storm %.1f min off" % (due / 60.0))
	check(radio.on_air() == Sounds.RADIO_CLEAR_SKIES, "with nothing to report, its clear-skies song plays")
	check(radio.said.contains("a storm from the"), "and the forecast still names the storm on its way")

	# Just inside the calm horizon, the next reading has something to report.
	var calm := Tuning.current().radio_calm_minutes * 60.0
	world.time = radio.reading.change - calm + 10.0
	radio.read_at = -INF
	await physics_frames(5)
	print("%.0f s before the storm: on air %s, \"%s\"" % [radio.reading.change - world.time, radio.on_air(), radio.said])
	check(radio.on_air() == null, "within %d min of the storm the song breaks off for the report" % roundi(calm / 60.0))


func _landed() -> Array:
	for i in 1200:
		if world.has_meta(&"scenario_kit"):
			return world.get_meta(&"scenario_kit")
		await get_tree().physics_frame
	return []
