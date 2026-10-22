extends MenuProbe
## Exclusive
## The landed Surveyor crawls straight ahead out of the original pod and stands up.
func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	await drop_in()
	check(world.arrival_state.get("phase") == &"recovery", "the real opening lands")
	if world.arrival_state.get("phase") != &"recovery":
		return
	await physics_frames(5)
	var player := world.player
	check(player.is_physics_processing() and player.posture.clear(&"prone"), "the recovered capsule starts clear of the surviving frame")
	await crawl_out()
