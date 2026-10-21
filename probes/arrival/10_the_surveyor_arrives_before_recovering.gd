extends MenuProbe
## A real new Surveyor arrives with physical survivors rather than a second starter kit.
func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	for phase in [&"orbit", &"ejection", &"descent", &"entry", &"landing"]:
		tuning.surveyor_arrival[String(phase) + "_s"] = 0.12
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	check(world.arrival_enabled and world.player.suit.carried.is_empty(), "the Surveyor begins without the old inventory grant")
	var saw: Array[StringName] = []
	var until := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < until:
		await get_tree().physics_frame
		var phase: StringName = world.arrival_state.get("phase", &"")
		if phase != &"" and not saw.has(phase):
			saw.append(phase)
		if phase == &"recovery":
			break
	check(saw == SurveyorArrival.PHASES, "orbit, ejection, descent, entry and landing lead to recovery")
	check(world.arrival_state.get("materialized", false) and not world.arrival_nodes.is_empty(), "survivors exist on actual landing ground")
	check(world.player.is_physics_processing() and world.player.is_processing_unhandled_input() and world.time_warp == 1.0,
		"walking and normal world time return at recovery")
	var board := world.arrival_nodes.get(&"board") as Device
	check(is_instance_valid(board) and board.battery() != null and board.battery().charge_wh > 0.0, "a recovered board has its own real charged cell")
	var ration := world.arrival_nodes.get(&"food") as RigidBody3D
	check(is_instance_valid(ration) and not world.arrival_state.equipment.filter(func(entry: Dictionary) -> bool: return entry.uid == &"food")[0].recovered,
		"materialization alone does not recover the food")
	if is_instance_valid(ration):
		world.player.hands.hold(ration)
		check(world.arrival_state.equipment.filter(func(entry: Dictionary) -> bool: return entry.uid == &"food")[0].recovered,
			"actually taking the physical food records recovery")
	var count := world.arrival_nodes.size()
	world.arrival.restore()
	check(world.arrival_nodes.size() == count and world.player.suit.carried.is_empty(), "restoring the completed controller grants no duplicate kit")
