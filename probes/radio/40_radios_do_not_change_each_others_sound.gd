extends ShieldProbe
## A second set must not change the first set's reception effects or own their lifetime.

func run() -> void:
	await load_storm(0.0)
	var first := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	var second := Scenarios.standing(world, &"radio", [&"battery"], [2.0, 2.0]) as Radio
	first.on = true
	second.on = true
	first.frequency = Radio.gods_of(world).carrier(&"walker", world.time)
	second.frequency = 1995.0
	await physics_frames(3)
	var bus := AudioServer.get_bus_index(first.signal_bus())
	var filter := AudioServer.get_bus_effect(bus, Garble.Stage.HIGHS) as AudioEffectLowPassFilter
	first._listen(1.0 / 60.0)
	var cutoff := filter.cutoff_hz
	second._listen(1.0 / 60.0)
	check(filter.cutoff_hz == cutoff and first.signal_bus() != second.signal_bus(),
		"listening on a second set leaves the first set's effects alone")
	for id: StringName in Constellation.voiced():
		check(first.sky.bus_for(id) != second.sky.bus_for(id), "satellite effects belong to their own set")
	var owned := first._effect_buses.duplicate()
	first.free()
	check(owned.all(func(name: StringName) -> bool: return AudioServer.get_bus_index(name) == -1)
		and AudioServer.get_bus_index(second.signal_bus()) >= 0, "freeing one set releases only its own buses")
