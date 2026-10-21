extends HandsProbe
## Radio probe 10: the volume knob. Looking at a radio playing music, the
## volume actions turn it down a notch at a time, and the music and
## the hiss under it go quieter with it, while the dial stays where it was.
## Turned all the way down it's silent and still on, still saying its words;
## turned back up it plays as loud as before. Each notch is the same step in
## dB, as ears hear loudness, so a tenth is barely audible.


func run() -> void:
	# Clear skies everywhere and FM carrying everywhere, so the port's music comes in steady.
	Tuning.current().storm_threshold = 2.0
	Tuning.current().fm_margin_db = 1e6
	await load_hands()
	var radio := device(&"radio", spot(0.0, -1.2), 0.0, true) as Radio
	Scenarios.fill(world, radio, [&"fm_converter"])
	await physics_frames(30)
	radio.freeze = true
	radio.channel = Radio.MUSIC
	await physics_frames(5)
	look(eye(), radio.global_position)
	await physics_frames(2)
	# A small speaker: all it plays through the radio bus, its lows cut, on into the world's;
	# its signal by way of its interference chain first.
	var bus := AudioServer.get_bus_index(Sounds.RADIO)
	var cut := AudioServer.get_bus_effect(bus, 0) as AudioEffectHighPassFilter if bus >= 0 else null
	check(radio.music.bus == radio.signal_bus() and AudioServer.get_bus_send(AudioServer.get_bus_index(radio.signal_bus()))
		== Sounds.RADIO and radio.hiss.bus == Sounds.RADIO and cut != null
		and is_equal_approx(cut.cutoff_hz, Tuning.current().radio_highpass_hz)
		and AudioServer.get_bus_send(bus) == Sounds.WORLD, "it plays through a high-pass at %d Hz, into the world's sound"
		% roundi(Tuning.current().radio_highpass_hz))
	var khz := radio.frequency
	var loud := radio.music.volume_db
	var hiss := radio.hiss.volume_db
	_turn(-1)
	await physics_frames(3)
	print("a notch down: music %.1f to %.1f dB, hiss %.1f to %.1f dB" % [loud, radio.music.volume_db, hiss,
		radio.hiss.volume_db])
	check(is_equal_approx(radio.volume, 1.0 - Radio.VOLUME_STEP) and radio.frequency == khz,
		"the volume action on the radio turns it down a notch, the dial where it was")
	check(absf(loud - radio.music.volume_db - Tuning.current().radio_volume_range_db * Radio.VOLUME_STEP) < 0.1,
		"the music goes quieter by a fixed step")
	check(radio.hiss.volume_db <= hiss, "and the hiss under it no louder")
	for i in 8:
		_turn(-1)
	await physics_frames(3)
	print("at a tenth: music %.1f dB, %.1f under full" % [radio.music.volume_db, loud - radio.music.volume_db])
	check(is_equal_approx(radio.volume, 0.1) and loud - radio.music.volume_db >= 50.0,
		"a tenth is barely audible, 50 dB and more under full")
	for i in 4:
		_turn(-1)
	await physics_frames(3)
	check(radio.volume == 0.0 and radio.music.volume_db < -60.0 and radio.playing() and radio.track() != null,
		"all the way down it's silent, and still on (%.0f dB)" % radio.music.volume_db)
	for i in 12:
		_turn(1)
	await physics_frames(3)
	check(radio.volume == 1.0 and absf(radio.music.volume_db - loud) < 0.01, "turned back up it's as loud as before")


## A notch of the volume knob, up or down, as its action.
func _turn(notches: int) -> void:
	press(&"volume_up" if notches > 0 else &"volume_down")
