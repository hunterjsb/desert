class_name ChunkBuild
extends RefCounted
## One chunk's arrays, computed on a worker thread from the ground's one function.
## Vertices sit at the same world points as the neighbour's edge, so seams are exact.

var coord: Vector2i
var step: int
## The ruin standing on it, or null: its ground is in the heights already.
var ruin: Ruin
## (n+1)^2 samples in rows along z: the collision data and the seam check.
var heights: PackedFloat32Array
var arrays: Array
## The arrays as a RenderingServer mesh, once a worker has filled it.
var mesh: RID


static func make(shape: TerrainShape, coord: Vector2i, size: int, step: int, skirt: float,
		indices: PackedInt32Array) -> ChunkBuild:
	var build := ChunkBuild.new()
	build.coord = coord
	build.step = step
	var n := size / step
	var x0 := float(coord.x * size)
	var z0 := float(coord.y * size)
	# A ruin's ground never leaves its chunk, so it's the only one these samples can meet.
	build.ruin = shape.ruins.in_chunk(coord)

	# One sample of border, so edge normals match the neighbour's.
	var w := n + 3
	var bordered := PackedFloat32Array()
	bordered.resize(w * w)
	for j in w:
		for i in w:
			bordered[j * w + i] = shape.sample(x0 + (i - 1) * step, z0 + (j - 1) * step, build.ruin)

	var grid := (n + 1) * (n + 1)
	build.heights.resize(grid)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	vertices.resize(grid + 4 * (n + 1))
	normals.resize(grid + 4 * (n + 1))
	for j in n + 1:
		for i in n + 1:
			var b := (j + 1) * w + (i + 1)
			var k := j * (n + 1) + i
			build.heights[k] = bordered[b]
			vertices[k] = Vector3(i * step, bordered[b], j * step)
			normals[k] = Vector3(bordered[b - 1] - bordered[b + 1], 2.0 * step,
				bordered[b - w] - bordered[b + w]).normalized()

	# Skirts hang below each edge, hiding cracks where a detailed chunk meets a coarse one.
	var v := grid
	for edge in edges(n):
		for k in edge:
			vertices[v] = vertices[k] - Vector3(0, skirt, 0)
			normals[v] = normals[k]
			v += 1

	build.arrays.resize(Mesh.ARRAY_MAX)
	build.arrays[Mesh.ARRAY_VERTEX] = vertices
	build.arrays[Mesh.ARRAY_NORMAL] = normals
	build.arrays[Mesh.ARRAY_INDEX] = indices
	return build


## Converting arrays to the GPU's layout is most of an upload, so a worker does it,
## into a mesh the main thread made: making RIDs off the main thread isn't safe in
## every renderer. All that's left for the main thread is the copy into video
## memory, which the RenderingServer queues for its next call there, outside the
## streaming budget.
static func fill(into: RID, mesh_arrays: Array, material: RID) -> void:
	RenderingServer.mesh_add_surface_from_arrays(into, RenderingServer.PRIMITIVE_TRIANGLES, mesh_arrays)
	RenderingServer.mesh_surface_set_material(into, 0, material)


## Triangle indices for a chunk of n cells a side, shared by every chunk of that size.
static func indices_for(n: int) -> PackedInt32Array:
	var indices := PackedInt32Array()
	for j in n:
		for i in n:
			var a := j * (n + 1) + i
			var c := a + n + 1
			indices.append_array(PackedInt32Array([a, a + 1, c, a + 1, c + 1, c]))
	var v := (n + 1) * (n + 1)
	for edge in edges(n):
		for k in edge.size() - 1:
			var e0 := edge[k]
			var e1 := edge[k + 1]
			var l0 := v + k
			var l1 := v + k + 1
			# Both windings, so a skirt shows from either side.
			indices.append_array(PackedInt32Array([e0, e1, l0, e1, l1, l0, e0, l0, e1, e1, l0, l1]))
		v += edge.size()
	return indices


static func edges(n: int) -> Array[PackedInt32Array]:
	var north := PackedInt32Array()
	var south := PackedInt32Array()
	var west := PackedInt32Array()
	var east := PackedInt32Array()
	for i in n + 1:
		north.append(i)
		south.append(n * (n + 1) + i)
		west.append(i * (n + 1))
		east.append(i * (n + 1) + n)
	return [north, south, west, east]
