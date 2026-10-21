extends MenuProbe
## A joined lid and missing stores are actionable before seating; contact noise is not cargo loss.
func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.surveyor_preflight.enabled = true
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	for i in 1800:
		if world.arrival != null and is_instance_valid(world.arrival.preflight):
			break
		await get_tree().physics_frame
	await physics_frames(5)
	var prep := world.arrival.preflight
	var target := prep.ship.pod_entry_at.global_position + Vector3.UP * 0.5
	world.teleport(world.player, Transform3D(Basis.IDENTITY, prep.ship.pod_entry_at.global_position + Vector3(0, 0, 0.6)))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(target)
	check(not world.arrival_state.preflight.seated and prep.hint().contains(prep.readiness()[0]), "the pod exposes a missing confirmed course before seating")
	world.arrival_state.preflight.plan_confirmed = true
	var nodes := SurveyorRecovery.named(world)
	var food := nodes[&"food"] as RigidBody3D
	var pose := food.global_transform
	food.freeze = true
	world.teleport(food, pose.translated(Vector3.DOWN * 0.00002))
	check(PreflightCargo.loaded(world, prep.ship).has(&"food"), "observed twenty-micrometre native floor settlement retains the real ration")
	world.teleport(food, pose.translated(Vector3.DOWN * 0.001))
	check(not PreflightCargo.loaded(world, prep.ship).has(&"food"), "a millimetre outside the physical envelope is refused")
	var rear := nodes[&"roof_b"] as Chassis
	var hatch := nodes[&"hatch"] as Chassis
	rear.join(hatch, rear.ring_to(rear.global_position + rear.global_basis.x * Chassis.WIDTH))
	var before := world.arrival_state.duplicate(true)
	var missing := prep.readiness()
	check(missing.size() >= 2 and Array(missing).any(func(reason: String) -> bool: return reason.contains("rear roof")) and Array(missing).any(func(reason: String) -> bool: return reason.contains("food")), "joined rear roof and unloaded ration are reported together with actionable names")
	check(Array(missing).all(func(reason: String) -> bool: return prep.hint().contains(reason)), "the approach hint exposes every current launch blocker before entry")
	check(world.arrival_state == before and hatch.deck == rear, "reading blockers never edits the manifest or unjoins the real panel")
	rear.detach(hatch)
	world.teleport(food, pose)
	check(prep.readiness().is_empty(), "ordinary separation and returning the same ration restores readiness")
