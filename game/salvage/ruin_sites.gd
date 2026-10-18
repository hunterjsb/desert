class_name RuinSites
extends RefCounted
## Where this run's ruins stand: at most one in each square cell of
## ruin_cell_chunks chunks a side, wholly inside one chunk so a ruin is that
## chunk's ground and nobody else's, and only where the dunes are flat enough
## to take its floor. Pure in the seed, like the dunes it stands in.
##
## Asking whether a place is on a ruin costs a table lookup: each cell's
## candidate spot comes from the seed alone, and only near it is the ground
## surveyed, once a run, to say whether a ruin really stands there.

## A ruin's middle stays this far inside its chunk, so its ground and the
## lattice point beyond never reach a neighbour.
const MARGIN := Ruin.REACH + 1
## The survey's grid, m.
const SURVEY_STEP := 2
## Candidates repeat every this many cells each way; the dunes under them
## don't, so the ruins don't.
const TABLE := 64

var _on: bool
var _chunk: int
var _per_cell: int
var _cell: int
var _max_rise: float
var _max_grade: float
## The terrain shape, held weakly: it holds us.
var _shape: WeakRef
## Each cell's candidate within it, packed: x and z metres, 12 bits each, then
## quarter turns.
var _spots := PackedInt32Array()
## Cells surveyed: the Ruin standing there, or null.
var _known := {}
var _lock := Mutex.new()


func _init(run_seed: int, tuning: Tuning, shape: TerrainShape) -> void:
	_on = tuning.salvage
	_chunk = tuning.chunk_size
	_per_cell = tuning.ruin_cell_chunks
	_cell = _chunk * _per_cell
	_max_rise = tuning.ruin_max_rise
	_max_grade = tan(deg_to_rad(tuning.ruin_max_degrees))
	_shape = weakref(shape)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, "ruins"])
	var span := _chunk - 2 * MARGIN + 1
	_spots.resize(TABLE * TABLE)
	for k in _spots.size():
		var x := rng.randi_range(0, _per_cell - 1) * _chunk + MARGIN + rng.randi_range(0, span - 1)
		var z := rng.randi_range(0, _per_cell - 1) * _chunk + MARGIN + rng.randi_range(0, span - 1)
		_spots[k] = x | (z << 12) | (rng.randi_range(0, 3) << 24)


## The ruin whose ground a world place might be on, or null: the one cheap
## check every height_at makes.
func covering(x: float, z: float) -> Ruin:
	if not _on:
		return null
	var i := floori(x / _cell)
	var j := floori(z / _cell)
	var code := _spots[(i & (TABLE - 1)) * TABLE + (j & (TABLE - 1))]
	if absf(x - i * _cell - (code & 4095)) > MARGIN or absf(z - j * _cell - ((code >> 12) & 4095)) > MARGIN:
		return null
	var cell := Vector2i(i, j)
	return _site(cell, _spot(cell))


## The ruin standing in a chunk, or null.
func in_chunk(coord: Vector2i) -> Ruin:
	if not _on:
		return null
	var cell := Vector2i(floori(float(coord.x) / _per_cell), floori(float(coord.y) / _per_cell))
	var spot := _spot(cell)
	if Vector2i(floori(float(spot.x) / _chunk), floori(float(spot.y) / _chunk)) != coord:
		return null
	return _site(cell, spot)


## Every ruin within `radius` m of a world place, nearest first.
func around(x: float, z: float, radius: float) -> Array[Ruin]:
	var found: Array[Ruin] = []
	if not _on:
		return found
	var lo := Vector2i(floori((x - radius) / _cell), floori((z - radius) / _cell))
	var hi := Vector2i(floori((x + radius) / _cell), floori((z + radius) / _cell))
	for j in range(lo.y, hi.y + 1):
		for i in range(lo.x, hi.x + 1):
			var cell := Vector2i(i, j)
			var ruin := _site(cell, _spot(cell))
			if ruin != null and Vector2(ruin.center).distance_to(Vector2(x, z)) <= radius:
				found.append(ruin)
	var from := Vector2(x, z)
	found.sort_custom(func(a: Ruin, b: Ruin) -> bool:
		return Vector2(a.center).distance_squared_to(from) < Vector2(b.center).distance_squared_to(from))
	return found


## Every ruin whose ground touches a rectangle of world metres.
func touching(rect: Rect2) -> Array[Ruin]:
	var found: Array[Ruin] = []
	if not _on:
		return found
	var grown := rect.grow(Ruin.REACH)
	for j in range(floori(grown.position.y / _cell), floori(grown.end.y / _cell) + 1):
		for i in range(floori(grown.position.x / _cell), floori(grown.end.x / _cell) + 1):
			var cell := Vector2i(i, j)
			var spot := _spot(cell)
			if not grown.has_point(Vector2(spot.x, spot.y)):
				continue
			var ruin := _site(cell, spot)
			if ruin != null and ruin.touches(rect):
				found.append(ruin)
	return found


## The nearest ruin within `radius` m of a world place whose middle `wanted`
## keeps, or null. The test is asked before the ground is surveyed, so one
## of the seed alone spares the surveys a wide search would cost.
func nearest(x: float, z: float, radius: float, wanted: Callable) -> Ruin:
	if not _on:
		return null
	var from := Vector2(x, z)
	var lo := Vector2i(floori((x - radius) / _cell), floori((z - radius) / _cell))
	var hi := Vector2i(floori((x + radius) / _cell), floori((z + radius) / _cell))
	var near: Array[Vector3i] = []
	for j in range(lo.y, hi.y + 1):
		for i in range(lo.x, hi.x + 1):
			var spot := _spot(Vector2i(i, j))
			if Vector2(spot.x, spot.y).distance_to(from) <= radius:
				near.append(spot)
	near.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return Vector2(a.x, a.y).distance_squared_to(from) < Vector2(b.x, b.y).distance_squared_to(from))
	for spot in near:
		if wanted.call(Vector2i(spot.x, spot.y)):
			var ruin := _site(Vector2i(floori(float(spot.x) / _cell), floori(float(spot.y) / _cell)), spot)
			if ruin != null:
				return ruin
	return null


## A cell's candidate: its middle (x, z) in world metres, and quarter turns.
func _spot(cell: Vector2i) -> Vector3i:
	var code := _spots[(cell.x & (TABLE - 1)) * TABLE + (cell.y & (TABLE - 1))]
	return Vector3i(cell.x * _cell + (code & 4095), cell.y * _cell + ((code >> 12) & 4095), code >> 24)


## The ruin standing on a cell's candidate, surveyed once; workers ask too.
func _site(cell: Vector2i, spot: Vector3i) -> Ruin:
	_lock.lock()
	var seen := _known.has(cell)
	var ruin: Ruin = _known.get(cell)
	_lock.unlock()
	if seen:
		return ruin
	ruin = _survey(spot)
	_lock.lock()
	_known[cell] = ruin
	_lock.unlock()
	return ruin


## A ruin stands on its candidate if the dunes over all its ground rise no
## more than ruin_max_rise and are nowhere steeper than ruin_max_degrees. Its
## floor sits at their mean under it.
func _survey(spot: Vector3i) -> Ruin:
	var shape: TerrainShape = _shape.get_ref()
	if shape == null:
		return null
	var half := Ruin.half_on(spot.z)
	var reach := half + Vector2i.ONE * int(Ruin.APRON)
	var low := INF
	var high := -INF
	var under := 0.0
	var count := 0
	var row := PackedFloat32Array()
	var last := PackedFloat32Array()
	for j in range(-reach.y, reach.y + 1, SURVEY_STEP):
		row.clear()
		for i in range(-reach.x, reach.x + 1, SURVEY_STEP):
			var h := shape.dunes(spot.x + i, spot.y + j)
			low = minf(low, h)
			high = maxf(high, h)
			if absi(i) <= half.x and absi(j) <= half.y:
				under += h
				count += 1
			var k := row.size()
			if (k > 0 and absf(h - row[k - 1]) > _max_grade * SURVEY_STEP) \
					or (not last.is_empty() and absf(h - last[k]) > _max_grade * SURVEY_STEP):
				return null
			row.append(h)
		last = row.duplicate()
	if high - low > _max_rise:
		return null
	return Ruin.new(Vector2i(spot.x, spot.y), spot.z, under / count)
