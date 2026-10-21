extends "res://probes/rope/26_the_coil_gathers_continuously.gd"
## Real held-end display, animated through the old fill thresholds in both directions.

func run() -> void:
	await super.run()
	Dev.hide_overlays()
	_hide_ui(get_tree().root)
	var line: Line = hands.held.get_meta(&"line")
	line.set_physics_process(false)
	# The sweep includes synthetic zero-length states; do not feed those to the solver.
	world.ropes.set_physics_process(false)
	hands.set_physics_process(false)
	var coil := hands.reel._coil

	var camera := Camera3D.new()
	camera.fov = 43
	add_child(camera)
	camera.make_current()
	var center := coil.global_transform * Vector3(0, 0, 0.03)
	camera.global_position = center + coil.global_basis.z * 0.75 + Vector3.UP * 0.12
	camera.look_at(center)
	var output := OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	for stage in [["empty", 0.001], ["third_before", 1.0 / 3.0 - 0.003],
			["third_after", 1.0 / 3.0 + 0.003], ["two_thirds_before", 2.0 / 3.0 - 0.003],
			["two_thirds_after", 2.0 / 3.0 + 0.003], ["full", 1.0]]:
		line.rope.length = line.rope.full * (1.0 - float(stage[1]))
		line.rope.strand.set_length(line.rope.length)
		for i in 60:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		check(hands.held == line.ends[1 - line._first], "controlled fill keeps the same held endpoint")
		print("capture %s: fill %.4f, held endpoint unchanged" % [stage[0], hands.reel._coil_amount])
		get_viewport().get_texture().get_image().save_png(output.path_join(stage[0] + ".png"))
	# Change fill continuously in both directions; save actual consecutive GPU frames.
	for frame in 121:
		var fill := absf(float(frame) / 60.0 - 1.0)
		line.rope.length = line.rope.full * (1.0 - fill)
		line.rope.strand.set_length(line.rope.length)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("motion_%03d.png" % frame))
	print("actual winding motion: 121 consecutive rendered frames, shared mesh retained %s" % [coil.mesh == Dress.coil()])


func _hide_ui(node: Node) -> void:
	if node is CanvasLayer:
		node.visible = false
	for child in node.get_children():
		_hide_ui(child)
