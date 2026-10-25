extends PodProbe
## Impact must unseat doomed cargo while its doomed carrier is still in the tree.

func run() -> void:
	await load_lines(1)
	var named := board_ship()
	var panel := named[&"panel"] as Device
	var wall := ship.pod_parts[&"side_front_a"] as Chassis
	var root := ship.pod.deck
	var why := Stick.why_not(root, wall, Chassis.TOP, panel)
	check(why == "", "the real panel is allowed on the pod wall")
	if why != "":
		return
	var pose := Stick.pose_on(root, wall, Chassis.TOP, Vector2.ZERO, 0.0, panel)
	check(Stick.clear(panel, root.global_transform * pose, world.player) == "", "the packed panel clears the real pod")
	Stick.put(root, wall, Chassis.TOP, Vector2.ZERO, 0.0, panel)
	state = PreflightCargo.seal(world, ship, state, SurveyorManifest.approach(world.tuning, &"steep"))
	check(not state.is_empty(), "the real loaded pod seals")
	if state.is_empty():
		return
	for uid: StringName in [&"panel", &"side_front_a"]:
		check((state.structure + state.equipment).any(func(entry: Dictionary) -> bool: return entry.uid == uid and not entry.survives),
			"seed 1's actual impact loses the %s" % uid)
	wall.tree_exiting.connect(func() -> void:
		check(not is_instance_valid(panel) or panel.host() != wall, "lost cargo leaves its wall before the wall retires"))
	var made := SurveyorRecovery.land(world, state)
	await physics_frames(2)
	check(state.get("materialized", false) and not made.has(&"panel") and not made.has(&"side_front_a")
		and not is_instance_valid(panel) and not is_instance_valid(wall), "the seeded impact retires both lost bodies")
