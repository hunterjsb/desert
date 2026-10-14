extends WeatherProbe
## Wind & storms probe 4: in every direction, the curtain stands where the
## storm field crosses its threshold, checked against a fine march of the field
## itself, and the drawn mesh stands on exactly those points, through an
## origin shift too.

const FINE := 5.0


func run() -> void:
	await load_weather()
	var wall := world.weather.wall
	var start := find_time(func(t: float) -> bool: return player_storm_at(t) == 0.0 and _fronts_seen(t) >= 8)
	world.time = start
	var sweep := ceili(float(wall.distances.size()) / Tuning.current().wall_directions_per_frame)
	await physics_frames(sweep * 2)
	_check_rays(wall)
	_check_mesh(wall, "before a shift")
	world.shift_origin(Vector2i(3, -2))
	await get_tree().physics_frame
	_check_mesh(wall, "after a shift")


## How many of 16 directions see a front within reach at time t.
func _fronts_seen(t: float) -> int:
	var x := world.player_world_x()
	var z := world.player_world_z()
	var seen := 0
	for i in 16:
		var dir := Vector2.from_angle(TAU * i / 16.0)
		var d := 200.0
		while d < Tuning.current().wall_reach:
			if field.raw_storm_at(x + dir.x * d, z + dir.y * d, t) > 0.0:
				seen += 1
				break
			d += 200.0
	return seen


func _check_rays(wall: StormWall) -> void:
	var reach := Tuning.current().wall_reach
	var fronts := 0
	var wrong := 0
	for i in wall.distances.size():
		var x := wall.origins_x[i]
		var z := wall.origins_z[i]
		var t := wall.cast_at[i]
		var dir := wall.ray(i)
		var first := -1.0
		var d := 0.0
		while d <= reach:
			if field.raw_storm_at(x + dir.x * d, z + dir.y * d, t) > 0.0:
				first = d
				break
			d += FINE
		var said := wall.distances[i]
		if said > 0.0:
			fronts += 1
		var agrees := (said < 0.0 and first < 0.0) or (said >= 0.0 and first >= 0.0 and absf(said - first) <= FINE)
		if not agrees:
			wrong += 1
			printerr("ray %d: wall says %.1f m, field says %.1f m" % [i, said, first])
	print("%d of %d rays see a front" % [fronts, wall.distances.size()])
	check(fronts >= 8, "the wall sees fronts in many directions (%d)" % fronts)
	check(wrong == 0, "every ray's front is where the field crosses (%d wrong)" % wrong)


func _check_mesh(wall: StormWall, when: String) -> void:
	check(wall.mesh != null, "the wall is drawn %s" % when)
	if wall.mesh == null:
		return
	var arrays := wall.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var fronts: Array[Vector2] = []
	for i in wall.distances.size():
		if wall.distances[i] > 0.0:
			fronts.append(wall.front_point(i))
	var stray := 0
	for v in vertices.size():
		if uvs[v].y != 0.0:
			continue
		var at := Vector2(world.world_x(vertices[v].x), world.world_z(vertices[v].z))
		if not fronts.any(func(f: Vector2) -> bool: return f.distance_to(at) < 0.01):
			stray += 1
	check(stray == 0, "every foot of the curtain stands on a front %s (%d stray)" % [when, stray])
