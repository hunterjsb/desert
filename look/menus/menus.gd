extends Node
## Look-test helper: shoots the main menu, its title and crate, over its desert
## as it opens and once its storm has passed, and with its music switched
## off; Options, its controls list and the question over a save with the prop
## aside; who you come as with each origin highlighted, its piece and gear,
## one of them locked, and the modes; the main menu after a Homesteader's run;
## the system menu over a run; Resume with that run's camp, and with the save
## LOOK_SAVE names if it's set; then the main menu and Resume at the menu's
## darkest.
## The eye adapts here as in the game; it prints how far it swung over ten
## seconds at the menu, in its storm and in the clear, beside how far the
## frame's own light did, so a pumping desert shows. Needs a window, not --headless:
##   godot --path . res://look/menus/menus.tscn -- <out dir>

const MAIN := preload("res://game/main.tscn")

var _out := ""


func _ready() -> void:
	_out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	# Hunter may be playing in another window while this runs: never take his
	# focus or his keys, and stay silent.
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	# New game deletes a save: never the player's own.
	var away := OS.get_temp_dir().path_join("sandgame-look-menus")
	DirAccess.make_dir_recursive_absolute(away)
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		get_node(keeper).dir = away
	# As a first session: no save, no profile, the settings as they come.
	SaveFile.remove(get_node(^"/root/Saves").path())
	get_node(^"/root/Profile").reset()
	Settings.path = away.path_join("settings.cfg")
	SaveFile.remove(Settings.path)
	Tuning.current().run_seed = 1234
	var main: Main = MAIN.instantiate()
	add_child(main)
	# The real mouse may pass over this window: the crate rests facing you.
	main.showpiece.set_process_input(false)
	await _idle(main.view)
	await _ticks(120)
	await _held(main.view, "in its storm,")
	_shoot("main_storm")
	# Left running, the menu's storm passes.
	var view := main.view
	await _clear(view)
	await _ticks(120)
	await _held(view, "in the clear,")
	_shoot("main")
	# Up from the top word is the music's switch.
	_press(&"ui_up")
	_press(&"ui_accept")
	await _ticks(10)
	_shoot("main_muted")
	_press(&"ui_accept")
	_press(&"ui_down")
	_press(&"ui_down")
	_press(&"ui_accept")
	await _settle(main)
	_shoot("options")
	for i in 4:
		_press(&"ui_down")
	_press(&"ui_accept")
	await _ticks(10)
	_shoot("controls")
	_press(&"ui_cancel")
	_press(&"ui_cancel")
	_press(&"ui_up")
	var origins := Kit.origins()
	_press(&"ui_accept")
	for k in origins.size():
		if k > 0:
			_press(&"ui_down")
		await _settle(main)
		_shoot("origin_%s" % origins[k].id)
	_press(&"ui_accept")
	await _settle(main)
	_shoot("modes")
	_press(&"ui_cancel")
	_press(&"ui_cancel")
	# Locked, as an origin will be until its unlock is found.
	origins[1].unlock = "look_locked"
	_press(&"ui_accept")
	await _settle(main)
	_shoot("origin_locked")
	origins[1].unlock = ""
	_press(&"ui_cancel")
	main.showpiece.home = origins[2]
	await _settle(main)
	_shoot("main_homesteader")

	# A Homesteader's camp set down and lived in a moment, then saved and quit.
	main.new_game(false, false, origins[2])
	while main.world() == null or main.ui._fading or not main.world().has_meta(&"kit"):
		await get_tree().process_frame
	await _idle(main.world())
	await _ticks(120)
	main.ui.back()
	await _ticks(10)
	_shoot("system")
	main.ui.close_all()
	await main.save_and_quit()
	view = main.view
	main.showpiece.set_process_input(false)
	await _idle(view)
	await _clear(view)
	await _ticks(60)
	_press(&"ui_down")
	_press(&"ui_accept")
	await _settle(main)
	_shoot("question")
	_press(&"ui_cancel")
	_press(&"ui_up")
	_press(&"ui_accept")
	await _settle(main)
	_shoot("resume")
	var yours := OS.get_environment("LOOK_SAVE")
	if yours != "" and FileAccess.file_exists(yours):
		_press(&"ui_cancel")
		DirAccess.copy_absolute(yours, get_node(^"/root/Saves").path())
		_press(&"ui_accept")
		await _settle(main)
		_shoot("resume_yours")

	# The menu's darkest moment in the next day, its clock on fast to get there.
	_press(&"ui_cancel")
	var darkest := _darkest(view)
	view.time_warp = 60.0
	while view.time < darkest:
		await get_tree().physics_frame
	view.time_warp = 1.0
	# As the eye stands after a while at the menu.
	view.weather.eye.settle()
	await _ticks(120)
	await _held(view, "at its darkest,")
	_shoot("main_night")
	_press(&"ui_accept")
	await _settle(main)
	_shoot("resume_night")
	get_tree().quit()


## The menu's clock on fast till a clear day.
func _clear(view: World) -> void:
	view.time_warp = 60.0
	while view.weather.in_storm or view.weather.day.sun_direction(view.time, view.moon.latitude, view.moon.longitude).y < 0.3:
		await get_tree().physics_frame
	view.time_warp = 1.0


## The world time over the next day when the least light reaches the menu's
## sand: the sun's, its eclipse's ring and Tu's.
func _darkest(view: World) -> float:
	var day := view.weather.day
	var moon := view.moon
	var best := view.time
	var least := INF
	for k in 480:
		var t := view.time + k * view.tuning.day_minutes * 60.0 / 480.0
		var sun := day.sun_direction(t, moon.latitude, moon.longitude)
		var light := smoothstep(-0.1, 0.2, sun.y) * day.sun_shown(t) + day.ring_light(t) \
			+ day.tu_light(t, moon.latitude, moon.longitude) * view.tuning.tu_shine_scale
		if light < least:
			least = light
			best = t
	return best


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


## Long enough for the prop to slide and swap.
func _settle(main: Main) -> void:
	await get_tree().create_timer(Showpiece.SLIDE_SECONDS + Showpiece.SWAP_SECONDS + 0.2).timeout
	print("menus: the prop shows %s, at %d%% of its size" % [main.showpiece.shown, roundi(main.showpiece._fit * 100.0)])


func _idle(world: World) -> void:
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle():
			return


## Physics ticks, not frames: the weather and its wall update on the tick.
func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _shoot(shot: String) -> void:
	var path := _out.path_join("menu_%s.png" % shot)
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
