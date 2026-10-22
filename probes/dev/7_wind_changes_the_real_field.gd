extends MenuProbe
## Dev probe 7: changing the prevailing wind keeps the storm where it is and its past as it was.


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
	check(field.drift_at(at - 600.0).distance_to(WeatherField.new(world.run_seed, world.tuning).drift_at(at - 600.0)) < 0.001,
		"the storms' past is the seed's, not rewritten by the new wind")
	console.run("wind reset")
	var generated := WeatherField.new(world.run_seed, world.tuning)
	check(field.prevailing_at(world.time + 30.0).distance_to(generated.prevailing_at(world.time + 30.0)) < 0.001,
		"reset restores the generated wind")
	check(not Snapshot.take(world).has("test_wind"), "a dev wind is never saved")
