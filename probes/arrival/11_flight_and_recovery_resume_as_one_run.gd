extends MenuProbe
## Real Main resume continues the saved flight and never grants the survivors twice.
func run() -> void:
	var tuning := Tuning.current()
	# Exercise the saved automatic opening; preparation has separate acceptance.
	tuning.surveyor_preflight["enabled"] = false
	tuning.run_seed = 1234
	tuning.salvage = false
	for phase in [&"orbit", &"ejection", &"descent", &"entry", &"landing"]:
		tuning.surveyor_arrival[String(phase) + "_s"] = 0.35
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var until := Time.get_ticks_msec() + 60000
	while world.arrival_state.get("phase", &"") != &"ejection" and Time.get_ticks_msec() < until:
		await get_tree().physics_frame
	check(main.save_run(), "real flight can be saved")
	var flight: Dictionary = saves().held().arrival.duplicate(true)
	var observed: Array[Dictionary] = []
	saves().restored.connect(func(at: World) -> void: observed.append(at.arrival_state.duplicate(true)), CONNECT_ONE_SHOT)
	await main.resume()
	world = main.world()
	check(observed.size() == 1 and observed[0].phase == flight.phase and observed[0].elapsed == flight.elapsed,
		"resume reconnects the exact saved phase before its clock continues")
	check(world.arrival_state.phase == &"recovery" and world.arrival_state.structure == flight.structure \
		and world.arrival_state.equipment == flight.equipment, "the resumed flight lands with the same resolved survivors")
	var roles := world.arrival_nodes.size()
	var food := world.arrival_nodes.get(&"food") as RigidBody3D
	check(is_instance_valid(food), "food physically exists after landing")
	if not is_instance_valid(food):
		return
	world.player.hands.hold(food)
	check(main.save_run(), "partly recovered actual run saves")
	await main.resume()
	world = main.world()
	check(world.arrival_state.phase == &"recovery" and world.arrival_nodes.size() == roles,
		"recovery resumes with the same number of real roles")
	check(is_instance_valid(world.player.hands.held) and world.player.hands.held.get_meta(&"arrival_uid", &"") == &"food",
		"the actually recovered food stays in hand")
	check(world.arrival_state.equipment.filter(func(entry: Dictionary) -> bool: return entry.uid == &"food")[0].recovered,
		"physical recovery is preserved")
	check(world.player.suit.carried.is_empty() and world.player.is_physics_processing(), "resume grants no inventory kit and returns movement")
