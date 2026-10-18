extends Node
## Look-test helper: shoots the main menu, its title and crate, over its desert
## as it opens and once its storm has passed; who you come as with each origin
## highlighted, one of them locked, and the modes; the main menu after a
## Homesteader's run; then the system menu over a run.
## The eye adapts here as in the game; it prints how far it swung over ten
## seconds at the menu, in its storm and in the clear, beside how far the
## frame's own light did, so a pumping desert shows. Needs a window, not --headless:
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
	await _held(main.view, "in its storm,")
	_shoot(out.path_join("menu_main_storm.png"))
	# Left running, the menu's storm passes: its clock on fast till a clear day.
	var view := main.view
	view.time_warp = 60.0
	while view.weather.in_storm or view.weather.day.sun_direction(view.time, view.moon.latitude, view.moon.longitude).y < 0.3:
		await get_tree().physics_frame
	view.time_warp = 1.0
	await _ticks(120)
	await _held(view, "in the clear,")
	_shoot(out.path_join("menu_main.png"))
	var origins := Kit.origins()
	_press(&"ui_accept")
	for k in origins.size():
		if k > 0:
			_press(&"ui_down")
		await _settle(main)
		_shoot(out.path_join("menu_origin_%s.png" % origins[k].id))
	_press(&"ui_accept")
	await _settle(main)
	_shoot(out.path_join("menu_modes.png"))
	_press(&"ui_cancel")
	_press(&"ui_cancel")
	# Locked, as an origin will be until its unlock is found.
	origins[1].unlock = "look_locked"
	_press(&"ui_accept")
	await _settle(main)
	_shoot(out.path_join("menu_origin_locked.png"))
	origins[1].unlock = ""
	_press(&"ui_cancel")
	main.showpiece.home = origins[2]
	await _settle(main)
	_shoot(out.path_join("menu_main_homesteader.png"))
	main.new_game()
	while main.world() == null or main.ui._fading:
		await get_tree().process_frame
	await _idle(main.world())
	await _ticks(60)
	main.ui.back()
	await _ticks(10)
	_shoot(out.path_join("menu_system.png"))
	get_tree().quit()


## The eye over ten seconds at the menu against the frame's own light: a
## pumping eye would swing as far as the light, or further.
func _held(world: World, what: String) -> void:
	var eye := world.weather.eye
	var light := Vector2(INF, -INF)
	var opened := Vector2(INF, -INF)
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 10000:
		await get_tree().process_frame
		light = Vector2(minf(light.x, eye.reading.x), maxf(light.y, eye.reading.x))
		opened = Vector2(minf(opened.x, eye.stops), maxf(opened.y, eye.stops))
	print("menus: %s over 10 s the frame's light swung %.2f stops, the eye %.2f (+%.2f to +%.2f)"
		% [what, light.y - light.x, opened.y - opened.x, opened.x, opened.y])


## The first key bound to an action, pressed and let go.
func _press(action: StringName) -> void:
	var event: InputEvent = InputMap.action_get_events(action)[0].duplicate()
	event.pressed = true
	get_viewport().push_input(event)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event)


## Long enough for the kit on show to slide and swap.
func _settle(main: Main) -> void:
	await get_tree().create_timer(Showpiece.SLIDE_SECONDS + Showpiece.SWAP_SECONDS + 0.2).timeout
	print("menus: the %s's kit on show, at %d%% of its size" % [main.showpiece.kit.label, roundi(main.showpiece._fit * 100.0)])


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
