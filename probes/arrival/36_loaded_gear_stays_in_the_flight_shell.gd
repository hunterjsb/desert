extends MovementProbe
## Real selected mounted, loose and fitted cargo remains in the render snapshot exactly once.
func run() -> void:
	await load_moving()
	world.time_warp = 0.0
	var ship := SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis(Vector3.UP, 0.4), player.global_position + Vector3.UP * 60))
	player.set_physics_process(false)
	world.teleport(player, ship.spawn_at.global_transform)
	var state := {"phase": &"preflight", "preflight": {"version": 1, "launched": false},
		"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude)}
	var nodes := PreflightCargo.stage(world, ship, state)
	var board := nodes[&"board"] as Device
	Stick.put(ship.pod.deck, ship.pod_parts[&"side_back_b"], Chassis.TOP, Vector2.ZERO, PI * 0.5, board)
	await physics_frames(2)
	var sealed := PreflightCargo.seal(world, ship, state, SurveyorManifest.approach(world.tuning, &"shallow"))
	check(not sealed.is_empty(), "actual stores and fitted external board seal")
	if sealed.is_empty(): return
	var selected := ship.pod_parts.duplicate()
	for uid: StringName in sealed.preflight.loaded_uids:
		selected[uid] = nodes[uid]
	var bodies := world.content.get_child_count()
	var shield := nodes[&"shield"] as Device
	var cell := nodes[&"camp_cell"] as Battery
	var water := nodes[&"water"] as Supply
	var charge := cell.charge_wh
	var fill := water.amount
	var interior := PodInterior.build(selected)
	world.add_child(interior)
	interior.global_transform = ship.global_transform * ship.pod_pose
	var copied := {}
	for mesh: MeshInstance3D in interior.get_children():
		var id: int = mesh.get_meta(&"pod_source_mesh", 0)
		check(id != 0 and not copied.has(id), "each actual source mesh is copied once")
		copied[id] = true
		var source := instance_from_id(id) as MeshInstance3D
		check(is_instance_valid(source) and mesh.global_transform.is_equal_approx(source.global_transform)
			and mesh.mesh == source.mesh and mesh.material_override == source.material_override
			and mesh.cast_shadow == source.cast_shadow and mesh.layers == source.layers
			and mesh.visible == source.is_visible_in_tree(), "selected mesh keeps its actual physical pose and material visibility")
		check((mesh.get_instance_shader_parameter(&"age") == null or mesh.get_instance_shader_parameter(&"age") == 0.0)
			and mesh.get_instance_shader_parameter(&"lit") == source.get_instance_shader_parameter(&"lit"),
			"selected mesh is clean of sand in orbit and keeps its powered state")
	check(copied.has(shield.frame_view.get_instance_id()) and copied.has(board.frame_view.get_instance_id()),
		"selected mounted device meshes remain visible")
	for part: Part in [cell, nodes[&"board_cell"]]:
		check(part.socket != null and not part.is_inside_tree(), "the fixture exercises a real off-tree fitted cell")
		for node in part.socket.fitted:
			if node is MeshInstance3D:
				check(copied.has(node.get_instance_id()), "selected fitted-part geometry remains visible without a second copy")
	for node in water.find_children("*", "MeshInstance3D", true, false):
		check(copied.has(node.get_instance_id()), "the selected loose water store remains visible")
	for node in (nodes[&"guide"] as Device).find_children("*", "MeshInstance3D", true, false):
		check(not copied.has(node.get_instance_id()), "forgotten rack gear is not invented inside the pod")
	check(interior.find_children("*", "CollisionObject3D", true, false).is_empty()
		and world.content.get_child_count() == bodies and cell.charge_wh == charge and water.amount == fill
		and cell.socket != null and board.battery() == nodes[&"board_cell"],
		"render copying changes no physical contents, charge, fittings or bodies")
	interior.free()
	if wind != null: wind.override = Callable()
	remove_child(world)
	world.queue_free()
	await physics_frames(4)
