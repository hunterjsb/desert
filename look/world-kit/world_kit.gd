extends WorldProbe
## The actual site meshes and sailing kit, at fixed viewing distances in the world's light.
const SITES: Array[StringName] = [&"pipe_wall_hut", &"cistern", &"low_wall", &"vent_mouth", &"fuel_bladder", &"pipeline_segment"]
const KIT: Array[StringName] = [&"streamer", &"fabric", &"crows_nest"]

func run() -> void:
	Tuning.current().storm_threshold = 2.0
	await load_world()
	world.time_warp = 0.0
	world.tuning.eye_adapts = false
	world.player.set_physics_process(false)
	world.player.visible = false
	Dev.hide_overlays()
	for layer in world.find_children("*", "CanvasLayer", true, false): layer.visible = false
	for child in world.content.get_children():
		if child is Node3D: child.visible = false
	var lens := Camera3D.new()
	lens.fov = 35
	lens.near = 0.02
	add_child(lens)
	lens.current = true
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	var base := world.player.global_position + Vector3(0, 0, -8)
	var eras := OS.get_cmdline_user_args().has("--eras")
	var entries: Array = []
	for id: StringName in KIT if eras else SITES + KIT:
		for era: StringName in [Eras.NEW, Eras.COLONIAL, Eras.FIRST, Eras.SECOND, Eras.SKIMMER] if eras else [Eras.NEW]:
			entries.append([id, era])
	var only := PackedStringArray()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="): only = arg.trim_prefix("--only=").split(",")
	for entry: Array in entries:
		if not only.is_empty() and not only.has(String(entry[0])): continue
		var id: StringName = entry[0]
		var era: StringName = entry[1]
		var root: Node3D
		var box: AABB
		if SITES.has(id):
			var piece := StructureKit.piece(id)
			var view := MeshInstance3D.new()
			view.mesh = piece.mesh(Exposure.EXPOSED, 0)
			view.set_instance_shader_parameter(&"age", (piece.age.x + piece.age.y) * 0.5)
			view.set_instance_shader_parameter(&"era", float(piece.marks))
			root = view
			box = view.mesh.get_aabb()
			print("WORLD KIT ", id, " triangles=", view.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3, " draws=", view.mesh.get_surface_count(), " bounds=", box)
		else:
			root = Catalog.part(id) if Catalog.PARTS.has(id) else Catalog.device(id)
			if era != Eras.NEW: Catalog.found_in(root, era, &"nomad_rig", 1234)
			(root as RigidBody3D).freeze = true
			var size: Vector3 = (Catalog.PARTS[id] if Catalog.PARTS.has(id) else Catalog.DEVICES[id]).size
			box = AABB(Vector3(-size.x * 0.5, -size.y * 0.5, 0) if root is Part else -size * 0.5, size)
		world.content.add_child(root)
		root.global_position = Vector3(base.x, world.height_under(base) - box.position.y + 0.03, base.z)
		var focus := root.global_position + box.get_center()
		for light: String in ["morning", "dusk"]:
			world.time = world.tuning.day_minutes * 60 * fposmod((0.38 if light == "morning" else 0.715) - world.tuning.start_time_of_day, 1.0)
			for distance: float in [3.0] if eras else [3.0, 20.0, 60.0]:
				lens.fov = 18 if id == &"streamer" and distance == 3.0 else 35
				var eye := focus + Vector3(1, 0.5, 1).normalized() * distance
				lens.global_transform = Transform3D(Basis.looking_at(focus - eye), eye)
				await physics_frames(12)
				await RenderingServer.frame_post_draw
				var name_ := "%s-%s-%s-%dm.png" % [id, era, light, distance] if eras else "%s-%s-%dm.png" % [id, light, distance]
				get_viewport().get_texture().get_image().save_png(out.path_join(name_))
				print("WORLD VIEW ", id, " ", light, " distance_m=", lens.global_position.distance_to(focus), " fov=", lens.fov)
		root.queue_free()
		await get_tree().process_frame
