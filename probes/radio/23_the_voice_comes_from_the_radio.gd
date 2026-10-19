extends WeatherProbe
## Radio probe 23: the weather station's voice comes from the radio. It reads
## a report in a few short phrases, not its line: a storm on its way is
## "Storm coming. From the <point>. <when>. Wind speed <n>.", one on you
## "Storm here. Wind speed <n>. Clearing, <when>.", and every phrase it can
## say is in its bank of recordings. Breaking in on the clear-skies scenario's radio, it reads from
## the radio itself, on the radio's bus, after its tones, the volume knob
## turning it down.


func run() -> void:
	await load_weather()
	Scenarios.apply(world, Scenarios.by_key("clear_skies"))
	var dropped := await _landed()
	check(not dropped.is_empty() and dropped[0] is Radio, "the scenario sets a radio down")
	if dropped.is_empty():
		return
	var radio: Radio = dropped[0]
	await physics_frames(10)
	var t := world.time
	var due: float = radio.reading.change
	var from: float = radio.reading.from
	radio.reading = {"stormy": false, "change": t + 240.0, "back": t + 900.0, "wind": 40.2, "from": from}
	var coming := radio.report(t)
	radio.reading = {"stormy": true, "change": t + 600.0, "back": INF, "wind": 26.4, "from": from}
	var on_you := radio.report(t)
	print("coming: \"%s\"; on you: \"%s\"" % [" ".join(coming), " ".join(on_you)])
	check(" ".join(coming) == "Storm coming. From the %s. Four minutes. Wind speed forty." % radio.say_point(from),
		"a storm on its way, in four short phrases")
	check(" ".join(on_you) == "Storm here. Wind speed twenty-six. Clearing, ten minutes.", "and one on you")

	var missing := {}
	for stormy in [false, true]:
		for bearing in range(0, 360, 10):
			for wind in [0.0, 7.4, 33.0, 61.0, 99.0, 140.0]:
				for ahead in [0.0, 4.0, 44.0, 89.0, 90.0, 300.0, 1234.0, 2400.0, 9000.0, INF]:
					radio.reading = {"stormy": stormy, "change": t + ahead, "back": INF, "wind": wind, "from": bearing}
					for phrase in radio.report(t, radio.reading):
						if Radio.clip(phrase) == null:
							missing[phrase] = true
	check(missing.is_empty(), "every phrase it can say is in its bank (missing: %s)" % ", ".join(missing.keys()))

	# Just inside the calm horizon the next reading breaks in, read from the radio.
	world.time = due - Tuning.current().radio_calm_minutes * 60.0 + 10.0
	radio.read_at = -INF
	for i in 300:
		await get_tree().physics_frame
		if radio.reader.playing:
			break
	print("it reads \"%s\", playing %s" % [" ".join(radio.spoken), radio.reader.stream.resource_path
		if radio.reader.stream != null else "nothing"])
	check(radio.spoken_count == 1 and radio.spoken[0] == "Storm coming." and radio.reader.playing
		and radio.reader.stream == Radio.clip("Storm coming."), "a storm due, it reads the report aloud, the storm first")
	check(radio.reader.get_parent() == radio and radio.reader.global_position.is_equal_approx(radio.global_position)
		and radio.reader.bus == Sounds.RADIO, "from the radio, through its speaker")
	var loud := radio.reader.volume_db
	radio.turn_volume(-1)
	await physics_frames(2)
	check(absf(loud - radio.reader.volume_db - Tuning.current().radio_volume_range_db * Radio.VOLUME_STEP) < 0.1,
		"and its volume knob turns the voice down")


func _landed() -> Array:
	for i in 1200:
		if world.has_meta(&"scenario_kit"):
			return world.get_meta(&"scenario_kit")
		await get_tree().physics_frame
	return []
