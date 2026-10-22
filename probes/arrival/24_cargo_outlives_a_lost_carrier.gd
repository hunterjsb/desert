extends SailProbe
## Surviving equipment keeps its actual fittings/ends when impact loses its carrier panel.

func run() -> void:
	await load_sailing()
	var ship := SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3.UP * 60.0))
	world.teleport(world.player, ship.spawn_at.global_transform)
	var state := {"phase": &"preflight", "preflight": {"version": 1, "launched": false},
		"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude),
		"landing_world": Vector2(world.world_x(open.x), world.world_z(open.z)), "heading": 0.0}
	var nodes := PreflightCargo.stage(world, ship, state)
	var deck := ship.pod.deck
	var board := nodes[&"board"] as Device
	Stick.put(deck, ship.pod_parts[&"side_back_b"], Chassis.TOP, Vector2.ZERO, PI * 0.5, board)
	hands.hold(nodes[&"rope"])
	await physics_frames(4)
	var first := hands.held as Part
	var line := first.get_meta(&"line") as Line
	for role in [&"side_front_b", &"side_back_b"]:
		Stick.put(deck, ship.pod_parts[role], Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"hook"))
	var a := deck.free_tie(ship.global_transform * ship.pod_pose * Vector3(1, 0.5, -0.3))
	deck.fit(hands.stow(), a)
	await physics_frames(3)
	var b := deck.free_tie(ship.global_transform * ship.pod_pose * Vector3(1, 0.5, 0.3))
	deck.fit(hands.stow(), b)
	await physics_frames(3)
	var ends := line.ends.duplicate()
	var rope := line.rope
	var length := rope.length
	check(PreflightCargo.loaded(world, ship).has(&"rope"), "the fully attached original line is selected cargo")
	state = PreflightCargo.seal(world, ship, state, {"id": &"steep", "extra_survival": 1.0,
		"outer_survival": 0.0, "frame_survival": 0.0, "device_durability": Vector2.ONE, "chassis_durability": Vector2.ONE})
	check(not state.is_empty(), "ready cargo seals before the known carrier losses")
	if state.is_empty():
		return
	var landed := PreflightCargo.land(world, state)
	await physics_frames(4)
	check(state.get("materialized", false) and landed.get(&"board") == board and board.host() == null
		and board.battery() == nodes[&"board_cell"], "the surviving actual board and cell detach from their lost carrier")
	check(ends.all(func(end: Variant) -> bool: return is_instance_valid(end)) and is_instance_valid(line)
		and line.rope == rope and ropes.ropes.has(rope) and rope.length == length,
		"both actual rope ends and their same line survive carrier loss")
	check(ship.pod.deck.pieces().size() == 2, "only the protected original floor core remains joined")
	wind.override = Callable()
	remove_child(world)
	world.queue_free()
	await physics_frames(4)
