extends WorldProbe
## Actual saved-time renderer and ordinary head input, with real side/roof glazing.
var view: ArrivalView
var state := {"phase": &"descent", "elapsed": 3.1, "progress": 0.45}
var out: String

func run() -> void:
	Tuning.current().eye_adapts = false
	await load_world()
	world.time_warp = 0.0
	world.time = world.tuning.day_minutes * 60.0 * 0.31
	world.player.set_physics_process(false)
	world.player.set_process_unhandled_input(false)
	world.player.feel.set_process(false)
	world.player.body.hide()
	world.player.hands._hud.hide()
	Dev.hide_overlays()
	var pod := PodShell.build(world.content, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3(0, 2, -4)))
	pod.deck.freeze = true
	world.arrival_nodes = pod.named.duplicate()
	view = ArrivalView.new()
	add_child(view)
	view.setup(world)
	out = OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	Controls.mouse_free = false
	await shot("forward")
	await motion(Vector2(-580, -40))
	await shot("side")
	await motion(Vector2(580, -550))
	await shot("roof")
	await motion(Vector2(-400, 350))
	state.phase = &"entry"
	state.elapsed = 1.7
	state.progress = 0.65
	await shot("entry_side")
	view.dispose()

func motion(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	Input.parse_input_event(event)
	await get_tree().process_frame

func shot(label: String) -> void:
	view.present(state)
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(label + ".png"))
	print("FLIGHT_FEEL_CAPTURE ", label, " head=", view.head_angles())
