extends FarmProbe
## A grown harvest must pay for a modest deck through a night and a storm,
## without free water or a burner that beats a panel in clear noon light.

func run() -> void:
	await load_storm(0.0)
	world.moon.latitude = 0.0
	weather_everywhere(0.0, 0.0)
	var bed := spawn_device(&"deep_planter", 4.0, 0.4, false) as Planter
	bed.freeze = true
	bed.tank_l = world.tuning.planter_tank_litres
	var cane := fit_part(bed, &"coalcane") as Plant
	hold_temperature(bed.global_position, 20.0)
	await clock_at(time_of(0.25))
	var water := bed.tank_l
	var began := world.time
	while not cane.ripe() and world.time - began < 2400.0:
		await pass_time(50.0)
	check(cane.ripe(), "a watered deep bed yields in two clear days")
	if not cane.ripe():
		return
	var drank := water - bed.tank_l
	check(absf(drank - cane.litres) < 0.00001 and drank > 1.0, "the harvest spent real tank water")
	var fuel := bed.take(cane.socket)
	check(fuel.get_meta(&"catalog") == &"coalcane_bundle" and cane.growth < 1.0, "harvest gives the existing fuel and leaves a cut stump")
	bed.tank_l = 0.0
	await clock_at(time_of(0.5, 3))
	var cut := cane.growth
	await pass_time(30.0)
	check(cane.growth == cut, "an empty bed cannot regrow fuel")

	var deck := spawn_device(&"chassis", 7.0, 0.2, false) as Chassis
	deck.freeze = true
	var burner := Catalog.device(&"burner") as Burner
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.15, -0.15), 0.0, burner)
	var shield := Catalog.device(&"light_shield") as ShieldGenerator
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.3, 0.3), 0.0, shield)
	var radio := Catalog.device(&"radio") as Radio
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.3, 0.3), 0.0, radio)
	var cell := Catalog.part(&"battery") as Battery
	cell.charge_wh = 0.0
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.3, -0.3), 0.0, cell)
	burner.fit(fuel, burner.hopper())
	burner.interact(world.player)
	await pass_time(1.0)
	check(shield.switch(true), "the burner charges the empty pool enough to start the shield")
	radio.switch(true)
	var panel_deck := spawn_device(&"chassis", -5.0, 0.1, false)
	panel_deck.freeze = true
	fit_part(panel_deck, &"solar_panel")
	check(panel_deck.production_w() > burner.production_w(), "clear noon favours the solar panel")
	panel_deck.queue_free()
	await physics_frames(2)
	await clock_at(time_of(0.75, 4))
	var generated := world.power.generated_wh
	var spent := world.power.used_wh
	var spill := world.power.spilled_wh
	var stored := world.power.stored_wh()
	var brownouts := [0]
	await pass_time(600.0, func() -> void:
		if not shield.running() or not radio.powered:
			brownouts[0] += 1)
	weather_everywhere(1.0, 25.0)
	await pass_time(90.0, func() -> void:
		if not shield.running() or not radio.powered:
			brownouts[0] += 1)
	check(brownouts[0] == 0, "a single harvest carries a light shield and radio through night and storm")
	await pass_time(60.0)
	var made := world.power.generated_wh - generated
	var used := world.power.used_wh - spent
	var held := world.power.stored_wh() - stored
	var wasted := world.power.spilled_wh - spill
	check(absf(made - used - held - wasted) < 0.00001, "all fuel energy is used, stored or spilled")
	check(burner.fuel_seconds < 0.001 and not burner.stocked() and burner.production_w() == 0.0, "spent fuel stops generating")
	print("coalcane: %.2f L; %.2f Wh made, %.2f used, %.2f stored; night 600s + storm 90s, then exhaustion" % [drank, made, used, held])
	metric("Harvest water", drank, "L")
	metric("Harvest energy", made, "Wh")
	metric("Night and storm load", used, "Wh")
