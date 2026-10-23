extends ShieldProbe
## Radio probe 14: spoken reports, and the meltdown. The Stoker's song never
## plays by itself: its frequency carries only its talk and tones until a
## meltdown (the dev console's, for now) calls it up, when it plays through
## once from its start and stops; called up again while it plays, it starts
## over. The weather station speaks only with news (Hunter, 2026-10-19:
## "probably announce less often"): tuned in to calm, Clear Skies plays and it
## says nothing, however long the calm holds; a storm that comes and lasts
## breaks in with an advisory, read whole through the dirty signal, then
## nothing while its news holds; its clearing is a short report your ears
## hear; and a fast storm's advisory comes once.


func run() -> void:
	var tuning := Tuning.current()
	# FM carrying everywhere, for the Stoker's station.
	tuning.fm_margin_db = 1e6
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"fm_converter", &"sw_converter"],
		[0.0, 2.0]) as Radio
	radio.freeze = true
	radio.fit(Catalog.part(&"valve_preamp"), Scenarios._free(radio, &"radio_bay"))
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
	radio.switch_band()
	radio.fm_mhz = radio.fm_of(&"stoker")
	await physics_frames(5)
	check(radio.tuned_to() == &"stoker" and radio.on_air() == null, "tuned to the Stoker, no song")
	gods.meltdown(world.time)
	world.time += 2.0
	await physics_frames(5)
	var at := radio.music.get_playback_position()
	print("2 s into a meltdown: on air %s, %.1f s into it" % [radio.on_air(), at])
	check(radio.on_air() == Sounds.RADIO_STOKER and absf(at - 2.0) < 1.0, "a meltdown calls up its song from its start")
	# A new call must not inherit a fragment stuck in the previous occurrence.
	radio._glitch.kind = &"stutter"
	radio._glitch._anchor = at
	radio._glitch._length = 2.0
	radio._glitch._left = 2.0
	radio._glitch._period = 0.001
	radio._glitch._since = 0.0
	gods.meltdown(world.time)
	await physics_frames(5)
	print("called up again: %.3f s into it, interference %s" % [radio.music.get_playback_position(), radio._glitch.kind])
	check(radio.music.get_playback_position() < 1.0, "called up again, it starts over")
	world.time += length + 1.0
	await physics_frames(5)
	check(radio.on_air() == null and gods.stoker_song(world.time + 600.0, length) < 0.0, "then it stops, and stays stopped")

	# Port Morgan Tower, after the Stoker's own transmissions. Its schedule of the
	# deliveryship is news of its own, so only its weather lines are counted.
	world.time = 0.0
	radio.channel = Radio.WEATHER
	var broadcast := world.player.get_node(^"Broadcast") as Broadcast
	var said := await _weather_over(radio, 10)
	check(radio.on_air() == Sounds.RADIO_CLEAR_SKIES and said.is_empty(),
		"tuned in to calm, Clear Skies plays and it gives no weather report")
	for k in 3:
		world.time += tuning.radio_report_every
		radio.read_at = -INF
		said.append_array(await _weather_over(radio, 3))
	check(said.is_empty(), "however long the calm holds: no timed report")

	# A storm the same everywhere never ends: large, so an advisory at once,
	# read whole through the dirty signal; then nothing while it holds.
	weather_everywhere(0.3)
	radio.read_at = -INF
	said = await _weather_over(radio, 900, true)
	print("a thin storm that never ends (dirt %.2f): %s" % [radio.dirt, said])
	check(said.size() == 1 and radio.spoken_urgent and not said[0].contains("..."),
		"a storm that lasts and lasts: an advisory, read whole")
	said = []
	for k in 3:
		world.time += tuning.radio_report_every
		radio.read_at = -INF
		said.append_array(await _weather_over(radio, 3))
	check(said.is_empty(), "while its news holds, nothing more")

	# Its clearing is news: a short report, heard.
	weather_everywhere(0.0)
	radio.read_at = -INF
	said = await _weather_over(radio, 900, true)
	var longest := 0
	for sentence in " ".join(said).split(".", false):
		longest = maxi(longest, sentence.split(" ", false).size())
	for i in 3:
		await get_tree().process_frame
	print("cleared: %s; you hear \"%s\"" % [said, broadcast.reading])
	check(said.size() == 1 and not radio.spoken_urgent and longest <= 5, "its clearing is news, in short sentences")
	check(broadcast.reading == said[-1] if not said.is_empty() else false, "and your ears hear it")

	# A fast storm: an advisory at once, and once.
	weather_everywhere(0.3, tuning.advisory_fast_ms + 1.5)
	radio.read_at = -INF
	said = await _weather_over(radio, 900, true)
	print("a fast storm: %s" % [said])
	check(said.size() == 1 and radio.spoken_urgent, "a fast storm breaks in with an advisory at once")
	said = []
	for k in 4:
		radio.read_at = -INF
		world.time += tuning.radio_forecast_every
		said.append_array(await _weather_over(radio, 3))
	check(said.is_empty(), "warned of once, not again while it lasts")


## The weather lines it reads aloud over `frames` physics frames, its
## deliveryship schedule left out; with `first`, only until the first.
func _weather_over(radio: Radio, frames: int, first := false) -> Array[String]:
	var out: Array[String] = []
	var count := radio.spoken_count
	for i in frames:
		await get_tree().physics_frame
		if radio.spoken_count == count:
			continue
		count = radio.spoken_count
		var line := " ".join(radio.spoken)
		if line != Radio.spoken_words(radio.survey_words(radio.spoken_at)):
			out.append(line)
			if first:
				break
	return out
