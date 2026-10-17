extends MenuProbe
## Dev probe 2: a scenario over a run you've started, as the console starts
## one. Its things land in view in place of the run's kit, though the ground
## left behind has unloaded that kit by then; a second scenario clears the
## first's for its own.


func run() -> void:
	await open_main(false)
	await started()
	Scenarios.apply(world, Scenarios.by_key("radio"))
	var dropped := await _landed()
	check(dropped.size() == 2 and dropped[0] is Radio, "radio: its radio and shield land over the run's kit")
	check(not world.has_meta(&"kit"), "radio: the run's kit is cleared")
	var camera := get_viewport().get_camera_3d()
	check(dropped.all(func(body: Node3D) -> bool: return camera.is_position_in_frustum(body.global_position)),
		"radio: both in view as you arrive")

	Scenarios.apply(world, Scenarios.by_key("board"))
	var board := await _landed()
	check(board.size() == 3 and dropped.all(func(body: Variant) -> bool:
		return not is_instance_valid(body) or body.is_queued_for_deletion()), "board: its own things in place of the radio's")


## What the scenario dropped, once it has.
func _landed() -> Array:
	for i in 1200:
		if world.has_meta(&"scenario_kit"):
			return world.get_meta(&"scenario_kit")
		await get_tree().physics_frame
	return []
