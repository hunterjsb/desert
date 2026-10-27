extends WorldProbe
## The live vent includes its own crater terrain; its spatter cannot stand on a flat display row.
func run() -> void:
	var tuning := Tuning.current()
	tuning.storm_threshold = 2.0
	var history := History.new(1234, tuning)
	var point: Vector3 = history.geology.live()[0].p
	tuning.spawn_latitude_degrees = rad_to_deg(Sphere.latitude(point))
	tuning.spawn_longitude_degrees = rad_to_deg(Sphere.longitude(point))
	tuning.run_seed = 1234
	tuning.salvage = true
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	world = WORLD_SCENE.instantiate()
	add_child(world)
	# The camera surveys the crater; no walker is being tested inside its forming ground.
	world.player.set_physics_process(false)
	await settle()

	world.time_warp = 0.0
	world.tuning.eye_adapts = false
	world.player.set_physics_process(false)
	world.player.visible = false
	Dev.hide_overlays()
	for layer in world.find_children("*", "CanvasLayer", true, false): layer.visible = false
	var sites := structures_near(&"vent_mouth", 300.0)
	check(not sites.is_empty(), "the native vent and its crater are loaded")
	if sites.is_empty(): return
	var site: Structure = sites[0]
	var centre := Vector3(world.engine_x(site.x), site.pad() + GeologyKit.CREST_HEIGHT, world.engine_z(site.z))
	var lens := Camera3D.new()
	lens.fov = 35
	lens.near = 0.02
	add_child(lens)
	lens.current = true
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	for light: String in ["morning", "dusk"]:
		world.time = world.tuning.day_minutes * 60 * fposmod((0.38 if light == "morning" else 0.715) - world.tuning.start_time_of_day, 1.0)
		for distance: float in [3.0, 20.0, 60.0]:
			var focus := centre
			if distance == 3.0:
				var box: AABB = site.piece.boxes[0]
				var at := site.to_world(Vector2(box.get_center().x, box.get_center().z))
				focus = Vector3(world.engine_x(at.x), site.pad() + box.get_center().y, world.engine_z(at.y))
			var eye := focus + Vector3(1, 0.5, 1).normalized() * distance
			lens.global_transform = Transform3D(Basis.looking_at(focus - eye), eye)
			await physics_frames(18)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("vent_mouth-%s-%dm.png" % [light, distance]))
			print("NATIVE VENT ", light, " distance_m=", lens.global_position.distance_to(focus), " site=", Vector2(site.x, site.z))
