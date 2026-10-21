extends WeatherProbe
## Radio probe 12: the clear-skies scenario. It stands you on a clear day
## with a radio on, tuned to the weather: Port Morgan Tower, far off, on the
## relay's shortwave carrier and a wire. With no storm due at the tower within
## radio_calm_minutes there's nothing to report, so its clear-skies song
## plays; once the storm comes within them, the next reading breaks the song
## off for the report.


func run() -> void:
	await load_weather()
	Scenarios.apply(world, Scenarios.by_key("clear"))
	var dropped := await _landed()
	check(world.player.hands.held is Flare and world.player.hands.held in dropped,
		"the same clear setup supplies the deliveryship signal flare")
	for alias in ["clear_skies", "deliveryship"]:
		check(Scenarios.by_key(alias) == Scenarios.by_key("clear"), "old setup names reach the unified clear scenario")
	check(not dropped.is_empty() and dropped[0] is Radio and dropped.any(func(n: Node) -> bool: return n is ShieldGenerator),
		"it sets a radio and a shield on its plate in front of you")
	if dropped.is_empty():
		return
	var radio: Radio = dropped[0]
	await physics_frames(60)
	var t := world.time
	var due: float = radio.reading.change - t
	var calm := Tuning.current().radio_calm_minutes * 60.0
	print("on air %s, the tower's storm due in %.0f s: \"%s\"" % [radio.on_air(), due, radio.said])
	check(radio.channel == Radio.WEATHER and radio.said.contains("Port Morgan Tower"),
		"tuned to the weather: Port Morgan Tower, on the relay")
	check((radio.on_air() == Sounds.RADIO_CLEAR_SKIES) == Transmissions.calm(radio.reading, t),
		"with nothing to report, its clear-skies song plays, and only then")
	if radio.reading.change == INF:
		return

	# Just inside the calm horizon, the next reading has something to report.
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
