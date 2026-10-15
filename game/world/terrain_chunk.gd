class_name TerrainChunk
extends Node3D
## One square of ground. Its collision is built once from the same samples as its
## mesh, and never reshaped while it exists.

var coord: Vector2i
## Metres between samples; 0 until the first build arrives.
var step := 0
var heights: PackedFloat32Array

var _view: GeometryInstance3D
## A RenderingServer mesh, owned here: a worker made it, so no Mesh resource does.
var _mesh: RID
var _body: StaticBody3D
var _shape: HeightMapShape3D


func show_build(build: ChunkBuild) -> void:
	if _view == null:
		_view = GeometryInstance3D.new()
		add_child(_view)
	_view.set_base(build.mesh)
	if _mesh.is_valid():
		RenderingServer.free_rid(_mesh)
	_mesh = build.mesh
	build.mesh = RID()
	step = build.step
	heights = build.heights


## Needs 1 m samples: a heightmap's samples are one unit apart.
func add_collision(size: int, sand: PhysicsMaterial) -> void:
	_shape = HeightMapShape3D.new()
	_shape.map_width = size + 1
	_shape.map_depth = size + 1
	_shape.map_data = heights
	var holder := CollisionShape3D.new()
	holder.shape = _shape
	# A heightmap is centred on its node; the chunk's origin is its corner.
	holder.position = Vector3(size * 0.5, 0.0, size * 0.5)
	_body = StaticBody3D.new()
	_body.physics_material_override = sand
	_body.add_child(holder)
	add_child(_body)


## Freed now, not queued, so the cost lands inside the terrain's frame budget.
func remove_collision() -> void:
	if _body:
		_body.free()
	_body = null
	_shape = null


func has_collision() -> bool:
	return _body != null


func collision_data() -> PackedFloat32Array:
	return _shape.map_data if _shape else PackedFloat32Array()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _mesh.is_valid():
		RenderingServer.free_rid(_mesh)
