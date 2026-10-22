extends SailProbe
## Ordinary coil/end changes keep one cargo identity; an attached line keeps its own route.

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
	var coil := nodes[&"rope"] as Part
	hands.hold(coil)
	await physics_frames(4)
	check(hands.held is RopeTip and hands.held.get_meta(&"arrival_uid", &"") == &"rope", "taking the coil transfers its single material identity to the original end")
	hands.drop()
	await physics_frames(4)
	coil = SurveyorRecovery.named(world).get(&"rope") as Part
	check(is_instance_valid(coil) and coil.get_meta(&"catalog") == &"coil", "ordinary dropping before attachment returns that identity to its coil")
	if not is_instance_valid(coil):
		return
	hands.hold(coil)
	await physics_frames(4)
	var first := hands.held as Part
	var line := first.get_meta(&"line") as Line
	var deck := ship.pod.deck
	for pair: Array in [[&"floor_a", -0.3], [&"floor_b", 0.3]]:
		Stick.put(deck, ship.pod_parts[pair[0]], Chassis.TOP, Vector2(pair[1], 0), 0.0, Catalog.part(&"hook"))
	var near := deck.free_tie(ship.global_transform * ship.pod_pose * Vector3(-0.3, 0.1, 0))
	deck.fit(hands.stow(), near)
	await physics_frames(3)
	check(not PreflightCargo.loaded(world, ship).has(&"rope"), "a line still connected to the player's hand is not cargo")
	var far := deck.free_tie(ship.global_transform * ship.pod_pose * Vector3(1.3, 0.1, 0))
	deck.fit(hands.stow(), far)
	await physics_frames(3)
	check(PreflightCargo.loaded(world, ship).has(&"rope"), "the fully fitted original line counts as actual pod cargo")
	var guide := Catalog.part(&"hook") as RopeHook
	Stick.put(deck, ship.pod_parts[&"floor_a"], Chassis.TOP, Vector2(-0.35, 0.3), 0.0, guide)
	check(line.route(guide.guide) == "", "the real line passes through its real fairlead")
	var rope := line.rope
	var length := rope.length
	var full := line.full
	var through := rope.through
	var ends := line.ends.duplicate()
	state = PreflightCargo.seal(world, ship, state, {"id": &"shallow", "extra_survival": 1.0,
		"outer_survival": 1.0, "frame_survival": 1.0, "device_durability": Vector2.ONE, "chassis_durability": Vector2.ONE})
	check(not state.is_empty(), "the actual line and emergency stores seal")
	if not state.is_empty():
		var landed := PreflightCargo.land(world, state)
		check(state.get("materialized", false) and landed.get(&"rope") == first and line.rope == rope
			and line.ends == ends and rope.length == length and line.full == full and rope.through == through,
			"landing preserves both original endpoints, line length and fairlead without a replacement")
	check(get_node(^"/root/Saves").save(world) and await resume(), "the physically loaded original rope saves to disk")
	var restored := SurveyorRecovery.named(world).get(&"rope") as Part
	var resumed := restored.get_meta(&"line") as Line if is_instance_valid(restored) else null
	check(is_instance_valid(resumed) and resumed.state == Line.State.LAID and resumed.full == full
		and resumed.rope.length == length and is_instance_valid(resumed.rope.through)
		and resumed.ends.has(restored), "disk restore preserves the actual line identity, lengths and physical route")
	wind.override = Callable()
	remove_child(world)
	world.queue_free()
	await physics_frames(4)
