extends WorldProbe
## Actual renderer with a sealed real shell and matching ground eye; controller transport is separate.
var view: ArrivalView
var out: String
var pod: Rig

func run() -> void:
	Tuning.current().eye_adapts = false
	await load_world()
	world.time_warp = 0.0
	world.time = world.tuning.day_minutes * 60.0 * 0.31
	world.player.set_physics_process(false)
	world.player.feel.set_process(false)
	world.player.body.hide()
	world.player.hands.set_physics_process(false)
	world.player.hands.set_process(false)
	world.player.hands._hud.hide()
	world.player.vitals.set_physics_process(false)
	Dev.hide_overlays()
	var at := world.player.global_position + Vector3(0, 0, -4)
	at.y = world.height_under(at) + 0.15
	pod = PodShell.build(world.content, Transform3D(Basis.IDENTITY, at))
	pod.deck.freeze = true
	world.arrival_nodes = pod.named.duplicate()
	world.player.restore_ground_pose(&"prone")
	world.player.global_transform = pod.deck.global_transform * PodShell.seat_pose()
	world.player.camera.position = Vector3(0, world.tuning.surveyor_preflight.seat_eye_m, 0)
	world.player.camera.rotation = Vector3(0.1, 0, 0)
	view = ArrivalView.new()
	add_child(view)
	view.setup(world)
	out = OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	await shot("orbit", &"orbit", 1.0, 0.4)
	await shot("ejection", &"ejection", 1.0, 0.5)
	await shot("descent", &"descent", 3.0, 0.5)
	view.present({"phase": &"entry", "elapsed": 2.8, "progress": 0.95})
	var window: Vector4 = view._effects._look.get_shader_parameter(&"aperture")
	var aperture := Rect2(Vector2(window.x, window.y), Vector2(window.z, window.w))
	var windows := int(view._effects._look.get_shader_parameter(&"window_count"))
	var corners: PackedVector2Array = view._effects._look.get_shader_parameter(&"window_corners")
	# Hold the real renderer's pose/light fixed to isolate only its aperture overlay.
	view._effects.present({"phase": &"entry", "elapsed": 0.0, "progress": 0.0}, aperture)
	var clear := await capture("entry_clear")
	var hot := await shot("entry_hot", &"entry", 2.8, 0.95)
	var outside := 0
	var heated := 0
	for y in clear.get_height():
		for x in clear.get_width():
			if clear.get_pixel(x,y) == hot.get_pixel(x,y): continue
			var uv := Vector2(x + 0.5, y + 0.5) / Vector2(clear.get_size())
			if not _inside_window(uv, corners, windows, aperture): outside += 1
			else: heated += 1
	print("SEATED_ENTRY_GPU aperture=%s outside=%d changed=%d" % [aperture, outside, heated])
	check(outside == 0 and heated > 100, "entry changes the actual visible windows while the surrounding shell stays fixed")
	await shot("impact", &"landing", world.tuning.surveyor_arrival.impact_jolt_s * 0.25, 0.1)
	await shot("settled", &"landing", 1.2, 1.0)
	view.dispose()

func shot(label: String, phase: StringName, seconds: float, progress: float) -> Image:
	view.present({"phase": phase, "elapsed": seconds, "progress": progress})
	return await capture(label)

func capture(label: String) -> Image:
	for i in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var capture := get_viewport().get_texture().get_image()
	capture.save_png(out.path_join(label + ".png"))
	print("SEATED_VIEW_CAPTURE ", label)
	return capture

func _inside_window(uv: Vector2, corners: PackedVector2Array, count: int, fallback: Rect2) -> bool:
	if count == 0:
		return fallback.grow(0.003).has_point(uv)
	for i in count:
		var polygon := corners.slice(i * 4, i * 4 + 4)
		if Geometry2D.is_point_in_polygon(uv, polygon):
			return true
		for edge in 4:
			if Geometry2D.get_closest_point_to_segment(uv, polygon[edge], polygon[(edge + 1) % 4]).distance_to(uv) <= 0.003:
				return true
	return false
