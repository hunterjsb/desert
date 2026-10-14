class_name TerrainChunk
extends Node3D
## One square of ground. Its collision is built once from the same samples as its
## mesh, and never reshaped while it exists.

var coord: Vector2i
## Metres between samples; 0 until the first build arrives.
var step := 0
var heights: PackedFloat32Array

var _mesh_instance: MeshInstance3D
var _body: StaticBody3D
var _shape: HeightMapShape3D


func show_build(build: ChunkBuild, material: Material) -> void:
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, build.arrays)
	mesh.surface_set_material(0, material)
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		add_child(_mesh_instance)
	_mesh_instance.mesh = mesh
	step = build.step
	heights = build.heights


## Needs 1 m samples: a heightmap's samples are one unit apart.
func add_collision(size: int) -> void:
	_shape = HeightMapShape3D.new()
	_shape.map_width = size + 1
	_shape.map_depth = size + 1
	_shape.map_data = heights
	var holder := CollisionShape3D.new()
	holder.shape = _shape
	# A heightmap is centred on its node; the chunk's origin is its corner.
	holder.position = Vector3(size * 0.5, 0.0, size * 0.5)
	_body = StaticBody3D.new()
	_body.add_child(holder)
	add_child(_body)


func remove_collision() -> void:
	if _body:
		_body.queue_free()
	_body = null
	_shape = null


func has_collision() -> bool:
	return _body != null


func collision_data() -> PackedFloat32Array:
	return _shape.map_data if _shape else PackedFloat32Array()
