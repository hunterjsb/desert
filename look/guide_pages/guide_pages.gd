extends DeckProbe
## The Surveyor's Guide's pictures, on real gear with the HUD hidden:
##   scripts/unseen.sh --path . --resolution 1600x900 res://look/guide_pages/guide_pages.tscn -- <dir>
## Each is staged where the last left off: loose gear, the deck it becomes
## with its shield up, the Home beacon on it, and the board to scout on.

func run() -> void:
	await load_lines()
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	Dev.hide_overlays()
	var me := world.player.global_position
	var ahead := me + Vector3(0.0, 0.0, -3.0)
	var loose: Array[Node3D] = []
	for each: Array in [[&"battery", Vector2(-0.6, -2.7)], [&"canister", Vector2(0.5, -2.5)],
			[&"ration", Vector2(0.1, -2.1)]]:
		var at: Vector2 = each[1]
		loose.append(part(each[0], Transform3D(Basis(Vector3.UP, at.x * 3.0), spot(at.x, at.y) + Vector3.UP * 0.15)))
	var shield := device(&"light_shield", ahead + Vector3(-0.2, 0.0, -0.5), 0.3)
	var deck := piece(ahead + Vector3(1.6, 0.0, -0.8))
	await simulate(1.5)
	await shot(out, "salvage", me + Vector3(0.6, 1.5, 0.4), ahead)

	for thing in loose:
		thing.queue_free()
	shield.freeze = true
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.15, 0.1), 0.0, shield)
	var battery := fit_part(deck, &"battery") as Battery
	battery.fill(battery.capacity())
	shield.switch(true)
	await simulate(2.0)
	await shot(out, "shelter", deck.global_position + Vector3(-2.6, 2.0, 3.2), deck.global_position)

	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.25, -0.2), 0.0, beacon)
	world.home.mark(beacon)
	await simulate(2.0)
	await shot(out, "home", deck.global_position + Vector3(1.4, 1.1, 1.6), beacon.global_position + Vector3.UP * 0.7)

	# Out past the shield, the board points away over the dunes.
	var board := device(&"board", deck.global_position + Vector3(-1.0, 0.0, 7.5), 0.2, true)
	board.rotation.y = PI
	await simulate(1.5)
	await shot(out, "scout", board.global_position + Vector3(0.4, 1.6, -2.2), board.global_position + Vector3(0.0, 1.5, 14.0))


func shot(out: String, name: String, from: Vector3, toward: Vector3) -> void:
	look(from, toward)
	world.player.set_physics_process(false)
	for layer in get_tree().root.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false
	await physics_frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
