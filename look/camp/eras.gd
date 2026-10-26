extends DeckProbe
## Catalog devices and lineage, at a measured three metres in the world's light.
const IDS: Array[StringName] = [&"planter", &"deep_planter", &"burner", &"turbine", &"condenser", &"light_panel", &"console", &"cargo", &"survival_kit", &"bedroll"]
const ERAS: Array[StringName] = [Eras.NEW, Eras.COLONIAL, Eras.FIRST, Eras.SECOND, Eras.SKIMMER]
func run() -> void:
	await load_lines()
	world.time_warp = 0.0
	world.tuning.eye_adapts = false
	Dev.hide_overlays()
	world.player.vitals.god = true
	world.player.feel.set_process(false)
	world.player.camera.fov = 45.0
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	var groups: Array[Device] = []
	var base := world.player.global_position + Vector3(0, 0, -5)
	for id: StringName in IDS:
		for i in ERAS.size():
			var body := Catalog.device(id)
			if ERAS[i] != Eras.NEW: Catalog.found_in(body, ERAS[i], &"watchtower", 1234)
			world.content.add_child(body)
			body.freeze = true
			var at := base + Vector3(i * 4.0, 0, -IDS.find(id) * 5.0)
			at.y = world.height_under(at) + Catalog.DEVICES[id].size.y * 0.5 + 0.03
			body.global_position = at
			groups.append(body)
			print("CAMP MODEL ", id, " ", ERAS[i], " triangles=", body.frame_view.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3, " surfaces=", body.frame_view.mesh.get_surface_count())
	for light: String in ["morning", "dusk"]:
		world.time = world.tuning.day_minutes * 60.0 * fposmod((0.38 if light == "morning" else 0.715) - world.tuning.start_time_of_day, 1.0)
		for k in groups.size():
			var id := IDS[k / ERAS.size()]
			var focus := groups[k].global_position + Vector3.UP * (0.85 if id == &"turbine" else 0.0)
			var offset := Vector3(-1.6, 1.2, -2.23) if id == &"console" else Vector3(1.6, 1.2, 2.23)
			if id == &"turbine": offset = Vector3(1.6, 0.45, 2.23)
			look(focus + offset.normalized() * 3.0, focus)
			for tick in 12: await get_tree().physics_frame
			print("CAMP VIEW ", light, " ", id, " ", ERAS[k % ERAS.size()], " distance_m=", world.player.camera.global_position.distance_to(focus), " local_time=", world.weather.day.time_of_day(world.time, world.moon.longitude))
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join(light + "-" + String(id) + "-" + String(ERAS[k % ERAS.size()]) + ".png"))
	for body in groups: body.queue_free()
	await get_tree().process_frame
