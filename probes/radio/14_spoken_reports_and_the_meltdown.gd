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
	await load_storm(0.0)
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
	broadside(radio, &"stoker")
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

	# The weather station, after the Stoker's own transmissions.
	var earlier := radio.spoken_count
	world.time = 0.0
	broadside(radio, &"walker")
	radio.frequency = gods.carrier(&"walker", world.time)
	var broadcast := world.player.get_node(^"Broadcast") as Broadcast
	await physics_frames(10)
	check(radio.on_air() == Sounds.RADIO_CLEAR_SKIES and radio.spoken_count == earlier,
		"tuned in to calm, Clear Skies plays and it says nothing")
	for k in 3:
		world.time += tuning.radio_report_every
		radio.read_at = -INF
		await physics_frames(3)
	check(radio.spoken_count == earlier, "however long the calm holds: no timed report")

	# A storm the same everywhere never ends: large, so an advisory at once,
	# read whole through the dirty signal; then nothing while it holds.
	weather_everywhere(0.3)
	radio.read_at = -INF
	await _heard(radio, earlier + 1)
	print("a thin storm that never ends (dirt %.2f): \"%s\"" % [radio.dirt, " ".join(radio.spoken)])
	check(radio.spoken_count == earlier + 1 and radio.spoken_urgent and not " ".join(radio.spoken).contains("..."),
		"a storm that lasts and lasts: an advisory, read whole")
	for k in 3:
		world.time += tuning.radio_report_every
		radio.read_at = -INF
		await physics_frames(3)
	check(radio.spoken_count == earlier + 1, "while its news holds, nothing more")

	# Its clearing is news: a short report, heard.
	weather_everywhere(0.0)
	radio.read_at = -INF
	await _heard(radio, earlier + 2)
	var longest := 0
	for sentence in " ".join(radio.spoken).split(".", false):
		longest = maxi(longest, sentence.split(" ", false).size())
	print("cleared: \"%s\"; you hear \"%s\"" % [" ".join(radio.spoken), broadcast.reading])
	check(radio.spoken_count == earlier + 2 and not radio.spoken_urgent and longest <= 5,
		"its clearing is news, in short sentences")
	check(broadcast.reading == " ".join(radio.spoken), "and your ears hear it")

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
	print("a fast storm: \"%s\"" % " ".join(radio.spoken))
	check(radio.spoken_count == before + 1 and radio.spoken_urgent, "a fast storm breaks in with an advisory at once")
	check(broadcast.reading == " ".join(radio.spoken), "and your ears hear it over what was being read")
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
