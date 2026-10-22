extends MenuProbe
## Exclusive
## The landed Surveyor crawls out of the original pod and stands up.
func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	await open_main(false)
	check(world.arrival_state.get("phase") == &"recovery", "the real opening lands")
	if world.arrival_state.get("phase") != &"recovery":
		return
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
