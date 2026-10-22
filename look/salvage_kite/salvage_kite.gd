extends SailProbe
## The packed find, its camp flight, and the landmark from a dune.


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if not args.is_empty() else OS.get_temp_dir().path_join("desert-salvage-kite")
	DirAccess.make_dir_recursive_absolute(out)
	await load_sailing()
	blow(downwind * 9.0)
	var camp := Catalog.device(&"chassis") as Chassis
	world.content.add_child(camp)
	camp.global_position = open + Vector3.UP * 0.5
	fit_part(camp, &"hook")
	camp.freeze = true
	var kite := Catalog.device(&"salvage_kite") as SalvageKite
	world.content.add_child(kite)
	kite.global_position = open + Vector3(1.4, 0.25, 0.0)
	kite.freeze = true
	kite.durability = 0.7
	kite.show_wear()
	look(kite.global_position + Vector3(0.8, 0.5, 0.7), kite.global_position)
	await _shoot(out.path_join("packed.png"))
	kite.freeze = false
	kite.global_position = open + Vector3.UP * 2.0
	var line := Line.between(world, kite.bridle(), camp.free_tie(kite.global_position), 1.0)
	line.full = world.tuning.traction_line_m
	line.rope.full = line.full
	kite.use(world.player, kite.global_position)
	speed_up(4)
	await simulate(35.0)
	speed_up(1)
	look(camp.global_position - Vector3(downwind.x, 0.0, downwind.y) * 7.0 + Vector3.UP * 2.0, kite.global_position * 0.6 + camp.global_position * 0.4)
	await _shoot(out.path_join("camp.png"))
	var near := kite.global_position - kite.load_n.normalized() * 6.0
	look(near, kite.global_position)
	await _shoot(out.path_join("wing.png"))
	var far := camp.global_position - Vector3(downwind.x, 0.0, downwind.y) * 200.0
	far.y = maxf(world.height_under(far) + 1.7, camp.global_position.y + 4.0)
	look(far, camp.global_position + Vector3.UP * 20.0)
	await settle(true)
	await _shoot(out.path_join("landmark.png"))


func _shoot(path: String) -> void:
	Dev.hide_overlays()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await physics_frames(3)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("salvage kite: ", path)
