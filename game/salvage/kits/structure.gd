class_name Structure
extends Site
## A site its kind's kit builds on the ground (StructureKit): pressed into the ground's
## one function, built of boxes that stand with the chunk its middle stands
## on, sunk as far into the sand as its exposure says. Its ground is surveyed
## once, wherever it's first needed. Its exposure is the weather's, a pure
## function of where and when, so it reads the same loaded or not; while its
## ground is loaded it follows the weather a frame at a time, rising out of
## the sand and sinking back as a storm works on it, its ground following in
## steps too fine to see, and never burying you or your camp.

## Its ground is surveyed at most this many plan metres apart.
const SURVEY_STEP := 4.0

var piece: StructureKit.Piece
## The chunks whose ground holds it, as a set.
var holders := {}
## Read as at this world time, for probes and look-tests; NAN, the world's clock.
var pinned_at := NAN
## The step of its level its loaded ground is built at (StructureKit.Piece.steps);
## -1 while nothing holds it.
var ground := -1
## Whether a bigger site's ground takes this one's: -1 until its ground is
## first built.
var yields := -1
## The floor's top as it stands now, world height.
var floor_y: float:
	get:
		return _pad - piece.sink_at(level())

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
## Its weather's readings, kept by tick.
var _memo := Exposure.Memo.new()
## While its ground is loaded: the sand off it as that ground shows it, m
## (NAN while nothing holds it), whether that's held up over you, and when
## it last followed the weather.
var _shown := NAN
var _held := false
var _followed := NAN
## Read for one moment while nothing holds it: what height_at asks over and over.
var _now_t := NAN
var _now_taken := 0.0
## Its ground's lattice points, from its ground's first corner, made once:
## in a room, its sand there once dug out, else how far up the drift its
## wall's sand there reaches; and how far toward the dunes' own (-1 in a
## room). Then the ground they make at a step, the last few kept.
var _base := PackedFloat32Array()
var _grids := {}
var _grid_x := 0.0
var _grid_z := 0.0
var _grid_w := 0
var _grid_d := 0.0

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
## the end of its apron. Loaded, at the step its ground is built at; else at
## its level now.
func sand(at_x: float, at_z: float, dunes: float) -> float:
	var dx := at_x - x
	var dz := at_z - z
	if absf(dx) > _reach.x or absf(dz) > _reach.y:
		return dunes
	var step := ground if ground >= 0 else piece.step_of(level())
	var i := at_x - _grid_x
	var j := at_z - _grid_z
	if i == floorf(i) and j == floorf(j):
		var grid := _grid_for(step)
		var k := (int(j) * _grid_w + int(i)) * 2
		return lerpf(grid[k], dunes, grid[k + 1])
	var made := _made(dx, dz, piece.level_of(step))
	return lerpf(made.x, dunes, made.y)


## Its ground as a chunk's build presses it in at a step: [what each lattice
## point is made, the first lattice point's x and z, how many across and
## down]; what's outside it is the dunes'.
func carve(step: int) -> Array:
	return [_grid_for(step), _grid_x, _grid_z, float(_grid_w), _grid_d]


## The sand at a world offset from its middle, as [what it is near it, how
## far toward the dunes'] at a level.
func _made(dx: float, dz: float, level: float) -> Vector2:
	var p := plan(dx, dz)
	for room in piece.rooms:
		if room.holds(p):
			return Vector2(_pad - piece.sink_at(level) + maxf(room.sand(p), piece.fill_at(level))
				- StructureKit.SAND_UNDER, 0.0)
	var d := piece.out_of(p)
	var drift := piece.drift_at(level) * (1.0 - smoothstep(0.0, piece.drift_reach, d)) * piece.clear_of_doors(p)
	return Vector2(_pad - StructureKit.SAND_UNDER + drift, smoothstep(piece.drift_reach, piece.apron, d))


## Its ground at every lattice point at a step, from what each point is,
## made once. Workers read it unlocked as they build its chunks, so each is
## made aside and kept under the lock; a step's is never written again.
func _grid_for(step: int) -> PackedFloat32Array:
	_lock.lock()
	var had: Variant = _grids.get(step)
	_lock.unlock()
	if had != null:
		return had
	var base := _base_points()
	var level := piece.level_of(step)
	var sink := piece.sink_at(level)
	var fill := piece.fill_at(level)
	var drift := piece.drift_at(level)
	var under := _pad - StructureKit.SAND_UNDER
	var made := PackedFloat32Array()
	made.resize(base.size())
	for k in range(0, base.size(), 2):
		var w := base[k + 1]
		if w < 0.0:
			made[k] = under - sink + maxf(base[k], fill)
			made[k + 1] = 0.0
		else:
			made[k] = under + drift * base[k]
			made[k + 1] = w
	_lock.lock()
	if not _grids.has(step):
		if _grids.size() >= 4:
			_grids.erase(_grids.keys()[0])
		_grids[step] = made
	else:
		made = _grids[step]
	_lock.unlock()
	return made


func _base_points() -> PackedFloat32Array:
	_lock.lock()
	var base := _base
	_lock.unlock()
	if not base.is_empty():
		return base
	var rows := int(_grid_d)
	base.resize(_grid_w * rows * 2)
	for j in rows:
		for i in _grid_w:
			var k := (j * _grid_w + i) * 2
			var p := plan(_grid_x + i - x, _grid_z + j - z)
			var room_sand := NAN
			for room in piece.rooms:
				if room.holds(p):
					room_sand = room.sand(p)
					break
			if not is_nan(room_sand):
				base[k] = room_sand
				base[k + 1] = -1.0
			else:
				var d := piece.out_of(p)
				base[k] = (1.0 - smoothstep(0.0, piece.drift_reach, d)) * piece.clear_of_doors(p)
				base[k + 1] = smoothstep(piece.drift_reach, piece.apron, d)
	_lock.lock()
	if _base.is_empty():
		_base = base
	_lock.unlock()
	return _base


# --- Its exposure. ---

## The sand taken off it now, m: as its loaded ground shows it, else the
## weather's at the world's clock (or the moment it's pinned to).
func taken() -> float:
	if not is_nan(pinned_at):
		return pure_taken(pinned_at)
	if not is_nan(_shown):
		return _shown
	var t: float = _ctx.clock.call()
	_lock.lock()
	var cached := _now_t == t
	var got := _now_taken
	_lock.unlock()
	if cached:
		return got
	got = pure_taken(t)
	_lock.lock()
	_now_t = t
	_now_taken = got
	_lock.unlock()
	return got


## The weather's sand taken off it at a world time, m (Exposure.taken).
func pure_taken(t: float) -> float:
	return Exposure.taken(_ctx.field, x, z, t, _ctx.tuning, _memo)


## The settled sand alone, m: what it would be without the storm working on it now.
func settled() -> float:
	var t: float = pinned_at if not is_nan(pinned_at) else _ctx.clock.call()
	return Exposure.settled(_ctx.field, x, z, t, _ctx.tuning, _memo)


## Buried, partly exposed or exposed (Exposure), now.
func state() -> int:
	return Exposure.state(depth, taken())


## How far out of the sand it is now, 0 to Exposure.DUG_OUT.
func level() -> float:
	return Exposure.level(depth, taken())


## How much further out of the sand the storm working on it has it than its
## settled sand would, in levels: what's newly bare.
func bared() -> float:
	return maxf(level() - Exposure.level(depth, settled()), 0.0)


## The same as the weather has it at world time `t`, loaded or not: what it sheds as drift.
func bared_at(t: float) -> float:
	var settled_then := Exposure.settled(_ctx.field, x, z, t, _ctx.tuning, _memo)
	return maxf(Exposure.level(depth, pure_taken(t)) - Exposure.level(depth, settled_then), 0.0)


## Read as at world time `t` from now on: for probes and look-tests.
func decide(t: float) -> void:
	pinned_at = t


## Follows the world's clock again.
func forget() -> void:
	pinned_at = NAN


## Its ground is first built: shown from now as the weather has it.
func hold_ground() -> void:
	_shown = pure_taken(_ctx.clock.call())
	_held = false
	_followed = _ctx.clock.call()
	ground = piece.step_of(level())


## Nothing holds its ground any more: it's the weather's alone again.
func release_ground() -> void:
	_shown = NAN
	_held = false
	ground = -1
	_lock.lock()
	_grids.clear()
	_lock.unlock()


## Follows the weather while its ground is loaded, at world time `t`. Where
## you or your camp stand on its ground (`occupied(self)`) the sand never
## comes back over it; once you're off, it comes back no faster than
## site_rebury_m_s. True if the step its ground should be built at changed.
func follow(t: float, occupied: Callable) -> bool:
	if is_nan(_shown):
		return false
	var dt := maxf(t - _followed, 0.0) if not is_nan(_followed) else 0.0
	_followed = t
	var pure := pure_taken(t)
	if pure >= _shown:
		_shown = pure
		_held = false
	elif occupied.call(self):
		_held = true
	elif _held:
		_shown = maxf(pure, _shown - _ctx.tuning.site_rebury_m_s * dt)
		_held = _shown > pure
	else:
		_shown = pure
	var step := piece.step_of(level())
	if step == ground:
		return false
	ground = step
	return true


func _stripped(t: float) -> float:
	return Exposure.stripped(_ctx.field, x, z, t, _ctx.tuning, _memo)


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
	return piece.sand_line_at(p, level())


## Its look in a state, its frame's origin at `at` in its chunk's frame.
func view(at: Vector3, s: int) -> MeshInstance3D:
	var made := MeshInstance3D.new()
	made.mesh = piece.mesh(s, _variant)
	made.transform = placed(at)
	made.set_instance_shader_parameter(&"age", _age)
	made.set_instance_shader_parameter(&"era", float(piece.marks))
	return made


## Its look in a state, in its own colours.
func look(s: int) -> ArrayMesh:
	return piece.mesh(s, _variant)


## Its frame with its origin at `at`, turned and leaning.
func placed(at: Vector3) -> Transform3D:
	return Transform3D(basis(), at) * _lean()


## Its collision: a box for each box the sand leaves showing in a state, in
## its own frame. The sand and it are one ground.
func add_shapes(body: CollisionObject3D, s: int) -> void:
	for i in piece.shown(s):
		var holder := CollisionShape3D.new()
		holder.shape = piece.shape(i)
		holder.position = piece.boxes[i].get_center()
		body.add_child(holder)


## Where its frame's origin is, world metres.
func origin() -> Vector3:
	return Vector3(x, floor_y, z)


# --- How it's seen from far off (Skyline). ---

## Its frame in a state with the dunes' mean under it at `under`: its own
## pad where it's built, the far ground's height for a stand-in.
func frame_on(s: int, under: float) -> Transform3D:
	return Transform3D(basis(), Vector3(x, under - piece.sink[s], z)) * _lean()


## Its own frame at a level, on its pad.
func frame_at(at_level: float) -> Transform3D:
	return Transform3D(basis(), Vector3(x, _pad - piece.sink_at(at_level), z)) * _lean()


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


## The same at a level between states, each with its index among its kind's
## glints, so it's the same glint as it comes and goes.
func bare_glints_at(at_level: float) -> Array[Array]:
	var lean := _lean()
	var out: Array[Array] = []
	for j in piece.glints.size():
		var each: Array = piece.glints[j]
		var at: Vector3 = lean * (each[0] as Vector3)
		var bare := at.y - piece.sink_at(at_level) >= StructureKit.GLINT_CLEAR if piece.lean > 0.0 \
			else at.y - StructureKit.GLINT_CLEAR > piece.sand_line_at(Vector2(at.x, at.z), at_level) + StructureKit.SHOWS
		if bare:
			out.append([at, lean.basis * (each[1] as Vector3), each[2], j])
	return out


## How it leans, about its kind's pivot, so its free end digs into the sand.
func _lean() -> Transform3D:
	if piece.lean == 0.0 or tilt == 0.0:
		return Transform3D.IDENTITY
	var turned := Basis(piece.lean_axis, tilt * piece.lean)
	return Transform3D(turned, piece.lean_pivot - turned * piece.lean_pivot)
