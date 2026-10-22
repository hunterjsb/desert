extends WeatherProbe
## Radio probe 23: Port Morgan Tower's voice comes from the radio. It reads
## a report in a few short phrases, not its line: a storm on its way is
## "Storm coming. From the <point>. <when>.", one on you
## "Storm here. Clearing, <when>.", and every phrase it can
## say is in its bank of recordings. On the clear-skies scenario's radio, its reading of a storm
## just due at the tower, it reads from
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
	var from: float = radio.reading.from
	radio.reading = {"stormy": false, "change": t + 240.0, "back": t + 900.0, "wind": 40.2, "from": from}
	var coming := radio.report(t)
	radio.reading = {"stormy": true, "change": t + 600.0, "back": INF, "wind": 26.4, "from": from}
	var on_you := radio.report(t)
	print("coming: \"%s\"; on you: \"%s\"" % [" ".join(coming), " ".join(on_you)])
	check(" ".join(coming) == "Storm coming. From the %s. Four minutes." % radio.say_point(from),
		"a storm on its way, in three short phrases")
	check(" ".join(on_you) == "Storm here. Clearing, ten minutes.", "and one on you")

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

	# A storm just inside the calm horizon at the tower, as its reading has it
	# (held, so the field doesn't read afresh): its report, read from the radio.
	var before := radio.spoken_count
	radio.reading = {"stormy": false, "change": world.time + 120.0, "back": world.time + 900.0, "wind": 20.0,
		"from": from}
	radio.read_at = world.time
	radio._checked_at = radio.read_at
	radio.spoken_at = -INF
	for i in 300:
		await get_tree().physics_frame
		if radio.reader.playing and radio.spoken_count > before:
			break
	print("it reads \"%s\", playing %s" % [" ".join(radio.spoken), radio.reader.stream.resource_path
		if radio.reader.stream != null else "nothing"])
	check(radio.spoken_count == before + 1 and " ".join(radio.spoken).contains("storm") and radio.reader.playing,
		"the scheduled report is read aloud from bundled recordings")
	check(radio.reader.get_parent() == radio and radio.reader.global_position.is_equal_approx(
		radio.to_global(Hands.middle_of(radio))) and radio.reader.bus == radio.signal_bus(),
		"from the radio through its own speaker and interference chain")
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
