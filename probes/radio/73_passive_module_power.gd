extends ShieldProbe
## A powered counter or logger cannot run from a passive crystal set.


func run() -> void:
	await load_storm(0.0)
	await beside_god(&"quartermaster")
	var crystal := Scenarios.standing(world, &"crystal_set", [&"frequency_counter"], [0.0, 2.0]) as Radio
	crystal.freeze = true
	crystal.set_physics_process(false)
	crystal.on = true
	var carrier := Radio.gods_of(world).carrier(&"cistern", world.time)
	crystal.frequency = carrier - 6.0
	crystal.tune(1, true)
	check(crystal.frequency == snappedf(carrier - 5.0, Tuning.current().dial_fine_khz),
		"a crystal set cannot power its frequency counter")
	var logger := Scenarios.standing(world, &"crystal_set", [&"wire_logger"], [0.6, 2.0]) as Radio
	logger.freeze = true
	logger.set_physics_process(false)
	logger.on = true
	logger.frequency = Radio.gods_of(world).carrier(&"quartermaster", world.time)
	broadside(logger, &"quartermaster")
	logger._listen(0.0)
	check(not logger._lines.is_empty() and logger._reading_dirt >= Tuning.current().logger_dirty,
		"the passive set receives a real dirty transmission")
	logger._read(logger._done_at + 1.0, logger.channel)
	check(logger.played_back == 0 and logger._lines.is_empty(), "a crystal set cannot power logger playback")
	check(crystal.demand_w() == 0.0 and logger.demand_w() == 0.0, "passive sets still draw no power")
