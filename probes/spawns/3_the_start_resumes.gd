extends MenuProbe
## Spawns probe 3: the origin and its start outlast a save. A Homesteader's
## run saved out on the sand and resumed is the Homesteader's still, begun
## at the same start on the moon, you where you stood; a new run after a
## death there comes as a Homesteader again, on a new seed. A save from
## before origins has none: it resumes with the start it had, the tuning's,
## and no origin of its own.


func run() -> void:
	await open_main()
	var homesteader := Kit.named(&"homesteader")
	main.new_game(false, false, homesteader)
	await faded_in()
	await started()
	var began := world.start
	teleport(world.spawn.x + 6.0, world.spawn.y - 9.0)
	await physics_frames(30)
	var stood := Vector2(world.player_world_x(), world.player_world_z())
	var moon := Vector2(world.moon.latitude, world.moon.longitude)
	check(main.save_run(), "the Homesteader's run saved")
	await main._quit_to_menu()
	main.resume()
	await faded_in()
	if saves().restoring:
		await saves().restored
	check(main.in_run() and world.has_meta(&"resumed") and world.kit == homesteader and world.start == began,
		"resumed, it's the Homesteader's run from the same start")
	check(Vector2(world.player_world_x(), world.player_world_z()).distance_to(stood) < 0.1
		and Vector2(world.moon.latitude, world.moon.longitude).distance_to(moon) < 1e-6,
		"you're back where you stood, there on the moon too")
	var old_seed := world.run_seed
	main.new_game(false, true)
	await faded_in()
	check(world.kit == homesteader and world.run_seed != old_seed and world.start != began,
		"a new run after a death comes as the Homesteader again, from a start on its own seed")

	# A run with no origin, as every run was before them, saved as an older build wrote it.
	await main._quit_to_menu()
	main.new_game()
	await faded_in()
	await started()
	teleport(world.spawn.x - 8.0, world.spawn.y + 5.0)
	await physics_frames(30)
	moon = Vector2(world.moon.latitude, world.moon.longitude)
	check(main.save_run(), "the run with no origin saved")
	var data: Dictionary = SaveFile.read(saves().path(), saves().KIND, saves().VERSION).data
	data.erase("kit")
	SaveFile.write(saves().path(), saves().KIND, saves().VERSION, data)
	await main._quit_to_menu()
	main.resume()
	await faded_in()
	if saves().restoring:
		await saves().restored
	var tuning := Tuning.current()
	var old_start := Sphere.point(deg_to_rad(tuning.spawn_latitude_degrees), deg_to_rad(tuning.spawn_longitude_degrees))
	check(main.in_run() and world.has_meta(&"resumed") and world.kit == null and world.start == old_start
		and Sphere.point(world.moon._spawn_latitude, world.moon._spawn_longitude).distance_to(old_start) < 1e-6
		and Vector2(world.moon.latitude, world.moon.longitude).distance_to(moon) < 1e-6,
		"a save from before origins resumes with the start it had")
