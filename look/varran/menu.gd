extends Node
## Look-test: the origin menu with four starts. On a first run, the Surveyor
## alone open and the rest ????; then with every start open, the Varran
## settler highlighted and his rig on show. Needs a GPU; unseen:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/varran/menu.tscn -- <out dir>

const MAIN := preload("res://game/main.tscn")

var _out := ""


func _ready() -> void:
	_out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	# New game deletes a save: never the player's own.
	var away := OS.get_temp_dir().path_join("sandgame-look-varran")
	DirAccess.make_dir_recursive_absolute(away)
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		get_node(keeper).dir = away
	SaveFile.remove(get_node(^"/root/Saves").path())
	get_node(^"/root/Profile").reset()
	Settings.path = away.path_join("settings.cfg")
	SaveFile.remove(Settings.path)
	Tuning.current().run_seed = 1234
	var main: Main = MAIN.instantiate()
	add_child(main)
	main.showpiece.set_process_input(false)
	for i in 1800:
		await get_tree().process_frame
		if main.view.terrain.is_idle():
			break
	await _ticks(120)
	_press(&"ui_accept")
	await _settle()
	_shoot("first")
	_press(&"ui_cancel")
	for kit in Kit.origins():
		if kit.unlock != "":
			get_node(^"/root/Profile").unlock(kit.unlock)
	_press(&"ui_accept")
	for k in 3:
		_press(&"ui_down")
	await _settle()
	_shoot("varran")
	print("menu: the prop shows %s" % main.showpiece.shown)
	get_tree().quit()


func _press(action: StringName) -> void:
	var event: InputEvent = InputMap.action_get_events(action)[0].duplicate()
	event.pressed = true
	get_viewport().push_input(event)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event)


func _settle() -> void:
	await get_tree().create_timer(Showpiece.SLIDE_SECONDS + Showpiece.SWAP_SECONDS + 0.4).timeout


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _shoot(shot: String) -> void:
	var path := _out.path_join("menu_%s.png" % shot)
	get_viewport().get_texture().get_image().save_png(path)
	print("menu: shot ", path)
