class_name WeatherProbe
extends WorldProbe
## For probes that need the world with its weather: finds the moments they test.

var field: WeatherField


func load_weather(run_seed := 1234, salvage := false) -> void:
	await load_world(run_seed, false, salvage)
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


## Stands you `aside` m off the rift's live vent, across the rift, on fresh
## ground, its mouth laid and its plume drawn; the vent.
func beside_vent(aside: float) -> Dictionary:
	var vent: Dictionary = world.shape.history.geology.live()[0]
	var at := Sphere.toward(vent.p, vent.bearing + PI * 0.5, aside / world.shape.history.radius)
	world.travel(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)), 0.0)
	await settle()
	for i in 4:
		await get_tree().process_frame
	return vent
