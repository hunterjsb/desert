extends Node
## Look-test helper: the creative menu over a run, a while into it, opened by
## its action, a battery picked into your hands and the Console highlighted;
## then, with --scenarios, the scenarios remade or new as they land: the still
## camp to sleep at, every make of board, and the vent, as you arrive and as
## it bursts; with --devui, the menu narrowed by a search, and the dev console
## pulled bigger saying help and the scenarios. Needs a GPU, not --headless;
## it runs unseen:
##   scripts/unseen.sh --path . res://look/creative/creative.tscn -- <out.png> [--scenarios] [--devui]
## The other shots are <out>_<key>.png, <out>_search.png and <out>_console.png.

const MAIN := preload("res://game/main.tscn")
## Played this long before it opens, s: the pictures were drawn as the game started.
const PLAYED := 20.0
## The vent's burst is shot this long after you arrive, s of world time.
const BURST := Scenarios.VENT_LEAD + 40.0

var _main: Main


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if not args.is_empty() else "user://creative.png"
	# Hunter may be playing in another window while this runs: never take his
	# focus or his keys, and stay silent.
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	# Its own profile and saves, never the player's.
	var away := OS.get_temp_dir().path_join("sandgame-look-creative")
	DirAccess.make_dir_recursive_absolute(away)
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		get_node(keeper).dir = away
	Settings.path = away.path_join("settings.cfg")
	SaveFile.remove(Settings.path)
	# This surface capture retains the automatic-arrival baseline.
	Tuning.current().run_seed = 1234
	_main = MAIN.instantiate()
	add_child(_main)
	_main.new_game()
	while _main.world() == null or _main.ui._fading:
		await get_tree().process_frame
	await SurfaceStart.begin(_main)
	await _idle()
	await get_tree().create_timer(PLAYED).timeout
	_press(&"creative")
	await get_tree().create_timer(0.5).timeout
	var grid: CreativeGrid = _main.ui.top().find_children("*", "CreativeGrid", true, false)[0]
	grid._cards[&"battery"].grab_focus()
	_press(&"ui_accept")
	grid._cards[&"console"].grab_focus()
	await get_tree().create_timer(0.5).timeout
	Dev.hide_overlays()
	await _shoot(out)
	if args.has("--devui"):
		grid._search.grab_focus()
		_type("board")
		await get_tree().create_timer(0.5).timeout
		print("search shows ", grid.shown())
		await _shoot(out.get_basename() + "_search.png")
		_main.ui.close_all()
		_press(&"console")
		await get_tree().process_frame
		var console := _main.ui.dev_console
		var corner := console._panel.get_global_rect().end - Vector2(2.0, 2.0)
		_drag(corner, corner + Vector2(150.0, 250.0))
		for line in ["help", "scenario"]:
			_type(line + "\n")
		await get_tree().create_timer(0.5).timeout
		await _shoot(out.get_basename() + "_console.png")
		_main.ui.close_all()
	if args.has("--scenarios"):
		_main.ui.close_all()
		for key in ["sleep", "board", "vent"]:
			await _scenario(key)
			await _shoot(out.get_basename() + "_%s.png" % key)
		var world := _main.world()
		world.time_warp = 10.0
		while world.time < world.get_meta(&"arrived") + BURST:
			await get_tree().process_frame
		world.time_warp = 1.0
		await _shoot(out.get_basename() + "_vent_burst.png")
	get_tree().quit()


## A scenario started as the console starts it, its things down and settled.
func _scenario(key: String) -> void:
	var world := _main.world()
	var was: Variant = world.get_meta(&"scenario_kit") if world.has_meta(&"scenario_kit") else null
	_main.start_scenario(Scenarios.by_key(key))
	while not world.has_meta(&"scenario_kit") or world.get_meta(&"scenario_kit") == was:
		if str(Dev.read("world/scn")).ends_with("none found"):
			print("no %s in this run's weather" % key)
			break
		await get_tree().physics_frame
	world.set_meta(&"arrived", world.time)
	await _idle()
	await get_tree().create_timer(2.0).timeout


func _shoot(path: String) -> void:
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	var world := _main.world()
	print("shot %s at %.3f of the day" % [path, world.weather.day.time_of_day(world.time, world.moon.longitude)])


func _press(action: StringName) -> void:
	var event: InputEvent = InputMap.action_get_events(action)[0].duplicate()
	event.pressed = true
	get_viewport().push_input(event)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event)


## Each character typed, a line's end as confirm.
func _type(text: String) -> void:
	for c in text:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER if c == "\n" else KEY_SPACE if c == " " else OS.find_keycode_from_string(c.to_upper())
		key.physical_keycode = key.keycode
		key.unicode = 0 if c == "\n" else c.unicode_at(0)
		key.pressed = true
		get_viewport().push_input(key)
		key = key.duplicate()
		key.pressed = false
		get_viewport().push_input(key)


## The pointer pressed, moved and let go.
func _drag(from: Vector2, to: Vector2) -> void:
	for at: Vector2 in [from, to]:
		var move := InputEventMouseMotion.new()
		move.button_mask = MOUSE_BUTTON_MASK_LEFT if at == to else 0
		move.position = at
		move.global_position = at
		get_viewport().push_input(move)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = at == from
		press.position = at
		press.global_position = at
		get_viewport().push_input(press)


func _idle() -> void:
	for i in 1800:
		await get_tree().process_frame
		if _main.world().terrain.is_idle():
			return
