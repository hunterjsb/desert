extends SailProbe
## Actual winch and halyard on an assembled rig, captured with an isolated profile.

func run() -> void:
	await load_sailing()
	blow(Vector2.ZERO)
	rig(open, heading())
	deck.freeze = true
	var winch := Catalog.device(&"hand_winch") as ManualWinch
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP, Vector2.ZERO, 0.0, winch)
	await physics_frames(3)
	mast.rig_hoist(winch)
	look(winch.global_position + winch.global_basis * Vector3(0, 0.6, 1.2), winch.global_position)
	await physics_frames(2)
	winch.notch(7, world.player)
	await simulate(2.2)
	Dev.hide_overlays()
	hands.set_process(false)
	hide_ui(get_tree().root)
	var camera := Camera3D.new()
	camera.fov = 55.0
	add_child(camera)
	camera.make_current()
	var out := OS.get_cmdline_user_args()[0]
	await shoot(camera, winch.global_position + winch.global_basis * Vector3(0.65, 0.45, 0.85),
		winch.global_position + Vector3.UP * 0.02, out.path_join("wheel.png"))
	await shoot(camera, mast.global_position + mast.global_basis * Vector3(0.7, 0.8, -1.0) + Vector3.UP * 3.3,
		mast.pulley.global_position - Vector3.UP * 0.05, out.path_join("pulley.png"))
	await shoot(camera, deck.global_position + deck.global_basis * Vector3(4.5, 3.2, 5),
		mast.global_position + Vector3.UP * 1.5, out.path_join("rig.png"))


func shoot(camera: Camera3D, from: Vector3, at: Vector3, file: String) -> void:
	camera.global_position = from
	camera.look_at(at)
	for i in 12:
		await get_tree().process_frame
	hide_ui(get_tree().root)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(file)
	print("hoist shot ", file)


func hide_ui(node: Node) -> void:
	if node is CanvasLayer:
		node.visible = false
	for child in node.get_children():
		hide_ui(child)
