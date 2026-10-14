extends Probe
## World & terrain probe 6: the same seed and coordinates always give the same
## heights, a different seed gives different ones, and a chunk builds identically.


func run() -> void:
	var tuning := Tuning.current()
	var first := TerrainShape.new(7, tuning)
	var again := TerrainShape.new(7, tuning)
	var other := TerrainShape.new(8, tuning)
	var differ := 0
	var same := true
	for i in 10000:
		var x := randf_range(-200000.0, 200000.0)
		var z := randf_range(-200000.0, 200000.0)
		if first.height_at(x, z) != again.height_at(x, z):
			same = false
		if first.height_at(x, z) != other.height_at(x, z):
			differ += 1
	check(same, "the same seed gives the same heights everywhere")
	check(differ > 9000, "a different seed gives a different desert (%d of 10000 differ)" % differ)

	var indices := ChunkBuild.indices_for(tuning.chunk_size)
	var a := ChunkBuild.make(first, Vector2i(-3, 5), tuning.chunk_size, 1, tuning.skirt_depth, indices)
	var b := ChunkBuild.make(again, Vector2i(-3, 5), tuning.chunk_size, 1, tuning.skirt_depth, indices)
	check(a.heights == b.heights, "a chunk builds the same heights twice")
	check(a.arrays[Mesh.ARRAY_VERTEX] == b.arrays[Mesh.ARRAY_VERTEX], "and the same mesh")
