extends MovementProbe
## The actual player walks on the ship floor, stops at its sealed window,
## and crawls through the open PodShell head onto its real chassis floor.

func run() -> void:
	await load_moving()
	world.time_warp = 0.0
	var ship := SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, player.global_position + Vector3.UP * 60.0))
	player.global_position = ship.spawn_at.global_position
	player.velocity = Vector3.ZERO
	face(Vector2(0, -1))
	await simulate(0.5)
	var start := ship.to_local(player.global_position)
	hold(["move_forward"])
	await simulate(4.0)
	hold([])
	var at := ship.to_local(player.global_position)
	print("SHIP_WALK start%s end%s" % [start, at])
	check(at.z < start.z - 4.0 and at.z > -4.85 and absf(at.y) < 0.08 and player.is_on_floor(),
		"the normal player crosses the floor and stops at the sealed window")
	player.global_position = ship.pod_entry_at.global_position
	player.restore_ground_pose(&"prone")
	player.velocity = Vector3.ZERO
	face(Vector2(0, -1))
	await simulate(0.25)
	hold(["move_forward"])
	await simulate(3.0)
	hold([])
	at = ship.to_local(player.global_position)
	print("SHIP_POD feet%s" % at)
	check(at.z < 0.3 and at.z > -1.3 and at.y > 0.20 and at.y < 0.38 and player.is_on_floor(),
		"the real prone capsule crawls up the berth ramp into the open pod")
	check(ship.pod.deck.get_parent() == world.content and ship.pod.named.size() == 12,
		"the exact capsule parts remain normal saveable content")
	for role in [&"roof_a", &"roof_b", &"hatch"]:
		var panel := ship.pod_parts[role] as Chassis
		check(panel.deck == null and panel.get_parent() == world.content and panel.freeze,
			"the %s remains a real retained panel" % role)
	var deck := ship.pod.deck
	ship.queue_free()
	await physics_frames(2)
	check(is_instance_valid(deck) and deck.is_inside_tree(), "disposing the cabin preserves its physical capsule")
