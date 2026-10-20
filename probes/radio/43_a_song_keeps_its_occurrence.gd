extends Probe
## Mixer time may advance while slow simulation ticks lag behind it.
## Runs alone

func run() -> void:
	get_viewport().audio_listener_enable_3d = true
	var camera := Camera3D.new()
	add_child(camera)
	camera.make_current()
	var radio := Radio.new()
	radio.freeze = true
	radio.set_physics_process(false)
	add_child(radio)
	radio.set_physics_process(false)
	radio._put_on(Sounds.RADIO_STOKER, 103.0, 3.0)
	await physics_frames(2)
	var playback := radio.music.get_stream_playback()
	var before := radio.music.get_playback_position()
	await get_tree().create_timer(2.2).timeout
	var after := radio.music.get_playback_position()
	check(after > before + 1.0, "the mixer advances while the simulated station clock waits")
	radio._put_on(Sounds.RADIO_STOKER, 103.1, 3.1)
	await physics_frames(2)
	check(playback != null and radio.music.playing and radio.music.get_stream_playback() == playback,
		"the same scheduled song keeps its playback when the clocks drift")
	radio._put_on(Sounds.RADIO_STOKER, 104.0, 0.0)
	await physics_frames(2)
	check(radio.music.get_stream_playback() != playback and radio.music.playing,
		"calling the same recording for a new occurrence starts a new playback")
	var called := radio.music.get_stream_playback()
	radio._put_on(Sounds.RADIO_STOKER, 104.1, 0.1)
	await physics_frames(2)
	check(radio.music.get_stream_playback() == called, "the new occurrence also remains continuous")
	radio.free()
