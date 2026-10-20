class_name TerrainChunk
extends Node3D
## One square of ground, and the structures whose middle stands on it. Its
## collision is built from the same samples as its mesh. Where a storm works
## a structure on it, the structure rises out of the sand or sinks back a
## frame at a time, its look and its boxes together, and the ground round it
## follows in steps too fine to see (Structure.ground), mesh and collision
## swapped together.

## Its collision is this many heightmaps a side, each a body of its own with a
## lip all round (Terrain.LIP): a quarter's build is a quarter of the main
## thread's time, so the terrain's budget can hold one.
const SPLIT := 2
## A structure moves once it's this far from where it's drawn, m.
const MOVES := 0.001

var coord: Vector2i
## Metres a side.
var side := 64
## Metres between samples; 0 until the first build arrives.
var step := 0
var heights: PackedFloat32Array
## What its collision is built from (ChunkBuild.pieces).
var pieces: Array[PackedFloat32Array] = []
## The dunes alone under it, kept where structures press into it; every
## structure pressed in, and the step each is pressed at now.
var dunes: PackedFloat32Array
var carved: Array[Structure] = []
var carved_steps := PackedInt32Array()

var _view: GeometryInstance3D
## A RenderingServer mesh, owned here: a worker made it, so no Mesh resource does.
var _mesh: RID
var _bodies: Array[StaticBody3D] = []
var _shapes: Array[HeightMapShape3D] = []
## The structures standing on it, drawn from the first build, solid with the
## sand; each one's look as [view, the state its look is of, how far it's
## sunk], and its boxes as [body, the state they're of].
var _structures: Array[Structure] = []
var _views := {}
var _boxes := {}


func show_build(build: ChunkBuild) -> void:
	if _view == null:
		_view = GeometryInstance3D.new()
		add_child(_view)
	_show_ground(build)
	_show_structures(build.structures)


## A build of the same ground with what stands in it pressed in afresh: each
## piece of collision it changed takes its new samples, and a structure just
## laid over it (Terrain.join) is drawn, made solid if the ground is. What it
## drew new.
func show_pressed(build: ChunkBuild) -> Array[Structure]:
	var was := pieces
	_show_ground(build)
	for piece in _shapes.size():
		if piece < was.size() and pieces[piece] != was[piece]:
			_shapes[piece].map_data = pieces[piece]
	var new: Array[Structure] = []
	for each in build.structures:
		if not _views.has(each):
			new.append(each)
	if new.is_empty():
		return new
	_show_structures(build.structures)
	if not _bodies.is_empty():
		for each in new:
			_add_boxes(each, _bodies[0])
	return new


func _show_ground(build: ChunkBuild) -> void:
	_view.set_base(build.mesh)
	if _mesh.is_valid():
		RenderingServer.free_rid(_mesh)
	_mesh = build.mesh
	build.mesh = RID()
	step = build.step
	heights = build.heights
	pieces = build.pieces
	dunes = build.dunes
	carved = build.carved
	carved_steps = build.carved_steps


## Draws what stands on it as it stands now, keeping what's already drawn.
func _show_structures(structures: Array[Structure]) -> void:
	var kept := {}
	for each in structures:
		if _views.has(each):
			kept[each] = _views[each]
			_views.erase(each)
			continue
		var s := StructureKit.Piece.shown_state(each.level())
		var made := each.view(Vector3.ZERO, s)
		add_child(made)
		kept[each] = [made, s, NAN]
	for gone: Array in _views.values():
		gone[0].free()
	_views = kept
	_structures = structures
	follow_structures()


## Moves what stands on it to where it stands now: out of the sand or into
## it, its look and its boxes together. True if anything moved.
func follow_structures() -> bool:
	var moved := false
	for each in _structures:
		var level := each.level()
		var s := StructureKit.Piece.shown_state(level)
		var sink := each.piece.sink_at(level)
		var view: Array = _views[each]
		if view[1] == s and absf(sink - view[2]) < MOVES:
			continue
		moved = true
		var mesh: MeshInstance3D = view[0]
		if view[1] != s:
			mesh.mesh = each.look(s)
			view[1] = s
		view[2] = sink
		var at := _at(each, level)
		mesh.transform = each.placed(at)
		# Its look's sand stain was drawn at its state's sand line.
		mesh.set_instance_shader_parameter(&"foot_shift", sink - each.piece.sink[s])
		var boxes: Array = _boxes.get(each, [])
		if boxes.is_empty():
			continue
		if boxes[1] != s:
			for shape in (boxes[0] as Node).get_children():
				shape.free()
			each.add_shapes(boxes[0], s)
			boxes[1] = s
		(boxes[0] as StaticBody3D).transform = each.placed(at)
	return moved


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
		# Each structure's boxes are a body of their own, moved as it rises or
		# sinks: what stands on it is lifted with it.
		for each in _structures:
			_add_boxes(each, body, sand)
	add_child(body)
	_bodies.append(body)
	_shapes.append(shape)
	return has_collision()


func _add_boxes(each: Structure, body: StaticBody3D, sand: PhysicsMaterial = null) -> void:
	var level := each.level()
	var s := StructureKit.Piece.shown_state(level)
	var boxes := StaticBody3D.new()
	boxes.physics_material_override = sand if sand != null else body.physics_material_override
	each.add_shapes(boxes, s)
	boxes.transform = each.placed(_at(each, level))
	body.add_child(boxes)
	_boxes[each] = [boxes, s]


## Freed now, not queued, so the cost lands inside the terrain's frame budget.
func remove_collision() -> void:
	for body in _bodies:
		body.free()
	_bodies.clear()
	_shapes.clear()
	_boxes.clear()


## All of it, not some.
func has_collision() -> bool:
	return _bodies.size() == SPLIT * SPLIT


## The structures standing on it.
func structures() -> Array[Structure]:
	return _structures


## A structure's look as this chunk draws it, or null.
func view_of(structure: Structure) -> MeshInstance3D:
	return _views.get(structure, [null])[0]


## A structure's boxes as this chunk makes them solid, or null.
func body_of(structure: Structure) -> StaticBody3D:
	return _boxes.get(structure, [null])[0]


## The state a structure's look stands in, as drawn now; -1 if it isn't.
func state_of(structure: Structure) -> int:
	return structure.state() if _views.has(structure) else -1


## How far a structure's look is sunk under its pad, as drawn now; NAN if it isn't.
func sink_of(structure: Structure) -> float:
	return _views.get(structure, [null, 0, NAN])[2]


## Whether a structure pressed into it stands at another step than its
## ground was pressed at, by at least `least` steps.
func behind(least := 1) -> bool:
	for k in carved.size():
		if carved[k].ground >= 0 and absi(carved[k].ground - carved_steps[k]) >= least:
			return true
	return false


## The house ruin its finds are laid out in, if any: of those standing on
## it, the one made first, as the site index says (Sites.ruin_in).
func ruin() -> Ruin:
	var first: Ruin = null
	for each in _structures:
		if each is Ruin and (first == null or each.id < first.id):
			first = each
	return first


## Where a structure's frame sits in this chunk's, at a level.
func _at(structure: Structure, level: float) -> Vector3:
	return Vector3(structure.x - coord.x * side, structure.pad() - structure.piece.sink_at(level),
		structure.z - coord.y * side)


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


## Exclude triangle-based sand from solid-surface queries; sand has its own
## analytic height and Jolt reports a heightmap once per intersected triangle.
func ground_bodies() -> Array[RID]:
	var out: Array[RID] = []
	for body in _bodies:
		out.append(body.get_rid())
	return out
