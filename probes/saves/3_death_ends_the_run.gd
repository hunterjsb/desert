extends SavesProbe
## Profile & saves probe 3: in Ironman, death ends the run. An Ironman run
## saved and played on dies by its own body's tick; the save is gone with it,
## so the menu has nothing to resume and offers New game, and the next run
## starts fresh.


func run() -> void:
	saves = get_node("/root/Saves")
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = false
	# The world and the runs beside it, as the game has them.
	var main := Node.new()
	world = WORLD_SCENE.instantiate()
	world.name = "World"
	main.add_child(world)
	var runs := Runs.new()
	runs.ironman = true
	main.add_child(runs)
	add_child(main)
	await settle(true)
	check(saves.save(world, true), "saved")
	check(saves.has_run(), "there's a run to resume")
	var started := []
	runs.started.connect(func(next: World) -> void: started.append(next))
	var player := world.player
	var died := []
	player.vitals.died.connect(func() -> void: died.append(true))
	player.vitals.wounds.sick = 1.0
	player.vitals.health = 0.01
	for i in 120:
		await get_tree().physics_frame
		if not started.is_empty():
			break
	check(died.size() == 1 and started.size() == 1, "you died and a new run began")
	check(not saves.has_run() and not FileAccess.file_exists(saves.path()), "the save went with the run")
	world = runs.world()
	check(not saves.save(started[0]) or saves.has_run(), "a new run can be saved again")
