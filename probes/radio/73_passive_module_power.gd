extends ShieldProbe
## A powered logger cannot run from a passive crystal set.


func run() -> void:
	await load_storm(0.0)
	await beside_god(&"quartermaster")
	var logger := Scenarios.standing(world, &"crystal_set", [&"wire_logger"], [0.6, 2.0]) as Radio
	logger.freeze = true
	logger.set_physics_process(false)
	logger.on = true
	logger.frequency = Radio.gods_of(world).carrier(&"quartermaster", world.time)
	broadside(logger, &"quartermaster")
	logger._listen(0.0)
	check(not logger._lines.is_empty(), "the passive set receives a real transmission")
	logger._read(logger._done_at * 0.5, logger.channel)
	check(logger.transcript == "", "a crystal set cannot power the logger's transcript")
	check(logger.demand_w() == 0.0, "a passive set still draws no power")
