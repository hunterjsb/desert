extends MenuProbe
## Empty-hand use while supported and prone opens the ordinary safe sleep choices.
func run() -> void:
	await open_main(false)
	await started()
	await faded_in()
	var player := world.player
	for end in player.waist.tied.duplicate():
		player.waist.untie(end)
	player.rotation.y += PI
	player.camera.rotation.x = 0.0
	var until := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < until and (not player.is_on_floor() or world.sleep.refusal() != ""):
		await get_tree().physics_frame
	check(world.sleep.refusal() == "", "the ordinary camp is safe for sleep: " + world.sleep.refusal())
	press(&"lie_down")
	await physics_frames(2)
	check(player.ground_pose == &"prone", "the lie action rests on supported ground")
	check(player.hands.interact() and main.ui.is_open(), "ordinary use offers sleep without finding a bedroll")
	check(not world.sleep.sleeping, "offering the choices does not advance a night")
	main.ui.close_top()
	player.global_position.y += 3.0
	player.velocity = Vector3.DOWN
	await physics_frames(1)
	check(not player.is_on_floor(), "the unsupported case is actually falling")
	check(not player.hands.interact() and not main.ui.is_open(), "falling prone cannot offer bare-ground sleep")
