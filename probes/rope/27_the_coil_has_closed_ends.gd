extends Probe
## A winding's end disks must face outward; reversed caps look like a hollow tube.

func run() -> void:
	var mesh := Dress.coil()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var caps := vertices.size() - 2
	var seen := 0
	for i in range(0, indices.size(), 3):
		var center := indices[i]
		if center < caps:
			continue
		var cross := (vertices[indices[i + 1]] - vertices[center]).cross(vertices[indices[i + 2]] - vertices[center])
		check(cross.dot(normals[center]) < -0.00001, "each end disk faces out with Godot's clockwise winding")
		seen += 1
	check(seen == 2 * int(Tuning.current().rope_coil_visual.sides), "both tube ends have complete disks")
