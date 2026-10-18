extends MenuProbe
## Dev probe 2: a scenario over a run you've started, as the console starts
## one. Its things land in view in place of the run's kit, though the ground
## left behind has unloaded that kit by then; a second scenario clears the
## first's for its own, but not what you put in your suit.


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

	# What you've put in your suit is yours, whatever the next scenario clears.
	var radio: Radio = dropped[0]
	var shield: Node3D = dropped[1]
	world.player.hands.hold(radio)
	for i in 30:
		await get_tree().physics_frame
	check(world.player.suit.put_in(), "the radio goes in your suit")
	Scenarios.apply(world, Scenarios.by_key("board"))
	var board := await _landed()
	check(board.size() == 3 and (not is_instance_valid(shield) or shield.is_queued_for_deletion()),
		"board: its own things in place of the radio's")
	check(is_instance_valid(radio) and not radio.is_queued_for_deletion() and radio in world.player.suit.carried,
		"the radio you put in your suit stays yours")
	# A fresh suit's kit takes the place of what you carry.
	Scenarios.apply(world, Scenarios.by_key("console"))
	await _landed()
	check(not is_instance_valid(radio) and not world.player.suit.carried.is_empty(),
		"console: a fresh suit's kit in place of the radio")


## What the scenario dropped, once it has.
func _landed() -> Array:
	for i in 1200:
		if world.has_meta(&"scenario_kit"):
			return world.get_meta(&"scenario_kit")
		await get_tree().physics_frame
	return []
