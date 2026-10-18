class_name Structure
extends Site
## A site its kind's kit builds on the ground (StructureKit): pressed into the ground's
## one function, built of boxes that join the collision of the chunk its
## middle stands on, sunk as far into the sand as its exposure says. Its
## ground is surveyed once, wherever it's first needed. Its exposure is read
## when its ground is first built and held while any of that ground is
## loaded, so nothing changes in front of you; it can while you're away.

## Its ground is surveyed at most this many plan metres apart.
const SURVEY_STEP := 4.0

var piece: StructureKit.Piece
## The chunks whose ground holds its exposure as it was read, as a set, and
## when it was read, world time; NAN while nothing holds it.
var holders := {}
var decided_at := NAN
## Whether a bigger site's ground takes this one's: -1 until its ground is
## first built.
var yields := -1
## The floor's top as it stands now, world height.
var floor_y: float:
	get:
		return floor_in(state())

var _ctx: StructureKit.Context
## Its frame's turn about the vertical: plan +v faces the way it faces.
var _turn_rad := 0.0
var _cos := 1.0
var _sin := 0.0
## Half its ground along world x and z.
var _reach := Vector2.ZERO
var _variant := 0
var _age := 0.5
## Surveyed as it's laid: the dunes' mean under its footprint, and whether
## they took it; and, while it's surveyed, how many places it's tried and the
## dunes sampled so far.
var _pad := NAN
var _stands := false
var _tries := 0
var _columns := {}
## Read once while held: the sand taken off it, and its state.
var _state := -1
var _taken := 0.0
## Its ground at the lattice points it covers, as [near, toward the dunes]
## pairs from its ground's first corner, for the state it was made in.
var _grid := PackedFloat32Array()
var _grid_state := -1
var _grid_x := 0.0
var _grid_z := 0.0
var _grid_w := 0
var _grid_d := 0.0
## Read for the moment while nothing holds it, once a tick.
var _now_tick := NAN
var _now_state := -1
var _now_taken := 0.0

static var _lock := Mutex.new()


## Becomes its kind's structure: on the lattice in quarter turns if it has
## walls, facing its bearing otherwise.
func setup(kit: StructureKit.Piece, ctx: StructureKit.Context) -> void:
	piece = kit
	_ctx = ctx
	planned = false
	reach = kit.reach
	if kit.lattice:
		x = roundf(x)
		z = roundf(z)
		turn = posmod(roundi((PI - bearing) / (PI * 0.5)), 4)
		bearing = fposmod(PI - turn * PI * 0.5, TAU)
		_turn_rad = turn * PI * 0.5
		_cos = [1.0, 0.0, -1.0, 0.0][turn]
		_sin = [0.0, 1.0, 0.0, -1.0][turn]
		var half := kit.half + Vector2.ONE * kit.apron
		_reach = half if turn % 2 == 0 else Vector2(half.y, half.x)
	else:
		_turn_rad = PI - bearing
		_cos = cos(_turn_rad)
		_sin = sin(_turn_rad)
		_reach = Vector2.ONE * kit.reach
	var rng := RandomNumberGenerator.new()
	rng.seed = loot
	_variant = rng.randi_range(0, kit.looks() - 1)
	_age = rng.randf_range(kit.age.x, kit.age.y)


## Its ground is a rectangle round its footprint.
func touches(rect: Rect2) -> bool:
	return rect.intersects(Rect2(Vector2(x, z) - _reach, _reach * 2.0), true)


## Whether a world place is on its ground, within `margin` m beyond it.
func reaches(at_x: float, at_z: float, margin := 0.0) -> bool:
	return absf(at_x - x) <= _reach.x + margin and absf(at_z - z) <= _reach.y + margin


## A world offset from its middle, in plan coordinates.
func plan(dx: float, dz: float) -> Vector2:
	return Vector2(dx * _cos - dz * _sin, dx * _sin + dz * _cos)


## A plan point as a world place, metres.
func to_world(p: Vector2) -> Vector2:
	return Vector2(x + p.x * _cos + p.y * _sin, z - p.x * _sin + p.y * _cos)


func basis() -> Basis:
	var b := Basis(Vector3.UP, _turn_rad)
	return Basis(b.x.round(), b.y.round(), b.z.round()) if piece.lattice else b


## Its frame in world metres: the floor's top at its middle, turned, leaning.
func frame() -> Transform3D:
	return Transform3D(basis(), Vector3(x, floor_y, z)) * _lean()


# --- Its ground. ---

## Whether the dunes over its ground take it, as its laying surveyed them.
func stands() -> bool:
	return _stands


## The floor's top in a state, world height: sunk under the dunes' mean.
func floor_in(s: int) -> float:
	return _pad - piece.sink[s]


## The dunes' mean under its footprint: its floor's top once dug out.
func pad() -> float:
	return _pad


## Surveys its ground as it's laid, on a worker, before the index hashes it: it stands
## where the dunes over all its ground rise no more than its survey's rise
## and are nowhere steeper than its survey's slope, its floor at their mean
## under its footprint. Where they won't take it, it looks along its line,
## a little either way, for ground that will, as a road's builders did; on
## the lattice by whole metres. Where none does, the dunes took it.
func place() -> void:
	while not place_step():
		pass


## One placement of the survey; true once it's done. The columns of dunes
## sampled are shared between placements.
func place_step() -> bool:
	var shape: TerrainShape = _ctx.shape.get_ref()
	if shape == null:
		_stands = false
		planned = true
		return true
	var span := piece.half + Vector2.ONE * piece.apron
	var along_u := piece.slide.x > 0.5
	var sa := span.x if along_u else span.y
	var sb := span.y if along_u else span.x
	# Coarse enough to be cheap, fine enough to catch a slip face.
	var step := clampf(minf(sa, sb) * 0.5, 1.0, SURVEY_STEP)
	if piece.lattice:
		step = maxf(1.0, floorf(step))
	var rows := ceili(2.0 * sb / step) + 1
	var row_step := 2.0 * sb / (rows - 1)
	var shift := maxf(step, roundf(piece.slide_m / 3.0 / step) * step)
	var k := _tries
	var offset := shift * ceili(k * 0.5) * (1.0 if k % 2 == 1 else -1.0)
	_tries += 1
	if absf(offset) > piece.slide_m + 0.001:
		_stands = false
		planned = true
		_columns = {}
		return true
	var got := _window(shape, _columns, offset, along_u, sa, sb, step, rows, row_step, tan(deg_to_rad(piece.survey.y)))
	if k == 0:
		_pad = got.x
	if got.y < 0.5:
		return false
	var moved := to_world(Vector2(offset, 0.0) if along_u else Vector2(0.0, offset)) - Vector2(x, z)
	x += moved.x
	z += moved.y
	if piece.lattice:
		x = roundf(x)
		z = roundf(z)
	_pad = got.x
	_stands = true
	planned = false
	_columns = {}
	_grid_x = floorf(x - _reach.x)
	_grid_z = floorf(z - _reach.y)
	_grid_w = int(ceilf(x + _reach.x) - _grid_x) + 1
	_grid_d = ceilf(z + _reach.y) - _grid_z + 1.0
	return true


## One placement's ground along its slide, from columns of the dunes sampled
## across it, shared between placements: [mean under its footprint, 1 if it
## stands there].
func _window(shape: TerrainShape, columns: Dictionary, offset: float, along_u: bool, sa: float, sb: float,
		step: float, rows: int, row_step: float, grade: float) -> Vector2:
	var half_a := piece.half.x if along_u else piece.half.y
	var half_b := piece.half.y if along_u else piece.half.x
	var low := INF
	var high := -INF
	var under := 0.0
	var count := 0
	var last := PackedFloat32Array()
	for j in ceili(2.0 * sa / step - 0.001) + 1:
		var a := minf(-sa + j * step, sa)
		var key := roundi((a + offset) * 100.0)
		var column: PackedFloat32Array = columns.get(key, PackedFloat32Array())
		if column.is_empty():
			column.resize(rows)
			for i in rows:
				var b := -sb + i * row_step
				var at := to_world(Vector2(a + offset, b) if along_u else Vector2(b, a + offset))
				column[i] = shape.dunes(at.x, at.y)
			columns[key] = column
		for i in rows:
			var h := column[i]
			low = minf(low, h)
			high = maxf(high, h)
			if (i > 0 and absf(h - column[i - 1]) > grade * row_step) \
					or (not last.is_empty() and absf(h - last[i]) > grade * step):
				return Vector2(NAN if count == 0 else under / count, 0.0)
			if absf(a) <= half_a and absf(-sb + i * row_step) <= half_b:
				under += h
				count += 1
		last = column
	return Vector2(under / maxi(count, 1), 1.0 if high - low <= piece.survey.x else 0.0)


## The sand at a lattice point, given what the dunes alone would be there:
## in its rooms just under their floors once dug out, else filled to the sand
## line; drifted up its walls, level at its openings; back to the dunes by
## the end of its apron. At a lattice point it's read from what the state
## made of its ground once, since it's the same whatever the dunes.
func sand(at_x: float, at_z: float, dunes: float) -> float:
	var dx := at_x - x
	var dz := at_z - z
	if absf(dx) > _reach.x or absf(dz) > _reach.y:
		return dunes
	var s := state()
	var i := at_x - _grid_x
	var j := at_z - _grid_z
	if i == floorf(i) and j == floorf(j):
		var grid := _grid_for(s)
		var k := (int(j) * _grid_w + int(i)) * 2
		return lerpf(grid[k], dunes, grid[k + 1])
	var made := _made(dx, dz, s)
	return lerpf(made.x, dunes, made.y)


## Its ground as a chunk's build presses it in: [what each lattice point is
## made, the first lattice point's x and z, how many across and down], in
## the state it's held in; what's outside it is the dunes'.
func carve() -> Array:
	return [_grid_for(state()), _grid_x, _grid_z, float(_grid_w), _grid_d]


## The sand at a world offset from its middle, as [what it is near it, how
## far toward the dunes'] in a state.
func _made(dx: float, dz: float, s: int) -> Vector2:
	var p := plan(dx, dz)
	for room in piece.rooms:
		if room.holds(p):
			return Vector2(_pad - piece.sink[s] + maxf(room.sand(p), piece.fill[s]) - StructureKit.SAND_UNDER, 0.0)
	var d := piece.out_of(p)
	var drift := piece.drift[s] * (1.0 - smoothstep(0.0, piece.drift_reach, d)) * piece.clear_of_doors(p)
	return Vector2(_pad - StructureKit.SAND_UNDER + drift, smoothstep(piece.drift_reach, piece.apron, d))


## Its ground at every lattice point in a state, made once and kept while
## that's the state it's in. Workers read it unlocked as they build its
## chunks, so it's made aside and put in place under the lock only if no
## other got there first: while its state is held it's never written again.
func _grid_for(s: int) -> PackedFloat32Array:
	if _grid_state == s:
		return _grid
	var made := PackedFloat32Array()
	var rows := int(_grid_d)
	made.resize(_grid_w * rows * 2)
	for j in rows:
		for i in _grid_w:
			var each := _made(_grid_x + i - x, _grid_z + j - z, s)
			made[(j * _grid_w + i) * 2] = each.x
			made[(j * _grid_w + i) * 2 + 1] = each.y
	_lock.lock()
	if _grid_state != s:
		_grid = made
		_grid_state = s
	_lock.unlock()
	return made


# --- Its exposure. ---

## Buried, partly exposed or exposed (Exposure): as read when its ground was
## first built while that's held, else as it would read now.
func state() -> int:
	if not is_nan(decided_at):
		if _state < 0:
			var taken := _stripped(decided_at)
			_lock.lock()
			_taken = taken
			_state = Exposure.state(depth, taken)
			_lock.unlock()
		return _state
	var t: float = _ctx.clock.call()
	var tick := floorf(t / (_ctx.tuning.site_exposure_step_minutes * 60.0))
	if tick != _now_tick:
		var taken := _stripped(t)
		_lock.lock()
		_now_taken = taken
		_now_state = Exposure.state(depth, taken)
		_now_tick = tick
		_lock.unlock()
	return _now_state


## The sand the weather had taken off it, m, when its state was read.
func taken() -> float:
	state()
	return _taken if not is_nan(decided_at) else _now_taken


## Held from now on as it reads at world time `t`.
func decide(t: float) -> void:
	_lock.lock()
	decided_at = t
	_state = -1
	_lock.unlock()


## Nothing holds it any more: the next ground built over it reads it afresh.
func forget() -> void:
	_lock.lock()
	decided_at = NAN
	_state = -1
	_grid = PackedFloat32Array()
	_grid_state = -1
	_lock.unlock()


func _stripped(t: float) -> float:
	return Exposure.stripped(_ctx.field, x, z, t, _ctx.tuning)


# --- What it holds, and what's built of it. ---

## A socket's place, world metres.
func socket_at(i: int) -> Vector3:
	return frame() * piece.sockets[i].at


## Whether a socket can be reached now: clear of the sand and no higher than
## a hand reaches from it, and if it lies deeper than the rest of the site, a
## storm has stripped that much more. Asks the ground's one function.
func reached(i: int) -> bool:
	var at := socket_at(i)
	var shape: TerrainShape = _ctx.shape.get_ref()
	var under := shape.height_at(at.x, at.z)
	if at.y < under - 0.05 or at.y > under + StructureKit.HANDS:
		return false
	var deep := piece.sockets[i].deep
	return deep <= 0.0 or taken() >= depth * (1.0 + deep)


## Whether the floor at a plan spot is dug out, the sand there under its top.
func dug(p: Vector2) -> bool:
	return _sand_on(p) <= 0.0


## Where something set down at a plan spot comes to rest, world height: on
## the floor where it's dug out, else on the sand over it.
func rest(p: Vector2) -> float:
	return floor_y + maxf(_sand_on(p) + StructureKit.SAND_UNDER, 0.0)


## The sand at a plan spot on its footprint, over the floor's top, m.
func _sand_on(p: Vector2) -> float:
	return piece.sand_line(p, state())


## Its look in a state, its frame's origin at `at` in its chunk's frame.
func view(at: Vector3, s: int) -> MeshInstance3D:
	var made := MeshInstance3D.new()
	made.mesh = piece.mesh(s, _variant)
	made.transform = Transform3D(basis(), at) * _lean()
	made.set_instance_shader_parameter(&"age", _age)
	made.set_instance_shader_parameter(&"era", float(piece.marks))
	return made


## Its collision joins a chunk's: a box for each box the sand leaves showing
## in a state, its frame's origin at `at` in the body's frame. The sand and it
## are one ground.
func add_shapes(body: StaticBody3D, at: Vector3, s: int) -> void:
	var placed := Transform3D(basis(), at) * _lean()
	for i in piece.shown(s):
		var holder := CollisionShape3D.new()
		holder.shape = piece.shape(i)
		holder.transform = placed.translated_local(piece.boxes[i].get_center())
		if i in piece.beds:
			holder.set_meta(&"bed", true)
		body.add_child(holder)


## Where its frame's origin is, world metres.
func origin() -> Vector3:
	return Vector3(x, floor_y, z)


# --- How it's seen from far off (Skyline). ---

## Its frame in a state with the dunes' mean under it at `ground`: its own
## pad where it's built, the far ground's height for a stand-in.
func frame_on(s: int, ground: float) -> Transform3D:
	return Transform3D(basis(), Vector3(x, ground - piece.sink[s], z)) * _lean()


## Its far look in a state: each box as [a unit cube's transform in its
## frame, tone], cut off at the sand.
func far_look(s: int) -> Array[Array]:
	var out: Array[Array] = []
	var line := piece.sink[s] if piece.lean == 0.0 else -INF
	for each in piece.far:
		var box: AABB = each[0]
		var lo := maxf(box.position.y, line)
		if box.end.y <= lo + StructureKit.SHOWS:
			continue
		var size := Vector3(box.size.x, box.end.y - lo, box.size.z)
		out.append([Transform3D(Basis.from_scale(size), Vector3(box.get_center().x, lo + size.y * 0.5,
			box.get_center().z)), each[1]])
	return out


## How high it rises over the dunes' mean under it in a state, m: its far
## look's top, or its boxes' for what has none.
func top_in(s: int) -> float:
	var frame := frame_on(s, 0.0)
	var top := -INF
	var boxes: Array = far_look(s).map(func(each: Array) -> Transform3D: return each[0]) if not piece.far.is_empty() \
		else piece.boxes.map(func(b: AABB) -> Transform3D: return Transform3D(Basis.from_scale(b.size), b.get_center()))
	for each: Transform3D in boxes:
		var box := frame * each
		for i in 8:
			top = maxf(top, (box * (Vector3(i & 1, (i >> 1) & 1, (i >> 2) & 1) - Vector3.ONE * 0.5)).y)
	return top


## Its glints the sand leaves bare in a state: [place in its frame, the way
## it faces, how wide it sweeps].
func bare_glints(s: int) -> Array[Array]:
	var lean := _lean()
	var out: Array[Array] = []
	for each in piece.glints:
		var at: Vector3 = lean * (each[0] as Vector3)
		var bare := at.y - piece.sink[s] >= StructureKit.GLINT_CLEAR if piece.lean > 0.0 \
			else StructureKit.shows(piece, s, at.y - StructureKit.GLINT_CLEAR, Vector2(at.x, at.z))
		if bare:
			out.append([at, lean.basis * (each[1] as Vector3), each[2]])
	return out


## How it leans, about its kind's pivot, so its free end digs into the sand.
func _lean() -> Transform3D:
	if piece.lean == 0.0 or tilt == 0.0:
		return Transform3D.IDENTITY
	var turned := Basis(piece.lean_axis, tilt * piece.lean)
	return Transform3D(turned, piece.lean_pivot - turned * piece.lean_pivot)
