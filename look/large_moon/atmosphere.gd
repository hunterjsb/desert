extends Node
## Controlled real-GPU sky, storm-roof and nearby shelter acceptance.
var world: World
var out: String

func _ready() -> void:
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.eye_adapts = false
	tuning.salvage = false
	tuning.storm_threshold = -2.0 if OS.get_cmdline_user_args().has("--storm") else 2.0
	world = preload("res://game/world/world.tscn").instantiate()
	add_child(world)
	world.player.set_physics_process(false)
	world.player.set_process_unhandled_input(false)
	world.time_warp = 0.0
	world.time = 480.0
	RenderingServer.frame_pre_draw.connect(_diagnostic_frame)
	for i in 180:
		await get_tree().physics_frame
	var origin := world.player.global_position
	world.player.camera.look_at(origin + Vector3(0.0, 1.4, -1000.0))
	await shoot("low")
	world.player.global_position.y = 2000.0
	world.player.camera.look_at(world.player.camera.global_position + Vector3(0.0, -0.03, -1.0))
	await shoot("high_horizon")
	world.player.camera.look_at(Vector3(origin.x, 0.0, origin.z - 2500.0))
	await shoot("high_down")
	world.player.global_position = origin
	var plate := Catalog.device(&"chassis") as Chassis
	world.content.add_child(plate)
	plate.global_position = origin + Vector3(0.0, 0.0, -3.0)
	plate.global_position.y = world.height_under(plate.global_position) + Chassis.THICK * 0.5
	plate.freeze = true
	var shield := Catalog.device(&"shield") as ShieldGenerator
	Stick.put(plate, plate, Chassis.TOP, Vector2.ZERO, 0.0, shield)
	Stick.put(plate, plate, Chassis.TOP, Vector2(0.32, 0.32), 0.0, Catalog.part(&"battery"))
	shield.stand(true)
	world.player.camera.look_at(plate.global_position + Vector3.UP)
	for i in 120:
		await get_tree().physics_frame
	await shoot("shield_inside")
	world.player.global_position.x += 20.0
	world.player.camera.look_at(plate.global_position + Vector3.UP)
	await shoot("shield_outside")
	RenderingServer.frame_pre_draw.disconnect(_diagnostic_frame)
	world.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func shoot(label: String) -> void:
	for i in 12:
		await get_tree().process_frame
	var gpu := 0.0
	for i in 40:
		await RenderingServer.frame_post_draw
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
		await get_tree().process_frame
	print("GPU ", label, ": ", gpu / 40.0, "ms")
	get_viewport().get_texture().get_image().save_png(out.path_join(label + ".png"))
	print("large-moon atmosphere: ", label, "; eye=", world.player.camera.global_position,
		" dip=", world.weather.sky.material.get_shader_parameter(&"horizon_dip"),
		" frame=", world.weather.face.material.get_shader_parameter(&"surface_frame"))

func _diagnostic_frame() -> void:
	if OS.get_cmdline_user_args().has("--flat-atmosphere"):
		world.weather.face.material.set_shader_parameter(&"surface_frame", Vector3.ZERO)
