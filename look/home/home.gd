extends DeckProbe
## Actual marked camp and navigation, captured without service stand-ins.
func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -3))
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.25, 0.1), 0.0, beacon)
	var battery := fit_part(deck, &"battery") as Battery
	battery.fill(battery.capacity())
	check(world.home.mark(beacon) == "", "mark admitted")
	var until := Time.get_ticks_msec() + 60000
	while not world.home.supported and Time.get_ticks_msec() < until:
		await get_tree().process_frame
	await simulate(0.5)
	check(world.home.supported and beacon.powered, "actual camp is supported and broadcasting")
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	Dev.hide_overlays()
	look(deck.global_position + Vector3(1.8, 1.3, 2.0), beacon.global_position)
	await shot(out, "beacon")
	var at := Vector2(world.player_world_x(), world.player_world_z())
	teleport(at.x + 1000, at.y)
	await settle()
	world.player.suit.show_view(true)
	world.player.suit._home_view.show_home()
	await shot(out, "return")
	print("HOME METRICS chunks=%d collision=%d members=%d items=%d terrain_max_ms=%.2f" % [world.terrain._chunks.size(), world.terrain.collision_count(), world.home.members.size(), world.home.item_count, world.terrain.slowest_frame_ms])

func shot(out: String, name: String) -> void:
	await physics_frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
