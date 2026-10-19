extends ShieldProbe
## Radio probe 14: spoken reports, and the meltdown. The Stoker's song never
## plays by itself: its frequency carries only its talk and tones until a
## meltdown (the dev console's, for now) calls it up, when it plays through
## once from its start and stops; called up again while it plays, it starts
## over. The weather station says nothing aloud while it holds on Clear
## Skies; once a storm breaks in, it reads the report aloud at once, in
## phrases from its bank of recordings, the storm taking some, in the radio's
## own voice, and again every radio_speak_every s while there's something to
## report.


func run() -> void:
	await load_storm(0.0)
	var tuning := Tuning.current()
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	var length := Sounds.RADIO_STOKER.get_length()

	# The Stoker: nothing until a meltdown, then its song once.
	check(DevConsole.COMMANDS.has("meltdown"), "the dev console has a meltdown")
	var never := true
	for k in 120:
		never = never and gods.stoker_song(k * 30.0, length) < 0.0
	check(never, "its song never plays by itself")
	radio.on = true
	radio.frequency = gods.carrier(&"stoker", world.time)
	await physics_frames(5)
	check(radio.tuned_to() == &"stoker" and radio.on_air() == null, "tuned to the Stoker, no song")
	gods.meltdown(world.time)
	world.time += 2.0
	await physics_frames(5)
	var at := radio.music.get_playback_position()
	print("2 s into a meltdown: on air %s, %.1f s into it" % [radio.on_air(), at])
	check(radio.on_air() == Sounds.RADIO_STOKER and absf(at - 2.0) < 1.0, "a meltdown calls up its song from its start")
	gods.meltdown(world.time)
	await physics_frames(5)
	check(radio.music.get_playback_position() < 1.0, "called up again, it starts over")
	world.time += length + 1.0
	await physics_frames(5)
	check(radio.on_air() == null and gods.stoker_song(world.time + 600.0, length) < 0.0, "then it stops, and stays stopped")

	# The weather station's voice.
	world.time = 0.0
	radio.frequency = gods.carrier(&"walker", world.time)
	await physics_frames(5)
	check(radio.on_air() == Sounds.RADIO_CLEAR_SKIES and radio.spoken_count == 0, "holding on Clear Skies, it says nothing aloud")
	weather_everywhere(0.3)
	radio.read_at = -INF
	for i in 120:
		await get_tree().physics_frame
		if radio.spoken_count > 0:
			break
	print("the storm breaks in: \"%s\"" % " ".join(radio.spoken))
	check(radio.spoken_count == 1 and radio.spoken.size() >= 3 and Array(radio.spoken).all(func(phrase: String) -> bool:
		return phrase == "..." or Radio.clip(phrase) != null), "a storm breaking in, it reads the report aloud from its bank")
	check(radio.reader.bus == Sounds.RADIO, "in the radio's own voice")
	var first := radio.spoken_at
	world.time = first + tuning.radio_speak_every * 0.5
	await physics_frames(5)
	check(radio.spoken_count == 1, "not again before %d s" % roundi(tuning.radio_speak_every))
	world.time = first + tuning.radio_speak_every + 1.0
	for i in 120:
		await get_tree().physics_frame
		if radio.spoken_count > 1:
			break
	check(radio.spoken_count == 2, "and again after")
