extends MenuProbe
## Optional cargo is selected by ordinary Take, physical fitting and removal.

func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.surveyor_preflight.enabled = true
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var until := Time.get_ticks_msec() + 60000
	while (world.arrival == null or not is_instance_valid(world.arrival.preflight)) and Time.get_ticks_msec() < until:
		await get_tree().physics_frame
	var prep := world.arrival.preflight
	check(is_instance_valid(prep), "the physical departure room initializes")
	if not is_instance_valid(prep):
		return
	await physics_frames(5)
	var ship := prep.ship
	var guide := SurveyorRecovery.named(world)[&"guide"] as Device
	var at := guide.global_position + Vector3(1.1, 0, 0)
	at.y = ship.global_position.y
	stand_at(at, guide.global_position)
	await physics_frames(4)
	press(&"hands_grab")
	await physics_frames(60)
	var hands := world.player.hands
	print("PICK guide",hands.held == guide," look",hands.look_device," notice",hands.notice)
	check(hands.held == guide, "ordinary Take picks the actual guide from its rack")
	if hands.held != guide:
		return
	check(not PreflightCargo.loaded(world, ship).has(&"guide"), "a held item has not loaded itself")
	var panel := ship.pod_parts[&"side_back_b"] as Chassis
	var panel_pose := ship.pod.deck.global_transform * panel.pose()
	var normal := panel_pose.basis.y
	var target := panel_pose.origin + normal * Chassis.THICK * 0.5
	at = target + normal * 0.65
	at.y = ship.global_position.y
	stand_at(at, target)
	await physics_frames(20)
	print("FIT offered",hands.sticking," socket",hands.socket," notice",hands.notice)
	check(not hands.sticking.is_empty() and hands.sticking.get("deck") == ship.pod.deck,
		"the actual pod face offers the normal physical fitting preview")
	if hands.sticking.is_empty():
		return
	press(&"hands_grab")
	await physics_frames(4)
	check(hands.held == null and guide.host() == ship.pod.deck and PreflightCargo.loaded(world, ship).has(&"guide"),
		"ordinary Take attaches that same guide as selected cargo")
	stand_at(at, guide.global_position)
	await physics_frames(4)
	press(&"hands_grab")
	await physics_frames(60)
	check(hands.held == guide and guide.host() == null and not PreflightCargo.loaded(world, ship).has(&"guide"),
		"ordinary Take removes it and the launch selection follows")


func stand_at(at: Vector3, toward: Vector3) -> void:
	world.teleport(world.player, Transform3D(Basis.IDENTITY, at))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(toward)
