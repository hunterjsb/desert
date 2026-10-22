extends MenuProbe
## Exclusive
## Recovery must return a capsule that can actually crawl out of the original pod.
func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	tuning.surveyor_preflight.enabled = true
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var deadline := Time.get_ticks_msec() + 60000
	while (world.arrival == null or not is_instance_valid(world.arrival.preflight)) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var prep := world.arrival.preflight
	check(is_instance_valid(prep), "the actual Surveyor preparation is ready")
	if not is_instance_valid(prep):
		return
	await physics_frames(5)
	world.arrival_state.preflight.plan_confirmed = true
	world.arrival_state.preflight.seated = true
	prep._seat()
	check(prep.launch(), "the original pod launches")
	deadline = Time.get_ticks_msec() + 60000
	while world.arrival_state.phase != &"recovery" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(world.arrival_state.phase == &"recovery", "the flight reaches actual physical recovery")
	await physics_frames(5)
	var player := world.player
	var floor := world.arrival_nodes[&"floor_a"] as Chassis
	var deck := floor.deck if floor.deck != null else floor
	var from := player.global_position
	check(player.is_physics_processing() and player.posture.clear(&"prone"), "the recovered capsule starts clear of the surviving frame")
	Input.action_press(&"move_back")
	await physics_frames(180)
	Input.action_release(&"move_back")
	check(player.global_position.distance_to(from) > 1.5, "ordinary crawling leaves the pod through its opened hatch")
	check(player.posture.change(&"stand"), "the player can stand after clearing the original pod")
