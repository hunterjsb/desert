extends WeatherProbe
## Wind & storms probe 4: the wall stands where the field says. The renderer
## draws every storm from the storm map, so: the map holds the field's own
## values, its fronts land on the field's fronts in every direction to within
## a fifth of a map cell (the billows then bulge the face on purpose), and the
## shader is told where the map is after an origin shift.

const RAYS := 36
const FINE := 5.0


func run() -> void:
	await load_weather()
	var start := find_time(func(t: float) -> bool: return player_storm_at(t) == 0.0 and _fronts_seen(t) >= 8)
	world.time = start
	world.time_warp = 0.0
	await physics_frames(3)
	var map := world.weather.map
	check(map.ready, "the storm map is ready")

	# At its own grid points and first moment, the map is the field.
	var drift := field.drift_at(map.t0)
	var worst_value := 0.0
	for k in 200:
		var x := map.origin_x + randi_range(1, map.size - 2) * map.cell + drift.x
		var z := map.origin_z + randi_range(1, map.size - 2) * map.cell + drift.y
		worst_value = maxf(worst_value, absf(map.raw_at(x, z, map.t0) - field.raw_storm_at(x, z, map.t0)))
	check(worst_value < 1.0e-5, "the map holds the field's values (worst %.7f)" % worst_value)

	# Between them, its fronts land on the field's.
	var tolerance := map.cell / 5.0
	var px := world.player_world_x()
	var pz := world.player_world_z()
	var t := world.time
	var fronts := 0
	var worst_front := 0.0
	for i in RAYS:
		var dir := Vector2.from_angle(TAU * i / RAYS)
		var truth := _first(px, pz, dir, func(x: float, z: float) -> bool: return field.raw_storm_at(x, z, t) > 0.0)
		var drawn := _first(px, pz, dir, func(x: float, z: float) -> bool: return map.raw_at(x, z, t) > 0.0)
		if truth == INF and drawn == INF:
			continue
		fronts += 1
		worst_front = maxf(worst_front, absf(drawn - truth))
	print("%d of %d rays see a front; worst %.1f m off (tolerance %.0f m)" % [fronts, RAYS, worst_front, tolerance])
	check(fronts >= 8, "fronts in many directions (%d)" % fronts)
	check(worst_front <= tolerance, "the map's fronts land on the field's (worst %.1f m)" % worst_front)

	# The shader locates the map from the engine origin, so a shift must reach
	# it before the next frame is drawn: _process runs after physics, before drawing.
	world.shift_origin(Vector2i(3, -2))
	await get_tree().process_frame
	await get_tree().process_frame
	var told: Vector2 = world.weather.face.material.get_shader_parameter("storm_air")
	var truth_air := Vector2(world.world_x(0.0), world.world_z(0.0)) - field.drift_at(world.time)
	check(told.distance_to(truth_air) < 0.5, "the shader knows where the map is after a shift (%.2f m off)"
		% told.distance_to(truth_air))


## How many of 16 directions see a front within reach at time t.
func _fronts_seen(t: float) -> int:
	var x := world.player_world_x()
	var z := world.player_world_z()
	var seen := 0
	for i in 16:
		var dir := Vector2.from_angle(TAU * i / 16.0)
		var d := 200.0
		while d < 4000.0:
			if field.raw_storm_at(x + dir.x * d, z + dir.y * d, t) > 0.0:
				seen += 1
				break
			d += 200.0
	return seen


## Metres along dir to where stormy first holds, within 4 km; INF if never.
func _first(x: float, z: float, dir: Vector2, stormy: Callable) -> float:
	var d := 0.0
	while d <= 4000.0:
		if stormy.call(x + dir.x * d, z + dir.y * d):
			return d
		d += FINE
	return INF
