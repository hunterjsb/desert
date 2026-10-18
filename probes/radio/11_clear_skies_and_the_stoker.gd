extends ShieldProbe
## Radio probe 11: clear skies, and the Stoker's song. Tuned to the Walker
## under skies with no storm anywhere, the weather station has nothing to
## report and holds: its clear-skies song plays, with no report tones, and its
## line still gives the forecast. Let a storm in and it breaks off the song for
## the report at its next reading. Tuned to the Stoker in a meltdown, its
## furnace song plays on its frequency, and a storm on the way to it turns it down without
## starting it over.


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	radio.on = true
	radio.frequency = gods.carrier(&"walker", world.time)
	await physics_frames(5)
	print("the Walker, clear skies: \"%s\", on air %s" % [radio.said, radio.on_air()])
	check(radio.on_air() == Sounds.RADIO_CLEAR_SKIES and radio.music.playing,
		"with nothing to report, the weather station plays its clear-skies song")
	check(radio.said.contains("clear for"), "and still gives the forecast")

	weather_everywhere(1.0)
	# The station reads the field every few seconds: this once, at once.
	radio.read_at = -INF
	await physics_frames(8)
	print("the Walker, in a storm: \"%s\", on air %s" % [radio.said, radio.on_air()])
	check(radio.on_air() == null and not radio.music.playing, "a storm breaks the song off for the report")
	check(radio.reading.stormy, "the report is of the storm")

	weather_everywhere(0.0)
	radio.frequency = gods.carrier(&"stoker", world.time)
	gods.meltdown(world.time)
	await physics_frames(8)
	var clear := radio.music.volume_db
	var at := radio.music.get_playback_position()
	print("the Stoker, clear skies: on air %s at %.1f dB" % [radio.on_air(), clear])
	check(radio.on_air() == Sounds.RADIO_STOKER and radio.music.playing, "the Stoker's frequency carries its song")
	weather_everywhere(1.0)
	await physics_frames(8)
	print("the Stoker, in a storm: %.1f dB, %s" % [radio.music.volume_db, radio.said])
	check(radio.on_air() == Sounds.RADIO_STOKER and radio.music.volume_db < clear - 3.0,
		"a storm on the way turns it down")
	check(radio.music.get_playback_position() > at, "without starting it over")
