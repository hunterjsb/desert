extends ShieldProbe
## Radio probe 14: spoken reports, and the meltdown. The Stoker's song never
## plays by itself: its frequency carries only its talk and tones until a
## meltdown (the dev console's, for now) calls it up, when it plays through
## once from its start and stops; called up again while it plays, it starts
## over. The weather station reports aloud the moment you tune in, Clear
## Skies or not, and every radio_report_every s after: the local time, the
## wind and the temperature where the radio stands, read from the world, then
## its outlook, units in words, every word and number of it, through a dirty
## signal too; and your ears hear it. A fast storm breaks in at once with an
## advisory, out of turn, read over whatever was being read, and only once.


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
	var broadcast := world.player.get_node(^"Broadcast") as Broadcast
	await _heard(radio, 1)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var heat := roundi(world.weather.field_temperature(radio.global_position, radio.spoken_at))
	var local := world.weather.day.time_of_day(radio.spoken_at, Sphere.longitude(radio.point_at(x, z)))
	var minutes := roundi(local * 24.0 * 60.0) % (24 * 60)
	print("tuned in: \"%s\"; you hear \"%s\"" % [radio.spoken, broadcast.reading])
	check(radio.on_air() == Sounds.RADIO_CLEAR_SKIES and radio.spoken_count == 1, "tuned in, it reports at once, Clear Skies or not")
	check(radio.spoken.contains("Local time %d:%02d" % [minutes / 60, minutes % 60])
		and radio.spoken.contains("Temperature %s degrees" % (str(heat) if heat >= 0 else "minus %d" % -heat))
		and (radio.spoken.contains("Wind") or radio.spoken.contains("Calm")),
		"the local time, the temperature and the wind, read from the world, units in words")
	check(not radio.spoken.contains("..."), "every word of it")
	check(broadcast.reading == radio.spoken and not radio.spoken_urgent, "and your ears hear it, in its turn")
	var first := radio.spoken_at
	world.time = first + tuning.radio_report_every * 0.5
	await physics_frames(5)
	check(radio.spoken_count == 1, "not again before %d s" % roundi(tuning.radio_report_every))
	world.time = first + tuning.radio_report_every + 1.0
	await _heard(radio, 2)
	check(radio.spoken_count == 2, "and again after")

	# A storm the same everywhere never ends: large, so an advisory at once,
	# read whole through the dirty signal; then the report in its turn, whole.
	weather_everywhere(0.3)
	radio.read_at = -INF
	await _heard(radio, 3)
	print("a thin storm that never ends (dirt %.2f): \"%s\"" % [radio.dirt, radio.spoken])
	check(radio.spoken_urgent and radio.spoken.contains("large") and not radio.spoken.contains("..."),
		"a storm that lasts and lasts: an advisory, read whole")
	world.time = radio.spoken_at + tuning.radio_report_every + 1.0
	await _heard(radio, 4)
	print("its report: \"%s\"" % radio.spoken)
	check(radio.dirt > 0.3 and not radio.spoken_urgent and radio.spoken.contains("Temperature")
		and radio.spoken.contains("In a storm") and not radio.spoken.contains("..."),
		"through a dirty signal, the report still read whole")

	# Out of it, then a fast storm: an advisory at once, out of turn, and once.
	weather_everywhere(0.0)
	radio.read_at = -INF
	await physics_frames(3)
	var before := radio.spoken_count
	weather_everywhere(0.3, tuning.advisory_fast_ms + 1.5)
	radio.read_at = -INF
	await _heard(radio, before + 1)
	for i in 3:
		await get_tree().process_frame
	print("a fast storm: \"%s\"" % radio.spoken)
	check(radio.spoken_count == before + 1 and radio.spoken_urgent and radio.spoken.begins_with("Weather advisory.")
		and radio.spoken.contains("fast"), "a fast storm breaks in with an advisory at once, out of turn")
	check(broadcast.reading == radio.spoken, "and your ears hear it over what was being read")
	for k in 4:
		radio.read_at = -INF
		world.time += tuning.radio_forecast_every
		await physics_frames(3)
	check(radio.spoken_count == before + 1, "warned of once, not again while it lasts")


## Ticks until the radio has read its `count`th report aloud, or a while.
func _heard(radio: Radio, count: int) -> void:
	for i in 600:
		await get_tree().physics_frame
		if radio.spoken_count >= count:
			break
	# The voice is the view's: it hears the radio on a drawn frame, not a tick.
	for i in 3:
		await get_tree().process_frame
