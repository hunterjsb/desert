extends WorldProbe
## Actual hooks and their real rope guides, from a camera fixed at one metre.
const ERAS: Array[StringName] = [Eras.NEW, Eras.COLONIAL, Eras.FIRST, Eras.SECOND, Eras.SKIMMER]
func run() -> void:
	Tuning.current().storm_threshold = 2.0
	await load_world()
	world.time_warp = 0.0
	world.tuning.eye_adapts = false
	world.player.set_physics_process(false)
	world.player.visible = false
	Dev.hide_overlays()
	for layer in world.find_children("*", "CanvasLayer", true, false): layer.visible = false
	var lens := Camera3D.new()
	lens.fov = 18
	lens.near = 0.02
	add_child(lens)
	lens.current = true
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	var base := world.player.global_position + Vector3(0, 0, -4)
	var hooks: Array[RigidBody3D] = []
	for i in ERAS.size():
		var hook := Catalog.part(&"hook")
		if ERAS[i] != Eras.NEW: Catalog.found_in(hook, ERAS[i], &"watchtower", 1234)
		world.content.add_child(hook)
		hook.freeze = true
		var at := base + Vector3(i * 1.2, 0, 0)
		at.y = world.height_under(at) + 0.12
		hook.global_position = at
		hooks.append(hook)
	var rig := Rig.build(world.content, [[&"hook", Vector2i.ZERO, Vector2i(1, 0), &"hook"]])
	rig.deck.freeze = true
	rig.deck.global_position = base + Vector3(0, 0.3, -1.8)
	var tied: Part = rig.named.hook
	var anchor := RopeEnd.make(world.content, tied.guide.global_position + Vector3(0.7, 0.1, 0.5), false)
	world.ropes.tie(tied.guide, anchor, 0.9)
	for light: String in ["morning", "dusk"]:
		world.time = world.tuning.day_minutes * 60 * fposmod((0.38 if light == "morning" else 0.715) - world.tuning.start_time_of_day, 1.0)
		for i in hooks.size():
			var focus := hooks[i].global_position + Vector3(0, 0, 0.08)
			for view: Array in [["front", Vector3(0.35, 0.2, 1)], ["side", Vector3(1, 0.2, 0.1)], ["three_quarter", Vector3(1, 0.4, 1)]]:
				await _shot(lens, focus, view[1], 1.0, out.path_join("%s-%s-%s.png" % [light, ERAS[i], view[0]]))
		var fitted: Part = rig.named.hook
		var focus: Vector3 = fitted.socket.global_transform * Vector3(0, 0, 0.08)
		await _shot(lens, focus, Vector3(1, 0.2, 1), 1.0, out.path_join(light + "-fitted.png"))
		lens.fov = 45
		await _shot(lens, rig.deck.global_position, Vector3(1, 0.7, 1), 5.0, out.path_join(light + "-deck5.png"))
		lens.fov = 18
	for hook in hooks: hook.queue_free()
	rig.deck.queue_free()
	await get_tree().process_frame
func _shot(lens: Camera3D, focus: Vector3, toward: Vector3, distance: float, path: String) -> void:
	var eye := focus + toward.normalized() * distance
	lens.global_transform = Transform3D(Basis.looking_at(focus - eye), eye)
	await physics_frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("HOOK VIEW ", path.get_file(), " distance_m=", lens.global_position.distance_to(focus), " fov=", lens.fov)
