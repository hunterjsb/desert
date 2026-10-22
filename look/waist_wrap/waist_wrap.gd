extends LineProbe
## Real tie/untie with the cached suit wrap and the unchanged held coil.
func run() -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	var out := OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	Tuning.current().eye_adapts = false
	await load_lines()
	world.time_warp = 0.0
	world.time = fposmod(0.42 - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) * world.tuning.day_minutes * 60.0
	Dev.hide_overlays()
	var player := world.player
	var stake := driven_stake(player.global_position + Vector3(4, 0, -4))
	var line := Line.to_waist(world, stake.free_tie(player.global_position), 2.0)
	line.rope.haul_gathered = 2.0
	hands.reel.choose(line.ends[1])
	var outside := Camera3D.new()
	outside.fov = 48
	world.add_child(outside)
	outside.look_at_from_position(player.to_global(Vector3(-0.9, 1.25, -1.25)), player.to_global(Vector3(0, 1.05, 0.12)))
	outside.make_current()
	await _save(out, "belt_close")
	outside.look_at_from_position(player.to_global(Vector3(1.6, 1.4, -2.4)), player.to_global(Vector3(0, 1.0, 0.1)))
	await _save(out, "tied")
	player.camera.rotation_degrees.x = -70
	player.camera.make_current()
	await _save(out, "own_waist")
	look(eye(), eye() + Vector3(0, 3, -10))
	player.waist.give_back()
	await simulate(world.tuning.untie_seconds + Hands.ARRIVE + 0.2)
	player.camera.rotation_degrees.x = -25
	await _save(out, "held_coil")

func _save(out: String, label: String) -> void:
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(label + ".png"))
