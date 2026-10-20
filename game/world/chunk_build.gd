class_name ChunkBuild
extends RefCounted
## One chunk's arrays, computed on a worker thread from the ground's one function.
## Vertices sit at the same world points as the neighbour's edge, so seams are exact.

var coord: Vector2i
var step: int
## The structures whose middle stands on it: what it draws and makes solid.
var structures: Array[Structure] = []
## Every structure pressed into its ground, and the step of its level each
## was pressed at (Structure.ground).
var carved: Array[Structure] = []
var carved_steps := PackedInt32Array()
## The dunes alone at its samples and one of border, before any structure:
## kept where structures press into it, so following them costs no dunes.
var dunes: PackedFloat32Array
## (n+1)^2 samples in rows along z: the mesh's, the seam check's and the reads'.
var heights: PackedFloat32Array
## Collision's, in TerrainChunk.SPLIT² pieces in rows: each piece's samples
## and a ring a sample past them, Terrain.LIP lower.
var pieces: Array[PackedFloat32Array] = []
var arrays: Array
## The arrays as a RenderingServer mesh, once a worker has filled it.
var mesh: RID


## A chunk built from the dunes, with the structures the index held for it
## pressed in at the steps they were held at.
static func make(shape: TerrainShape, coord: Vector2i, size: int, step: int, skirt: float,
		indices: PackedInt32Array, held: Array[Structure] = [], steps := PackedInt32Array()) -> ChunkBuild:
	var n := size / step
	var x0 := float(coord.x * size)
	var z0 := float(coord.y * size)
	# One sample of border, so edge normals match the neighbour's.
	var w := n + 3
	var profiles := shape.landforms.profiles()
	var bordered := PackedFloat32Array()
	bordered.resize(w * w)
	for j in w:
		for i in w:
			bordered[j * w + i] = shape.dunes(x0 + (i - 1) * step, z0 + (j - 1) * step, profiles)
	return pressed(shape, bordered, coord, size, step, skirt, indices, held, steps, profiles)


## A chunk from its dunes, with structures pressed in at steps: a whole
## build's last part, and all of a loaded chunk's as a storm moves what
## stands on it.
static func pressed(shape: TerrainShape, bordered: PackedFloat32Array, coord: Vector2i, size: int, step: int, skirt: float,
		indices: PackedInt32Array, held: Array[Structure], steps: PackedInt32Array,
		profiles: Array[Landforms.Hill] = []) -> ChunkBuild:
	if profiles.is_empty():
		profiles = shape.landforms.profiles()
	var build := ChunkBuild.new()
	build.coord = coord
	build.step = step
	var n := size / step
	var x0 := float(coord.x * size)
	var z0 := float(coord.y * size)
	var w := n + 3
	var square := Rect2(x0, z0, size, size)
	var carves: Array[Array] = []
	for k in held.size():
		var each := held[k]
		if not each.stands():
			continue
		carves.append(each.carve(steps[k], square.grow(step)))
		build.carved.append(each)
		build.carved_steps.append(steps[k])
		if square.has_point(Vector2(each.x, each.z)):
			build.structures.append(each)
	var ground := bordered
	if not carves.is_empty():
		build.dunes = bordered
		ground = bordered.duplicate()
	# Each structure over the samples its ground covers, from what its step
	# makes of each lattice point (Structure.carve), as the one function does.
	for carve in carves:
		var made: PackedFloat32Array = carve[0]
		var gx: float = carve[1]
		var gz: float = carve[2]
		var across := int(carve[3])
		var lo := Vector2i(ceili((gx - x0) / step) + 1, ceili((gz - z0) / step) + 1).clamp(Vector2i.ZERO, Vector2i.ONE * w)
		var hi := Vector2i(floori((gx + carve[3] - 1.0 - x0) / step) + 2, floori((gz + carve[4] - 1.0 - z0) / step) + 2) \
			.clamp(Vector2i.ZERO, Vector2i.ONE * w)
		for j in range(lo.y, hi.y):
			var cj := int(z0 + (j - 1) * step - gz)
			for i in range(lo.x, hi.x):
				var k := (cj * across + int(x0 + (i - 1) * step - gx)) * 2
				ground[j * w + i] = lerpf(made[k], ground[j * w + i], made[k + 1])

	if step == 1:
		var part := n / TerrainChunk.SPLIT
		var pw := part + 3
		for piece in TerrainChunk.SPLIT * TerrainChunk.SPLIT:
			var corner := Vector2i(piece % TerrainChunk.SPLIT, piece / TerrainChunk.SPLIT) * part
			var data := PackedFloat32Array()
			data.resize(pw * pw)
			for j in pw:
				for i in pw:
					var lip := i == 0 or j == 0 or i == pw - 1 or j == pw - 1
					data[j * pw + i] = ground[(corner.y + j) * w + corner.x + i] - (Terrain.LIP if lip else 0.0)
			build.pieces.append(data)

	var grid := (n + 1) * (n + 1)
	build.heights.resize(grid)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var shades := PackedFloat32Array()
	vertices.resize(grid + 4 * (n + 1))
	normals.resize(grid + 4 * (n + 1))
	shades.resize(4 * vertices.size())
	for j in n + 1:
		for i in n + 1:
			var b := (j + 1) * w + (i + 1)
			var k := j * (n + 1) + i
			build.heights[k] = ground[b]
			vertices[k] = Vector3(i * step, ground[b], j * step)
			normals[k] = Vector3(ground[b - 1] - ground[b + 1], 2.0 * step,
				ground[b - w] - ground[b + w]).normalized()
			put_shade(shades, k, shape.shade(x0 + i * step, z0 + j * step, ground[b], profiles))

	# Skirts hang below each edge, hiding cracks where a detailed chunk meets a coarse one.
	var v := grid
	for edge in edges(n):
		for k in edge:
			vertices[v] = vertices[k] - Vector3(0, skirt, 0)
			normals[v] = normals[k]
			for c in 4:
				shades[4 * v + c] = shades[4 * k + c]
			v += 1

	build.arrays.resize(Mesh.ARRAY_MAX)
	build.arrays[Mesh.ARRAY_VERTEX] = vertices
	build.arrays[Mesh.ARRAY_NORMAL] = normals
	build.arrays[Mesh.ARRAY_CUSTOM0] = shades
	build.arrays[Mesh.ARRAY_INDEX] = indices
	return build


## A vertex's dune shading (TerrainShape.shade), the sand shader's CUSTOM0.
static func put_shade(into: PackedFloat32Array, k: int, shade: Vector4) -> void:
	into[4 * k] = shade.x
	into[4 * k + 1] = shade.y
	into[4 * k + 2] = shade.z
	into[4 * k + 3] = shade.w


## Converting arrays to the GPU's layout is most of an upload, so a worker does it,
## into a mesh the main thread made: making RIDs off the main thread isn't safe in
## every renderer. All that's left for the main thread is the copy into video
## memory, which the RenderingServer queues for its next call there, outside the
## streaming budget.
static func fill(into: RID, mesh_arrays: Array, material: RID) -> void:
	RenderingServer.mesh_add_surface_from_arrays(into, RenderingServer.PRIMITIVE_TRIANGLES, mesh_arrays, [], {},
		RenderingServer.ARRAY_CUSTOM_RGBA_FLOAT << RenderingServer.ARRAY_FORMAT_CUSTOM0_SHIFT)
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
