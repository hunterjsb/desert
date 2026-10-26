extends MenuProbe
## Menus probe 52: the graphics quality holds. Stepped down in Options, the
## window and the world in view draw at it at once; the next session restores
## it before its world is built.


func run() -> void:
	DirAccess.make_dir_recursive_absolute(user_dir)
	await open_main()
	main.ui._change(-1, &"quality", false)
	check(Settings.quality != Settings.QUALITIES[1] and _drawn_at(Settings.quality),
		"stepped down, the window and the world in view draw at it at once (%s)" % Settings.quality)
	var chosen := Settings.quality
	main.queue_free()
	await get_tree().process_frame
	# As a new session starts, before its settings are read.
	Settings.quality = Settings.QUALITIES[1]
	await open_main()
	check(Settings.quality == chosen and _drawn_at(chosen), "the next session restores it before its world is built")


func _drawn_at(quality: StringName) -> bool:
	var drawn: Dictionary = Settings.DRAWN[quality]
	var environment: Environment = (main.view.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	return get_window().msaa_3d == drawn.msaa and get_window().screen_space_aa == drawn.aa \
		and environment.glow_enabled == drawn.glow and environment.ssao_enabled == drawn.ao
