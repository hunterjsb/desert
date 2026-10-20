extends Probe
## World & terrain probe 12: the dune shading each vertex carries (the sand
## shader's CUSTOM0, TerrainShape.shade) is the same on both sides of a seam,
## 1 m chunk to 1 m and to 2 m, so no line shows where chunks meet.

## In the dune sea near spawn on seed 1234 (look/dunes' "sea"), world x and z.
const SEA := Vector2(-1100.0, -2450.0)


func run() -> void:
	var tuning := Tuning.current()
	var shape := TerrainShape.new(1234, tuning)
	var size := tuning.chunk_size
	var middle := Vector2i(floori(SEA.x / size), floori(SEA.y / size))
	var indices := {}
	var builds := {}
	# 1 m chunks, with 2 m ones east of them.
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var step := 1 if dx <= 0 else tuning.mid_step
			if not indices.has(step):
				indices[step] = ChunkBuild.indices_for(size / step)
			builds[Vector2i(dx, dz)] = ChunkBuild.make(shape, middle + Vector2i(dx, dz), size, step,
				tuning.skirt_depth, indices[step])
	var compared := 0
	var differ := 0
	var steepest := 0.0
	for at: Vector2i in builds:
		for side in [Vector2i(1, 0), Vector2i(0, 1)]:
			var other: ChunkBuild = builds.get(at + side)
			if other == null:
				continue
			var mine: ChunkBuild = builds[at]
			for t in range(0, size + 1, maxi(mine.step, other.step)):
				var a := _shade(mine, size, size if side.x == 1 else t, t if side.x == 1 else size)
				var b := _shade(other, size, 0 if side.x == 1 else t, t if side.x == 1 else 0)
				compared += 1
				differ += 0 if a == b else 1
				steepest = maxf(steepest, maxf(a.y, a.z))
	check(compared > 300 and steepest > 0.05, "seams over dunes compared (%d points, a horizon of %.2f)" % [compared, steepest])
	check(differ == 0, "the dune shading agrees across every seam (%d differ)" % differ)


## A build's shading at local metres (x, z), one of its samples.
func _shade(build: ChunkBuild, size: int, x: int, z: int) -> Vector4:
	var n := size / build.step
	var k := 4 * ((z / build.step) * (n + 1) + x / build.step)
	var custom: PackedFloat32Array = build.arrays[Mesh.ARRAY_CUSTOM0]
	return Vector4(custom[k], custom[k + 1], custom[k + 2], custom[k + 3])
