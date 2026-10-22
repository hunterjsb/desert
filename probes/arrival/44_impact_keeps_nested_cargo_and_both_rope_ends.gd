extends SailProbe
## Clearing the exit releases assemblies whole and places the unlisted second rope end.

func run() -> void:
	await load_sailing()
	world.time_warp = 0.0
	var ship := SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3.UP * 60.0))
	world.teleport(world.player, ship.spawn_at.global_transform)
	var state := {"phase": &"preflight", "preflight": {"version": 1, "launched": false},
		"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude),
		"landing_world": Vector2(world.world_x(open.x), world.world_z(open.z)), "heading": 0.0}
	var nodes := PreflightCargo.stage(world, ship, state)
	var pod := ship.pod.deck
	var water := nodes[&"water"] as Supply
	world.teleport(water, water.global_transform.translated(pod.global_basis * Vector3(0, 0, 0.05)))
	var board := nodes[&"board"] as Device
	# Fitted ahead of the seat, across the way out the impact opens.
	Stick.put(pod, nodes[&"floor_b"], Chassis.TOP, Vector2(0.1, 0.0), 0.0, board)
	var cell := nodes[&"board_cell"] as Battery
	cell.charge_wh *= 0.5
	var charge := cell.charge_wh
	hands.hold(nodes[&"rope"])
	await physics_frames(4)
	var line := (hands.held as Part).get_meta(&"line") as Line
	var ties: Array[Socket] = []
	for pair: Array in [[&"floor_a", Vector2(-0.42, 0.0)], [&"floor_b", Vector2(-0.4, 0.25)]]:
		var hook := Catalog.part(&"hook")
		var mounted := Stick.put(pod, nodes[pair[0]], Chassis.TOP, pair[1], 0.0, hook)
		for child in mounted.fitted:
			if child is Socket and child.kind == &"tie":
				ties.append(child)
	check(ties.size() == 2, "the ordinary hooks expose both real rope fittings")
	if ties.size() != 2:
		return
	pod.fit(hands.stow(), ties[0])
	await physics_frames(3)
	pod.fit(hands.stow(), ties[1])
	await physics_frames(3)
	var ends := line.ends.duplicate()
	var rope := line.rope
	var length := rope.length
	var secondary := ends[1] as Part
	var selected := PreflightCargo.loaded(world, ship)
	check(selected.has(&"board") and selected.has(&"board_cell") and selected.has(&"rope"),
		"the real bounded board/cell assembly and both fitted ends qualify as selected cargo")
	state = PreflightCargo.seal(world, ship, state, SurveyorManifest.approach(world.tuning, &"shallow").merged({"extra_survival": 1.0, "outer_survival": 1.0, "frame_survival": 1.0, "device_wear": Vector2.ONE, "chassis_wear": Vector2.ONE}, true))
	check(not state.is_empty(), "the packed original pod seals through ordinary readiness")
	if state.is_empty():
		return
	nodes = SurveyorRecovery.named(world)
	var original := {}
	for entry: Dictionary in state.structure + state.equipment:
		original[entry.uid] = nodes[entry.uid].get_instance_id()
	var landed := SurveyorRecovery.land(world, state)
	check(state.get("materialized", false) and not landed.is_empty(), "the actual selected load reaches physical recovery")
	if landed.is_empty():
		return
	check(board.host() == null and board.battery() == cell and cell.socket != null
		and cell.socket.get_parent() == board and cell.charge_wh == charge,
		"impact releases the obstructing board whole with its same fitted charged cell")
	check(secondary.socket == null, "the actual secondary rope end is freed from the surviving pod across the exit")
	var landing_at := PreflightCargo.body_pose(landed[&"floor_a"])
	check(PreflightCargo.body_pose(secondary).origin.distance_to(landing_at.origin) < 5.0,
		"the released secondary end is physically placed beside the landed pod")
	check(ends.all(func(end: Variant) -> bool: return is_instance_valid(end)) and line.rope == rope
		and ropes.ropes.has(rope) and rope.length == length,
		"clearing the exit preserves both original ends, their rope identity and paid length")
	for uid: StringName in original:
		check(is_instance_valid(landed.get(uid)) and landed[uid].get_instance_id() == original[uid],
			"recovery preserves original cargo and structure identity: %s" % uid)
	var placements: Dictionary = state.placements.duplicate(true)
	var count := world.content.get_child_count()
	check(SurveyorRecovery.land(world, state).size() == landed.size() and state.placements == placements
		and world.content.get_child_count() == count, "repeated recovery does not release or duplicate the equipment again")
	wind.override = Callable()
	remove_child(world)
	world.queue_free()
	await physics_frames(4)
