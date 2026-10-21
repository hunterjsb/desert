class_name CoilLooks
extends RefCounted
## Round windings keep their gauge as a gathered bundle gains rope.

static func make(level: int) -> ArrayMesh:
	var b := Paint.Pieces.new()
	var rope := Paint.coat(Paint.ROPE.lightened(0.14), 0.0, 0.0, 0.95, 0.35)
	var shadow := Paint.coat(Paint.ROPE.lightened(0.06), 0.0, 0.0, 1.0, 0.35)
	var binding := Paint.coat(Paint.TEAL.darkened(0.24), 0.0, 0.0, 0.95, 0.25)
	var turns := 1.25 if level == 0 else 2.25
	var outer := 0.112 if level == 0 else 0.145
	var layers := 2 if level == 2 else 1
	for layer in layers:
		var path := PackedVector3Array()
		var count := ceili(turns * 40.0)
		for i in count + 1:
			var t := float(i) / count
			var a := t * turns * TAU + layer * 0.2
			var r := lerpf(0.055, outer, t)
			# Slightly irregular winding gives each course its own edge of light.
			r += sin(a * 3.0 + layer) * 0.0015
			path.append(Vector3(cos(a) * r, sin(a) * r * 0.98, 0.021 + layer * 0.025 + sin(a * 2.0) * 0.001))
		_tube(b, path, 0.02, rope if layer == layers - 1 else shadow)
	var top := 0.021 + (layers - 1) * 0.025
	# A small binding crosses one side, leaving the central hole open.
	_tube(b, PackedVector3Array([
		Vector3(0.095, -0.028, 0.006), Vector3(outer + 0.006, -0.028, 0.006),
		Vector3(outer + 0.008, -0.028, top + 0.0195), Vector3(0.095, -0.028, top + 0.0195),
		Vector3(0.095, -0.028, 0.006)]), 0.0035, binding)
	var tail := PackedVector3Array([
		Vector3(0.055, 0.0, top), Vector3(0.046, 0.025, top),
		Vector3(0.055, 0.065, top + 0.002), Vector3(0.09, 0.085, top)])
	_tube(b, tail, 0.02, rope)
	for i in 4:
		var a := Vector3(0.077 + i * 0.003, 0.078 + i * 0.0017, top)
		var turn := Basis(Vector3.UP, (tail[-1] - tail[-2]).normalized(), Vector3.UP.cross((tail[-1] - tail[-2]).normalized())).orthonormalized()
		b.ring(0.019, 0.021, a, binding, turn, 6)
	return b.commit()


static func _tube(b: Paint.Pieces, path: PackedVector3Array, radius: float, coat: Paint.Coat) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var sides := 9
	var rings: Array[PackedVector3Array] = []
	var shades: Array[PackedVector3Array] = []
	for i in path.size():
		var tangent := (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var across := tangent.cross(Vector3.BACK).normalized()
		if across.length_squared() < 0.1:
			across = tangent.cross(Vector3.UP).normalized()
		var up := tangent.cross(across).normalized()
		var ring := PackedVector3Array()
		var shade := PackedVector3Array()
		for j in sides:
			var section := j * TAU / sides
			var angle := section + i * 0.65
			var radial := across * cos(angle) + up * sin(angle)
			var around := -across * sin(angle) + up * cos(angle)
			# Three soft lobes twist together instead of reading as a rubber hose.
			var gauge := 0.98 + 0.02 * cos(section * 3.0)
			ring.append(radial * gauge)
			shade.append((radial * gauge + around * 0.18 * sin(section * 3.0)).normalized())
		rings.append(ring)
		shades.append(shade)
	for i in path.size() - 1:
		for j in sides:
			var k := (j + 1) % sides
			for corner in [[i, j], [i + 1, j], [i + 1, k], [i, j], [i + 1, k], [i, k]]:
				vertices.append(path[corner[0]] + rings[corner[0]][corner[1]] * radius)
				normals.append(shades[corner[0]][corner[1]])
	for end in [0, path.size() - 1]:
		var normal := (path[end] - path[1 if end == 0 else end - 1]).normalized()
		for j in sides:
			var k := (j + 1) % sides
			var a := path[end] + rings[end][j] * radius
			var c := path[end] + rings[end][k] * radius
			for vertex in [path[end], a, c] if end == 0 else [path[end], c, a]:
				vertices.append(vertex)
				normals.append(normal)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	b._add(arrays, Transform3D.IDENTITY, coat, Vector3.ONE, 1.0)
