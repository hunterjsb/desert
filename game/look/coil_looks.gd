class_name CoilLooks
extends RefCounted
## One winding path with a fixed leading end and shared shader-deformed tube.

static func make() -> ArrayMesh:
	var rules := Tuning.current().rope_coil_visual
	var rings: int = rules.rings
	var sides: int = rules.sides
	var mesh := ArrayMesh.new()
	var arrays := _pose(1.0, rules)
	var indices := PackedInt32Array()
	for i in rings:
		for j in sides:
			var a := i * sides + j
			var b := (i + 1) * sides + j
			var c := (i + 1) * sides + (j + 1) % sides
			var d := i * sides + (j + 1) % sides
			indices.append_array(PackedInt32Array([a, b, c, a, c, d]))
	var caps := (rings + 1) * sides
	for j in sides:
		indices.append_array(PackedInt32Array([caps, j, (j + 1) % sides,
			caps + 1, rings * sides + (j + 1) % sides, rings * sides + j]))
	arrays[Mesh.ARRAY_INDEX] = indices
	var uv := PackedVector2Array()
	for i in rings + 1:
		for j in sides:
			uv.append(Vector2(float(i) / rings, float(j) * TAU / sides))
	uv.append(Vector2(0.0, -1.0))
	uv.append(Vector2(1.0, -1.0))
	arrays[Mesh.ARRAY_TEX_UV] = uv
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var finish := ShaderMaterial.new()
	finish.shader = preload("res://game/look/coil.gdshader")
	for key in [&"turns", &"inner_radius", &"outer_radius", &"gauge", &"layer_height", &"lead_fraction", &"anchor", &"fibre_turns", &"fibre_contrast", &"dust_amount", &"roughness", &"whipping", &"fibre_relief", &"fibre_normal"]:
		finish.set_shader_parameter(key, rules[key])
	finish.set_shader_parameter(&"rope_color", Paint.ROPE.lightened(0.14))
	finish.set_shader_parameter(&"whipping_color", Paint.TEAL.darkened(0.24))
	finish.set_shader_parameter(&"dust_color", Paint.BONE)
	mesh.surface_set_material(0, finish)
	mesh.custom_aabb = mesh.get_aabb().grow(float(rules.gauge))
	return mesh


static func anchor() -> Vector3:
	return Tuning.current().rope_coil_visual.anchor


## Only the instance parameter changes; topology and material remain shared.
static func show_amount(instance: MeshInstance3D, amount: float) -> void:
	instance.set_instance_shader_parameter(&"coil_amount", clampf(amount, 0.0, 1.0))


static func _pose(amount: float, rules: Dictionary) -> Array:
	var rings: int = rules.rings
	var sides: int = rules.sides
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in rings + 1:
		var t := float(i) / rings * amount
		var center := _point(t, rules)
		var tangent := (_point(t + 0.0001, rules) - _point(t - 0.0001, rules)).normalized()
		var across := tangent.cross(Vector3.BACK).normalized()
		if across.length_squared() < 0.1:
			across = tangent.cross(Vector3.UP).normalized()
		var up := tangent.cross(across).normalized()
		for j in sides:
			var angle := float(j) * TAU / sides
			var normal := across * cos(angle) + up * sin(angle)
			vertices.append(center + normal * float(rules.gauge))
			normals.append(normal)
	vertices.append(_point(0.0, rules))
	vertices.append(_point(amount, rules))
	normals.append(-(_point(0.0001, rules) - _point(-0.0001, rules)).normalized())
	normals.append((_point(amount + 0.0001, rules) - _point(amount - 0.0001, rules)).normalized())
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	return arrays


static func _point(t: float, rules: Dictionary) -> Vector3:
	var lead: float = rules.lead_fraction
	var first := Vector3(float(rules.inner_radius), 0.0, float(rules.gauge))
	if t < lead:
		# Meet the first winding along its tangent, without a folded tube at the lead.
		var start: Vector3 = rules.anchor
		var initial := Vector3((float(rules.outer_radius) - float(rules.inner_radius)) * PI,
			-float(rules.inner_radius) * float(rules.turns) * TAU, 0.0) / (1.0 - lead)
		var a := start.lerp(first, 1.0 / 3.0)
		var b := first - initial * lead / 3.0
		var v := t / lead
		return start * pow(1.0 - v, 3.0) + a * 3.0 * v * pow(1.0 - v, 2.0) \
			+ b * 3.0 * v * v * (1.0 - v) + first * v * v * v
	var u := (t - lead) / (1.0 - lead)
	var angle := -u * float(rules.turns) * TAU
	var radius := lerpf(float(rules.inner_radius), float(rules.outer_radius), sin(u * PI))
	var height := float(rules.gauge) + float(rules.layer_height) * smoothstep(0.4, 0.6, u)
	return Vector3(cos(angle) * radius, sin(angle) * radius * 0.98, height)
