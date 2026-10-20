extends Node
## Render identical words through the actual speech profiles for comparison.
## godot --headless --path . res://look/radio_voices/record.tscn -- <output>

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if not args.is_empty() else "user://radio-voices"
	DirAccess.make_dir_recursive_absolute(out)
	get_viewport().audio_listener_enable_3d = true
	var camera := Camera3D.new()
	add_child(camera)
	camera.make_current()
	var radio := Radio.new()
	radio.freeze = true
	radio.set_physics_process(false)
	add_child(radio)
	radio.reader.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	radio.reader.volume_db = 0.0
	var sentence := "Wind speed forty. Temperature minus three. Bearing one hundred seventy three."
	var plan := RadioSpeech.plan(sentence, Radio.clip)
	var profiles := Tuning.current().radio_voice_profiles
	for id: StringName in [&"walker", &"quartermaster", &"cistern", &"almanac", &"ledger", &"stoker", &"beacon"]:
		var profile: Dictionary = profiles.get(id, {})
		radio.reader.pitch_scale = profile.get("rate", 1.0)
		var bus := radio._speech_bus(profile)
		radio.reader.bus = bus
		var index := AudioServer.get_bus_index(bus)
		var recorder := AudioEffectRecord.new()
		AudioServer.add_bus_effect(index, recorder)
		recorder.set_recording_active(true)
		await get_tree().create_timer(0.15).timeout
		for entry: Array in plan:
			var clip: AudioStream = entry[0]
			radio.reader.stream = clip
			radio.reader.play()
			await get_tree().create_timer(clip.get_length() / radio.reader.pitch_scale
				+ (Radio.STOP_GAP if entry[1] else Tuning.current().radio_word_gap_seconds)).timeout
		await get_tree().create_timer(0.25).timeout
		recorder.set_recording_active(false)
		var recording := recorder.get_recording()
		if recording.data.is_empty() or recording.data.count(0) == recording.data.size():
			push_error("No speech reached the recording bus for %s" % id)
			get_tree().quit(1)
			return
		recording.save_to_wav(out.path_join("%s.wav" % id))
		AudioServer.remove_bus_effect(index, AudioServer.get_bus_effect_count(index) - 1)
		print("voice: ", id)
	radio.free()
	get_tree().quit()
