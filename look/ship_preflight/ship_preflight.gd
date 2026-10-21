extends Node
## The actual ship room, through the normal player's camera and from outside.
var world: World
var ship: SurveyorShip
var out := ""

func _ready() -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://ship_preflight"
	DirAccess.make_dir_recursive_absolute(out)
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.prevailing_speed = 0.0
	tuning.storm_threshold = 2.0
	tuning.eye_adapts = false
	world = preload("res://game/world/world.tscn").instantiate()
	add_child(world)
	for i in 2400:
		await get_tree().process_frame
		if world.terrain.is_idle(): break
	world.time_warp = 0.0
	world.time = world.tuning.day_minutes * 60.0 * 0.31
	ship = SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3.UP * 60.0))
	Dev.hide_overlays()
	world.player.set_physics_process(false)
	world.player.vitals.set_physics_process(false)
	await _eyes("interior", Vector3(-0.5, 1.65, 1.2), Vector3(0.0, 1.45, -4.5))
	await _eyes("window", Vector3(0.25, 1.65, -2.9), Vector3(0, 1.7, -5))
	await _eyes("pod_berth", Vector3(-0.5, 1.65, 1.5), Vector3(1.4, 0.6, -0.3))
	await _eyes("launch_station", Vector3(-1.3, 1.65, -2.1), Vector3(-1.8, 1.1, -3.7))
	var camera := Camera3D.new()
	camera.fov = 55
	world.add_child(camera)
	camera.look_at_from_position(ship.to_global(Vector3(8, 6, 9)), ship.to_global(Vector3(0, 1, -1)))
	camera.make_current()
	await _save("exterior")
	get_tree().quit()

func _eyes(label: String, eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var from := ship.to_global(eye)
	var to := ship.to_global(target) - from
	player.global_position = from - player.camera.position
	player.rotation.y = atan2(-to.x, -to.z)
	player.camera.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())
	player.camera.make_current()
	await _save(label)

func _save(label: String) -> void:
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(label + ".png"))
	print("SHIP_CAPTURE ", label)
