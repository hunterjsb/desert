class_name FarRing
extends RefCounted
## The crude far view: one coarse, visual-only mesh out to the haze, with a hole
## where the chunks are. It overlaps the outermost chunk ring by one chunk and sits
## a little lower, so a ring that lags the player by a chunk still shows no gap.
## Its samples are 32 m apart and on the lattice, so it reads the dunes alone:
## what stands on it far off is the skyline's (Skyline), set on its ground.


## Its own ground at a world place: the dunes at its lattice points, split
## into triangles as its mesh is, and dropped as it's drawn. What stands on
## it far off stands on this, not on the dunes it skips between samples.
static func ground(shape: TerrainShape, tuning: Tuning, x: float, z: float) -> float:
	var step := float(tuning.far_step)
	var i := floorf(x / step)
	var j := floorf(z / step)
	var fx := x / step - i
	var fz := z / step - j
	var corner := shape.dunes(i * step, j * step) if fx + fz <= 1.0 else shape.dunes((i + 1.0) * step, (j + 1.0) * step)
	return TerrainShape.across(fx, fz, shape.dunes((i + 1.0) * step, j * step), shape.dunes(i * step, (j + 1.0) * step),
		corner) - tuning.far_drop


static func make(shape: TerrainShape, center: Vector2i, tuning: Tuning) -> Array:
	var size := tuning.chunk_size
	var step := tuning.far_step
	var reach := ceili(tuning.far_radius / size) * size
	var lo := -reach
	var cells := (2 * reach + size) / step
	var hole_lo := -(tuning.view_radius - 1) * size
	var hole_hi := tuning.view_radius * size
	var x0 := float(center.x * size)
	var z0 := float(center.y * size)

	var w := cells + 3
	var bordered := PackedFloat32Array()
	bordered.resize(w * w)
	for j in w:
		for i in w:
			bordered[j * w + i] = shape.dunes(x0 + lo + (i - 1) * step, z0 + lo + (j - 1) * step)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	vertices.resize((cells + 1) * (cells + 1))
	normals.resize(vertices.size())
	for j in cells + 1:
		for i in cells + 1:
			var b := (j + 1) * w + (i + 1)
			var k := j * (cells + 1) + i
			vertices[k] = Vector3(lo + i * step, bordered[b] - tuning.far_drop, lo + j * step)
			normals[k] = Vector3(bordered[b - 1] - bordered[b + 1], 2.0 * step,
				bordered[b - w] - bordered[b + w]).normalized()

	var indices := PackedInt32Array()
	for j in cells:
		for i in cells:
			var x := lo + i * step
			var z := lo + j * step
			if x >= hole_lo and x + step <= hole_hi and z >= hole_lo and z + step <= hole_hi:
				continue
			var a := j * (cells + 1) + i
			var c := a + cells + 1
			indices.append_array(PackedInt32Array([a, a + 1, c, a + 1, c + 1, c]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays
