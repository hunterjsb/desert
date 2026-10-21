extends MenuProbe
## Runs alone
## Mid-impact disk resume retains the seated eye and remaining original flight.
var _resume_done := false

func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.surveyor_preflight.enabled = true
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var deadline := Time.get_ticks_msec() + 60000
	while (world.arrival == null or not is_instance_valid(world.arrival.preflight)) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(world.arrival != null and is_instance_valid(world.arrival.preflight), "the actual ship becomes ready")
	if world.arrival == null or not is_instance_valid(world.arrival.preflight):
		return
	await physics_frames(5)
	await get_tree().process_frame
	check(world.player.feel.is_processing(), "ordinary walking starts with the real presentation active")
	var prep := world.arrival.preflight
	_stand(Vector3(prep.ship.computer_at.global_position.x, prep.ship.global_position.y + 0.02,
		prep.ship.computer_at.global_position.z + 0.9), prep.ship.computer_at.global_position)
	await physics_frames(2)
	press(&"interact")
	await get_tree().create_timer(0.6).timeout
	check(prep.computer_open(), "the actual physical display takes focus")
	if not prep.computer_open():
		return
	prep.computer.ui._confirm.pressed.emit()
	press(&"ui_cancel")
	await get_tree().create_timer(0.6).timeout
	_stand(prep.ship.pod_entry_at.global_position + Vector3(0, 0, 0.6),
		prep.ship.pod_entry_at.global_position + Vector3.UP * 0.5)
	await physics_frames(2)
	press(&"interact")
	await get_tree().process_frame
	check(world.arrival_state.preflight.seated and not world.player.feel.is_processing(),
		"seating suspends the real camera driver")
	press(&"interact")
	check(world.arrival_state.phase == &"ejection", "the physical seat launches the committed course")
	if world.arrival_state.phase != &"ejection":
		return
	var flight: Dictionary = world.arrival_state.preflight.flight_sample.duplicate(true)
	var equipment: Array = world.arrival_state.equipment.duplicate(true)
	var departure := float(world.arrival_state.preflight.departure_time)
	deadline = Time.get_ticks_msec() + 60000
	while (world.arrival_state.phase != &"landing" or float(world.arrival_state.elapsed) < 0.09) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(world.arrival_state.phase == &"landing" and float(world.arrival_state.elapsed) < tuning.surveyor_arrival.impact_jolt_s,
		"the save boundary is the actual mid-impact recoil")
	if world.arrival_state.phase != &"landing":
		return
	var before := world.arrival._view as ArrivalView
	check(not world.player.feel.is_processing() and before._effects.camera_offset.length() > 0.001,
		"normal rendering presents the recoil without the ordinary camera overwriting it")
	var roles := SurveyorRecovery.named(world).keys()
	roles.sort()
	check(main.save_run(), "mid-impact saves through the real disk store")
	var disk: Dictionary = saves().held()
	check(disk.arrival.phase == &"landing" and disk.arrival.materialized,
		"disk contains the already materialized impact")
	var saved_elapsed := float(disk.arrival.elapsed)
	var old := world
	_resume()
	deadline = Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < deadline:
		world = main.world()
		if world != null and world != old and world.arrival_state.get("phase") == &"landing" \
				and not world.get_meta(&"arrival_restoring", false) and is_instance_valid(world.arrival._view):
			break
		await get_tree().process_frame
	check(world != old and world.arrival_state.get("phase") == &"landing", "resume restores the impact before recovery")
	if world == old or world.arrival_state.get("phase") != &"landing":
		return
	var restored := world.arrival._view as ArrivalView
	check(float(world.arrival_state.elapsed) >= saved_elapsed and not restored._voice.playing,
		"restore continues saved impact time without replaying impact audio")
	check(world.arrival_state.preflight.flight_sample == flight and world.arrival_state.equipment == equipment
		and float(world.arrival_state.preflight.departure_time) == departure,
		"resume retains the sealed manifest, exact timed path and launch clock")
	var resumed_roles := SurveyorRecovery.named(world).keys()
	resumed_roles.sort()
	check(resumed_roles == roles, "every original surviving gear role returns once")
	restored.present(world.arrival_state)
	var pose := world.player.camera.transform
	restored.present(world.arrival_state)
	check(world.player.camera.transform.is_equal_approx(pose), "presenting the saved impact twice never accumulates recoil")
	var floor := world.arrival_nodes[&"floor_a"] as Chassis
	var deck := floor.deck if floor.deck != null else floor
	var seat := deck.global_transform * floor.pose() * PodShell.seat_pose()
	check(world.player.global_position.distance_to(seat.origin) < 0.001 and world.player.ground_pose == &"prone",
		"disk resume keeps the player in the actual pod seat")
	var base := Transform3D(Basis(Vector3.RIGHT, 0.1), Vector3(0, float(tuning.surveyor_preflight.seat_eye_m), 0))
	var recoil := Transform3D(Basis.from_euler(restored._effects.camera_rotation), restored._effects.camera_offset)
	check(world.player.camera.transform.is_equal_approx(base * recoil), "the restored eye has exactly one current recoil over the seated base")
	check(not world.player.feel.is_processing(), "restored impact retains exclusive control of the eye")
	deadline = Time.get_ticks_msec() + 60000
	while not _resume_done and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(_resume_done and world.arrival_state.phase == &"recovery", "resume finishes the same arrival")
	await physics_frames(2)
	check(world.player.feel.is_processing() and world.player.global_position.distance_to(seat.origin) < 0.1,
		"recovery restores normal camera control without an outside teleport")

func _resume() -> void:
	await main.resume()
	_resume_done = true

func _stand(at: Vector3, toward: Vector3) -> void:
	world.teleport(world.player, Transform3D(Basis.IDENTITY, at))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(toward)
