extends "res://probes/rope/25_the_paying_coil_follows_your_hand.gd"
## Changing gathered length must not swap or jump the coil away from its live end.

func run() -> void:
	await super.run()
	var reel := hands.reel
	var coil := reel._coil
	var mesh := coil.mesh as ArrayMesh
	var line: Line = hands.held.get_meta(&"line")
	var previous := 0.0
	for amount in [0.001, 1.0 / 3.0 - 0.001, 1.0 / 3.0 + 0.001,
			2.0 / 3.0 - 0.001, 2.0 / 3.0 + 0.001, 0.999, 1.0]:
		line.rope.length = line.rope.full * (1.0 - amount)
		reel._process(1.0)
		check(coil.mesh == mesh and Dress.coil() == mesh, "all fill amounts retain one shared mesh")
		var end := Line._tip(line.ends[1 - line._first])
		check((coil.global_transform * CoilLooks.anchor()).distance_to(end.global_position) < 0.001,
			"gathering keeps its leading end on the held rope")
		var shown: float = coil.get_instance_shader_parameter(&"coil_amount")
		check(absf(shown - amount) < 0.001, "the visible amount follows actual remaining rope")
		if amount == 1.0 / 3.0 + 0.001 or amount == 2.0 / 3.0 + 0.001:
			check(absf(shown - previous) < 0.003, "crossing an old fill boundary does not jump the winding")
		previous = shown
	var arrays := mesh.surface_get_arrays(0)
	print("coil storage: %d vertices, %d triangles, no blend-shape pose storage" % [
		arrays[Mesh.ARRAY_VERTEX].size(), arrays[Mesh.ARRAY_INDEX].size() / 3])
