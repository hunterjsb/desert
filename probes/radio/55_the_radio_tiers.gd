extends ShieldProbe
## Radio probe 55: the radio's tiers. A crystal set draws nothing and hears a
## god weaker than a field radio does at the same spot; a survey set reaches
## FM with no converter; and a field radio in any maker's look relights its
## band window in the band's own colour as its band switches.


func run() -> void:
	await load_storm(0.0)
	var field := Scenarios.standing(world, &"radio", [&"battery", &"fm_converter"], [0.0, 2.0]) as Radio
	var crystal := Scenarios.standing(world, &"crystal_set", [], [0.6, 2.0]) as Radio
	var survey := Scenarios.standing(world, &"survey_set", [&"battery"], [-0.6, 2.0]) as Radio
	for radio: Radio in [field, crystal, survey]:
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
	check(survey.switch_band() and survey.band == Radio.FM_BAND, "a survey set reaches FM with no converter")
	var looks := {}
	for band in [Radio.AM_BAND, Radio.FM_BAND]:
		await physics_frames(1)
		looks[field._window.mesh] = band
		field.switch_band()
	print("the field radio's window looks %d ways over its bands" % looks.size())
	check(field.style == &"company" and looks.size() == 2, "its band window relights as its band switches")
