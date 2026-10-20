extends NomadHoistProbe
## A kept yacht's actual winch, rigging and crow's-nest clearance.

func run() -> void:
	await load_nomads()
	var deck := lay_nomad(&"yacht")
	await physics_frames(3)
	var mast := mast_on(deck)
	var winch := winch_on(deck)
	var rope := mast.halyard()
	rope.length -= Mast.LUFF * 0.7
	rope.strand.set_length(rope.length)
	await physics_frames(12)
	hands.set_process(false)
	Dev.hide_overlays()
	var camera := Camera3D.new()
	camera.fov = 55.0
	add_child(camera)
	camera.make_current()
	var out := OS.get_cmdline_user_args()[0]
	await shoot(camera, deck.global_position + Vector3(5, 4, 6), mast.global_position + Vector3.UP * 2,
		out.path_join("nomad-yacht.png"))
	await shoot(camera, mast.global_position + Vector3(0.8, 3.8, -1.2), mast.pulley.global_position,
		out.path_join("nomad-yacht-pulley.png"))


func shoot(camera: Camera3D, from: Vector3, at: Vector3, file: String) -> void:
	camera.global_position = from
	camera.look_at(at)
	for i in 12:
		await get_tree().process_frame
	hide_ui(get_tree().root)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(file)
	print("nomad hoist shot ", file)


func hide_ui(node: Node) -> void:
	if node is CanvasLayer:
		node.visible = false
	for child in node.get_children():
		hide_ui(child)
