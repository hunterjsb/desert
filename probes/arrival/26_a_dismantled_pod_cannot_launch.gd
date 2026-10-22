extends MovementProbe
## Broken real supports and unavailable closure parts refuse without reconstruction.

func run() -> void:
	await load_moving()
	world.time_warp = 0.0
	var ship := SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, player.global_position + Vector3.UP * 60.0))
	player.set_physics_process(false)
	world.teleport(player, ship.spawn_at.global_transform)
	var state := {"phase": &"preflight", "preflight": {"version": 1, "launched": false},
		"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude)}
	var nodes := PreflightCargo.stage(world, ship, state)
	var deck := ship.pod.deck
	check(PreflightCargo.readiness(world, ship).is_empty(), "the authored shell and intentionally parked closures are ready")
	var side := nodes[&"side_front_a"] as Chassis
	var face := side.joined_at
	deck.detach(side)
	_refuses(ship, state, "a removed side panel")
	deck.join(side, face)
	check(PreflightCargo.readiness(world, ship).is_empty(), "ordinary rejoining of the original side repairs readiness")
	# Removing the actual supporting frame takes its face panels out of the deck too.
	for role: StringName in [&"side_front_b", &"side_back_b", &"tail"]:
		deck.detach(nodes[role])
	var frame := nodes[&"frame_b"] as Frame
	deck.pop(frame.socket)
	_refuses(ship, state, "a removed support frame")
	var floor := nodes[&"floor_b"] as Chassis
	var floor_ring := floor.joined_at
	deck.detach(floor)
	_refuses(ship, state, "a dismantled two-floor core")
	deck.join(floor, floor_ring, 0)
	Stick.put(deck, nodes[&"floor_b"], Chassis.TOP, Vector2.ZERO, 0.0, frame)
	for role: StringName in [&"side_front_b", &"side_back_b", &"tail"]:
		deck.join(nodes[role], frame.faces()[PodShell.PANELS[role][1]])
	check(PreflightCargo.readiness(world, ship).is_empty(), "ordinary fitting and joining of the same frame and walls repairs readiness")
	var roof := nodes[&"roof_a"] as Chassis
	var roof_pose := roof.global_transform
	player.hands.hold(roof)
	_refuses(ship, state, "a closure panel in the hand")
	await physics_frames(60)
	check(player.suit.put_in(), "the ordinary suit accepts the loose original roof")
	_refuses(ship, state, "a closure panel stored in the suit")
	var stacks := player.suit.stacks()
	for i in stacks.size():
		if stacks[i].has(roof):
			player.suit.take_out(i)
			break
	check(player.hands.held == roof, "ordinary suit retrieval returns the same roof")
	player.hands.drop()
	player.waist.tie(roof)
	_refuses(ship, state, "a closure panel carried at the waist")
	player.waist.untie(roof)
	world.teleport(roof, roof_pose)
	var other := Rig.build(world.content, [[&"frame", Vector2i.ZERO]])
	other.deck.join(roof, Rig.face_of(other.deck, Vector2i.ZERO, &"top"))
	_refuses(ship, state, "a closure panel fitted to another craft")
	other.deck.detach(roof)
	world.teleport(roof, roof_pose)
	var wrong_face := Rig.face_of(deck, Vector2i.ZERO, &"left")
	deck.join(roof, wrong_face)
	_refuses(ship, state, "an original roof on the hatch face")
	deck.detach(roof)
	world.teleport(roof, roof_pose)
	var blocker := Catalog.device(&"chassis") as Chassis
	var roof_face := Rig.face_of(deck, Vector2i.ZERO, &"top")
	deck.join(blocker, roof_face)
	_refuses(ship, state, "an occupied closure face")
	deck.detach(blocker)
	blocker.queue_free()
	deck.join(roof, Rig.face_of(deck, Vector2i.ZERO, &"top"))
	check(PreflightCargo.readiness(world, ship).is_empty(), "the same original roof already closed on its correct face is valid")
	var sealed := PreflightCargo.seal(world, ship, state, SurveyorManifest.approach(world.tuning, &"standard"))
	check(not sealed.is_empty() and sealed.preflight.launched and nodes[&"hatch"].deck == deck,
		"the repaired original shell seals normally without replacement bodies")
	if wind != null:
		wind.override = Callable()
	remove_child(world)
	world.queue_free()
	await physics_frames(4)

func _refuses(ship: SurveyorShip, state: Dictionary, why: String) -> void:
	var before := state.duplicate(true)
	var bodies := SurveyorRecovery.named(world)
	var poses := {}
	for role: StringName in bodies:
		poses[role] = PreflightCargo.body_pose(bodies[role])
	var count := world.content.get_child_count()
	var result := PreflightCargo.seal(world, ship, state, SurveyorManifest.approach(world.tuning, &"standard"))
	check(not PreflightCargo.readiness(world, ship).is_empty() and result.is_empty() and state == before,
		why + " refuses without changing arrival state")
	check(world.content.get_child_count() == count and bodies.keys().all(func(role: StringName) -> bool:
		return PreflightCargo.body_pose(bodies[role]).is_equal_approx(poses[role])),
		why + " keeps every physical body in place")
