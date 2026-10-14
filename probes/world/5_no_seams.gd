extends WorldProbe
## World & terrain probe 5: neighbouring chunks agree exactly on their shared edge,
## at the points both have, and collision holds exactly the mesh's samples.


func run() -> void:
	await load_world()
	var by_coord := {}
	for chunk: TerrainChunk in world.terrain.chunks():
		by_coord[chunk.coord] = chunk
	var size := Tuning.current().chunk_size
	var edges := 0
	var mismatches := 0
	for chunk: TerrainChunk in by_coord.values():
		for side in [Vector2i(1, 0), Vector2i(0, 1)]:
			var other: TerrainChunk = by_coord.get(chunk.coord + side)
			if other == null:
				continue
			edges += 1
			var shared := maxi(chunk.step, other.step)
			for t in range(0, size + 1, shared):
				var mine := _sample(chunk, size, size if side.x == 1 else t, t if side.x == 1 else size)
				var theirs := _sample(other, size, 0 if side.x == 1 else t, t if side.x == 1 else 0)
				if mine != theirs:
					mismatches += 1
	check(edges > 500, "checked the whole loaded area (%d edges)" % edges)
	check(mismatches == 0, "shared edges agree exactly (%d mismatches)" % mismatches)

	var near := 0
	for chunk: TerrainChunk in by_coord.values():
		if chunk.has_collision():
			near += 1
			check(chunk.collision_data() == chunk.heights, "collision holds the mesh's samples at %s" % chunk.coord)
	check(near == (2 * Tuning.current().near_radius + 1) ** 2, "every near chunk has collision (%d)" % near)


## The height a chunk stored at local metres (x, z), which must be one of its samples.
func _sample(chunk: TerrainChunk, size: int, x: int, z: int) -> float:
	var n := size / chunk.step
	return chunk.heights[(z / chunk.step) * (n + 1) + x / chunk.step]
