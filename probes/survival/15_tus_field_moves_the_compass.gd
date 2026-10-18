extends WeatherProbe
## Survival probe 15: Tu's field moves the compass. Lying flat and still in
## clear air through one turn of Tu, its needle sways with the turn, east of
## north as Tu's tipped field swings one way and west as it swings back, and
## never past the sway's bound. Spun half round in half a second, it's dragged
## along, then swings back slowly rather than snapping, and settles. Off old
## volcanic ground, the ground's own magnetism leaves it be.

## Steps of world time it's read in, s.
const STEP := 1.0 / 60.0


func run() -> void:
	await load_weather()
	world.time_warp = 0.0
	world.player.set_physics_process(false)
	var x := world.player_world_x()
	var z := world.player_world_z()
	var day := world.weather.day
	var turn := world.tuning.day_minutes * 60.0 / day.tu_turns()
	world.time = find_time(func(t: float) -> bool: return (field.storm_at(x, z, t) == 0.0
		and field.storm_at(x, z, t + turn + 30.0) == 0.0))
	var compass := Catalog.part(&"compass") as Compass
	world.content.add_child(compass)
	compass.freeze = true
	var face := Basis(Vector3.RIGHT, -PI / 2.0)
	compass.global_transform = Transform3D(face, world.player.global_position + Vector3.UP)
	var bound := world.tuning.compass_sway_degrees

	var most := 0.0
	var east := -INF
	var west := INF
	var start := world.time
	while world.time < start + turn:
		var off := _off_north(compass, face)
		most = maxf(most, absf(off))
		var phase := sin(day.tu_turn(world.time))
		if phase > 0.99:
			east = maxf(east, off)
		elif phase < -0.99:
			west = minf(west, off)
		world.time += STEP
	print("through a turn of Tu: %.1f° east at most, %.1f° west, %.1f° off at worst" % [east, -west, most])
	check(east > bound * 0.9 and west < -bound * 0.9 and most <= bound + 0.5,
		"it sways with Tu's turn, %.0f° either way and no further" % bound)

	for i in 30:
		face = Basis(Vector3.UP, PI * (i + 1) / 30.0) * Basis(Vector3.RIGHT, -PI / 2.0)
		compass.needle_on(face, world)
		world.time += STEP
	var dragged := absf(_off_field(compass, face))
	var back := INF
	var settled := INF
	var spun := world.time
	while world.time < spun + 12.0:
		var off := absf(_off_field(compass, face))
		if off < 5.0 and back == INF:
			back = world.time - spun
		if off > 1.0:
			settled = INF
		elif settled == INF:
			settled = world.time - spun
		world.time += STEP
	print("spun half round: dragged %.0f° off, back within 5° after %.2f s, settled within 1° after %.1f s"
		% [dragged, back, settled])
	check(dragged > 20.0 and back > 1.0 and settled < 10.0, "spun, it's dragged along, swings back slowly and settles")
	var ground := world.shape.sites.anchor().point_at(x, z)
	check(world.shape.history.geology.magnetized(ground) > 0.0
		or Compass.ground_deviation(world, world.player.global_position) == 0.0,
		"off old volcanic ground, the ground's own magnetism doesn't turn it")


## How far its needle points east of the moon's north, degrees.
func _off_north(compass: Compass, face: Basis) -> float:
	return rad_to_deg(angle_difference(0.0, _pointing(compass, face)))


## How far its needle points off the way Tu's field lies there and then, degrees.
func _off_field(compass: Compass, face: Basis) -> float:
	var field_way := Compass.field_bearing(world, compass.global_position, world.time)
	return rad_to_deg(angle_difference(field_way, _pointing(compass, face)))


## The needle's bearing on the ground: its case's top and its angle on the card.
func _pointing(compass: Compass, face: Basis) -> float:
	return -Compass.turn(face, Vector3.FORWARD) + compass.needle_on(face, world)
