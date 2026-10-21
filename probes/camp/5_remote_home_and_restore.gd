extends DeckProbe
## Runs alone
## A real camp keeps collision and battery use beyond player retention, including far resume.
func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -3))
	await simulate(1.0)
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.2, 0), 0.0, beacon)
	var battery := fit_part(deck, &"battery") as Battery
	battery.fill(battery.capacity())
	check(world.home.mark(beacon) == "", "mark admitted")
	var until := Time.get_ticks_msec() + 60000
	while not world.home.supported and Time.get_ticks_msec() < until:
		await get_tree().process_frame
	check(world.home.supported, "home ground and history become ready")
	var at := Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))
	var before := deck.global_position.y
	world.power.set_physics_process(false)
	var near_charge := battery.charge_wh
	world.power.live(10.0, world.time)
	var near_used := near_charge - battery.charge_wh
	var charge := battery.charge_wh
	teleport(at.x + 2100, at.y)
	await settle()
	await simulate(1.0)
	check(is_instance_valid(deck) and world.home.supported and world.terrain.has_collision_at(at.x, at.y), "remote home remains on actual collision")
	check(is_instance_valid(deck) and not deck.freeze and absf(deck.global_position.y - before) < 0.5, "remote home stays physically live")
	world.power.live(10.0, world.time)
	var far_used := charge - battery.charge_wh
	check(far_used > 0.0 and absf(far_used - near_used) < 0.000001, "the same power interval consumes equally near and far")
	print("HOME METRICS chunks=%d collision=%d members=%d items=%d terrain_max_ms=%.2f" % [world.terrain._chunks.size(), world.terrain.collision_count(), world.home.members.size(), world.home.item_count, world.terrain.slowest_frame_ms])
	check(world.home.unmark() != "", "unmark cannot discard distant camp support")
	var saves := get_node(^"/root/Saves")
	check(saves.save(world), "far camp saved")
	check(await resume(), "far camp restored")
	check(world.home.has_home() and world.home.supported and is_instance_valid(world.home.root), "restored identity is supported before play resumes")
	check(world.terrain.has_collision_at(at.x, at.y), "far restored camp has ground")
	teleport(at.x, at.y)
	await settle()
	await simulate(0.5)
	check(world.home.unmark() == "", "home releases safely after returning")
