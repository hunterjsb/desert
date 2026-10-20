extends Probe
## A brief interference drop recovers without restarting the station.

func run() -> void:
	var radio := Radio.new()
	radio.freeze = true
	add_child(radio)
	radio.set_physics_process(false)
	radio._put_on(Sounds.RADIO_STOKER, 103.0, 3.0)
	await physics_frames(2)
	var playback := radio.music.get_stream_playback()
	var glitch := radio._glitch
	glitch.kind = &"drop"
	glitch._length = 0.1
	glitch._left = glitch._length
	var muted := glitch.tick(0.04, 0.0)
	check(muted.x == 0.0, "a forced dropout mutes the station")
	glitch.tick(0.07, 0.0)
	var recovered := glitch.tick(0.01, 0.0)
	check(glitch.kind == &"" and recovered == Vector2.ONE,
		"the expired drop restores normal gain and pitch")
	check(playback != null and radio.music.playing and radio.music.get_stream_playback() == playback,
		"the dropped station kept playing throughout")
	radio.free()
