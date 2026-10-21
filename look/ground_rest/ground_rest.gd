extends Node
## Real eye-height comparison at one camp; run with scripts/unseen.sh.

func _ready() -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Tuning.current().run_seed = 1234
	Tuning.current().eye_adapts = false
	Tuning.current().prevailing_speed = 0.0
	Tuning.current().salvage = false
	Tuning.current().storm_threshold = 2.0
	var world: World = preload("res://game/world/world.tscn").instantiate()
	add_child(world)
	for i in 2400:
		await get_tree().process_frame
		if world.terrain.is_idle(): break
	world.time_warp = 0.0
	world.time = fposmod(0.4 - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) * world.tuning.day_minutes * 60.0
	var player := world.player
	var at := player.global_position
	player.set_process_unhandled_input(false)
	player.camera.rotation_degrees.x = -6.0
	for offset: Vector3 in [Vector3(-1.0, 0.2, -2.0), Vector3(0.0, 0.2, -2.0), Vector3(1.0, 0.2, -2.0)]:
		var chassis := Catalog.device(&"chassis") as Chassis
		world.content.add_child(chassis)
		chassis.global_position = at + offset
		chassis.global_position.y = world.height_under(chassis.global_position) + 0.25
		chassis.freeze = true
	var radio := Catalog.device(&"radio")
	world.content.add_child(radio)
	radio.global_position = at + Vector3(-1.0, 1.0, -2.0)
	for i in 40: await get_tree().physics_frame
	var out := OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	for pose: StringName in [&"stand", &"sit", &"prone"]:
		player.restore_ground_pose(pose)
		for i in 50: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(String(pose) + ".png"))
		print("captured ", pose, " eye=", player.camera.position.y)
	get_tree().quit()
