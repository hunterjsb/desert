extends LineProbe
## Real wheel actions with live rope solving; no synthetic lengths or hidden strands.

func run() -> void:
	await load_lines()
	var player := world.player
	var out := Vector3.FORWARD
	var planter := floating(&"planter", player.global_position + out * 5.0)
	await simulate(0.5)
	var line := await lead(planter)
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	blow(Vector2(out.x, out.z) * 4.0)
	await simulate(1.5)
	Dev.hide_overlays()
	_hide_ui(get_tree().root)
	var camera := Camera3D.new()
	camera.fov = 50
	add_child(camera)
	camera.make_current()
	var images: Array[Image] = []
	var before := line.rope.length
	_wheel(8)
	await _record(camera, line, images, 150)
	var gathered := line.rope.length
	check(hands.held == line.ends[1] and gathered < before - 1.5, "normal reel actions gather rope while its end stays held")
	_wheel(-8)
	await _record(camera, line, images, 150)
	check(hands.held == line.ends[1] and line.rope.length > gathered + 1.5, "normal payout actions return the same gathered rope")
	check(world.ropes.is_physics_processing() and line.is_physics_processing() and line.rope.strand.visible,
		"the live strand and solver stayed active throughout")
	print("live wheel: %.3fm -> %.3fm -> %.3fm; %d rendered frames, solver active" % [before, gathered, line.rope.length, images.size()])
	var output := OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	for i in images.size():
		images[i].save_png(output.path_join("live_%03d.png" % i))
	images.clear()
	check(world.rescued == 0, "live reeling never passed through the ground")
	world.queue_free()
	world = null
	hands = null
	ropes = null
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _record(camera: Camera3D, line: Line, images: Array[Image], ticks: int) -> void:
	for i in ticks:
		await get_tree().physics_frame
		var center := Line._tip(line.ends[1]).global_position - Vector3.UP * 0.08
		var axis := (world.player.global_basis.x - world.player.global_basis.z).normalized()
		camera.global_position = center + axis * 0.85 + Vector3.UP * 0.12
		camera.look_at(center)
		if i % 2 == 0:
			await RenderingServer.frame_post_draw
			var shot := get_viewport().get_texture().get_image()
			shot.resize(960, 540, Image.INTERPOLATE_LANCZOS)
			images.append(shot)


func _wheel(notches: int) -> void:
	for i in absi(notches):
		var step := InputEventMouseButton.new()
		step.button_index = MOUSE_BUTTON_WHEEL_UP if notches > 0 else MOUSE_BUTTON_WHEEL_DOWN
		step.pressed = true
		get_viewport().push_input(step)
		step = step.duplicate()
		step.pressed = false
		get_viewport().push_input(step)


func _hide_ui(node: Node) -> void:
	if node is CanvasLayer:
		node.visible = false
	for child in node.get_children():
		_hide_ui(child)
