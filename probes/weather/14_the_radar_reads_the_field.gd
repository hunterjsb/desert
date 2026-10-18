extends WeatherProbe
## Wind & storms probe 14: the radar reads the field. A Console with a radar
## stands in the clear with a front a few kilometres off, the clock stopped.
## Once it has swept round, the front it reports is the field's: as near as
## the nearest stormy ground in every direction, and that way. Inside a
## storm, it says so.

## Searched every degree, every few metres.
const STEP := 5.0
## Its sweep looks every 10°, so a front between two bearings reads a little farther.
const SLACK := 0.01


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	world.time_warp = 0.0
	var made := Scenarios.standing(world, &"console", [&"battery", &"radar"], [0.0, 2.0]) as Console
	made.freeze = true
	var x := world.world_x(made.global_position.x)
	var z := world.world_z(made.global_position.z)
	world.time = find_time(func(t: float) -> bool:
		var near := _nearest(x, z, t, 100.0)
		return near.x > 1500.0 and near.x < 4000.0)
	await physics_frames(60)
	var front: Dictionary = made.readings.get("front", {})
	var truth := _nearest(x, z, world.time, STEP)
	print("radar: %.0f m at %.0f°; the field: %.0f m at %.0f°" % [front.get("d", INF), front.get("bearing", NAN), truth.x, truth.y])
	check(not front.is_empty() and not front.inside, "it reads a front, from the clear")
	check(absf(front.get("d", INF) - truth.x) <= truth.x * SLACK + STEP,
		"as near as the field's nearest storm (%.0f m, the field %.0f m)" % [front.get("d", INF), truth.x])
	check(absf(angle_difference(deg_to_rad(front.get("bearing", 0.0)), deg_to_rad(truth.y))) <= deg_to_rad(10.0),
		"and that way (%.0f°, the field %.0f°)" % [front.get("bearing", NAN), truth.y])

	world.time = find_time(func(t: float) -> bool: return field.raw_storm_at(x, z, t) > 0.05, world.time)
	await physics_frames(60)
	check(made.readings.get("front", {}).get("inside", false), "inside a storm, it says so")


## The nearest stormy ground to a place, every degree out to 6 km: [m, bearing°].
func _nearest(x: float, z: float, t: float, step: float) -> Vector2:
	var best := Vector2(INF, NAN)
	for degree in 360:
		var along := Vector2(sin(deg_to_rad(degree)), -cos(deg_to_rad(degree)))
		var d := step
		while d < minf(best.x, 6000.0):
			if field.raw_storm_at(x + along.x * d, z + along.y * d, t) > 0.0:
				best = Vector2(d, degree)
				break
			d += step
	return best
