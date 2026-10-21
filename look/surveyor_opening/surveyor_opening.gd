extends MenuProbe
## The real new-game controller, real terrain, surviving equipment and recovery action.
func run() -> void:
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = false
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	Dev.hide_overlays()
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	var captured := {}
	var until := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < until:
		await get_tree().physics_frame
		var state := world.arrival_state
		var phase: StringName = state.get("phase", &"")
		if phase == &"" or captured.has(phase):
			continue
		if phase != &"recovery" and float(state.get("progress", 0.0)) < 0.5:
			continue
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(String(phase) + ".png"))
		captured[phase] = true
		if phase == &"recovery":
			break
	check(captured.size() == SurveyorArrival.PHASES.size(), "every actual arrival phase captured")
	check(world.arrival_state.get("materialized", false) and world.player.suit.carried.is_empty(), "physical gear replaces the inventory grant")
	print("Actual Surveyor opening: roles=%d rescued=%d phase=%s" % [world.arrival_nodes.size(), world.rescued, world.arrival_state.get("phase", &"")])
