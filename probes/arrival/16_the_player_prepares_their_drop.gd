extends MenuProbe
## The real fresh run waits for the player's computer choice and physical pod entry.
func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.surveyor_preflight["enabled"] = true
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var until := Time.get_ticks_msec() + 60000
	while (world.arrival == null or not is_instance_valid(world.arrival.preflight)) and Time.get_ticks_msec() < until:
		await get_tree().physics_frame
	check(world.arrival != null and is_instance_valid(world.arrival.preflight), "a fresh Surveyor run opens in the physical ship")
	if world.arrival == null or not is_instance_valid(world.arrival.preflight):
		return
	await physics_frames(5)
	var prep := world.arrival.preflight
	check(world.arrival.preparing() and world.player.is_physics_processing() and world.time_warp == 0.0,
		"preparation allows normal movement without advancing the surface clock")
	check(not prep.readiness().is_empty(), "launch waits for a deliberate landing choice")
	var pod := prep.ship.pod.deck
	var board := SurveyorRecovery.named(world).get(&"board") as RigidBody3D
	stand_at(prep.ship.pod_entry_at.global_position + Vector3(0, 0, 0.6), prep.ship.pod_entry_at.global_position + Vector3.UP * 0.5)
	await physics_frames(2)
	press(&"interact")
	check(world.arrival_state.preflight.seated and not world.player.is_physics_processing(), "use enters the actual pod seat")
	press(&"interact")
	check(world.arrival.preparing(), "use cannot bypass the missing landing plan")
	press(&"hands_grab")
	check(not world.arrival_state.preflight.seated and world.player.is_physics_processing(), "take leaves the pod and restores walking")
	stand_at(Vector3(prep.ship.computer_at.global_position.x, prep.ship.global_position.y + 0.02, prep.ship.computer_at.global_position.z + 0.9), prep.ship.computer_at.global_position)
	await physics_frames(2)
	press(&"interact")
	check(prep.computer_open(), "use focuses the persistent display through its real collider")
	if not prep.computer_open():
		return
	await get_tree().create_timer(0.6).timeout
	var computer := prep.computer.ui
	computer._confirm.pressed.emit()
	check(world.arrival_state.preflight.plan_confirmed and world.arrival_state.landing_plan.selected_id == &"launch_pulse",
		"confirming the visibly selected default makes that same course ready")
	press(&"ui_cancel")
	await get_tree().create_timer(0.6).timeout
	check(is_instance_valid(prep.computer) and not prep.computer_open() and world.player.is_physics_processing(),
		"stepping back restores walking and leaves the actual screen lit")
	check(prep.readiness().is_empty(), "the real preloaded survival stores allow launch after planning")
	stand_at(prep.ship.pod_entry_at.global_position + Vector3(0, 0, 0.6), prep.ship.pod_entry_at.global_position + Vector3.UP * 0.5)
	await physics_frames(2)
	press(&"interact")
	print("LAUNCH_READY ", prep.readiness(), " FORECAST ", prep.course_forecast().get("status"), " CLOCK ", world.arrival_state.preflight.departure_time)
	press(&"interact")
	check(not world.arrival.preparing() and world.arrival_state.phase == &"ejection", "use launches the prepared pod into the saved flight")
	check(is_instance_valid(pod) and pod.get_parent() == world.content, "launch carries the original physical pod")
	await physics_frames(2)
	check(not is_instance_valid(board), "the optional board left on the ship is not silently granted")

func stand_at(at: Vector3, toward: Vector3) -> void:
	world.teleport(world.player, Transform3D(Basis.IDENTITY, at))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(toward)
