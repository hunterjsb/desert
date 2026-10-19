class_name Lee
extends RefCounted
## The ground's lee: downwind of a crest that stands well above a place the
## wind is weaker, most of all close under a steep slip face, fading out a few
## crest-heights on, and none on a windward slope or an open flat. Read from
## the ground upwind along the wind as it blows, so it turns with the wind.
##
## Worked out at points on a lattice of places and headings and blended
## between them. Each point is a pure function of the ground and its heading,
## so the cache only saves work: a body resting in one place costs one
## lookup a tick, whatever is loaded and whatever was asked before.

## Lattice points this far apart, m: a lee changes over crest-heights, not metres.
const CELL := 4.0
## Headings this far apart, degrees: the wind turns a degree in tens of seconds.
const TURN_DEGREES := 2.0
## Headings kept at once: the two the wind is between, and room for a power
## tick reading a moment either side.
const KEPT_HEADINGS := 4
## A heading's lattice is forgotten past this many points, after a long ride.
const KEPT_POINTS := 65536

var _terrain: Terrain
var _shape: TerrainShape
var _turn := deg_to_rad(TURN_DEGREES)
var _headings := roundi(360.0 / TURN_DEGREES)
## Metres upwind of a place to read the ground at, nearest first.
var _reach := PackedFloat64Array()
var _spread: float
var _far: float
var _heights: Vector2
var _tall: Vector2
var _face: Vector2
var _windward: Vector2
## Heading index -> {lattice point: share}, oldest first.
var _points := {}
## (cell, heading index) -> the shares at its four corners at that heading
## and the next: what a body resting in the cell reads every tick.
var _cells := {}
var _held := PackedFloat32Array([0.0])


func _init(world: World) -> void:
	var tuning := world.tuning
	_terrain = world.terrain
	_shape = world.shape
	_heights = tuning.lee_heights
	_tall = tuning.lee_tall
	_face = Vector2(tan(deg_to_rad(tuning.lee_face_degrees.x)), tan(deg_to_rad(tuning.lee_face_degrees.y)))
	_windward = Vector2(tan(deg_to_rad(tuning.lee_windward_degrees.x)), tan(deg_to_rad(tuning.lee_windward_degrees.y)))
	# Spread out with distance, each the same share further than the last:
	# a crest's shelter scales with its height, so a far one needs a tall
	# crest to count and a coarser look finds it.
	var first := 2.0
	_far = tuning.lee_reach
	var count := maxi(tuning.lee_samples, 2)
	_spread = pow(tuning.lee_reach / first, 1.0 / (count - 1))
	for k in count:
		_reach.append(first * pow(_spread, k))


## How much shelter the ground gives a world place from a wind blowing toward
## heading (radians, world x and z), 0 to 1 of a full lee.
func share(x: float, z: float, heading: float) -> float:
	var b := fposmod(heading, TAU) / _turn
	var b0 := floori(b)
	var gx := x / CELL
	var gz := z / CELL
	var i := floori(gx)
	var j := floori(gz)
	var key := Vector3i(i, j, b0)
	var got: Variant = _cells.get(key)
	if got == null:
		if _cells.size() > KEPT_POINTS:
			_cells.clear()
		got = _corners(b0 % _headings, i, j) + _corners((b0 + 1) % _headings, i, j)
		_cells[key] = got
	var c: PackedFloat64Array = got
	var fx := gx - i
	var fz := gz - j
	return lerpf(lerpf(lerpf(c[0], c[1], fx), lerpf(c[2], c[3], fx), fz),
		lerpf(lerpf(c[4], c[5], fx), lerpf(c[6], c[7], fx), fz), b - b0)


func _corners(heading: int, i: int, j: int) -> PackedFloat64Array:
	var known: Dictionary = _points.get(heading, {})
	if not _points.has(heading):
		if _points.size() >= KEPT_HEADINGS:
			_points.erase(_points.keys()[0])
		_points[heading] = known
	elif known.size() > KEPT_POINTS:
		known.clear()
	return PackedFloat64Array([_known(known, heading, i, j), _known(known, heading, i + 1, j),
		_known(known, heading, i, j + 1), _known(known, heading, i + 1, j + 1)])


func _known(known: Dictionary, heading: int, i: int, j: int) -> float:
	var key := Vector2i(i, j)
	var got: Variant = known.get(key)
	if got == null:
		got = _point(key, heading)
		known[key] = got
	return got


func _point(at: Vector2i, heading: int) -> float:
	return exact(at.x * CELL, at.y * CELL, heading * _turn)


## The lee at a world place and heading, off the lattice: the best shelter
## any crest upwind gives, by how many of its own heights away it stands, how
## far above the place it rises and how steeply the ground falls from it
## toward the place; none if the place itself is on a slope climbing into the
## wind. share() blends these; the wind map draws them (LEE_GLSL).
func exact(x: float, z: float, heading: float) -> float:
	var up := -Vector2.from_angle(heading)
	var here := _ground(x, z)
	var best := 0.0
	var best_k := -1
	var best_steepest := 0.0
	var steepest := -INF
	var last := here
	var last_s := 0.0
	var climbing := 0.0
	for k in _reach.size():
		var s := _reach[k]
		var h := _ground(x + up.x * s, z + up.y * s)
		# How fast the ground falls going downwind, toward the place.
		var fall := (h - last) / (s - last_s)
		if k == 0:
			climbing = -fall
		steepest = maxf(steepest, fall)
		var strength := _strength(s, h - here, steepest)
		if strength > best:
			best = strength
			best_k = k
			best_steepest = steepest
		last = h
		last_s = s
	if best_k >= 0:
		# Between samples a crest's top can fall short: look either side once.
		var half := sqrt(_spread)
		for s: float in [_reach[best_k] * half, _reach[best_k] / half]:
			best = maxf(best, _strength(s, _ground(x + up.x * s, z + up.y * s) - here, best_steepest))
	return best * (1.0 - smoothstep(_windward.x, _windward.y, climbing))


## The shelter a crest gives from s m upwind, standing tall m above the
## place, the ground falling at most `steepest` (rise per metre) between.
func _strength(s: float, tall: float, steepest: float) -> float:
	if tall <= _tall.x:
		return 0.0
	return (1.0 - smoothstep(_heights.x, _heights.y, s / tall)) * smoothstep(_tall.x, _tall.y, tall) \
		* smoothstep(_face.x, _face.y, steepest) * (1.0 - smoothstep(_far * 0.75, _far, s))


## The ground at a world place from its own samples every 2 m, split into
## triangles as the chunks split theirs: the ground as a mid chunk draws it,
## within centimetres of height_at. Every loaded chunk, near or mid, holds
## those samples, and the shape gives the same numbers anywhere else.
func _ground(x: float, z: float) -> float:
	var i := floori(x * 0.5) * 2
	var j := floori(z * 0.5) * 2
	var fx := (x - i) * 0.5
	var fz := (z - j) * 0.5
	var chunk := _terrain.chunk_under(i, j)
	if chunk == null or chunk.step == 0 or 2 % chunk.step != 0:
		return TerrainShape.across(fx, fz, _sample(i + 2, j), _sample(i, j + 2),
			_sample(i, j) if fx + fz <= 1.0 else _sample(i + 2, j + 2))
	# The cell's far corners are on the chunk's own far edges at most.
	var w := chunk.side / chunk.step + 1
	var by := 2 / chunk.step
	var k := (j - chunk.coord.y * chunk.side) / chunk.step * w + (i - chunk.coord.x * chunk.side) / chunk.step
	var h := chunk.heights
	return TerrainShape.across(fx, fz, h[k + by], h[k + by * w], h[k] if fx + fz <= 1.0 else h[k + by * w + by])


## The shape's sample at a whole-metre point, held to 32 bits as a chunk
## holds it, so a point works out the same whether its ground was loaded.
func _sample(i: int, j: int) -> float:
	_held[0] = _shape.height_at(i, j)
	return _held[0]


## exact() on the GPU, for the wind map (WindMap), reading what pack_lee()
## packs into its params block p: change one, change the other. ground() is
## the map's own 2 m heights, split as _ground() splits them.
const LEE_PARAMS := "vec4 lee_a; vec4 lee_b; vec4 lee_c;"
const LEE_GLSL := """
float lee_strength(float s, float tall, float steepest) {
	if (tall <= p.lee_a.z) {
		return 0.0;
	}
	return (1.0 - smoothstep(p.lee_a.x, p.lee_a.y, s / tall)) * smoothstep(p.lee_a.z, p.lee_a.w, tall)
		* smoothstep(p.lee_b.x, p.lee_b.y, steepest) * (1.0 - smoothstep(p.lee_c.z * 0.75, p.lee_c.z, s));
}

// at: a place in the ground's metres; up: upwind, a unit vector.
float lee_share(vec2 at, vec2 up) {
	float here = ground(at);
	float best = 0.0;
	int best_k = -1;
	float best_steepest = 0.0;
	float steepest = -1.0e30;
	float last = here;
	float last_s = 0.0;
	float climbing = 0.0;
	for (int k = 0; k < int(p.lee_c.w); k++) {
		float s = p.lee_c.x * pow(p.lee_c.y, float(k));
		float h = ground(at + up * s);
		float fall = (h - last) / (s - last_s);
		if (k == 0) {
			climbing = -fall;
		}
		steepest = max(steepest, fall);
		float strength = lee_strength(s, h - here, steepest);
		if (strength > best) {
			best = strength;
			best_k = k;
			best_steepest = steepest;
		}
		last = h;
		last_s = s;
	}
	if (best_k >= 0) {
		float half_step = sqrt(p.lee_c.y);
		float s = p.lee_c.x * pow(p.lee_c.y, float(best_k));
		best = max(best, lee_strength(s * half_step, ground(at + up * (s * half_step)) - here, best_steepest));
		best = max(best, lee_strength(s / half_step, ground(at + up * (s / half_step)) - here, best_steepest));
	}
	return best * (1.0 - smoothstep(p.lee_b.z, p.lee_b.w, climbing));
}
"""


func pack_lee(into: StreamPeerBuffer) -> void:
	for v: float in [_heights.x, _heights.y, _tall.x, _tall.y, _face.x, _face.y, _windward.x, _windward.y,
			_reach[0], _spread, _far, float(_reach.size())]:
		into.put_float(v)
