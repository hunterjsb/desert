extends MenuProbe
## Profile & saves probe 10: quick save and quick load. In a Normal run quick
## save saves at once, says so, and you play on; moved elsewhere, quick load
## puts you back where and when you saved, through the fade. In Ironman
## neither saves or loads, though each says so, and a dev scenario's run
## never saves.


func run() -> void:
	await open_main(false)
	# Out from the spawn at time zero, so where you stand never depends on how
	# long the ground took to build.
	await started()
	world.respawn(world.spawn.x, world.spawn.y, 0.0, 0.0)
	teleport(world.spawn.x + 6.0, world.spawn.y - 9.0)
	await physics_frames(30)
	var stood := Vector2(world.player_world_x(), world.player_world_z())
	var clock := world.time
	var played_on := world.run_seed
	press(&"quick_save")
	check(saves().has_run() and saves().run_seed() == played_on and main.in_run() and not main.ui.holds_input()
		and main.ui._note.modulate.a > 0.0, "quick save saves at once and says so, and you play on")

	teleport(world.spawn.x - 8.0, world.spawn.y + 5.0)
	await physics_frames(30)
	var back := {}
	saves().restored.connect(func(at: World) -> void:
		back.merge({"at": Vector2(at.player_world_x(), at.player_world_z()), "time": at.time, "seed": at.run_seed}),
		CONNECT_ONE_SHOT)
	press(&"quick_load")
	check(main.ui.is_fading(), "quick load goes through the fade")
	await faded_in()
	print("saved at %.2f, %.2f, %.2f s; loaded at %.2f, %.2f, %.2f s" % [stood.x, stood.y, clock,
		back.get("at", Vector2.INF).x, back.get("at", Vector2.INF).y, back.get("time", INF)])
	check(main.in_run() and back.get("seed") == played_on and back.get("at", Vector2.INF).distance_to(stood) < 0.1
		and absf(back.get("time", INF) - clock) < 0.1 and not main.ironman(),
		"quick load puts you back where and when you saved, Normal still")

	main.new_game(true)
	await faded_in()
	check(main.ironman() and main.save_run(), "an Ironman run, saved")
	var saved := _saved_at()
	var playing := main.run
	await physics_frames(30)
	main.ui.note("")
	press(&"quick_save")
	check(_saved_at() == saved and main.ui._note.text != "", "Ironman: quick save saves nothing, and says so")
	press(&"quick_load")
	await physics_frames(5)
	check(main.run == playing and not main.ui.is_fading(), "Ironman: quick load loads nothing")

	main.new_game(false)
	await faded_in()
	main.start_scenario(Scenarios.by_key("spawn"))
	press(&"quick_save")
	check(not saves().has_run(), "a dev scenario's run: quick save saves nothing")


## The run's clock in the save on disk; -1 with none.
func _saved_at() -> float:
	if not saves().has_run():
		return -1.0
	return SaveFile.read(saves().path(), saves().KIND, saves().VERSION).data.time
