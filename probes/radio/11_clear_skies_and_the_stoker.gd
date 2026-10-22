extends ShieldProbe
## Radio probe 11: clear skies, and the Stoker's song. Tuned to Port Morgan
## Tower under skies with no storm anywhere, it has nothing to report and
## holds: its clear-skies song plays, and its line still gives the forecast.
## Let a storm in and it breaks off the song for the report at its next
## reading. Tuned to the Stoker in a meltdown, its furnace song plays on its
## FM station, and a storm over it, which FM shrugs off, neither turns it down
## nor starts it over. FM carries everywhere here.


class SteadySignal extends Glitch:
	func tick(_delta: float, _dirt: float) -> Vector2:
		return Vector2.ONE


func run() -> void:
	Tuning.current().fm_margin_db = 1e6
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"fm_converter"], [0.0, 2.0]) as Radio
	# Measure weather gain without an unrelated random dropout muting either sample.
	radio._glitch = SteadySignal.new(radio.music)
	radio.freeze = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	radio.channel = Radio.WEATHER
	await physics_frames(5)
	print("the tower, clear skies: \"%s\", on air %s" % [radio.said, radio.on_air()])
	check(radio.on_air() == Sounds.RADIO_CLEAR_SKIES and radio.music.playing,
		"with nothing to report, the weather station plays its clear-skies song")
	check(radio.said.contains("clear for"), "and still gives the forecast")

	weather_everywhere(1.0)
	# The station reads the field every few seconds: this once, at once.
	radio.read_at = -INF
	await physics_frames(8)
	print("the tower, in a storm: \"%s\", on air %s" % [radio.said, radio.on_air()])
	check(radio.on_air() == null and not radio.music.playing, "a storm breaks the song off for the report")
	check(radio.reading.stormy, "the report is of the storm")

	weather_everywhere(0.0)
	radio.fm_mhz = radio.fm_of(&"stoker")
	gods.meltdown(world.time)
	await physics_frames(8)
	var clear := radio.music.volume_db
	var playback := radio.music.get_stream_playback()
	print("the Stoker, clear skies: on air %s at %.1f dB" % [radio.on_air(), clear])
	check(radio.on_air() == Sounds.RADIO_STOKER and radio.music.playing, "the Stoker's frequency carries its song")
	weather_everywhere(1.0)
	await physics_frames(8)
	print("the Stoker, in a storm: %.1f dB, %s" % [radio.music.volume_db, radio.said])
	check(radio.on_air() == Sounds.RADIO_STOKER and absf(radio.music.volume_db - clear) < 1.0,
		"a storm over it doesn't turn it down on FM")
	check(playback != null and radio.music.playing and radio.music.get_stream_playback() == playback,
		"nor start it over")
