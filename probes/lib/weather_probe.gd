class_name WeatherProbe
extends WorldProbe
## For probes that need the world with its weather: finds the moments they test.

var field: WeatherField


func load_weather(run_seed := 1234) -> void:
	await load_world(run_seed, false)
	field = world.weather.field


## The first run time from `from` on, in `step`s, where wanted(t) holds; NAN if
## none within two days.
func find_time(wanted: Callable, from := 0.0, step := 30.0) -> float:
	var t := from
	while t < from + 2.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += step
	check(false, "found a moment to test")
	return NAN


func player_storm_at(t: float) -> float:
	return field.storm_at(world.player_world_x(), world.player_world_z(), t)
