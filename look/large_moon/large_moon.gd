extends "res://look/horizons/horizons.gd"
## Real main-view geometry, low and high observers, then the same view after rebasing.

func _ready() -> void:
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.eye_adapts = false
	tuning.storm_threshold = 2.0
	world = WORLD.instantiate()
	add_child(world)
	world.time_warp = 0
	world.player.set_physics_process(false)
	world.player.set_process_unhandled_input(false)
	await ground()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	var mark := world.shape.history.landmark(&"starcom")
	var p := Sphere.toward(mark.p, mark.bearing + 0.5, 15000.0 / world.shape.history.radius)
	world.travel(rad_to_deg(Sphere.latitude(p)), rad_to_deg(Sphere.longitude(p)), 0)
	await ground()
	world.time_warp = 0
	for t in range(0, 1200, 5):
		if absf(world.weather.day.time_of_day(t, world.moon.longitude) - 0.38) < 0.01:
			world.time = t
			break
	var hill := world.shape.landforms.get_hill(&"starcom")
	var camera := world.player.camera
	world.player.feel.set_process(false)
	var at := world.player.global_position
	at.y = world.height_at(world.player_world_x(), world.player_world_z()) + 2.0
	var target := Vector3(world.engine_x(hill.at.x), hill.height * 0.5, world.engine_z(hill.at.y))
	camera.global_position = at
	camera.look_at(target)
	await shoot("low")
	camera.global_position = at + Vector3.UP * 350.0
	camera.look_at(target)
	await shoot("high")
	world.shift_origin(Vector2i(3, -2))
	await shoot("high_shifted")
	print("LARGE_MOON apron vertices ", (world.tuning.horizon_apron_rings + 1) * world.tuning.horizon_apron_sides)
	get_tree().quit()
