extends ShieldProbe
## Radio probe 60: the valve preamp. In the radio's misc bay it lifts what the
## set hears: a god comes in preamp_gain times as strong, so one lost in the
## hiss comes through, at no cost in power (gonkhub, 2026-10-22).


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	await physics_frames(2)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var gods := Radio.gods_of(world)
	var id := &"ledger"
	radio.frequency = gods.carrier(id, world.time)
	var before: float = radio.receive(id, x, z, world.time).strength
	var drew := radio.demand_w()
	var preamp := Catalog.part(&"valve_preamp")
	radio.fit(preamp, Scenarios._free(radio, &"radio_bay"))
	var after: float = radio.receive(id, x, z, world.time).strength
	print("the Ledger %.3f bare, %.3f through the preamp; drawing %.1f W, then %.1f W" % [before, after, drew,
		radio.demand_w()])
	check(absf(after - before * Tuning.current().preamp_gain) < 1e-4, "it lifts a god's signal")
	check(is_equal_approx(radio.demand_w(), drew), "and the set draws no more power")
