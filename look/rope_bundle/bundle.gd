extends "res://probes/rope/29_continued_use_gathers_waist_ends.gd"
## The real held-Use gathering gesture, then ordinary anchoring of its knot.

func run() -> void:
	await super.run()
	if not hands.held is RopeTip:
		return
	Dev.hide_overlays()
	hide_ui(get_tree().root)
	var output := OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	var primary := hands.held as Part
	var camera := Camera3D.new()
	camera.fov = 48
	add_child(camera)
	camera.make_current()
	var at := primary.global_transform * Vector3(0.05, 0.0, 0.04)
	camera.global_position = at + world.player.global_basis * Vector3(0.28, 0.22, 0.35)
	camera.look_at(at)
	await capture(output.path_join("held.png"))

	var anchor := driven_stake(world.player.global_position + Vector3(0, 0, -1.5))
	var target := anchor.global_transform * Stake.RING
	look(target + Vector3(0, 0.3, 1), target)
	await simulate(0.4)
	check(hands.socket != null and hands.socket.get_parent() == anchor, "the real gathered knot offers the ordinary anchor")
	if hands.socket == null:
		return
	check(hands.grab(), "the ordinary take action anchors the captured knot")
	await simulate(2.0)
	var seat := anchor.global_transform * primary.socket.transform
	at = seat * Vector3(0.05, 0.0, 0.04)
	camera.global_position = at + Vector3(0.12, 0.05, 0.6)
	camera.look_at(at)
	look(eye(), eye() + Vector3(0, 4, -10))
	await capture(output.path_join("anchored.png"))
	camera.global_position = at + Vector3(1.6, 5.0, 6.0)
	camera.look_at(at + Vector3(0, 0, -1.0))
	await capture(output.path_join("anchored_context.png"))

func capture(path: String) -> void:
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func hide_ui(node: Node) -> void:
	if node is CanvasLayer:
		node.visible = false
	for child in node.get_children():
		hide_ui(child)
