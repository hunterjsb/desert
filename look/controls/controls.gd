extends "res://probes/menus/50_controls_live_in_the_system_menu.gd"
## The actual system menu and bounded controls reader at 720p.

func run() -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	await super.run()
	var out := OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	Dev.hide_overlays()
	press(&"ui_cancel")
	await _capture(out.path_join("system.png"))
	_select("CONTROLS")
	await _capture(out.path_join("controls-top.png"))
	var reader := _reader()
	for i in 30:
		_wheel(reader)
	await _capture(out.path_join("controls-bottom.png"))

func _capture(path: String) -> void:
	await _layout()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
