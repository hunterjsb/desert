extends PodProbe
## The ordinary take path records the landed object's recovery once, by its identity.
func run() -> void:
	await load_lines()
	board_ship()
	var made := drop()
	if made.is_empty():
		return
	state.phase = &"recovery"
	world.arrival_enabled = true
	world.arrival_state = state
	world.arrival_nodes = made
	var arrival := SurveyorArrival.new()
	arrival.world = world
	world.add_child(arrival)
	world.arrival = arrival
	arrival.restore()
	var food := made[&"food"] as RigidBody3D
	look(food.global_position + Vector3(0, 0.8, 1.3), food.global_position)
	await physics_frames(4)
	check(hands.grab(), "normal take accepts the landed ration")
	var marked: Array = state.equipment.filter(func(entry: Dictionary) -> bool: return entry.recovered)
	check(marked.size() == 1 and marked[0].uid == &"food", "gripping records exactly that object's recovery")
