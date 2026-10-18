class_name Sites
extends RefCounted
## The site index: every site, path piece and landmark laid on the ground near
## you, in world metres and hashed by the chunks they touch, with today's
## ruins from the ground's own grid. It answers what chunks and systems ask:
## what touches this area, whose ground is under this point, what's nearest.
##
## History is laid by the sheet. The flat ground can't hold the moon, so the
## history near you is laid from where you are: a moon cell, or a landmark,
## whose footprint is big, is laid once any of it comes within history_lay_m,
## each place through the anchor's map (its distance and bearing from where
## the moon position was last reckoned), and lifted once all of it is past
## history_lift_m on the ground. Loaded ground reaches less far than either,
## so nothing laid ever changes under loaded ground.

## Where the sheet lays from: a place on the ground, world metres, with the
## moon's point there and which way north lies on the ground (-z, or +z past a
## pole).
class Anchor:
	var x: float
	var z: float
	var p: Vector3
	var facing: float
	var radius: float

	func _init(at_x: float, at_z: float, point: Vector3, north: float, moon_radius: float) -> void:
		x = at_x
		z = at_z
		p = point
		facing = north
		radius = moon_radius

	## Where a place on the sphere lies on the ground, world metres.
	func place(q: Vector3) -> Vector2:
		var off := Sphere.flat_from(p, q) * radius
		return Vector2(x + off.x * facing, z - off.y * facing)

	## The place on the sphere under a point of the ground.
	func point_at(at_x: float, at_z: float) -> Vector3:
		return Sphere.from_flat(p, Vector2((at_x - x) * facing, -(at_z - z) * facing) / radius)

	## A bearing on the sphere as a bearing on the ground.
	func ground_bearing(bearing: float) -> float:
		return fposmod(bearing + (0.0 if facing > 0.0 else PI), TAU)


## A path's line through one moon cell, in world metres.
class Piece:
	var path: int
	## Its first point's index along the path's line.
	var first: int
	var kind: StringName
	var eras: int
	var carries: int
	var points := PackedVector2Array()

	func crosses(rect: Rect2) -> bool:
		for i in points.size() - 1:
			var box := Rect2(points[i], Vector2.ZERO).expand(points[i + 1])
			if box.grow(0.01).intersects(rect, true):
				return true
		return false


## A landmark laid on the ground: its middle, heading and footprint, and its
## parts as {id, name, x, z, radius}.
class Mark:
	var landmark: Dictionary
	var x: float
	var z: float
	var bearing: float
	var radius: float
	var parts: Array[Dictionary] = []

	func touches(rect: Rect2) -> bool:
		var dx := maxf(maxf(rect.position.x - x, 0.0), x - rect.end.x)
		var dz := maxf(maxf(rect.position.y - z, 0.0), z - rect.end.y)
		return dx * dx + dz * dz <= radius * radius


## What one cell or landmark laid: its sites, pieces or mark, its ground, and
## the chunks they're hashed in.
class Unit:
	var key: int
	var anchor: Anchor
	var sites: Array[Site] = []
	var pieces: Array[Piece] = []
	var mark: Mark
	var ground: Rect2
	## The chunks its things are hashed in, as a set.
	var chunks := {}
	## What's left to make of it, a part at a time.
	var todo: Array[Array] = []


var history: History
var ruins: RuinSites
## Whether any of a rectangle of world metres is loaded ground, and builds
## that ground again: the world's.
var loaded := func(_rect: Rect2) -> bool: return false
var rebuild := func(_rect: Rect2) -> void: pass
## Main-thread time laying took in a frame, the most any has, ms; and how
## often the sheet has followed you and laid a unit, all run.
var slowest_ms := 0.0
var follows := 0
var laid := 0

var _size: float
var _lay: float
var _lift: float
var _anchor: Anchor
## The units of this sheet, by key: a cell's id, or -1 - a landmark's index.
var _units := {}
## Units laid by an earlier sheet, kept while their ground is loaded.
var _orphans: Array[Unit] = []
## Units waiting to be laid, nearest first: [key, anchor, metres off].
var _queue: Array[Array] = []
var _queued := {}
## The unit at the head of the queue, part made.
var _making: Unit
var _sites := {}
var _pieces := {}
## Where laying was last asked from, and how far round it everything is laid.
var _ready_at := Vector2(INF, INF)
var _ready_m := -1.0


func _init(world_history: History, grid: RuinSites, tuning: Tuning) -> void:
	history = world_history
	ruins = grid
	_size = tuning.chunk_size
	_lay = tuning.history_lay_m
	_lift = tuning.history_lift_m


# --- What chunks and systems ask. ---

## Every site whose ground touches a rectangle of world metres: laid ones,
## planned ones too unless asked not to, and the grid's ruins.
func query(rect: Rect2, planned := true) -> Array[Site]:
	var found: Array[Site] = []
	var seen := {}
	for chunk in _chunks_of(rect):
		for site: Site in _sites.get(chunk, []):
			if not seen.has(site) and (planned or not site.planned) and site.touches(rect):
				seen[site] = true
				found.append(site)
	for ruin in ruins.touching(rect):
		found.append(ruin)
	return found


## Every path piece crossing a rectangle of world metres.
func paths_in(rect: Rect2) -> Array[Piece]:
	var found: Array[Piece] = []
	var seen := {}
	for chunk in _chunks_of(rect):
		for piece: Piece in _pieces.get(chunk, []):
			if not seen.has(piece) and piece.crosses(rect):
				seen[piece] = true
				found.append(piece)
	return found


## Every laid landmark whose footprint touches a rectangle of world metres.
func landmarks_in(rect: Rect2) -> Array[Mark]:
	var found: Array[Mark] = []
	for unit in units():
		if unit.mark != null and unit.mark.touches(rect):
			found.append(unit.mark)
	return found


## The sites whose middle stands in a chunk: those whose boxes it builds.
func in_chunk(coord: Vector2i) -> Array[Site]:
	var found: Array[Site] = []
	var square := Rect2(Vector2(coord) * _size, Vector2.ONE * _size)
	for site: Site in _sites.get(coord, []):
		if square.has_point(Vector2(site.x, site.z)):
			found.append(site)
	var ruin := ruins.in_chunk(coord)
	if ruin != null:
		found.append(ruin)
	return found


## The site whose ground a world place is on, or null: what the ground's one
## function asks. Only the grid's ruins press into the ground yet.
func covering(x: float, z: float) -> Site:
	return ruins.covering(x, z)


## The nearest site within `radius` m of a world place that `wanted(kind, x,
## z)` keeps, asked before a grid ruin's ground is surveyed; built ones only
## unless asked.
func nearest(x: float, z: float, radius: float, wanted: Callable, planned := false) -> Site:
	var best: Site = null
	var near := radius
	for unit in units():
		for site in unit.sites:
			var by := site.distance_to(x, z)
			if by <= near and (planned or not site.planned) and wanted.call(site.kind, site.x, site.z):
				best = site
				near = by
	var ruin := ruins.nearest(x, z, near, func(middle: Vector2i) -> bool:
		return wanted.call(&"house_ruin", float(middle.x), float(middle.y)))
	return ruin if ruin != null else best


## Every unit laid, this sheet's and any kept from an earlier one.
func units() -> Array[Unit]:
	var all: Array[Unit] = []
	for unit: Unit in _units.values():
		all.append(unit)
	all.append_array(_orphans)
	return all


## Whether everything that could touch a rectangle of world metres is laid,
## so ground there can be built.
func ready(rect: Rect2) -> bool:
	for corner in [rect.position, rect.end, Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.position.y)]:
		if corner.distance_to(_ready_at) > _ready_m:
			return false
	return true


# --- The sheet. ---

## Lays what's coming within reach of where the moon position was last
## reckoned, `x, z` in world metres with its latitude, longitude and facing,
## and lifts what's gone out of it. Everything within `due` m is laid at once,
## the rest a little each frame (step). A moon point that disagrees with the
## ground walked from it is a jump, and starts a new sheet.
func follow(x: float, z: float, latitude: float, longitude: float, facing: float, due: float) -> void:
	follows += 1
	var anchor := Anchor.new(x, z, Sphere.point(latitude, longitude), facing, history.radius)
	if _anchor != null and _jumped(anchor):
		_new_sheet()
	_anchor = anchor
	for unit: Unit in _units.values():
		if _off(unit, x, z):
			_take_up(unit)
	for unit in _orphans.duplicate():
		if _off(unit, x, z) or not loaded.call(unit.ground):
			_take_up(unit)
	var cells := history.cells
	for cell in cells.within(anchor.p, _lay):
		_offer(cell, anchor, Sphere.angle(anchor.p, cells.center(cell)) * history.radius - cells.half_diagonal(cell))
	for i in history.landmarks.size():
		var each: Dictionary = history.landmarks[i]
		_offer(-1 - i, anchor, Sphere.angle(anchor.p, each.p) * history.radius - each.radius)
	_queue.sort_custom(func(a: Array, b: Array) -> bool: return a[2] < b[2])
	while not _queue.is_empty() and _queue[0][2] <= due:
		_lay_next()
	_ready_at = Vector2(x, z)
	_ready_m = due


## Lays waiting units until the frame's streaming deadline, Time ticks (usec).
func step(deadline: int) -> void:
	var started := Time.get_ticks_usec()
	while not _queue.is_empty() and Time.get_ticks_usec() < deadline:
		_lay_next()
	slowest_ms = maxf(slowest_ms, (Time.get_ticks_usec() - started) / 1000.0)


## Whether the sheet has somewhere to lay from: not before its first anchor,
## nor straight after a resume.
func anchored() -> bool:
	return _anchor != null


## Nothing waiting to be laid.
func is_idle() -> bool:
	return _queue.is_empty()


## What a save keeps: each laid unit's key and the anchor it was laid from.
func memories() -> Array:
	var out := []
	for unit: Unit in _units.values():
		var a := unit.anchor
		out.append([unit.key, a.x, a.z, Sphere.latitude(a.p), Sphere.longitude(a.p), a.facing])
	return out


## A resumed run's sheet as it was: each unit laid from its own anchor again.
## Loaded ground under anything that changes is built again.
func recall(memories: Array) -> void:
	var kept := {}
	for each: Array in memories:
		var anchor := Anchor.new(each[1], each[2], Sphere.point(each[3], each[4]), each[5], history.radius)
		var had: Unit = _units.get(each[0])
		if had != null and _same(had.anchor, anchor):
			kept[each[0]] = true
			continue
		if had != null:
			_lift_rebuilding(had)
		_lay_unit(each[0], anchor, true)
		kept[each[0]] = true
	for unit: Unit in _units.values():
		if not kept.has(unit.key):
			_lift_rebuilding(unit)
	for unit in _orphans.duplicate():
		_lift_rebuilding(unit)
	_queue.clear()
	_queued.clear()
	_making = null
	_anchor = null
	_ready_m = -1.0


func _lift_rebuilding(unit: Unit) -> void:
	_take_up(unit)
	if loaded.call(unit.ground):
		rebuild.call(unit.ground)


static func _same(a: Anchor, b: Anchor) -> bool:
	return a.x == b.x and a.z == b.z and a.p == b.p and a.facing == b.facing


func _offer(key: int, anchor: Anchor, metres: float) -> void:
	if metres > _lay or _units.has(key) or _queued.has(key):
		return
	_queue.append([key, anchor, metres])
	_queued[key] = true


## One part of the unit at the head of the queue; the last lays it.
func _lay_next() -> void:
	var head: Array = _queue[0]
	if _making == null or _making.key != head[0]:
		_making = _begun(head[0], head[1])
	if not _making.todo.is_empty():
		_make(_making, _making.todo.pop_front())
		if not _making.todo.is_empty():
			return
	_queue.pop_front()
	_queued.erase(head[0])
	var unit := _making
	_making = null
	_put(unit)


## All of a unit at once.
func _lay_unit(key: int, anchor: Anchor, anyway := false) -> void:
	var unit := _begun(key, anchor)
	while not unit.todo.is_empty():
		_make(unit, unit.todo.pop_front())
	_put(unit, anyway)


## A unit begun: a landmark's mark, or a cell's ground and the parts to make.
func _begun(key: int, anchor: Anchor) -> Unit:
	var unit := Unit.new()
	unit.key = key
	unit.anchor = anchor
	if key < 0:
		_lay_mark(unit, history.landmarks[-1 - key])
		return unit
	var cells := history.cells
	var ground := Rect2(anchor.place(cells.center(key)), Vector2.ZERO)
	for corner in cells.corners(key):
		ground = ground.expand(anchor.place(corner))
	unit.ground = ground.grow(SiteKinds.most_reach() + PathNetwork.CORRIDOR)
	unit.todo = history.cell_parts(key)
	unit.todo.append([&"pieces"])
	return unit


func _make(unit: Unit, part: Array) -> void:
	if part[0] == &"pieces":
		_lay_pieces(unit, unit.key)
		return
	var made: Array[Dictionary] = []
	history.sites_of(unit.key, part, made)
	for each in made:
		unit.sites.append(_site(each, unit.anchor))


func _put(unit: Unit, anyway := false) -> void:
	var key := unit.key
	# Over ground an earlier sheet left, it waits until that ground has gone.
	if not anyway and not _orphans.is_empty() and (loaded.call(unit.ground)
			or _orphans.any(func(o: Unit) -> bool: return o.ground.intersects(unit.ground))):
		return
	_units[key] = unit
	laid += 1
	for site in unit.sites:
		_hash(unit, _sites, site, Rect2(site.x - site.reach, site.z - site.reach, site.reach * 2.0, site.reach * 2.0))
	for piece in unit.pieces:
		for i in piece.points.size() - 1:
			_hash(unit, _pieces, piece, Rect2(piece.points[i], Vector2.ZERO).expand(piece.points[i + 1]))


func _site(each: Dictionary, anchor: Anchor) -> Site:
	var site := Site.new()
	site.id = each.id
	site.kind = each.kind
	site.era = each.era
	site.point = each.p
	var at := anchor.place(each.p)
	site.x = at.x
	site.z = at.y
	site.bearing = anchor.ground_bearing(each.bearing)
	site.turn = posmod(-roundi(site.bearing / (PI * 0.5)), 4)
	site.reach = each.reach
	site.depth = each.depth
	site.tilt = each.tilt
	site.loot = each.loot
	site.source = each.source
	site.region = each.region
	return site


## The cell's stretches of path: each belongs to the cell its middle is in.
func _lay_pieces(unit: Unit, cell: int) -> void:
	var anchor := unit.anchor
	var cells := history.cells
	var reaching := history.paths_in_cell(cell)
	for path_id: int in reaching:
		var path: PathNetwork.Path = history.network.paths[path_id]
		var span: Vector2 = reaching[path_id]
		var piece: Piece = null
		for i in range(path.segment(span.x), path.segment(span.y) + 1):
			if cells.cell_at(path.points[i].slerp(path.points[i + 1], 0.5)) != cell:
				piece = null
				continue
			if piece == null:
				piece = Piece.new()
				piece.path = path_id
				piece.first = i
				piece.kind = path.kind
				piece.eras = path.eras
				piece.carries = path.carries
				piece.points.append(anchor.place(path.points[i]))
				unit.pieces.append(piece)
			piece.points.append(anchor.place(path.points[i + 1]))


func _lay_mark(unit: Unit, each: Dictionary) -> void:
	var anchor := unit.anchor
	var mark := Mark.new()
	mark.landmark = each
	var at := anchor.place(each.p)
	mark.x = at.x
	mark.z = at.y
	mark.bearing = anchor.ground_bearing(each.bearing)
	mark.radius = each.radius
	for part: Dictionary in each.parts:
		var spot := anchor.place(part.p)
		mark.parts.append({"id": part.id, "name": part.name, "x": spot.x, "z": spot.y, "radius": part.radius})
	unit.mark = mark
	unit.ground = Rect2(at - Vector2.ONE * mark.radius, Vector2.ONE * mark.radius * 2.0)


## Puts a thing in every chunk a rectangle of world metres touches.
func _hash(unit: Unit, into: Dictionary, thing: Variant, rect: Rect2) -> void:
	for chunk in _chunks_of(rect):
		var held: Array = into.get(chunk, [])
		if held.is_empty():
			into[chunk] = held
		elif held.back() == thing:
			continue
		held.append(thing)
		unit.chunks[chunk] = true


func _take_up(unit: Unit) -> void:
	var own := {}
	for site in unit.sites:
		own[site] = true
	for piece in unit.pieces:
		own[piece] = true
	for chunk: Vector2i in unit.chunks:
		for into: Dictionary in [_sites, _pieces]:
			var held: Array = into.get(chunk, [])
			if held.is_empty():
				continue
			var kept := held.filter(func(t: Variant) -> bool: return not own.has(t))
			if kept.is_empty():
				into.erase(chunk)
			else:
				into[chunk] = kept
	if _units.get(unit.key) == unit:
		_units.erase(unit.key)
	else:
		_orphans.erase(unit)


## Every unit of this sheet becomes an earlier sheet's: kept while its ground
## is loaded, lifted otherwise. Nothing waiting is laid from the old anchor.
func _new_sheet() -> void:
	for unit: Unit in _units.values():
		if loaded.call(unit.ground):
			_orphans.append(unit)
		else:
			_take_up(unit)
	_units.clear()
	_queue.clear()
	_queued.clear()
	_making = null
	_ready_m = -1.0


## The moon point is where the ground walked from the last anchor should put it,
## within dead reckoning's own drift from a straight map.
func _jumped(anchor: Anchor) -> bool:
	var moved := Vector2(anchor.x - _anchor.x, anchor.z - _anchor.z)
	var expected := _anchor.point_at(anchor.x, anchor.z)
	return Sphere.angle(expected, anchor.p) * history.radius > 50.0 + 0.05 * moved.length()


func _off(unit: Unit, x: float, z: float) -> bool:
	var g := unit.ground
	var dx := maxf(maxf(g.position.x - x, 0.0), x - g.end.x)
	var dz := maxf(maxf(g.position.y - z, 0.0), z - g.end.y)
	return dx * dx + dz * dz > _lift * _lift


func _chunks_of(rect: Rect2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for j in range(floori(rect.position.y / _size), floori(rect.end.y / _size) + 1):
		for i in range(floori(rect.position.x / _size), floori(rect.end.x / _size) + 1):
			out.append(Vector2i(i, j))
	return out
