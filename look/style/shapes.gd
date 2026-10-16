extends RefCounted
## Mesh helpers for the art-direction look-test: chamfered boxes, faceted
## copies of primitives, and placing a mesh. Just enough to judge a style.


## A box with its edges cut back by `cut`, flat-shaded: the bevel catches a
## line of light, which is most of what reads as "made" at a distance.
static func chamfer_box(size: Vector3, cut: float) -> ArrayMesh:
	var h := size * 0.5
	var c := minf(cut, minf(h.x, minf(h.y, h.z)) * 0.9)
	var polys: Array[PackedVector3Array] = []
	# Each corner's three points, one on each face meeting there.
	var pts := {}
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				var s := Vector3(sx, sy, sz)
				pts[s] = [Vector3(sx * h.x, sy * (h.y - c), sz * (h.z - c)),
					Vector3(sx * (h.x - c), sy * h.y, sz * (h.z - c)),
					Vector3(sx * (h.x - c), sy * (h.y - c), sz * h.z)]
				polys.append(PackedVector3Array(pts[s]))
	for axis in 3:
		for side in [-1, 1]:
			var face := PackedVector3Array()
			for k in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
				var s := Vector3.ZERO
				s[axis] = side
				s[(axis + 1) % 3] = k[0]
				s[(axis + 2) % 3] = k[1]
				face.append(pts[s][axis])
			polys.append(face)
	# Edges along each axis, between the two corners at its ends.
	for axis in 3:
		var a1 := (axis + 1) % 3
		var a2 := (axis + 2) % 3
		for s1 in [-1, 1]:
			for s2 in [-1, 1]:
				var lo := Vector3.ZERO
				lo[axis] = -1
				lo[a1] = s1
				lo[a2] = s2
				var hi := lo
				hi[axis] = 1
				polys.append(PackedVector3Array([pts[lo][a1], pts[lo][a2], pts[hi][a2], pts[hi][a1]]))
	return _polys(polys)


## A faceted copy of any mesh: every triangle its own flat normal.
static func flat(mesh: Mesh) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var index = arrays[Mesh.ARRAY_INDEX]
	var order: PackedInt32Array = index if index != null and index.size() > 0 else PackedInt32Array(range(verts.size()))
	for t in order.size() / 3:
		var a := verts[order[t * 3]]
		var b := verts[order[t * 3 + 1]]
		var c := verts[order[t * 3 + 2]]
		var n := (c - a).cross(b - a).normalized()
		for v in [a, b, c]:
			tool.set_normal(n)
			tool.add_vertex(v)
	return tool.commit()


## Convex polygons, wound to face away from the middle, flat-shaded.
static func _polys(polys: Array[PackedVector3Array]) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for poly in polys:
		var mid := Vector3.ZERO
		for p in poly:
			mid += p
		mid /= poly.size()
		var n := (poly[1] - poly[0]).cross(poly[2] - poly[0]).normalized()
		if n.dot(mid) > 0.0:
			poly.reverse()
			n = -n
		for i in range(1, poly.size() - 1):
			for p in [poly[0], poly[i], poly[i + 1]]:
				tool.set_normal(-n)
				tool.add_vertex(p)
	return tool.commit()


static func cylinder(radius: float, height: float, sides := 16, top := -1.0) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = radius
	m.top_radius = radius if top < 0.0 else top
	m.height = height
	m.radial_segments = sides
	m.rings = 1
	return m


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func sphere(radius: float, segments := 16, rings := 8) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = segments
	m.rings = rings
	return m


static func torus(inner: float, outer: float, rings := 16, sides := 8) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = rings
	m.ring_segments = sides
	return m


## A mesh placed under a parent, with a look; returns it for instance params.
static func put(parent: Node3D, mesh: Mesh, look: Material, at := Vector3.ZERO, turn := Basis.IDENTITY) -> MeshInstance3D:
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = look
	made.transform = Transform3D(turn, at)
	parent.add_child(made)
	return made
