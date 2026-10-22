extends Node
## Look-test helper: shoots the main menu marking the deeds new, and the
## starts they opened; the whole of the deeds' tree, scrolled to its top and
## to its foot, with a few done, one of them early, a hidden one done and one
## not, and a card highlighted, over the main menu's desert and over a run;
## two deeds' badges done at once in a run, the first showing and its sound
## playing; then Resume, counting them. Needs a GPU, not --headless;
## shoot.sh runs it unseen:
##   scripts/unseen.sh --path . res://look/deeds/deeds.tscn -- <out dir>

const MAIN := preload("res://game/main.tscn")
## Long enough for the prop to slide aside and swap, s.
const SETTLE := Showpiece.SLIDE_SECONDS + Showpiece.SWAP_SECONDS + 0.4
## Done, one of them early: Six Pack before All Mod Cons, so it's still dark;
## Eye of the Anomaly done and shown, Tells after it hidden still.
const DONE: Array[StringName] = [&"board_distance", &"board_height", &"shield_day", &"shield_storm", &"anomaly_eye",
	&"crop", &"sail_waist", &"close_hauled", &"port_morgan", &"deck_pieces", &"ages", &"first_cut", &"god_heard",
	&"totality", &"under_tu", &"ten_days", &"slept_it_off"]


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
	# This surface capture retains the automatic-arrival baseline.
	Tuning.current().run_seed = 1234
	var main: Main = MAIN.instantiate()
	add_child(main)
	main.showpiece.set_process_input(false)
	await _idle(main.view)
	await _ticks(120)
	await get_tree().create_timer(SETTLE).timeout
	_shoot(out.path_join("deeds_marked.png"))
	main.ui.open(main.ui.origins())
	await get_tree().create_timer(SETTLE).timeout
	_shoot(out.path_join("deeds_new_starts.png"))
	main.ui.close_top()
	await _opened(main, &"crops", 0.0)
	_shoot(out.path_join("deeds_menu_top.png"))
	await _opened(main, &"nomad", 1.0, false)
	_shoot(out.path_join("deeds_menu_foot.png"))
	main.ui.close_top()
	main.new_game()
	while main.world() == null or main.ui._fading:
		await get_tree().process_frame
	await SurfaceStart.begin(main)
	await _idle(main.world())
	await _ticks(60)
	# Two at once: the second waits its turn.
	main.ui.badge(&"crops")
	main.ui.badge(&"shield_storm")
	await get_tree().create_timer(DeedBadge.IN_SECONDS + 0.3).timeout
	_shoot(out.path_join("deeds_badge.png"))
	await get_tree().create_timer(DeedBadge.HOLD_SECONDS + DeedBadge.OUT_SECONDS + DeedBadge.BETWEEN_SECONDS
		+ DeedBadge.IN_SECONDS).timeout
	_shoot(out.path_join("deeds_badge_next.png"))
	await get_tree().create_timer(DeedBadge.HOLD_SECONDS + DeedBadge.OUT_SECONDS).timeout
	main.ui.back()
	await _opened(main, &"tells", 0.0)
	_shoot(out.path_join("deeds_run_top.png"))
	await _opened(main, &"thunder", 1.0, false)
	_shoot(out.path_join("deeds_run_foot.png"))
	main.ui.close_all()
	await main.save_and_quit()
	main.ui.open(main.ui.resume_view())
	await get_tree().create_timer(SETTLE).timeout
	_shoot(out.path_join("deeds_resume.png"))
	get_tree().quit()


## The deeds open, the prop aside, a card highlighted, the tree scrolled to
## `down` of the way to its foot, and their pictures drawn.
func _opened(main: Main, highlighted: StringName, down: float, fresh := true) -> void:
	if fresh:
		main.ui.open(main.ui.deeds())
		await get_tree().create_timer(SETTLE).timeout
	for card: Button in main.ui.top().find_children("*", "Button", true, false):
		if card.get_meta(&"deed", &"") == highlighted:
			card.grab_focus()
	await _ticks(2)
	var tree: DeedsGrid = main.ui.top().find_children("*", "DeedsGrid", true, false)[0]
	tree.scroll = down * (tree._page.size.y - tree.size.y)
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
