extends ArrivalSaveProbe
## A mid-flight save preserves the resolved opening without waiting for nonexistent cargo.
func run() -> void:
	await prepare_arrival()
	world.arrival_state.merge({"phase": &"entry", "elapsed": 4.25, "progress": 0.62, "materialized": false,
		"heading": 0.4, "landing_world": world.spawn}, true)
	var expected := world.arrival_state.duplicate(true)
	var snapshot := Snapshot.take(world)
	world.arrival_state.equipment[0].state.fill_fraction = 0.01
	check(snapshot.arrival.equipment == expected.equipment, "taking a snapshot copies the nested resolved survivors")
	world.arrival_state = expected.duplicate(true)
	check(saves.save(world), "mid-flight state saved")
	check(await resume_arrival(), "mid-flight state resumed")
	check(world.arrival_enabled and world.arrival_state == expected and world.arrival_nodes.is_empty(),
		"phase, elapsed time, landing and exact survivors return without a physical pod")
	check(Snapshot.take(world).things.is_empty() and not world.arrival_state.materialized,
		"no replacement equipment is materialized by restoration")
	check(observer.restores == 1 and not observer.restored_under_guard and not world.has_meta(&"arrival_restoring"),
		"the controller resumes once after ordinary reconstruction completes")
