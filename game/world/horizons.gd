class_name Horizons
extends Node3D
## Only two coarse hills and their actual summit meshes. Near ground is the
## ordinary streamed terrain; no special collision or invisible destination.
var _world: World
var _views := {}
var _sand: ShaderMaterial

func setup(world: World) -> void:
	_world = world
	_sand = ShaderMaterial.new()
	_sand.shader = preload("res://game/world/horizon.gdshader")
	_sand.set_shader_parameter("sand", world.tuning.sand_color)
	_sand.set_shader_parameter("mountain_rock", world.tuning.mountain_rock)
	_sand.set_shader_parameter("mountain_rock_height", world.tuning.mountain_rock_height)
	_sand.set_shader_parameter("horizon_near", world.tuning.far_radius - 2.0 * world.tuning.chunk_size)
	_sand.set_shader_parameter("horizon_range", world.tuning.horizon_range)
	world.player.camera.far = maxf(world.player.camera.far, world.tuning.horizon_range.y + world.tuning.observatory_mountain.x)

func _process(_delta: float) -> void:
	if _world == null:
		return
	for hill in _world.shape.landforms.hills:
		if not _views.has(hill.id):
			var ground := MeshInstance3D.new()
			ground.mesh = mesh(hill, _world.tuning.horizon_step, _world.tuning.horizon_drop_m)
			ground.material_override = _sand
			ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(ground)
			var top := MeshInstance3D.new()
			top.mesh = StructureKit.piece(StringName(String(hill.id) + "_summit")).mesh(0, 0)
			top.visibility_range_begin = _world.tuning.skyline_handover_m.y
			top.visibility_range_begin_margin = _world.tuning.skyline_handover_m.y - _world.tuning.skyline_handover_m.x
			top.visibility_range_end = _world.tuning.horizon_range.y
			top.visibility_range_end_margin = _world.tuning.horizon_range.y - _world.tuning.horizon_range.x
			top.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			top.visible = _world.tuning.salvage
			add_child(top)
			_views[hill.id] = [ground, top]
		var pair: Array = _views[hill.id]
		pair[0].position = Vector3(_world.engine_x(hill.at.x), 0, _world.engine_z(hill.at.y))
		var mark := _world.shape.history.landmark(hill.id)
		pair[1].position = Vector3(_world.engine_x(hill.at.x), _world.shape.dunes(hill.at.x, hill.at.y), _world.engine_z(hill.at.y))
		pair[1].rotation.y = PI - hill.anchor.ground_bearing(mark.bearing)

static func mesh(hill: Landforms.Hill, step: float, drop: float) -> ArrayMesh:
	var cells := ceili(hill.radius / step) * 2
	var half := cells * step * 0.5
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	for j in cells + 1:
		for i in cells + 1:
			var x := i * step - half
			var z := j * step - half
			var at := hill.at + Vector2(x, z)
			points.append(Vector3(x, hill.rise(at.x, at.y) - drop, z))
			normals.append(Vector3(hill.rise(at.x - step, at.y) - hill.rise(at.x + step, at.y), 2 * step,
				hill.rise(at.x, at.y - step) - hill.rise(at.x, at.y + step)).normalized())
	var indices := PackedInt32Array()
	for j in cells:
		for i in cells:
			var a := j * (cells + 1) + i
			var b := a + cells + 1
			indices.append_array([a, a + 1, b, a + 1, b + 1, b])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var made := ArrayMesh.new()
	made.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return made
