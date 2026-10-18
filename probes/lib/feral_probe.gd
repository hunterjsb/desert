class_name FeralProbe
extends FarmProbe
## For probes of the feral layer: you stood on the moon on a path of history,
## the ground and its wild plants laid out round you.

var feral: Feral


## Stands you on the first path of a kind, a share of the way along it, on
## fresh ground, and waits for its wild plants. Returns the path.
func on_path(kind: StringName, share := 0.5) -> PathNetwork.Path:
	feral = world.farm.feral
	for path in world.shape.history.network.paths:
		if path.kind == kind:
			var at := path.at(path.length() * share)
			world.travel(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)), 0.0)
			await laid_out()
			return path
	check(false, "a %s on this seed" % kind)
	return null


## Waits for the ground round you and the wild plants on it.
func laid_out() -> void:
	await settle()
	for i in 1200:
		await get_tree().process_frame
		if feral.is_idle():
			return
	check(false, "the wild plants were laid out")


## Every wild plant laid out now, planned, as {.., coord}.
func planned() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for chunk: TerrainChunk in world.terrain.chunks():
		for each in feral.plants_in(chunk.coord):
			all.append(each)
	return all


## The laid path pieces round you that a habitat row's "along" takes.
func pieces_for(row: Dictionary) -> Array[Sites.Piece]:
	var around := Rect2(Vector2(world.player_world_x(), world.player_world_z()), Vector2.ZERO).grow(1200.0)
	var found: Array[Sites.Piece] = []
	for piece in world.shape.sites.paths_in(around):
		if Feral._runs_along(row.along, piece):
			found.append(piece)
	return found


## How far a place is from the nearest of some laid lines, m.
static func off_line(at: Vector2, pieces: Array[Sites.Piece]) -> float:
	var near := INF
	for piece in pieces:
		for i in piece.points.size() - 1:
			near = minf(near, Geometry2D.get_closest_point_to_segment(at, piece.points[i], piece.points[i + 1]).distance_to(at))
	return near


## The standing wild plant of a crop nearest you, or null.
func nearest_standing(crop: StringName) -> Plant:
	var you := world.player.global_position
	var best: Plant = null
	for plant in feral.standing():
		if plant.crop == crop and (best == null or feral.foot_of(plant).distance_to(you) < feral.foot_of(best).distance_to(you)):
			best = plant
	return best


## The next run time from now when the sun stands high where you are.
func midday() -> float:
	var day := world.weather.day
	var t := world.time
	while absf(day.time_of_day(t, world.moon.longitude) - 0.5) > 0.03 \
			or day.sunlight(t, world.moon.latitude, world.moon.longitude) < 0.6:
		t += 10.0
	return t
