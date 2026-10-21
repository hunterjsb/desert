extends Node
## Real sealed berth, then the same shell meshes in the orbital viewport at its seat.
var world: World
var out: String

func _ready() -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.eye_adapts = false
	tuning.storm_threshold = 2.0
	world = preload("res://game/world/world.tscn").instantiate()
	add_child(world)
	for i in 2400:
		await get_tree().process_frame
		if world.terrain.is_idle(): break
	world.time_warp = 0
	world.time = tuning.day_minutes * 60.0 * 0.31
	world.player.set_physics_process(false)
	world.player.vitals.set_physics_process(false)
	Dev.hide_overlays()
	var ship := SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3.UP * 60))
	PodShell.reseal(ship.pod)
	var pose := ship.global_transform * ship.pod_pose
	var camera := world.player.camera
	world.player.feel.set_process(false)
	var eye := PodShell.seat_pose() * Transform3D(Basis(Vector3.RIGHT, 0.1), Vector3(0, tuning.surveyor_preflight.seat_eye_m, 0))
	world.player.restore_ground_pose(&"prone")
	world.player.global_transform = pose * PodShell.seat_pose()
	camera.position = Vector3(0, tuning.surveyor_preflight.seat_eye_m, 0)
	camera.rotation = Vector3(0.1, 0, 0)
	camera.make_current()
	await _save("actual_seated")
	camera.look_at_from_position(pose * Vector3(2.3, 1.3, 0.8), pose * Vector3(0.6, 0.45, 0))
	await _save("actual_exterior")
	var screen := SubViewportContainer.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.stretch = true
	add_child(screen)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = get_viewport().size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	screen.add_child(viewport)
	var orbit := ArrivalOrbit.new()
	viewport.add_child(orbit)
	orbit.setup(world.shape.history, world.weather.day)
	orbit.update_light(world.time)
	orbit.camera.fov = camera.fov
	var point := Sphere.point(world.moon.latitude, world.moon.longitude)
	orbit.camera.position = point * ArrivalOrbit.RADIUS * 1.55
	orbit.camera.look_at(point * ArrivalOrbit.RADIUS, Sphere.north(point))
	var interior := PodShell.flight_interior(ship.pod.named)
	orbit.camera.add_child(interior)
	interior.transform = eye.affine_inverse()
	await _save("flight_actual_shell")
	interior.free()
	var fallback := PodShell.flight_interior()
	orbit.camera.add_child(fallback)
	fallback.transform = eye.affine_inverse()
	await _save("flight_legacy_shell")
	screen.queue_free()
	world.queue_free()
	world = null
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_tree().quit()

func _save(label: String) -> void:
	for i in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(label + ".png"))
	print("POD_VIEW_CAPTURE ", label)
