extends ShieldProbe
## Radio probe 57: the misc bay's modules. Against a bare field radio at the
## same spot, a valve preamp hears a god stronger and draws more; a static
## choke lets less of a storm's static through; a direction loop's null is
## deeper; a frequency counter reads the carrier near the dial; a headset on
## a set in your hands plays it louder; a solar lid makes power by day.


func run() -> void:
	await load_storm(0.0)
	var made := {}
	var at := 0.0
	for each: StringName in [&"", &"valve_preamp", &"static_choke", &"direction_loop", &"frequency_counter",
			&"headset", &"solar_lid"]:
		var radio := Scenarios.standing(world, &"radio", [&"battery"], [at, 2.0]) as Radio
		if each != &"":
			fit_part(radio, each)
		radio.freeze = true
		radio.on = true
		made[each] = radio
		at += 0.5
	await physics_frames(3)
	var bare: Radio = made[&""]
	var x := world.world_x(bare.global_position.x)
	var z := world.world_z(bare.global_position.z)
	var strength := func(radio: Radio) -> float:
		broadside(radio, &"quartermaster")
		radio.frequency = Radio.gods_of(world).carrier(&"quartermaster", world.time)
		return radio.receive(&"quartermaster", x, z, world.time).strength
	var plain: float = strength.call(bare)
	var lifted: float = strength.call(made[&"valve_preamp"])
	print("the Quartermaster %.2f bare, %.2f through a preamp; %.1f W against %.1f W" % [plain, lifted,
		made[&"valve_preamp"].demand_w(world.time), bare.demand_w(world.time)])
	check(lifted > plain * 1.5 and made[&"valve_preamp"].demand_w(world.time) > bare.demand_w(world.time) * 2.0,
		"a valve preamp hears stronger and draws more")
	check(made[&"static_choke"].static_share() < bare.static_share(), "a static choke lets less static through")
	# End-on to a station due east, along the rod.
	bare.global_basis = Basis.IDENTITY
	made[&"direction_loop"].global_basis = Basis.IDENTITY
	print("end-on: the rod %.3f, through a loop %.3f" % [bare.rod(90.0, false), made[&"direction_loop"].rod(90.0, false)])
	check(made[&"direction_loop"].rod(90.0, false) < bare.rod(90.0, false), "a direction loop's null is deeper")
	var counter: Radio = made[&"frequency_counter"]
	counter.frequency = Radio.gods_of(world).carrier(&"quartermaster", world.time) + 3.0
	print("the counter reads: %s" % counter.stats().tuned)
	check(str(counter.stats().tuned).contains("carrier"), "a frequency counter reads the carrier near the dial")
	var close: Radio = made[&"headset"]
	var loud := close.knob_db()
	world.player.hands.hold(close)
	await physics_frames(2)
	check(close.knob_db() > loud, "a headset on a set in your hands plays it louder")
	check(made[&"solar_lid"].stats().solar_w > 0.0, "a solar lid makes power")
