extends DeckProbe
## Era models through a dedicated narrow lens, one metre from the small instruments.
const IDS: Array[StringName] = [&"anemometer", &"barometer", &"hygrometer", &"particle_sensor", &"ground_radar", &"radar", &"harvester", &"screen", &"solar_panel", &"console", &"condenser"]
const ERAS: Array[StringName] = [Eras.NEW, Eras.COLONIAL, Eras.FIRST, Eras.SECOND, Eras.SKIMMER]
func run() -> void:
	await load_lines()
	world.time_warp = 0.0
	world.tuning.eye_adapts = false
	Dev.hide_overlays()
	for layer in world.find_children("*", "CanvasLayer", true, false): layer.visible = false
	world.player.vitals.god = true
	world.player.feel.set_process(false)
	var lens := Camera3D.new()
	lens.fov = 25.0
	lens.near = 0.02
	add_child(lens)
	lens.current = true
	world.player.visible = false
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	var groups: Array[RigidBody3D] = []
	var base := world.player.global_position + Vector3(0, 0, -5)
	for id: StringName in IDS:
		for i in ERAS.size():
			var part := Catalog.PARTS.has(id)
			var body: RigidBody3D = Catalog.part(id) if part else Catalog.device(id)
			if ERAS[i] != Eras.NEW: Catalog.found_in(body, ERAS[i], &"watchtower", 1234)
			world.content.add_child(body)
			body.freeze = true
			var at := base + Vector3(i * 4.0, 0, -IDS.find(id) * 5.0)
			at.y = world.height_under(at) + (Catalog.PARTS[id] if part else Catalog.DEVICES[id]).size.y * 0.5 + 0.03
			body.global_position = at
			groups.append(body)
			print("STATION MODEL ", id, " ", ERAS[i], " triangles=", _mesh(body).surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3, " surfaces=", _mesh(body).get_surface_count(), " complete=", _totals(body))
	for light: String in ["morning", "dusk"]:
		world.time = world.tuning.day_minutes * 60.0 * fposmod((0.38 if light == "morning" else 0.715) - world.tuning.start_time_of_day, 1.0)
		for k in groups.size():
			var id := IDS[k / ERAS.size()]
			var focus := groups[k].global_position + (Vector3(0, 0, Catalog.PARTS[id].size.z * 0.5) if Catalog.PARTS.has(id) else Vector3.ZERO)
			var offset := Vector3(-1.6, 1.2, -2.23) if id == &"console" else Vector3(1.6, 1.2, 2.23)
			var distance := 1.0 if Catalog.PARTS.has(id) and id not in [&"screen", &"solar_panel"] else (3.5 if id == &"console" else (3.0 if id == &"screen" else 1.8))
			var eye := focus + offset.normalized() * distance
			lens.global_transform = Transform3D(Basis.looking_at(focus - eye), eye)
			for tick in 12: await get_tree().physics_frame
			print("STATION VIEW ", light, " ", id, " ", ERAS[k % ERAS.size()], " distance_m=", lens.global_position.distance_to(focus), " fov=", lens.fov, " local_time=", world.weather.day.time_of_day(world.time, world.moon.longitude))
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join(light + "-" + String(id) + "-" + String(ERAS[k % ERAS.size()]) + ".png"))
	# A wider handling view complements the narrow era shots.
	world.time = world.tuning.day_minutes * 60.0 * fposmod(0.38 - world.tuning.start_time_of_day, 1.0)
	for k in groups.size():
		var id := IDS[k / ERAS.size()]
		var part := Catalog.PARTS.has(id)
		var focus := groups[k].global_position + (Vector3(0, 0, Catalog.PARTS[id].size.z * 0.5) if part else Vector3.ZERO)
		var distance := 0.65 if part and id not in [&"screen", &"solar_panel"] else 2.0
		var offset := Vector3(0.6, 0.4, 2) if id != &"console" else Vector3(-0.6, 0.4, -2)
		lens.fov = 45.0
		var eye := focus + offset.normalized() * distance
		lens.global_transform = Transform3D(Basis.looking_at(focus - eye), eye)
		for tick in 12: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("close-" + String(id) + "-" + String(ERAS[k % ERAS.size()]) + ".png"))
	for body in groups: body.queue_free()
	await get_tree().process_frame

func _mesh(body: RigidBody3D) -> Mesh:
	if body is Device: return body.frame_view.mesh
	for node in body.get_children():
		if node is MeshInstance3D: return node.mesh
	return null

func _totals(node: Node) -> Vector2i:
	var result := Vector2i.ZERO
	if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree():
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			result.x += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null and not arrays[Mesh.ARRAY_INDEX].is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3
			result.y += 1
	for child in node.get_children(): result += _totals(child)
	return result
