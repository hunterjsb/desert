extends MenuProbe
## Menus & UI probe 3: the menu's default, end to end. The main menu's title
## is the game's name, over the starting crate, which is only to look at: no
## body in it, and the storm doesn't move it. With no save, Resume is
## absent, New game is highlighted, and confirm asks which mode, Normal
## highlighted and Ironman below it; confirm again starts a Normal run, whose
## system menu holds Save. Save & quit from that run, somewhere out on the
## sand, and back on the menu Resume is there and highlighted; confirm
## resumes it, putting you back where you were, on the saved run's seed and
## clock.


func run() -> void:
	await open_main()
	var menu := main.ui.top()
	check(menu.title != null and menu.title.text == UIRoot.TITLE and menu.title.is_visible_in_tree(),
		"the main menu's title is the game's name")
	var piece := main.showpiece
	var eye := main.view.player.camera
	var was := eye.global_transform.affine_inverse() * piece.global_transform
	await physics_frames(60)
	check(main.view.weather.in_storm and piece.find_children("*", "CollisionObject3D", true, false).is_empty()
		and piece.find_children("*", "GeometryInstance3D", true, false).size() > 20
		and main.view.devices().is_empty() and eye.is_position_in_frustum(piece.global_position)
		and (eye.global_transform.affine_inverse() * piece.global_transform).is_equal_approx(was),
		"the starting crate floats in view, only to look at, and the storm doesn't move it")
	check(menu.words() == PackedStringArray(["NEW GAME", "OPTIONS", "QUIT"]) and menu.highlighted() == 0,
		"with no save, Resume is absent and New game is highlighted (%s)" % ", ".join(menu.words()))
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(Sounds.WORLD)) and not AudioServer.is_bus_mute(0),
		"the menu's storm makes no sound, and its words can")
	press(&"ui_accept")
	var modes := main.ui.top()
	check(modes != menu and modes.words() == PackedStringArray(["NORMAL", "IRONMAN"]) and modes.highlighted() == 0
		and not main.in_run(), "New game asks which mode, Normal highlighted (%s)" % ", ".join(modes.words()))
	press(&"ui_accept")
	await faded_in()
	check(main.in_run() and main.view == null and not main.ui.is_open() and not Controls.mouse_free,
		"confirm starts a run, the menu's world gone and the mouse captured")
	check(not main.ironman(), "a Normal run")
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(Sounds.WORLD)), "and the run is heard")

	# The ground takes as long to build as the machine takes: out from the
	# spawn at time zero, so where you end up never depends on it.
	world.respawn(world.spawn.x, world.spawn.y, 0.0, 0.0)
	teleport(world.spawn.x + 6.0, world.spawn.y - 9.0)
	await physics_frames(30)
	press(&"ui_cancel")
	check(main.ui.top().words() == PackedStringArray(["OPTIONS", "SAVE", "SAVE & QUIT"]),
		"the system menu holds Options, Save and Save & quit (%s)" % ", ".join(main.ui.top().words()))
	press(&"ui_down")
	press(&"ui_down")
	var stood := Vector2(world.player_world_x(), world.player_world_z())
	var clock := world.time
	var played_on := world.run_seed
	press(&"ui_accept")
	await faded_in()
	menu = main.ui.top()
	check(saves().has_run() and not main.in_run() and menu != null and menu.root,
		"Save & quit saves the run and goes back to the main menu")
	check(menu.words() == PackedStringArray(["RESUME", "NEW GAME", "OPTIONS", "QUIT"]) and menu.highlighted() == 0,
		"with a save, Resume is there and highlighted (%s)" % ", ".join(menu.words()))

	var back := {}
	saves().restored.connect(func(at: World) -> void:
		back.merge({"at": Vector2(at.player_world_x(), at.player_world_z()), "time": at.time, "seed": at.run_seed}),
		CONNECT_ONE_SHOT)
	press(&"ui_accept")
	await faded_in()
	print("saved at %.2f, %.2f, %.2f s; back at %.2f, %.2f, %.2f s" % [stood.x, stood.y, clock,
		back.get("at", Vector2.INF).x, back.get("at", Vector2.INF).y, back.get("time", INF)])
	check(main.in_run() and back.get("seed") == played_on, "confirm resumes it, on the saved run's seed")
	check(back.get("at", Vector2.INF).distance_to(stood) < 0.1 and absf(back.get("time", INF) - clock) < 0.1,
		"you're back where you were, when you were")
