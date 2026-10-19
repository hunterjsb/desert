extends MenuProbe
## Menus & UI probe 17: the console keeps its size. At first it shows every
## scenario at once, each on a line of its own. Its corner pulled out as far
## as can be, it stays within the screen; pulled in again, it's smaller about
## its middle. Let go, the settings keep that size, and the next session's
## console opens at it.


func run() -> void:
	get_window().size = Vector2i(1920, 1080)
	# The settings' folder, as the player's always is.
	DirAccess.make_dir_recursive_absolute(user_dir)
	await open_main()
	var console := main.ui.dev_console
	press(&"console")
	await get_tree().process_frame
	console.run("scenarios")
	await get_tree().process_frame
	var bar: PageBar = console._bar
	check(console.visible and console._out.get_line_count() == Scenarios.LIST.size() and bar.whole <= bar.shown,
		"at first it shows every scenario at once, each on a line of its own (%d lines, %d show)"
		% [console._out.get_line_count(), bar.shown])
	var panel: PanelContainer = console._panel
	var screen := get_viewport().get_visible_rect()
	var corner := panel.get_global_rect().end - Vector2(2.0, 2.0)
	drag(corner, corner + Vector2(3000.0, 3000.0))
	await get_tree().process_frame
	var out := panel.get_global_rect()
	check(screen.encloses(out) and out.size.x > screen.size.x * 0.9, "pulled out as far as can be, it stays within the screen (%s)" % out)
	corner = out.end - Vector2(2.0, 2.0)
	drag(corner, corner - Vector2(150.0, 200.0))
	await get_tree().process_frame
	var kept := out.size - Vector2(300.0, 200.0)
	check(panel.size == kept and is_equal_approx(panel.get_global_rect().get_center().x, screen.get_center().x),
		"pulled in, it's smaller about its middle (%s, %s wanted)" % [panel.size, kept])
	check(Settings.console_size == kept, "let go, the settings keep its size")
	main.queue_free()
	await get_tree().process_frame
	# As a new session starts, before its settings are read.
	Settings.console_size = Vector2.ZERO
	await open_main()
	press(&"console")
	await get_tree().process_frame
	check(main.ui.dev_console._panel.size == kept, "and the next session's opens at it (%s)" % main.ui.dev_console._panel.size)
