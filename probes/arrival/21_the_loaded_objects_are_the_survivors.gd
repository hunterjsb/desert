extends SailProbe
## Descended cargo is the same selected real bodies, preserving stores and fittings.

func run() -> void:
	await load_sailing()
	world.time_warp = 0.0
	var ship := SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, player_at() + Vector3.UP * 60.0))
	var landing := Vector2(world.world_x(open.x), world.world_z(open.z))
	var state := {"phase": &"preflight", "preflight": {"version": 1, "launched": false},
		"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude),
		"landing_world": landing, "heading": 0.0}
	var nodes := PreflightCargo.stage(world, ship, state)
	check(not nodes.is_empty(), "physical stores stage")
	if nodes.is_empty():
		return
	var board := nodes[&"board"] as Device
	Stick.put(ship.pod.deck, ship.pod_parts[&"side_back_b"], Chassis.TOP, Vector2.ZERO, PI * 0.5, board)
	var selected := PreflightCargo.loaded(world, ship)
	print("LOADED_BOARD ", selected, " bounds", PreflightCargo.bounds_in(board, ship.global_transform))
	check(selected.has(&"board") and selected.has(&"board_cell"), "the actual bounded external board includes its fitted original cell")
	var water := nodes[&"water"] as Supply
	water.drain(water.amount * 0.25)
	var amount := water.amount
	var battery := nodes[&"camp_cell"] as Battery
	battery.charge_wh *= 0.5
	var charge := battery.charge_wh
	var profile := SurveyorManifest.approach(world.tuning, &"shallow").merged({"extra_survival": 1.0,
		"outer_survival": 1.0, "frame_survival": 1.0, "device_wear": Vector2.ONE, "chassis_wear": Vector2.ONE}, true)
	state = PreflightCargo.seal(world, ship, state, profile)
	check(not state.is_empty(), "ready cargo seals")
	if state.is_empty():
		return
	var original := {}
	for entry: Dictionary in state.structure + state.equipment:
		original[entry.uid] = nodes[entry.uid].get_instance_id()
	var omitted := nodes[&"guide"] as Device
	var omitted_pose := omitted.global_transform
	var landed := SurveyorRecovery.land(world, state)
	check(state.get("materialized", false) and not landed.is_empty(), "the actual selected cargo lands")
	for uid: StringName in original:
		check(is_instance_valid(landed.get(uid)) and landed[uid].get_instance_id() == original[uid], "the original %s survives without replacement" % uid)
	check(water.amount == amount and battery.charge_wh == charge, "actual partial fill and charge survive impact")
	check(board.host() != null and board.battery() == nodes[&"board_cell"], "the external board retains the same fitted cell and real mounting")
	check(omitted.global_transform == omitted_pose, "forgotten rack equipment is not moved to the surface")
	var count := world.content.get_child_count()
	check(SurveyorRecovery.land(world, state).size() == landed.size() and world.content.get_child_count() == count,
		"a repeated landing cannot duplicate bodies")
	print("LANDED selected", state.preflight.loaded_uids, " placements", state.get("placements", {}))
	wind.override = Callable()
	remove_child(world)
	world.queue_free()
	await physics_frames(4)


func player_at() -> Vector3:
	return world.player.global_position
