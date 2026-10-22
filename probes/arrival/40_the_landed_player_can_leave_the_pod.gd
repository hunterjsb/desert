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
	var worn := 0
	for view in (world.arrival_nodes[&"floor_a"] as Node).find_children("*", "GeometryInstance3D", true, false):
		var age: Variant = (view as GeometryInstance3D).get_instance_shader_parameter(&"age")
		worn += 1 if age != null and float(age) > 0.0 else 0
	check(worn > 0, "the landed pod takes the ground's wear again")
	var player := world.player
	check(player.is_physics_processing() and player.posture.clear(&"prone"), "the recovered capsule starts clear of the surviving frame")
	await crawl_out()
