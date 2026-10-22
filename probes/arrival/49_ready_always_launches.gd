extends MenuProbe
## "Ready" always launches; until then the first thing actually in the way is named in one
## line: the unset pulse, a store left out, a landing the turning moon has carried off.

func run() -> void:
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = false
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var prep := await cabin()
	if prep == null:
		return
	await physics_frames(5)
	_at_pod(prep)
	await physics_frames(2)
	check(not prep.readiness().is_empty() and _one_line(prep), "an unset pulse is named before boarding")
	await set_pulse(prep)
	await _judged()
	check(prep.readiness().is_empty(), "the set pulse and staged stores read ready")
	var food := world.arrival_nodes[&"food"] as RigidBody3D
	var packed := food.global_transform
	world.teleport(food, prep.ship.spawn_at.global_transform.translated(Vector3.UP * 0.3))
	_at_pod(prep)
	await _judged()
	check(not prep.readiness().is_empty() and _one_line(prep), "a store left out is named before boarding")
	world.teleport(food, packed)
	await _judged()
	var start := prep.clock()
	var drifted := _rough_moment(prep, start)
	check(drifted > start, "the turning moon carries the landing onto rough ground some time")
	_at_pod(prep)
	await physics_frames(2)
	press(&"interact")
	await physics_frames(1)
	check(world.arrival_state.preflight.seated, "the pod is boarded")
	if drifted > start:
		world.arrival_state.preflight.departure_time = drifted
		prep.refresh_forecast()
		var missing := prep.readiness()
		press(&"interact")
		await physics_frames(1)
		check(not missing.is_empty() and world.arrival_state.phase == &"preflight" and world.player.hands.notice == missing[0],
			"a drifted landing refuses launch with the blocker it showed")
		world.arrival_state.preflight.departure_time = start
		prep.refresh_forecast()
	check(prep.readiness().is_empty(), "back on clear ground it reads ready")
	press(&"interact")
	await physics_frames(1)
	check(world.arrival_state.phase == &"ejection", "ready launches")


## Readiness is judged with each forecast.
func _judged() -> void:
	await physics_frames(ceili(world.tuning.arrival_forecast_s * Engine.physics_ticks_per_second) + 2)


func _at_pod(prep: SurveyorPreflight) -> void:
	stand(prep.ship.pod_entry_at.global_position + Vector3(0, 0, 0.6), prep.ship.pod_entry_at.global_position + Vector3.UP * 0.5)


func _one_line(prep: SurveyorPreflight) -> bool:
	var hint := prep.hint()
	return hint.contains(prep.readiness()[0]) and not hint.contains("\n")


## A later launch moment whose forecast is unsafe, within one loiter cycle.
func _rough_moment(prep: SurveyorPreflight, from: float) -> float:
	var plan: Dictionary = world.arrival_state.landing_plan
	for k in range(1, 400):
		var at := from + k * 30.0
		if not DepartureTrajectory.resolve(world.shape, plan, prep.model(), at, world.tuning).safe:
			return at
	return from
