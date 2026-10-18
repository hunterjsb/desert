class_name TerrainChunk
extends Node3D
## One square of ground, and the structures whose middle stands on it. Its
## collision is built once from the same samples as its mesh, with their boxes
## in the same body, and never reshaped while it exists.

var coord: Vector2i
## Metres a side.
var side := 64
## Metres between samples; 0 until the first build arrives.
var step := 0
var heights: PackedFloat32Array
## What its collision is built from: the heights and a lip (ChunkBuild.lipped).
var lipped: PackedFloat32Array

var _view: GeometryInstance3D
## A RenderingServer mesh, owned here: a worker made it, so no Mesh resource does.
var _mesh: RID
var _body: StaticBody3D
var _shape: HeightMapShape3D
## The structures standing on it, part of its ground, each in the state its
## build read: drawn from the first build, solid with the sand.
var _structures: Array[Structure] = []
var _states := PackedInt32Array()
var _views := {}


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
	lipped = build.lipped
	_show_structures(build.structures, build.states)


## Draws what stands on it as this build read it, keeping what's unchanged.
func _show_structures(structures: Array[Structure], states: PackedInt32Array) -> void:
	var kept := {}
	for i in structures.size():
		var each := structures[i]
		var had: Array = _views.get(each, [])
		if not had.is_empty() and had[1] == states[i]:
			kept[each] = had
			_views.erase(each)
			continue
		var made := each.view(_at(each, states[i]), states[i])
		add_child(made)
		kept[each] = [made, states[i]]
	for gone: Array in _views.values():
		gone[0].free()
	_views = kept
	_structures = structures
	_states = states


## Needs 1 m samples: a heightmap's samples are one unit apart.
func add_collision(size: int, sand: PhysicsMaterial) -> void:
	_shape = HeightMapShape3D.new()
	_shape.map_width = size + 3
	_shape.map_depth = size + 3
	_shape.map_data = lipped
	var holder := CollisionShape3D.new()
	holder.shape = _shape
	# A heightmap is centred on its node; the chunk's origin is its corner, and
	# its lip reaches a metre past every edge.
	holder.position = Vector3(size * 0.5, 0.0, size * 0.5)
	_body = StaticBody3D.new()
	_body.physics_material_override = sand
	_body.add_child(holder)
	for i in _structures.size():
		_structures[i].add_shapes(_body, _at(_structures[i], _states[i]), _states[i])
	add_child(_body)


## Freed now, not queued, so the cost lands inside the terrain's frame budget.
func remove_collision() -> void:
	if _body:
		_body.free()
	_body = null
	_shape = null


func has_collision() -> bool:
	return _body != null


## The structures standing on it, and the state each stands in.
func structures() -> Array[Structure]:
	return _structures


## A structure's look as this chunk draws it, or null.
func view_of(structure: Structure) -> MeshInstance3D:
	return _views.get(structure, [null])[0]


func state_of(structure: Structure) -> int:
	var i := _structures.find(structure)
	return _states[i] if i >= 0 else -1


## The house ruin its finds are laid out in, if any: of those standing on
## it, the one made first, as the site index says (Sites.ruin_in).
func ruin() -> Ruin:
	var first: Ruin = null
	for each in _structures:
		if each is Ruin and (first == null or each.id < first.id):
			first = each
	return first


## Where a structure's frame sits in this chunk's, in a state.
func _at(structure: Structure, state: int) -> Vector3:
	return Vector3(structure.x - coord.x * side, structure.floor_in(state), structure.z - coord.y * side)


## The samples its collision holds inside its edges, without the lip.
func collision_data() -> PackedFloat32Array:
	if _shape == null:
		return PackedFloat32Array()
	var all := _shape.map_data
	var w := _shape.map_width
	var inside := PackedFloat32Array()
	for j in range(1, w - 1):
		inside.append_array(all.slice(j * w + 1, j * w + w - 1))
	return inside


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _mesh.is_valid():
		RenderingServer.free_rid(_mesh)
