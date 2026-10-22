extends MenuProbe
## Preparing, seated and flight disk saves preserve selected real cargo without rerolling.

func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.surveyor_preflight.enabled = true
	tuning.surveyor_arrival.ejection_s = 0.3
	tuning.surveyor_arrival.landing_s = 0.3
	tuning.surveyor_preflight.profiles.standard.descent_s = 0.3
	tuning.surveyor_preflight.profiles.standard.entry_s = 0.3
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	await _prepared()
	var opening := world.arrival.preflight
	check(is_instance_valid(opening), "the new run waits in the real preparation room")
	if not is_instance_valid(opening):
		return
	var nodes := SurveyorRecovery.named(world)
	var water := nodes[&"water"] as Supply
	water.drain(water.amount * 0.25)
	var amount := water.amount
	var place := (opening.ship.global_transform * opening.ship.pod_pose).affine_inverse() * water.global_transform
	world.player.hands.hold(water)
	await physics_frames(3)
	check(main.save_run(), "partly loaded preparation saves to disk")
	await main.resume()
	world = main.world()
	await _prepared()
	opening = world.arrival.preflight
	nodes = SurveyorRecovery.named(world)
	water = nodes[&"water"]
	check(nodes.size() == 28 and world.player.hands.held == water and water.amount == amount,
		"preparation resumes the exact held store and all original roles once")
	world.player.hands.drop()
	world.teleport(water, opening.ship.global_transform * opening.ship.pod_pose * place)
	await physics_frames(3)
	world.arrival_state.preflight.plan_confirmed = true
	world.arrival_state.preflight.seated = true
	opening._seat()
	check(main.save_run(), "seated preparation saves")
	await main.resume()
	world = main.world()
	await _prepared()
	opening = world.arrival.preflight
	check(world.arrival_state.preflight.seated and world.player.ground_pose == &"prone"
		and not world.player.is_physics_processing(), "the actual seated state resumes")
	check(opening.launch(), "ready cargo launches after resume")
	var manifest: Array = world.arrival_state.equipment.duplicate(true)
	var chosen: Dictionary = world.arrival_state.preflight.profile.duplicate(true)
	check(main.save_run(), "the committed flight saves")
	await main.resume()
	world = main.world()
	check(world.arrival_state.phase == &"recovery" and world.arrival_state.equipment == manifest
		and world.arrival_state.preflight.profile == chosen, "flight resume lands the same sealed impact result")
	nodes = SurveyorRecovery.named(world)
	print("AFTER_FLIGHT roles",nodes.keys()," suit",world.player.suit.carried.map(func(body: Node) -> StringName: return body.get_meta(&"catalog")))
	check(not nodes.has(&"board") and not nodes.has(&"guide") and world.player.suit.carried.is_empty(),
		"unloaded rack gear and the old kit never appear on the surface")
	check(nodes.has(&"water") and nodes[&"water"].amount == amount, "the actual partial water store survives")
	var count := nodes.size()
	check(main.save_run(), "landed cargo saves")
	await main.resume()
	world = main.world()
	check(SurveyorRecovery.named(world).size() == count and world.arrival_state.equipment == manifest,
		"landed disk resume neither duplicates nor rerolls cargo")


func _prepared() -> void:
	var until := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < until:
		if world.arrival != null and is_instance_valid(world.arrival.preflight) and world.arrival_state.preflight.get("staged", false):
			return
		await get_tree().physics_frame
	check(false, "preparation initializes")
