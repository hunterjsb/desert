extends HandsProbe
## Radio probe 10: the volume knob. Looking at a radio playing music, the
## wheel with alt turns its volume down a notch at a time, and the music and
## the hiss under it go quieter with it, while the dial stays where it was.
## Turned all the way down it's silent and still on, still saying its words;
## turned back up it plays as loud as before. The look-at readout says where
## the knob stands.


func run() -> void:
	await load_hands()
	var radio := device(&"radio", spot(0.0, -1.2), 0.0, true) as Radio
	await physics_frames(30)
	radio.freeze = true
	while radio.channel != Radio.MUSIC:
		radio.interact(world.player)
	await physics_frames(5)
	look(eye(), radio.global_position)
	await physics_frames(2)
	var khz := radio.frequency
	var loud := radio.music.volume_db
	var hiss := radio.hiss.volume_db
	_wheel(-1)
	await physics_frames(3)
	print("a notch down: music %.1f to %.1f dB, hiss %.1f to %.1f dB" % [loud, radio.music.volume_db, hiss,
		radio.hiss.volume_db])
	check(is_equal_approx(radio.volume, 1.0 - Radio.VOLUME_STEP) and radio.frequency == khz,
		"alt and the wheel on the radio turn its volume down a notch, the dial where it was")
	check(radio.music.volume_db < loud - 0.5, "the music goes quieter")
	check(radio.hiss.volume_db <= hiss, "and the hiss under it no louder")
	hands._look()
	check(hands._readout.text.contains("volume 90%"), "the readout says where the knob stands: \"%s\"" % hands._readout.text)
	for i in 12:
		_wheel(-1)
	await physics_frames(3)
	check(radio.volume == 0.0 and radio.music.volume_db < -60.0 and radio.playing() and radio.track() != null,
		"all the way down it's silent, and still on (%.0f dB)" % radio.music.volume_db)
	for i in 12:
		_wheel(1)
	await physics_frames(3)
	check(radio.volume == 1.0 and absf(radio.music.volume_db - loud) < 0.01, "turned back up it's as loud as before")


## A notch of the wheel with alt held, up or down.
func _wheel(notches: int) -> void:
	for pressed in [true, false]:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP if notches > 0 else MOUSE_BUTTON_WHEEL_DOWN
		wheel.alt_pressed = true
		wheel.pressed = pressed
		get_viewport().push_input(wheel)
