extends MovementProbe
## Whatever survives and however hard it lands, the seat faces an open way out:
## crawling straight ahead always clears the pod, with room to stand.

func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var start := player.global_transform
	var arrival := SurveyorArrival.new()
	arrival.world = world
	world.add_child(arrival)
	var run_seed := world.run_seed
	for each in [1234, 7, 42, 2024, 9876]:
		for approach: StringName in SurveyorManifest.APPROACHES:
			world.teleport(player, start)
			player.restore_ground_pose(&"stand")
			var ship := SurveyorShip.new()
			world.add_child(ship)
			ship.setup(world, start.translated(Vector3.UP * 60.0))
			var state := {"phase": &"preflight", "preflight": {"version": 1, "launched": false},
				"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude),
				"landing_world": Vector2(world.player_world_x() + 6.0, world.player_world_z()), "heading": 0.0}
			PreflightCargo.stage(world, ship, state)
			# Survival rolls on the run's seed; the ground stays the same.
			world.run_seed = each
			state = PreflightCargo.seal(world, ship, state, SurveyorManifest.approach(world.tuning, approach))
			world.run_seed = run_seed
			var made := SurveyorRecovery.land(world, state) if not state.is_empty() else {}
			check(not made.is_empty(), "seed %d, %s: the pod lands" % [each, approach])
			if made.is_empty():
				continue
			world.arrival_nodes = made
			arrival.seat_in_pod()
			await physics_frames(2)
			var from := player.global_position
			hold(["move_forward"])
			var out := false
			for i in 10 * ticks_per_second():
				await get_tree().physics_frame
				out = player.global_position.distance_to(from) > 1.5 and player.posture.clear(&"stand")
				if out:
					break
			hold([])
			check(out and player.posture.change(&"stand"), "seed %d, %s landing: straight ahead leads out (%.2f m)"
				% [each, approach, player.global_position.distance_to(from)])
			for body: Node in SurveyorRecovery.named(world).values():
				if is_instance_valid(body) and body.get_parent() == world.content:
					body.queue_free()
			ship.queue_free()
			await physics_frames(2)
