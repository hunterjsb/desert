extends Probe
## Repeating an interference fragment must not replace the station's playback,
## and a slowed or sped-up one leaves the song where its station is in it.
## Runs alone

func run() -> void:
	get_viewport().audio_listener_enable_3d = true
	var camera := Camera3D.new()
	add_child(camera)
	camera.make_current()
	var radio := Radio.new()
	radio.freeze = true
	add_child(radio)
	radio.set_physics_process(false)
	radio._put_on(Sounds.RADIO_STOKER, 103.0, 3.0)
	await physics_frames(2)
	var playback := radio.music.get_stream_playback()
	var glitch := radio._glitch
	glitch.kind = &"stutter"
	glitch._anchor = 2.0
	glitch._length = 0.2
	glitch._left = glitch._length
	glitch._period = 0.01
	glitch._since = 0.0
	glitch.tick(0.02, 1.0)
	await physics_frames(2)
	var repeated := radio.music.get_playback_position()
	check(playback != null and radio.music.get_stream_playback() == playback,
		"a repeated fragment retains the active station playback")
	check(repeated >= glitch._anchor and repeated < glitch._anchor + 0.5,
		"the player's cursor follows the intended repeated fragment")
	glitch._end()
	await physics_frames(2)
	var caught_up := radio.music.get_playback_position()
	print(playback.get_class(), " repeated at ", repeated, ", caught up at ", caught_up)
	check(radio.music.get_stream_playback() == playback,
		"catching up also retains the active playback")
	check(caught_up >= glitch._anchor + glitch._length and caught_up < glitch._anchor + glitch._length + 0.5,
		"the player's cursor follows the intended catch-up position")
	# A drag slows the song for a moment; over, it's where it would have been.
	glitch.kind = &"drag"
	glitch._anchor = 5.0
	glitch._length = 0.5
	glitch._end()
	await physics_frames(2)
	var after_drag := radio.music.get_playback_position()
	check(after_drag >= 5.5 and after_drag < 6.0, "after a drag it catches up with its station (%.2f s)" % after_drag)
	radio.free()
