extends MovementProbe
## Actual riding frames through the normal camera, capped at 14 FPS/60 physics Hz.
func run() -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	var out := OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	await load_moving()
	Dev.hide_overlays()
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 100.0, 30.0)
	await place(flat.x, flat.z, Vector2(0, -1))
	await ride_here(&"big_battery")
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 14
	hold(["move_forward"])
	await simulate(3.0)
	player.camera.rotation_degrees.x = -58.0
	for i in 24:
		player.camera.rotation_degrees.x = -58.0 if i < 12 else -82.0
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("ride_%02d.png" % i))
	player.camera.rotation_degrees.x = -20.0
	for i in 6:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("ride_ahead.png"))
	hold([])
