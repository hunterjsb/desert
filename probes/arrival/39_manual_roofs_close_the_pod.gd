extends MovementProbe
## Identical retained roofs fit either frame; wrong attachments explain the real mount.

func run() -> void:
	await load_moving()
	world.time_warp = 0.0
	var ship := SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, player.global_position + Vector3.UP * 60.0))
	player.set_physics_process(false)
	world.teleport(player, ship.global_transform.translated(Vector3(1.4, 0.02, 1.7)))
	var state := {"phase": &"preflight", "preflight": {"version": 1, "launched": false},
		"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude)}
	var nodes := PreflightCargo.stage(world, ship, state)
	var deck := ship.pod.deck
	var front := nodes[&"roof_a"] as Chassis
	var rear := nodes[&"roof_b"] as Chassis
	var front_face := Rig.face_of(deck, Vector2i.ZERO, &"top")
	var rear_face := Rig.face_of(deck, Vector2i(1, 0), &"top")
	var blocker := Catalog.device(&"chassis") as Chassis
	deck.join(blocker, front_face)
	check(not PreflightCargo.readiness(world, ship).is_empty()
		and PreflightCargo.seal(world, ship, state, {"id": &"standard"}).is_empty(),
		"two loose roofs cannot both claim the one opening left by a foreign panel")
	deck.detach(blocker)
	blocker.queue_free()

	await physics_frames(2)
	await _place(ship, front, rear_face)
	check(front.deck == deck and front.joined_at == rear_face, "ordinary hands place the original front roof on the rear frame")
	check(PreflightCargo.readiness(world, ship).is_empty(), "one manually fitted roof on either frame leaves a valid free face for the loose roof")
	await _place(ship, rear, front_face)
	check(rear.deck == deck and rear.joined_at == front_face, "ordinary hands close the remaining roof face with the other original panel")
	check(PreflightCargo.readiness(world, ship).is_empty(), "both manually installed original roofs are launch-ready")
	var before := [PreflightCargo.body_pose(front), PreflightCargo.body_pose(rear)]
	var sealed := PreflightCargo.seal(world, ship, state, {"id": &"standard"})
	check(not sealed.is_empty() and sealed.preflight.launched, "the manually roofed original pod seals and launches")
	check(front.joined_at == rear_face and rear.joined_at == front_face \
		and before == [PreflightCargo.body_pose(front), PreflightCargo.body_pose(rear)] \
		and front.get_meta(&"arrival_uid") == &"roof_a" and rear.get_meta(&"arrival_uid") == &"roof_b",
		"sealing preserves original panel identities and manually fitted poses")
	deck.detach(rear)
	world.teleport(rear, ship.global_transform * Transform3D(Basis.IDENTITY, Vector3(-0.65, 0.66, 2.7)))
	var partial := PreflightCargo.seal(world, ship, state, {"id": &"standard"})
	check(not partial.is_empty() and rear.joined_at == front_face and front.joined_at == rear_face,
		"automatic closing uses the remaining free face without moving a fitted roof")
	deck.detach(front)
	if nodes[&"hatch"].deck == deck:
		deck.detach(nodes[&"hatch"])
	var hatch_face := Rig.face_of(deck, Vector2i.ZERO, &"left")
	deck.join(front, hatch_face)
	var wrong_pose := PreflightCargo.body_pose(front)
	var missing := PreflightCargo.readiness(world, ship)
	check(not missing.is_empty() and missing[0].contains("front frame") and missing[0].contains("left") \
		and missing[0].contains("top"), "a roof on the hatch names its actual frame/face and the required roof location")
	check(PreflightCargo.seal(world, ship, state, {"id": &"standard"}).is_empty() \
		and front.joined_at == hatch_face and PreflightCargo.body_pose(front) == wrong_pose,
		"wrong-location refusal never moves the roof")
	deck.detach(front)
	var other := Rig.build(world.content, [[&"frame", Vector2i.ZERO]])
	other.deck.join(front, Rig.face_of(other.deck, Vector2i.ZERO, &"top"))
	missing = PreflightCargo.readiness(world, ship)
	check(not missing.is_empty() and missing[0].contains("another chassis") and missing[0].contains("top"),
		"a roof on another craft names the actual host and where to refit it")
	if wind != null:
		wind.override = Callable()
	remove_child(world)
	world.queue_free()
	await physics_frames(4)

func _place(ship: SurveyorShip, roof: Chassis, face: Socket) -> void:
	var pose := ship.pod.deck.global_transform * face.transform * Frame.piece_seat()
	world.teleport(roof, pose.translated(Vector3.UP * 0.12))
	roof.freeze = true
	player.hands.grasp.take(roof)
	player.hands._find_stand(1.0)
	check(player.hands.stand == face, "ordinary placement preview selects the nearby open roof face")
	player.hands.grab()
	await physics_frames(2)
