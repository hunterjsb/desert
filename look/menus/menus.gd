extends Node
## Look-test helper: shoots the main menu, its title and crate, over its desert
## as it opens and once its storm has passed, then the system menu over a run.
## Needs a window, not --headless:
##   godot --path . res://look/menus/menus.tscn -- <out dir>

const MAIN := preload("res://game/main.tscn")


func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	# Hunter may be playing in another window while this runs: never take his
	# focus or his keys, and stay silent.
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	# New game deletes a save: never the player's own.
	var away := OS.get_temp_dir().path_join("sandgame-look-menus")
	DirAccess.make_dir_recursive_absolute(away)
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		get_node(keeper).dir = away
	Settings.path = away.path_join("settings.cfg")
	Tuning.current().run_seed = 1234
	var main: Main = MAIN.instantiate()
	add_child(main)
	# The real mouse may pass over this window: the crate rests facing you.
	main.showpiece.set_process_input(false)
	await _idle(main.view)
	await _ticks(120)
	_shoot(out.path_join("menu_main_storm.png"))
	# Left running, the menu's storm passes: its clock on fast till a clear day.
	var view := main.view
	view.time_warp = 60.0
	while view.weather.in_storm or view.weather.day.sun_direction(view.time, view.moon.latitude).y < 0.3:
		await get_tree().physics_frame
	view.time_warp = 1.0
	await _ticks(120)
	_shoot(out.path_join("menu_main.png"))
	main.new_game()
	while main.world() == null or main.ui._fading:
		await get_tree().process_frame
	await _idle(main.world())
	await _ticks(60)
	main.ui.back()
	await _ticks(10)
	_shoot(out.path_join("menu_system.png"))
	get_tree().quit()


func _idle(world: World) -> void:
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle():
			return


## Physics ticks, not frames: the weather and its wall update on the tick.
func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _shoot(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
