extends SailingAidProbe
## The real powered Console's Nav layer before and during physical sheet trim.

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if not args.is_empty() else OS.get_temp_dir().path_join("desert-sailing-aid")
	DirAccess.make_dir_recursive_absolute(out)
	await aid_rig()
	await sail_for(3.0)
	computer.page = Console.Page.MAP
	computer.filters_off = ["weather", "survey"]
	await _shoot(out.path_join("nav-hand.png"))
	computer.sailing.choose(computer, SailingAid.Mode.TRIM)
	await sail_for(8.0)
	await _shoot(out.path_join("nav-trim.png"))
	computer.filters_off = ["survey"]
	await _shoot(out.path_join("weather-nav.png"))


func _shoot(path: String) -> void:
	var screen := computer._screen()
	var at := screen.global_position
	look(at + screen.global_basis.z * 0.9, at)
	computer._screen_at = -INF
	await physics_frames(3)
	await RenderingServer.frame_post_draw
	var image := computer._viewport.get_texture().get_image()
	image.save_png(path)
	print("sailing aid: ", path)
