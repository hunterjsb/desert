extends MenuProbe
## Menus & UI probe 7: death in a Normal run. Saved from the system menu out
## on the sand, the run plays on elsewhere and you die: a screen offers Load
## last save, highlighted, and New run, and back doesn't wave it away. Load
## puts you back where and when you saved, on the same seed, still Normal.
## Dead again, New run starts a fresh run on a new seed, its save gone.


func run() -> void:
	await open_main(false)
	# Out from the spawn at time zero, so where you stand never depends on how
	# long the ground took to build.
	await started()
	world.respawn(world.spawn.x, world.spawn.y, 0.0, 0.0)
	teleport(world.spawn.x + 6.0, world.spawn.y - 9.0)
	await physics_frames(30)
	press(&"ui_cancel")
	var system := main.ui.top()
	var stood := Vector2(world.player_world_x(), world.player_world_z())
	var clock := world.time
	var played_on := world.run_seed
	for i in 3:
		press(&"ui_down")
	press(&"ui_accept")
	check(saves().has_run() and saves().run_seed() == played_on and main.in_run() and main.ui.top() == system
		and system.words()[3] == "SAVED", "Save saves the run, keeps you in it and says so (%s)" % ", ".join(system.words()))
	press(&"ui_cancel")

	teleport(world.spawn.x - 8.0, world.spawn.y + 5.0)
	await physics_frames(30)
	await _die()
	var death := main.ui.top()
	check(death != null and death.words() == PackedStringArray(["LOAD LAST SAVE", "NEW RUN"])
		and death.highlighted() == 0, "dying shows Load last save, highlighted, and New run (%s)"
			% (", ".join(death.words()) if death != null else "nothing"))
	press(&"ui_cancel")
	check(main.ui.top() == death and saves().has_run(), "back doesn't wave it away, and the save is still there")

	var back := {}
	saves().restored.connect(func(at: World) -> void:
		back.merge({"at": Vector2(at.player_world_x(), at.player_world_z()), "time": at.time, "seed": at.run_seed}),
		CONNECT_ONE_SHOT)
	press(&"ui_accept")
	await faded_in()
	print("saved at %.2f, %.2f, %.2f s; loaded at %.2f, %.2f, %.2f s" % [stood.x, stood.y, clock,
		back.get("at", Vector2.INF).x, back.get("at", Vector2.INF).y, back.get("time", INF)])
	check(main.in_run() and back.get("seed") == played_on and not world.player.vitals.dead and not main.ironman(),
		"Load puts the saved run back, alive and Normal still")
	check(back.get("at", Vector2.INF).distance_to(stood) < 0.1 and absf(back.get("time", INF) - clock) < 0.1,
		"you're back where you saved, when you saved")

	await _die()
	press(&"ui_down")
	press(&"ui_accept")
	await faded_in()
	check(main.in_run() and world.run_seed != played_on and not world.has_meta(&"resumed") and not saves().has_run()
		and not world.player.vitals.dead and not main.ironman(),
		"New run starts a fresh Normal run on a new seed, the save gone (%d after %d)" % [world.run_seed, played_on])


## Out of water, on the body's next tick, and the death screen up.
func _die() -> void:
	var player := world.player
	for part in player.suit.carried:
		if part is Supply and part.kind == &"water":
			part.drain(INF)
	player.vitals.thirst = 0.0
	player.vitals.health = 0.01
	for i in 120:
		await get_tree().physics_frame
		if main.ui.is_open():
			return
	check(false, "you died within 120 ticks")
