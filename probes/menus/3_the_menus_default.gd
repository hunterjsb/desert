extends MenuProbe
## Menus & UI probe 3: the menu's default, end to end. The main menu's title
## is the game's name, over the starting crate, which is only to look at: no
## body in it, and the storm doesn't move it. With no save, Resume is
## absent, New game is highlighted, and confirm asks who you come as, then
## which mode, Normal highlighted and Ironman below it; confirm again starts
## a Normal run, whose
## system menu holds Save. Save & quit from that run, somewhere out on the
## sand, and back on the menu Resume is there and highlighted. Confirm shows
## your camp aside as the save holds it, the crate by itself, and the save's
## numbers: time played, when it was saved, its day and who you came as.
## Back goes back. A save from before time played was kept shows the rest;
## confirm carries on, putting you back where you were, on the saved run's
## seed and clock.


func run() -> void:
	# A storm everywhere at the menu, as the shield probes make one, whatever
	# the seed's weather; the run after it has its own.
	var tuning := Tuning.current()
	var kept := [tuning.storm_threshold, tuning.storm_ramp]
	tuning.storm_threshold = -2.0
	tuning.storm_ramp = 0.04
	await open_main()
	tuning.storm_threshold = kept[0]
	tuning.storm_ramp = kept[1]
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
	# The default origin.
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

	press(&"ui_accept")
	var view := main.ui.top()
	var numbers := Snapshot.summary(saves().held())
	var camp: Array = main.showpiece._built.get(Showpiece.CAMP, [Node3D.new()])
	print("Resume lists ", view.aside())
	check(view != menu and view.side and view.shows == Showpiece.CAMP and camp[0].get_child_count() == 1
		and camp[0].find_children("*", "GeometryInstance3D", true, false).size() > 20
		and camp[0].find_children("*", "CollisionObject3D", true, false).is_empty(),
		"Resume shows your camp aside, the crate by itself and only to look at")
	check(view.aside().size() == 4 and numbers.played > 0.0 and view.aside()[2][1] == str(numbers.day)
		and view.aside()[3][1] == Kit.standard().label and view.aside()[1][1] == UIRoot.when(saves().saved_at(),
			saves().saved_at()), "with the save's numbers: played, saved today, its day and who you came as")
	press(&"ui_cancel")
	check(main.ui.top() == menu and menu.highlighted() == 0, "back goes back")
	# As a save from before time played was kept.
	var older: Dictionary = saves().held()
	older.erase("played")
	SaveFile.write(saves().path(), saves().KIND, saves().VERSION, older)
	press(&"ui_accept")
	check(main.ui.top().aside().size() == 3 and main.ui.top().shows == Showpiece.CAMP,
		"a save without time played shows the rest (%s)" % main.ui.top().aside())

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
