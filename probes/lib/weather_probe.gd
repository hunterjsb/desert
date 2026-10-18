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


## Stands you where the anomaly scenario does, the clock stopped, with its
## camp built for wind dropped: {camp, start, before, half, heart}, the
## scenario's moment, the last at or before it with no hidden term where you
## stand, the first after it when the term reaches a half, and a minute into
## its full; {} if there's none.
func meet_anomaly() -> Dictionary:
	var scenario := Scenarios.by_key("anomaly")
	var place := Scenarios.find(world, scenario)
	check(not place.is_empty(), "an anomaly to meet")
	if place.is_empty():
		return {}
	Scenarios.stand(world, scenario, place)
	world.player.set_physics_process(false)
	world.time_warp = 0.0
	await settle(true)
	var camp := Scenarios.anomaly_camp(world)
	await physics_frames(30)
	var met := {"camp": camp, "start": place.time, "before": place.time}
	while field.anomaly_at(place.x, place.z, met.before) > 0.0:
		met.before -= 10.0
	var t: float = place.time
	while t < place.time + 900.0 and not met.has("heart"):
		var deep := field.anomaly_at(place.x, place.z, t)
		if deep >= 0.5 and not met.has("half"):
			met["half"] = t
		if deep >= 1.0:
			met["heart"] = t + 60.0
		t += 1.0
	check(met.has("heart"), "its heart comes over")
	return met

