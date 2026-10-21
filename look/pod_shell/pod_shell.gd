extends DeckProbe
## Actual recoverable panels: a closed reclined pod, then an opened landed shell.

func run() -> void:
	await load_lines()
	world.time_warp = 0.0
	world.time = world.tuning.day_minutes * 60.0 * 0.32
	var at := world.player.global_position + Vector3(0, 0, -4)
	at.y = world.height_under(at) + Chassis.THICK * 0.5 + 0.12
	var rig := PodShell.build(world.content, Transform3D(Basis.IDENTITY, at))
	var deck := rig.deck
	deck.freeze = true
	check(deck.pieces().size() == 10 and rig.named.size() == 12, "all ten shell panels and two frames have stable recovery roles")
	check(deck.comes_off(rig.named[&"hatch"]) and deck.comes_off(rig.named[&"roof_a"]), "exit panels use normal bare-chassis removal")
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	Dev.hide_overlays()
	world.player.camera.fov = 65.0
	look(at + Vector3(-3.4, 1.8, 3.5), at + Vector3(0.45, 0.55, 0))
	await shot(out, "closed")
	look(at + Vector3(-1.7, 1.25, 1.7), at + Vector3(0.45, 0.5, 0))
	await shot(out, "closed_detail")
	look(at + Vector3(-3.4, 1.8, 3.5), at + Vector3(0.45, 0.55, 0))
	print("POD CLOSED ", metrics(deck), " bounds=", deck.shape_bounds(), " recovery=10 chassis +2 frames; reclined interior=2x1x1m")
	var hatch := deck.detach(rig.named[&"hatch"])
	var roof := deck.detach(rig.named[&"roof_a"])
	for panel: Chassis in [hatch, roof]:
		panel.freeze = true
	var hatch_at := at + Vector3(-1.7, 0, 0.7)
	hatch_at.y = world.height_under(hatch_at) + Chassis.THICK * 0.5 + 0.04
	world.teleport(hatch, Transform3D(Basis(Vector3.UP, 0.18), hatch_at))
	var roof_at := at + Vector3(-0.6, 0, 1.6)
	roof_at.y = world.height_under(roof_at) + Chassis.THICK * 0.5 + 0.04
	world.teleport(roof, Transform3D(Basis(Vector3.UP, -0.15), roof_at))
	check(deck.pieces().size() == 8 and hatch.deck == null and roof.deck == null, "real hatch and roof detach into reusable loose chassis")
	check(hatch.get_children().any(func(n: Node) -> bool: return n.has_meta(&"pod_skin")) \
		and roof.get_children().any(func(n: Node) -> bool: return n.has_meta(&"pod_skin")),
		"their armor follows its owning physical panel")
	await shot(out, "opened")
	look(at + Vector3(-1.6, 2.0, 1.5), at + Vector3(0.45, 0.25, 0))
	await shot(out, "interior")

func shot(out: String, name: String) -> void:
	await physics_frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))

func metrics(root: Node) -> Dictionary:
	var count := {"nodes": 0, "meshes": 0, "surfaces": 0, "triangles": 0, "collision_shapes": 0}
	var next: Array[Node] = [root]
	while not next.is_empty():
		var node := next.pop_back() as Node
		count.nodes += 1
		next.append_array(node.get_children())
		if node is CollisionShape3D:
			count.collision_shapes += 1
		if node is MeshInstance3D and node.mesh != null:
			count.meshes += 1
			for surface in node.mesh.get_surface_count():
				count.surfaces += 1
				var arrays: Array = node.mesh.surface_get_arrays(surface)
				count.triangles += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null and arrays[Mesh.ARRAY_INDEX].size() > 0 else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	return count
