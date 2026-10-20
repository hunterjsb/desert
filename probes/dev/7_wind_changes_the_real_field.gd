extends MenuProbe
## Dev probe 7: changing the prevailing wind preserves the storm's current position.


func run() -> void:
	await open_main(false)
	await started()
	var console := main.ui.dev_console
	var field := world.weather.field
	var at := world.time
	var drift := field.drift_at(at)
	console.run("wind 12 90")
	print("wind=", field.prevailing_at(at), " drift_gap=", field.drift_at(at).distance_to(drift), " t=", at)
	check(field.prevailing_at(at).distance_to(Vector2(-12.0, 0.0)) < 0.001
		and field.drift_at(at).distance_to(drift) < 0.001,
		"wind changes the actual prevailing field without jumping the storm")
	check(not world.counts_deeds, "changing weather marks the run as dev")
	var saved := Snapshot.take(world)
	var restored := WeatherField.new(world.run_seed, world.tuning)
	restored.restore_wind(saved.get("test_wind", {}))
	check(restored.prevailing_at(at).distance_to(field.prevailing_at(at)) < 0.001
		and restored.drift_at(at + 60.0).distance_to(field.drift_at(at + 60.0)) < 0.001,
		"the saved override restores the same wind and future drift")
	check(main.save_run(), "the changed wind saves with its dev run")
	await main.resume()
	world = main.world()
	await faded_in()
	var again := world.weather.field
	check(again.prevailing_at(world.time).distance_to(field.prevailing_at(world.time)) < 0.001
		and again.drift_at(world.time).distance_to(field.drift_at(world.time)) < 0.001,
		"resuming restores the same field wind and drift anchor")
	field = again
	var before_reset := field.drift_at(world.time)
	console.run("wind reset")
	var generated := WeatherField.new(world.run_seed, world.tuning)
	check(field.prevailing_at(world.time).distance_to(generated.prevailing_at(world.time)) < 0.001
		and field.drift_at(world.time).distance_to(before_reset) < 0.001,
		"reset restores generated wind while preserving the current storm position")
