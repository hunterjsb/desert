extends MovementProbe
## World & terrain probe 10: walking leaves footprints by your feet and nowhere
## else, a crate sits in its own imprint, the wind fills marks faster in a
## storm yet leaves a 500 m walk back readable after more storm, and none of it
## changes the ground's one function or its collision.

## A mark this deep still reads as trodden sand.
const READS := 0.25


func run() -> void:
	await load_moving()
	var tracks := world.terrain.tracks
	var flat := flat_place(world.spawn.x, world.spawn.y, 40.0, 12.0)
	await place(flat.x, flat.z, Vector2(1.0, 0.0))
	var start := Vector2(world.player_world_x(), world.player_world_z())
	var path: Array[Vector2] = []
	for i in 13:
		path.append(start + Vector2(i, 0.0))
	var ground := _ground(path)

	hold(["move_forward"])
	await simulate(8.0)
	hold([])
	await simulate(0.5)
	var walked := Vector2(world.player_world_x(), world.player_world_z()).distance_to(start)
	var missed := 0
	var deepest := 0.0
	for at in path.slice(1, floori(walked) - 1):
		var near := tracks.deepest_near(at.x, at.y, 0.6)
		deepest = maxf(deepest, near)
		if near < READS:
			missed += 1
	print("walked %.0f m, deepest print %.2f, metres with none %d" % [walked, deepest, missed])
	check(walked > 10.0, "walked over 10 m (%.1f)" % walked)
	check(missed == 0, "a print within 0.6 m of every metre walked (%d without)" % missed)
	var aside := tracks.deepest_near(start.x + 5.0, start.y + 3.0, 1.0)
	check(aside == 0.0, "no marks 3 m off the path (%.2f)" % aside)

	var box := drop_box(start.x + 4.0, start.y - 2.0, 0.3)
	await simulate(2.0)
	var under := tracks.depth_at(world.world_x(box.global_position.x), world.world_z(box.global_position.z))
	print("under the crate %.2f" % under)
	check(under > 0.8, "a resting crate sits in its imprint (%.2f)" % under)

	var at := start + Vector2(4.0, 0.0)
	var fresh := tracks.deepest_near(at.x, at.y, 0.6)
	var clock := tracks.clock
	tracks.fill(300.0, 0.0)
	var calm := fresh - tracks.deepest_near(at.x, at.y, 0.6)
	tracks.clock = clock
	tracks.fill(300.0, 1.0)
	var storm := fresh - tracks.deepest_near(at.x, at.y, 0.6)
	print("five minutes fill %.3f calm, %.3f in a storm" % [calm, storm])
	check(calm > 0.0 and storm > calm * 3.0, "a storm fills faster than calm (%.3f vs %.3f)" % [storm, calm])
	# Walked 500 m back through the storm, then three minutes more of it.
	tracks.clock = clock
	tracks.fill(500.0 / world.tuning.walk_speed + 180.0, 1.0)
	var left := tracks.deepest_near(at.x, at.y, 0.6)
	print("after 500 m and three minutes of storm %.2f" % left)
	check(left > READS, "a 500 m walk back still reads after more storm (%.2f)" % left)

	var after := _ground(path)
	check(after == ground, "height_at and collision under the path are unchanged")


## height_at and the collision's own ray hit at each place, and the collision
## data of the chunks they're on: what tracks must never change.
func _ground(path: Array[Vector2]) -> Array:
	var space := world.get_world_3d().direct_space_state
	var found: Array = []
	for at in path:
		var top := Vector3(world.engine_x(at.x), 200.0, world.engine_z(at.y))
		var ray := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 400.0)
		ray.exclude = [world.player.get_rid()]
		var hit := space.intersect_ray(ray)
		found.append([world.height_at(at.x, at.y), hit.get("position", Vector3.INF).y])
	for chunk: TerrainChunk in world.terrain.chunks():
		if chunk.has_collision() and chunk.coord == world.terrain.chunk_at(path[0].x, path[0].y):
			found.append(chunk.collision_data().duplicate())
	return found
