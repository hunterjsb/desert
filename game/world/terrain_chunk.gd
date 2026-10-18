class_name TerrainChunk
extends Node3D
## One square of ground, and the structures whose middle stands on it. Its
## collision is built once from the same samples as its mesh, with their boxes
## in its first body, and never reshaped while it exists.

## Its collision is this many heightmaps a side, each a body of its own with a
## lip all round (Terrain.LIP): a quarter's build is a quarter of the main
## thread's time, and the terrain adds one a frame.
const SPLIT := 2

var coord: Vector2i
## Metres a side.
var side := 64
## Metres between samples; 0 until the first build arrives.
var step := 0
var heights: PackedFloat32Array
## What its collision is built from (ChunkBuild.pieces).
var pieces: Array[PackedFloat32Array] = []

var _view: GeometryInstance3D
## A RenderingServer mesh, owned here: a worker made it, so no Mesh resource does.
var _mesh: RID
var _bodies: Array[StaticBody3D] = []
var _shapes: Array[HeightMapShape3D] = []
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
	pieces = build.pieces
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


## Its next piece of collision; true once it has all of them. Needs 1 m
## samples: a heightmap's samples are one unit apart.
func add_collision_piece(size: int, sand: PhysicsMaterial) -> bool:
	var piece := _bodies.size()
	var part := size / SPLIT
	var corner := Vector2i(piece % SPLIT, piece / SPLIT) * part
	var shape := HeightMapShape3D.new()
	shape.map_width = part + 3
	shape.map_depth = part + 3
	shape.map_data = pieces[piece]
	var holder := CollisionShape3D.new()
	holder.shape = shape
	# A heightmap is centred on its node; the chunk's origin is its corner.
	holder.position = Vector3(corner.x + part * 0.5, 0.0, corner.y + part * 0.5)
	var body := StaticBody3D.new()
	body.physics_material_override = sand
	body.add_child(holder)
	if piece == 0:
		for i in _structures.size():
			_structures[i].add_shapes(body, _at(_structures[i], _states[i]), _states[i])
	add_child(body)
	_bodies.append(body)
	_shapes.append(shape)
	return has_collision()


## Freed now, not queued, so the cost lands inside the terrain's frame budget.
func remove_collision() -> void:
	for body in _bodies:
		body.free()
	_bodies.clear()
	_shapes.clear()


## All of it, not some.
func has_collision() -> bool:
	return _bodies.size() == SPLIT * SPLIT


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


## The samples its collision holds inside its edges, its pieces put together
## without their lips.
func collision_data() -> PackedFloat32Array:
	if not has_collision():
		return PackedFloat32Array()
	var part := side / SPLIT
	var inside := PackedFloat32Array()
	inside.resize((side + 1) * (side + 1))
	for piece in _shapes.size():
		var corner := Vector2i(piece % SPLIT, piece / SPLIT) * part
		var all := _shapes[piece].map_data
		var w := _shapes[piece].map_width
		for j in part + 1:
			for i in part + 1:
				inside[(corner.y + j) * (side + 1) + corner.x + i] = all[(j + 1) * w + i + 1]
	return inside


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _mesh.is_valid():
		RenderingServer.free_rid(_mesh)
