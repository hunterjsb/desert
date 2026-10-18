extends Node
## Look-test helper: shoots the deeds' tree with a few done, one of them
## early, and a card highlighted, over the main menu's desert and over a run. Needs a GPU, not --headless; shoot.sh
## runs it unseen:
##   scripts/unseen.sh --path . res://look/deeds/deeds.tscn -- <out dir>

const MAIN := preload("res://game/main.tscn")
## Done, one of them early: Six Pack before All Mod Cons, so it's still dark.
const DONE: Array[StringName] = [&"board_distance", &"board_height", &"shield_day", &"crop", &"sail_waist",
	&"port_morgan", &"deck_pieces"]


func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	# Hunter may be playing in another window while this runs: never take his
	# focus or his keys, and stay silent.
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	# Its own profile and saves, never the player's.
	var away := OS.get_temp_dir().path_join("sandgame-look-deeds")
	DirAccess.make_dir_recursive_absolute(away)
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		get_node(keeper).dir = away
	Settings.path = away.path_join("settings.cfg")
	var profile := get_node(^"/root/Profile")
	profile.reset()
	for id in DONE:
		profile.deed(id, {"dev": true})
	profile.improve("shield_storm", 43.0)
	for crop in ["root_tuber", "saltbush"]:
		profile.toward("crops", crop)
	Tuning.current().run_seed = 1234
	var main: Main = MAIN.instantiate()
	add_child(main)
	main.showpiece.set_process_input(false)
	await _idle(main.view)
	await _ticks(120)
	await _opened(main, &"crops")
	_shoot(out.path_join("deeds_menu.png"))
	main.ui.close_top()
	main.new_game()
	while main.world() == null or main.ui._fading:
		await get_tree().process_frame
	await _idle(main.world())
	await _ticks(60)
	main.ui.back()
	await _opened(main, &"shield_storm")
	_shoot(out.path_join("deeds_run.png"))
	get_tree().quit()


## The deeds open, a card highlighted, and their pictures drawn.
func _opened(main: Main, highlighted: StringName) -> void:
	main.ui.open(main.ui.deeds())
	await _ticks(10)
	for card: Button in main.ui.top().find_children("*", "Button", true, false):
		if card.get_meta(&"deed", &"") == highlighted:
			card.grab_focus()
	await _ticks(10)


func _idle(world: World) -> void:
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle():
			return


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _shoot(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
