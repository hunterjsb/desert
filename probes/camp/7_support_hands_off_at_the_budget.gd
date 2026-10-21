extends WorldProbe
## Required old collision survives a bounded handoff; a new mark has a new region.

func run() -> void:
	await load_world()
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	var terrain := world.terrain
	var side := world.tuning.chunk_size
	var center := terrain.chunk_at(world.player_world_x(), world.player_world_z())
	world.home._marked = true
	world.home.anchor = Sites.Anchor.new(0.0, 0.0, Sphere.point(world.moon.latitude, world.moon.longitude), 1.0, world.moon.radius)
	world.home.bounds = Rect2(Vector2.ONE * (side - 1), Vector2.ONE * (2 * side - 1))
	var old := TerrainResidency.plan(center, world.tuning, world.home.bounds)
	check(old.camp_keep.get_area() == world.tuning.home_support_chunks,
		"the fixture occupies the whole admitted support budget")
	terrain._home_anchor = world.home.anchor
	terrain._home_kept = old.camp_keep
	world.home.bounds.position.x += side
	var next := TerrainResidency.plan(center, world.tuning, world.home.bounds)
	var required := next.camp_collision
	terrain._stage_home(next)
	check(not terrain._home_blocked and next.camp_keep.get_area() <= world.tuning.home_support_chunks,
		"one chunk of motion does not get stuck keeping an obsolete halo")
	check(next.camp_collision.encloses(old.camp_collision) and next.camp_collision.encloses(required),
		"old and replacement required collision coexist during the handoff")
	world.home.anchor = Sites.Anchor.new(3000.0, 0.0, world.home.anchor.p, 1.0, world.moon.radius)
	world.home.bounds.position.x += 3000.0
	var replaced := TerrainResidency.plan(center, world.tuning, world.home.bounds)
	var expected := replaced.camp_keep
	terrain._stage_home(replaced)
	check(not terrain._home_blocked and replaced.camp_keep == expected and not terrain._home_kept.has_area(),
		"replacing a safely retired mark does not inherit its previous support region")
