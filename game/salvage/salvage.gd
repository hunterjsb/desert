class_name Salvage
extends Node
## Finds in the world. A chunk's finds are laid out when its ground becomes
## solid, inside the streaming budget, and go when it stops being solid. They
## lie in the chunk as part of it, frozen where they were placed, buried or
## settled, until you take one, take from one, fit to one, use one or take
## hold of one: then it's yours, an ordinary thing in the world. While a chunk
## is loaded it remembers what you took from it, so its finds come back as
## they were less that; once it's forgotten, so is that.

## How long a loose find may take to settle before it's frozen anyway, s, and
## how still it must be to count as settled.
const SETTLE_SECONDS := 4.0
const STILL_SPEED := 0.05
const STILL_SECONDS := 0.3

## Main-thread time laying out finds took, the most any frame has, ms.
var slowest_ms := 0.0

var _world: World
var _tuning: Tuning
var _lots := {}
var _queue: Array[Piece] = []
## Finds forgotten, freed one at a time inside the budget: a chunk's all at
## once would overrun the frame it leaves in.
var _forgotten: Array = []
## Loose finds settling: [body, seconds since placed, seconds still].
var _settling: Array[Array] = []


## One chunk's finds while it's loaded: how hard the weather had been when it
## first came near, what was taken, and what lies there now.
class Lot:
	var exposure := NAN
	var taken := {}
	var finds: Array[RigidBody3D] = []
	var chunk: TerrainChunk


## Work for the streaming budget: planning a chunk (no spec), or one step of
## laying out a find: its body, each part it was found with, then into the world.
class Piece:
	var coord: Vector2i
	var spec: Dictionary
	var body: RigidBody3D
	var fitted := 0

	func _init(at: Vector2i, find := {}) -> void:
		coord = at
		spec = find


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	world.terrain.grounded.connect(_on_grounded)
	world.terrain.ungrounded.connect(_on_ungrounded)
	world.terrain.unloaded.connect(_on_unloaded)
	if _tuning.salvage:
		_first_time()


## The first find laid out in a run pays for everything done the first time,
## a millisecond; a stand-in pays it now, while the world loads, as the
## sand's shader does. So does the first ruin.
func _first_time() -> void:
	Ruin.prepare()
	var spec := {"id": &"crate_frame", "device": true, "layer": Finds.DEEP, "x": 0.0, "z": 0.0, "yaw": 0.0,
		"lean": 0.0, "lean_by": 0.0, "bury": 0.3, "sound": 0.5, "charge": 0.5,
		"fill": [[0, &"battery", 0.5], [1, &"hook", 0.0], [3, &"hover_tray", 0.0], [4, &"solar_panel", 0.0]]}
	var stand_in := Finds.make(spec)
	stand_in.transform = Finds.pose(stand_in, spec, func(_x: float, _z: float) -> float: return -1000.0)
	stand_in.freeze = true
	_world.content.add_child(stand_in)
	Finds.age(stand_in, spec.sound)
	stand_in.free()


func _ready() -> void:
	# Settling finds are watched after the physics step they moved in.
	process_physics_priority = 120


## Finds half made wait off the tree, so nothing else would free them.
func _exit_tree() -> void:
	while not _queue.is_empty():
		_drop(0)
	for body: Variant in _forgotten:
		if is_instance_valid(body):
			body.free()
	_forgotten.clear()


## Called by the terrain each frame with its budget's deadline (usec).
func stream(deadline: int) -> void:
	var started := Time.get_ticks_usec()
	while not _forgotten.is_empty() and Time.get_ticks_usec() < deadline:
		# Its chunk may have gone first, and taken it along.
		var body: Variant = _forgotten.pop_back()
		if is_instance_valid(body):
			body.free()
	while not _queue.is_empty() and Time.get_ticks_usec() < deadline:
		var piece: Piece = _queue[0]
		var lot: Lot = _lots.get(piece.coord)
		if lot == null or not is_instance_valid(lot.chunk) or not lot.chunk.has_collision():
			_drop(0)
		elif piece.spec.is_empty():
			_queue.pop_front()
			_plan(piece.coord, lot)
		elif piece.body == null:
			piece.body = Finds.bare(piece.spec)
		elif piece.fitted < piece.spec.fill.size():
			Finds.fit(piece.body as Device, piece.spec, piece.fitted)
			piece.fitted += 1
		else:
			_queue.pop_front()
			Finds.dark(piece.body)
			_lay_out(piece.coord, lot, piece.spec, piece.body)
	slowest_ms = maxf(slowest_ms, (Time.get_ticks_usec() - started) / 1000.0)


## Nothing left to lay out or settle.
func is_idle() -> bool:
	return _queue.is_empty() and _settling.is_empty()


## The chunks it holds finds or memories for: never more than are loaded.
func lots() -> int:
	return _lots.size()


## How many finds lie in the world now, untaken.
func count() -> int:
	var total := 0
	for lot: Lot in _lots.values():
		total += lot.finds.size()
	return total


## Every find lying in a chunk of its own now, untaken.
func finds() -> Array[RigidBody3D]:
	var all: Array[RigidBody3D] = []
	for lot: Lot in _lots.values():
		all.append_array(lot.finds)
	return all


## The finds lying in the chunks round a place: what your hands look over.
func near(at: Vector3) -> Array[RigidBody3D]:
	var all: Array[RigidBody3D] = []
	var middle := _world.terrain.chunk_at(_world.world_x(at.x), _world.world_z(at.z))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var lot: Lot = _lots.get(middle + Vector2i(dx, dz))
			if lot != null:
				all.append_array(lot.finds)
	return all


## How hard the weather had been in a loaded chunk when it came near; NAN if
## it hasn't yet.
func exposure_in(coord: Vector2i) -> float:
	var lot: Lot = _lots.get(coord)
	return lot.exposure if lot != null else NAN


## Whether a body still lies as it was found, or is buried: taken hold of,
## it comes up out of the sand first.
func lying(body: Node) -> bool:
	return body != null and (body.has_meta(&"find") or body.has_meta(&"buried"))


## A find becomes yours: out of its chunk into the world, an ordinary thing
## from now on, running if its battery can, and its chunk won't lay it out
## again while it's loaded.
func claim(body: Node) -> void:
	if body == null or not body.has_meta(&"find"):
		return
	var from: Array = body.get_meta(&"find")
	body.remove_meta(&"find")
	var lot: Lot = _lots.get(from[0])
	if lot != null:
		lot.taken[from[1]] = true
		lot.finds.erase(body)
	for i in range(_settling.size() - 1, -1, -1):
		if _settling[i][0] == body:
			_settling.remove_at(i)
	body.reparent(_world.content)
	if body is Device:
		_world.power.wake(body)
	_discovered(body)


## Every kind of thing a find held, reported to the profile: the first of
## each kind is a discovery.
func _discovered(body: Node) -> void:
	var profile := get_node_or_null(^"/root/Profile")
	if profile == null:
		return
	if body.has_meta(&"catalog"):
		profile.discover(str(body.get_meta(&"catalog")))
	for child in body.get_children():
		if child is Socket and child.part != null:
			_discovered(child.part)


## Takes something up out of the sand onto it, loose and yours: a buried
## device stands upright on the sand, a part rests on it.
func unbury(body: RigidBody3D) -> void:
	claim(body)
	if body.has_meta(&"buried"):
		body.remove_meta(&"buried")
		if body is Device:
			body.global_basis = Basis(Vector3.UP, body.global_rotation.y)
		var box := Finds.bounds(body)
		var rise := -INF
		for i in 8:
			var corner := body.global_transform * box.get_endpoint(i)
			rise = maxf(rise, _world.height_under(corner) - corner.y)
		body.global_position.y += rise + Finds.DROP
	body.freeze = false


func _on_grounded(chunk: TerrainChunk) -> void:
	if not _tuning.salvage:
		return
	var lot: Lot = _lots.get(chunk.coord)
	if lot == null:
		lot = Lot.new()
		_lots[chunk.coord] = lot
	lot.chunk = chunk
	_queue.append(Piece.new(chunk.coord))


## Its ground stops being solid: what lies there goes, to come back as it
## was if the ground does while the chunk is loaded.
func _on_ungrounded(chunk: TerrainChunk) -> void:
	var lot: Lot = _lots.get(chunk.coord)
	if lot == null:
		return
	_forget(chunk.coord, lot)


func _on_unloaded(coord: Vector2i) -> void:
	var lot: Lot = _lots.get(coord)
	if lot != null:
		_forget(coord, lot)
		_lots.erase(coord)


func _forget(coord: Vector2i, lot: Lot) -> void:
	for body in lot.finds:
		if is_instance_valid(body):
			# Out of sight and touching nothing until it's freed.
			body.freeze = true
			body.visible = false
			body.collision_layer = 0
			_forgotten.append(body)
	lot.finds.clear()
	for i in range(_queue.size() - 1, -1, -1):
		if _queue[i].coord == coord:
			_drop(i)
	for i in range(_settling.size() - 1, -1, -1):
		if not is_instance_valid(_settling[i][0]) or _settling[i][0].freeze:
			_settling.remove_at(i)


## The chunk's plan, from how hard the weather had been there when it first
## came near: each find not taken becomes a piece of work of its own.
func _plan(coord: Vector2i, lot: Lot) -> void:
	var size := _tuning.chunk_size
	if is_nan(lot.exposure):
		lot.exposure = Finds.exposure(_world.weather.field, (coord.x + 0.5) * size, (coord.y + 0.5) * size,
			_world.time, _tuning)
	var specs := Finds.plan(_world.run_seed, coord, lot.exposure, _tuning, _world.height_at, lot.chunk.ruin())
	for spec in specs:
		if not lot.taken.has(spec.index):
			_queue.append(Piece.new(coord, spec))


## A piece of work no longer wanted, and whatever it had begun to make.
func _drop(at: int) -> void:
	var piece := _queue[at]
	if piece.body != null:
		piece.body.free()
	_queue.remove_at(at)


## Lays out one find of a solid chunk's plan at once, as it lies there.
func lay(coord: Vector2i, spec: Dictionary) -> RigidBody3D:
	return _lay_out(coord, _lots[coord], spec, Finds.make(spec))


func _lay_out(coord: Vector2i, lot: Lot, spec: Dictionary, body: RigidBody3D) -> RigidBody3D:
	var pose := Finds.pose(body, spec, _world.height_at)
	var at := Vector3(_world.engine_x(pose.origin.x), pose.origin.y, _world.engine_z(pose.origin.z))
	body.transform = Transform3D(pose.basis, at - lot.chunk.position)
	body.set_meta(&"find", [coord, spec.index])
	if spec.bury > 0.0:
		body.set_meta(&"buried", true)
	body.freeze = spec.bury > 0.0
	lot.chunk.add_child(body)
	if body is Device:
		Finds.age(body, spec.sound)
	lot.finds.append(body)
	if not body.freeze:
		_settling.append([body, 0.0, 0.0])
	return body


## A loose find settles from where it was set down, then holds there.
func _physics_process(delta: float) -> void:
	for i in range(_settling.size() - 1, -1, -1):
		var each: Array = _settling[i]
		if not is_instance_valid(each[0]):
			_settling.remove_at(i)
			continue
		var body: RigidBody3D = each[0]
		each[1] += delta
		var still := body.linear_velocity.length() < STILL_SPEED and body.angular_velocity.length() < STILL_SPEED * 4.0
		each[2] = each[2] + delta if still else 0.0
		if each[2] >= STILL_SECONDS or each[1] >= SETTLE_SECONDS:
			body.freeze = true
			_settling.remove_at(i)
	var here := _world.terrain.chunk_at(_world.player_world_x(), _world.player_world_z())
	var exposed := exposure_in(here)
	Dev.put("salvage/finds", "%d" % count())
	Dev.put("salvage/exp", "-" if is_nan(exposed) else "%d%% deep %d%%"
		% [roundi(exposed * 100.0), roundi(Finds.deep_share(exposed, _tuning) * 100.0)])


## What a save keeps of the finds, for each chunk remembered: [coord, how
## hard the weather had been when it came near, the finds taken from it].
func memories() -> Array:
	var out := []
	for coord: Vector2i in _lots:
		var lot: Lot = _lots[coord]
		if not is_nan(lot.exposure):
			out.append([coord, lot.exposure, lot.taken.keys()])
	return out


## A resumed run's finds as they were: a remembered chunk within view of
## `around` lays its finds out again by its own weather, less what was taken;
## any other loaded now comes near afresh, at this moment.
func recall(memories: Array, around: Vector2i) -> void:
	var reach := _tuning.view_radius
	var kept := {}
	for each: Array in memories:
		var coord: Vector2i = each[0]
		if maxi(absi(coord.x - around.x), absi(coord.y - around.y)) <= reach:
			kept[coord] = each
	for coord: Vector2i in _lots.keys() + kept.keys():
		var lot: Lot = _lots.get(coord)
		if lot == null:
			lot = Lot.new()
			_lots[coord] = lot
		_forget(coord, lot)
		lot.exposure = kept[coord][1] if kept.has(coord) else NAN
		lot.taken = {}
		var taken: Array = kept[coord][2] if kept.has(coord) else []
		for index: int in taken:
			lot.taken[index] = true
		if is_instance_valid(lot.chunk) and lot.chunk.has_collision():
			_queue.append(Piece.new(coord))
