extends SalvageProbe
## Structure kits probe 5: the old grid is gone and the beacon still finds a
## site. Nothing is left of the grid that put a ruin in every few chunks: no
## source of it, and in the deep desert where a run begins history left no
## house ruin within 2 km, where the grid stood about nine. Among a town's
## ruins the radio's beacon picks one history put there, standing, and its
## hall's device lies where the beacon points.

## The grid stood a ruin in about one square of 5 by 5 chunks in four.
const RADIUS := 2000.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var names := ProjectSettings.get_global_class_list().map(func(c: Dictionary) -> String: return c["class"])
	var shape := TerrainShape.new(1234, tuning)
	check(not names.has("RuinSites") and not "ruins" in shape, "no grid source is left")
	shape.sites.follow(32.0, 32.0, 0.0, 0.0, 1.0, tuning.history_lay_m)
	var near := shape.sites.query(Rect2(32.0 - RADIUS, 32.0 - RADIUS, RADIUS * 2.0, RADIUS * 2.0)).filter(
		func(s: Site) -> bool: return s is Ruin and s.distance_to(32.0, 32.0) <= RADIUS)
	check(near.is_empty(), "no house ruin in the deep desert round the run's start (%d)" % near.size())

	await load_salvage()
	var heard := Finds.beacon(world.run_seed, world.shape.sites, world.spawn.x, world.spawn.y, world.tuning,
		salvage.taken)
	check(not heard.is_empty(), "a beacon is in reach among the town's ruins")
	if heard.is_empty():
		return
	var ruin := world.shape.sites.ruin_in(heard.coord)
	check(ruin != null and ruin.source != &"hand" and ruin.point != Vector3.ZERO
		and world.shape.sites.covering(ruin.x, ruin.z) == ruin,
		"it's in a house ruin history put there, standing (%s)" % (ruin.source if ruin != null else "none"))
	var hall := ruin.to_world(Ruin.SPOTS[0])
	check(Vector2(heard.x, heard.z).distance_to(hall) < 0.01, "it points at the ruin's hall")
	await go(heard.x, heard.z + 6.0)
	var found := salvage.finds().filter(func(b: Node) -> bool:
		return b.get_meta(&"find") == [heard.coord, heard.index, heard.site])
	check(found.size() == 1, "and its device lies there")
