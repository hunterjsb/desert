extends ShieldProbe
## Radio probe 67: the radio's tiers. A crystal set draws nothing and hears a
## god weaker than a field radio does at the same spot, with no knob to turn,
## barely heard and chewed up; a headset jacked into it, the set in your
## hands, brings it nearer and cleaner. A field radio in any maker's look
## relights its band window in the band's own colour as its band switches.


func run() -> void:
	await load_storm(0.0)
	var field := Scenarios.standing(world, &"radio", [&"battery", &"fm_converter"], [0.0, 2.0]) as Radio
	var crystal := Scenarios.standing(world, &"crystal_set", [], [0.6, 2.0]) as Radio
	for radio: Radio in [field, crystal]:
		radio.freeze = true
		radio.on = true
	await physics_frames(3)
	var x := world.world_x(field.global_position.x)
	var z := world.world_z(field.global_position.z)
	broadside(field, &"quartermaster")
	broadside(crystal, &"quartermaster")
	field.frequency = Radio.gods_of(world).carrier(&"quartermaster", world.time)
	crystal.frequency = field.frequency
	var strong: float = field.receive(&"quartermaster", x, z, world.time).strength
	var weak: float = crystal.receive(&"quartermaster", x, z, world.time).strength
	print("the Quartermaster on a field radio %.2f, on a crystal set %.2f; the crystal set draws %.1f W" % [strong,
		weak, crystal.demand_w(world.time)])
	check(crystal.demand_w(world.time) == 0.0 and crystal.powered, "a crystal set draws nothing and plays")
	check(weak > 0.0 and weak < strong * 0.5, "it hears a god weaker than a field radio does")
	check(not crystal.turn_volume(-1) and crystal.volume == 1.0, "it has no volume knob")
	await physics_frames(2)
	var bare := [crystal.knob_db(), crystal.dirt]
	fit_part(crystal, &"headset_jack")
	world.player.hands.hold(crystal)
	await physics_frames(3)
	var close := [crystal.knob_db(), crystal.dirt]
	print("a crystal set: %.1f dB, dirt %.2f bare; %.1f dB, dirt %.2f through a headset in your hands" % [bare[0],
		bare[1], close[0], close[1]])
	check(bare[0] < field.knob_db() - 20.0 and bare[1] >= 0.8, "bare, it's barely heard and chewed up")
	check(close[0] > bare[0] + 10.0 and close[1] < bare[1], "through a headset, nearer and cleaner")
	var looks := {}
	for band in [Radio.AM_BAND, Radio.FM_BAND]:
		await physics_frames(1)
		looks[field._window.mesh] = band
		field.switch_band()
	print("the field radio's window looks %d ways over its bands" % looks.size())
	check(field.style == &"company" and looks.size() == 2, "its band window relights as its band switches")
