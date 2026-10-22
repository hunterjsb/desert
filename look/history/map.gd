extends Node
## Look-test: the history map over the game on seed 1234, at a landmark or
## where the run began. No window: shoot it unseen (scripts/unseen.sh), so it
## runs while someone plays:
##   scripts/unseen.sh --path . --resolution 1280x720 res://look/history/map.tscn -- out.png [landmark] [metres]

const MAIN := preload("res://game/main.tscn")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://history_map.png"
	var where := args[1] if args.size() > 1 else ""
	var width := args[2] if args.size() > 2 else "2000"
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	# Its own profile and saves: a landmark reached here is no deed of the player's.
	var away := OS.get_temp_dir().path_join("sandgame-look-history")
	DirAccess.make_dir_recursive_absolute(away)
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		get_node(keeper).dir = away
	# This surface capture retains the automatic-arrival baseline.
	Tuning.current().run_seed = 1234
	var main: Main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	await _settled(main)
	if where != "":
		main.ui.dev_console.run("goto " + where)
		await _settled(main)
	main.ui.dev_console.run("map " + width)
	Dev.hide_overlays()
	for i in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out)
	print("%s: %s, %s" % [out, Dev.read("world/zone"), Dev.read("world/lmk")])
	get_tree().quit()


func _settled(main: Main) -> void:
	for i in 1200:
		await get_tree().process_frame
		var world := main.world()
		if world != null and world.terrain.is_idle() and world.shape.sites.is_idle() and i > 30:
			return
