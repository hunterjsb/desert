extends ShieldProbe
## A different voice rate must not truncate words, leak onto music or another set.

func run() -> void:
	await load_storm(0.0)
	var first := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	var second := Scenarios.standing(world, &"radio", [&"battery"], [2.0, 2.0]) as Radio
	for radio in [first, second]:
		radio.set_physics_process(false)
		radio.on = true
	var words := PackedStringArray(["Wind speed forty.", "Temperature minus three."])
	var gods := Radio.gods_of(world)
	first.frequency = gods.carrier(&"ledger", world.time)
	second.frequency = gods.carrier(&"almanac", world.time)
	first._queue(words, 0.0)
	var ledger_bus := first.reader.bus
	var ledger_pitch := AudioServer.get_bus_effect(AudioServer.get_bus_index(ledger_bus), 0) as AudioEffectPitchShift
	var pitch_before := ledger_pitch.pitch_scale
	second._queue(words, 0.0)
	check(first.reader.pitch_scale != second.reader.pitch_scale and first.reader.bus != second.reader.bus
		and ledger_pitch.pitch_scale == pitch_before, "station character and cadence belong to each receiver")
	check(first.music.bus == first.signal_bus() and second.music.bus == second.signal_bus(),
		"speech treatment leaves music on its existing signal path")
	for i in first._lines.size() - 1:
		var entry: Array = first._lines[i]
		check(first._lines[i + 1][1] >= entry[1] + entry[0].get_length() / first.reader.pitch_scale,
			"a slower voice finishes its clip before the next one")
	var last: Array = first._lines[-1]
	check(is_equal_approx(first._done_at, last[1] + last[0].get_length() / first.reader.pitch_scale),
		"the final word keeps its full playback time")
	first.announce(words)
	check(first.reader.pitch_scale == 1.0 and first.reader.bus == Sounds.radio_bus(),
		"local computer announcements retain the original voice")
	first._hush()
	first.frequency = gods.carrier(&"walker", world.time)
	first._queue(words, 0.0)
	check(first.reader.pitch_scale == 1.0 and first.reader.bus == first.signal_bus(),
		"weather keeps the approved voice after a station change")
	var owned := second._effect_buses.duplicate()
	second.free()
	check(owned.all(func(name: StringName) -> bool: return AudioServer.get_bus_index(name) == -1)
		and AudioServer.get_bus_index(ledger_bus) >= 0, "a removed set frees its speech bus without changing another")
