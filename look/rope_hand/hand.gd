extends "res://probes/rope/25_the_paying_coil_follows_your_hand.gd"
## Actual rope payout with an existing selected waist line, viewed from beside the hands.

func run() -> void:
	await super.run()
	Dev.hide_overlays()
	hide_ui(get_tree().root)
	var hand_at := hands.held.global_position
	var camera := Camera3D.new()
	camera.fov = 55
	add_child(camera)
	camera.make_current()
	camera.global_position = world.player.global_position + Vector3(2.2, 2.5, 2.2)
	camera.look_at((hand_at + hands.reel._coil.global_position) * 0.5)
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	var held := hands.held
	var line: Line = held.get_meta(&"line")
	var deck := Catalog.device(&"chassis") as Chassis
	world.content.add_child(deck)
	deck.global_position = world.player.global_position + Vector3(0, 0.2, 1.2)
	deck.freeze = true
	var hook := Catalog.part(&"hook") as RopeHook
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, 0.0, hook)
	look(hook.guide.global_position + Vector3(0, 0.9, -0.7), hook.guide.global_position)
	await simulate(0.3)
	press(&"interact")
	await simulate(0.1)
	check(line.rope.through == hook.guide and hands.held == held and held.socket == null,
		"use routes through the fitted hook while the paying end stays in the hand")
	print("actual hook routing: %s; held endpoint remains free %s" % [line.rope.through == hook.guide, held.socket == null])

func hide_ui(node: Node) -> void:
	if node is CanvasLayer:
		node.visible = false
	for child in node.get_children():
		hide_ui(child)
