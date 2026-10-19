class_name TerrainShape
extends RefCounted
## The ground's one function. The visible mesh, the collision and every placed
## object read height_at(); nothing computes height any other way.
##
## The dunes are ridges across the run's long-term wind: a gentle windward
## ramp, a rounded crest, a slip face, then a bare flat before the next. They
## are ramps measured in true metres, joined with min and max, which never
## steepen what they join, so nothing passes sand's 33° (look/dunes/measure
## checks). Between the 1 m lattice points the ground is the lattice's
## triangles, split as the mesh and collision split them, so all three agree
## exactly, crests included. Structures are part of it: each one's footprint
## is pressed into the dunes it stands in (Structure.sand).

## The wander changes this much slower down the wind than along a crest, so
## neighbouring crests wander together, as real ones do.
const WANDER_STRETCH := 0.3
## How deep crests dip along their length, as a share of their height.
const SADDLE_DEPTH := 0.35
## Share of each period left bare between ridges, where sand is short and
## where it's plentiful.
const BARE := Vector2(0.55, 0.05)
## A fork joins the ridge it runs into rounded over about this much height,
## m, at full strength, so it meets it in a curve, not a wedge.
const FORK_ROUND := 10.0

var _spacing: float
## Rise per metre of the windward ramp at full sand, and of the slip face.
var _rise: float
var _slip: float
var _crest_round: float
var _toe_round: float
var _wander: float
var _land_height: float
## Downwind, a unit vector in world x and z.
var _down: Vector2
var _land := FastNoiseLite.new()
var _sand := FastNoiseLite.new()
var _meander := FastNoiseLite.new()
var _fork_meander := FastNoiseLite.new()
var _fork_patch := FastNoiseLite.new()
var _saddle := FastNoiseLite.new()
## The plan of the whole moon, and the index that lays it near you and
## answers for every site on the ground.
var history: History
var sites: Sites
## Lattice points the main thread has read, by packed i and j; emptied
## when it holds HELD_MAX, a few chunks' worth.
const HELD_MAX := 16384
var _held := {}


func _init(run_seed: int, tuning: Tuning) -> void:
	_spacing = tuning.dune_spacing
	_rise = tan(deg_to_rad(tuning.dune_windward_degrees))
	_slip = tan(deg_to_rad(tuning.dune_slip_degrees))
	_crest_round = tuning.dune_rounding
	_toe_round = tuning.dune_rounding * 0.75
	_wander = tuning.dune_wander
	_land_height = tuning.land_height
	_down = Vector2.from_angle(WeatherField.mean_heading(run_seed))
	_field(_land, run_seed + 11, tuning.land_wavelength, 2)
	_field(_sand, run_seed + 12, tuning.sand_wavelength, 2)
	_field(_meander, run_seed + 13, tuning.dune_wander_wavelength, 1)
	_field(_fork_meander, run_seed + 14, tuning.dune_wander_wavelength * 0.8, 1)
	_field(_fork_patch, run_seed + 15, tuning.dune_fork_wavelength, 1)
	_field(_saddle, run_seed + 16, tuning.dune_saddle_wavelength, 1)
	history = History.new(run_seed, tuning)
	sites = Sites.new(history, self, tuning)


static func _field(noise: FastNoiseLite, noise_seed: int, wavelength: float, octaves: int) -> void:
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 1.0 / wavelength
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves


## World coordinates in metres. FastNoiseLite takes 32-bit inputs, so detail
## coarsens after ~1000 km of travel, but every reader still agrees exactly.
func height_at(x: float, z: float) -> float:
	var on := sites.covering(x, z)
	var i := floorf(x)
	var j := floorf(z)
	var fx := x - i
	var fz := z - j
	if fx == 0.0 and fz == 0.0:
		return sample(i, j, on)
	return across(fx, fz, sample(i + 1.0, j, on), sample(i, j + 1.0, on),
		sample(i, j, on) if fx + fz <= 1.0 else sample(i + 1.0, j + 1.0, on))


## height_at for the main thread, the same numbers from held lattice points:
## what floats or rests in the camp reads the same few points tick after tick.
func held_height_at(x: float, z: float) -> float:
	if sites.covering(x, z) != null:
		return height_at(x, z)
	var i := floorf(x)
	var j := floorf(z)
	var fx := x - i
	var fz := z - j
	if fx == 0.0 and fz == 0.0:
		return held(i, j)
	return across(fx, fz, held(i + 1.0, j), held(i, j + 1.0),
		held(i, j) if fx + fz <= 1.0 else held(i + 1.0, j + 1.0))


## The highest the ground rises anywhere over a world rectangle: between
## lattice points it's their triangles, never above the highest of them. INF
## where a structure might stand, since its ground isn't the dunes'.
func highest_in(x0: float, z0: float, x1: float, z1: float) -> float:
	# Narrower than any structure's ground, it can only reach that by a corner.
	if not (x1 - x0 <= sites.narrowest() and z1 - z0 <= sites.narrowest()):
		return INF
	# Asked at full precision, as height_at asks: a Vector2 would round them.
	if sites.covering(x0, z0) != null or sites.covering(x1, z0) != null \
			or sites.covering(x0, z1) != null or sites.covering(x1, z1) != null:
		return INF
	var top := -INF
	for j in range(floori(z0), floori(z1) + 2):
		for i in range(floori(x0), floori(x1) + 2):
			top = maxf(top, held(i, j))
	return top


## The bare dunes at a lattice point, held once read. Main thread only:
## the chunk workers read the shape too, and nothing here is locked.
func held(i: float, j: float) -> float:
	var key := (int(i) << 32) ^ (int(j) & 0xffffffff)
	var h: Variant = _held.get(key)
	if h == null:
		if _held.size() >= HELD_MAX:
			_held.clear()
		h = sample(i, j)
		_held[key] = h
	return h


## Between lattice points: the triangle a point falls in, split from (i+1, j)
## to (i, j+1) as the mesh and collision split each square. east is (i+1, j),
## south (i, j+1), and corner (i, j) when fx + fz <= 1, else (i+1, j+1).
static func across(fx: float, fz: float, east: float, south: float, corner: float) -> float:
	if fx + fz <= 1.0:
		return corner + fx * (east - corner) + fz * (south - corner)
	return corner + (1.0 - fx) * (south - corner) + (1.0 - fz) * (east - corner)


## The ground at a lattice point, with the footprint of the structure whose
## ground it might be on, if any: the site index says which.
func sample(x: float, z: float, on: Structure = null) -> float:
	var h := dunes(x, z)
	return h if on == null else on.sand(x, z, h)


## The dunes alone at a lattice point, before any structure. Its GPU twin
## is DUNES_GLSL.
func dunes(x: float, z: float) -> float:
	var land := _land.get_noise_2d(x, z)
	# Down the wind, and across it.
	var u := x * _down.x + z * _down.y
	var v := z * _down.x - x * _down.y
	return land * _land_height + _ridges(u, v, _sand_on(x, z, land))


## The run's long-term wind, which the dunes face: downwind, a unit vector in
## world x and z.
func downwind() -> Vector2:
	return _down


## How much sand lies here, 0 to 1: dune seas where it's high.
func sand_at(x: float, z: float) -> float:
	return _sand_on(x, z, _land.get_noise_2d(x, z))


## Sand gathers in the land's basins.
func _sand_on(x: float, z: float, land: float) -> float:
	return clampf(0.5 + 0.9 * _sand.get_noise_2d(x, z) - 0.4 * land, 0.0, 1.0)


## Ridges, bigger and closer together the more sand there is, rising and
## dipping along each crest, and forking where a second set grows.
func _ridges(u: float, v: float, sand: float) -> float:
	var saddle := 1.0 - SADDLE_DEPTH + SADDLE_DEPTH * _saddle.get_noise_2d(u * WANDER_STRETCH, v)
	var bare := lerpf(BARE.x, BARE.y, sand)
	var h := _ridge_set(u, v, _meander, _rise * sand * saddle, bare)
	var fork := smoothstep(0.05, 0.45, _fork_patch.get_noise_2d(u, v)) * sand
	if fork > 0.0:
		# The rounding fades with the fork, so where forks thin out no step is left.
		h = -_rounded_min(-h, -_ridge_set(u + 0.5 * _spacing, v, _fork_meander, _rise * fork * saddle, bare),
			FORK_ROUND * fork)
	return h


## One set of ridges: a windward ramp at `rise`, a rounded crest, a slip face,
## then `bare` of each period flat before the next. Distances are true metres:
## where the wander turns or bunches crests, the period is measured across
## them, not along the wind.
func _ridge_set(u: float, v: float, meander: FastNoiseLite, rise: float, bare: float) -> float:
	var su := u * WANDER_STRETCH
	var w := meander.get_noise_2d(su, v) * _wander
	var wu := 1.0 + meander.get_noise_2d(su + WANDER_STRETCH, v) * _wander - w
	var wv := meander.get_noise_2d(su, v + 1.0) * _wander - w
	var span := _spacing / sqrt(wu * wu + wv * wv)
	var p := (u + w) / _spacing
	var t := p - floorf(p)
	var crest := _rounded_min(span * (t - bare) * rise, span * (1.0 - t) * _slip, _crest_round)
	# Just past a lee foot the last ridge's slip face runs on below the sand,
	# so the period's wrap is seamless. Rounding shrinks with the ridge, so
	# ridges fading out leave no step behind.
	return _rounded_max0(maxf(crest, -span * t * _slip), _toe_round * clampf(rise / 0.05, 0.02, 1.0))


## min, and max with 0, with the corner rounded over k: a blend of the two
## slopes, so never steeper than either.
static func _rounded_min(a: float, b: float, k: float) -> float:
	var h := maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * k * 0.25


static func _rounded_max0(a: float, k: float) -> float:
	var h := maxf(k - absf(a), 0.0) / k
	return maxf(a, 0.0) + h * h * k * 0.25


## dunes() on the GPU, for the wind map's lee (WindMap), reading what
## pack_dunes() packs into its params block p: change one, change the other.
## No structures: their ground is pressed in on the CPU only.
const DUNES_PARAMS := "vec4 dune_a; vec4 dune_b; vec4 dune_c; vec4 dune_d; Noise land; Noise sand; Noise meander; Noise fork_meander; Noise fork_patch; Noise saddle;"
const DUNES_GLSL := """
float dune_rounded_min(float a, float b, float k) {
	float h = max(k - abs(a - b), 0.0) / k;
	return min(a, b) - h * h * k * 0.25;
}

float dune_rounded_max0(float a, float k) {
	float h = max(k - abs(a), 0.0) / k;
	return max(a, 0.0) + h * h * k * 0.25;
}

float dune_ridge_set(float u, float v, Noise meander, float rise, float bare) {
	float spacing = p.dune_a.x;
	float stretch = p.dune_c.y;
	float wander = p.dune_b.z;
	float su = u * stretch;
	float w = noise2(meander, su, v) * wander;
	float wu = 1.0 + noise2(meander, su + stretch, v) * wander - w;
	float wv = noise2(meander, su, v + 1.0) * wander - w;
	float span = spacing / sqrt(wu * wu + wv * wv);
	float q = (u + w) / spacing;
	float t = q - floor(q);
	float crest = dune_rounded_min(span * (t - bare) * rise, span * (1.0 - t) * p.dune_a.z, p.dune_a.w);
	return dune_rounded_max0(max(crest, -span * t * p.dune_a.z), p.dune_c.x * clamp(rise / 0.05, 0.02, 1.0));
}

float dunes(vec2 at) {
	float land = noise2(p.land, at.x, at.y);
	float u = at.x * p.dune_b.x + at.y * p.dune_b.y;
	float v = at.y * p.dune_b.x - at.x * p.dune_b.y;
	float sand = clamp(0.5 + 0.9 * noise2(p.sand, at.x, at.y) - 0.4 * land, 0.0, 1.0);
	float rise = p.dune_a.y;
	float saddle = 1.0 - p.dune_c.z + p.dune_c.z * noise2(p.saddle, u * p.dune_c.y, v);
	float bare = mix(p.dune_d.x, p.dune_d.y, sand);
	float h = dune_ridge_set(u, v, p.meander, rise * sand * saddle, bare);
	float fork = smoothstep(0.05, 0.45, noise2(p.fork_patch, u, v)) * sand;
	if (fork > 0.0) {
		h = -dune_rounded_min(-h, -dune_ridge_set(u + 0.5 * p.dune_a.x, v, p.fork_meander, rise * fork * saddle, bare),
			p.dune_c.w * fork);
	}
	return land * p.dune_b.w + h;
}
"""


func pack_dunes(into: StreamPeerBuffer) -> void:
	for v: float in [_spacing, _rise, _slip, _crest_round, _down.x, _down.y, _wander, _land_height,
			_toe_round, WANDER_STRETCH, SADDLE_DEPTH, FORK_ROUND, BARE.x, BARE.y, 0.0, 0.0]:
		into.put_float(v)
	for noise in [_land, _sand, _meander, _fork_meander, _fork_patch, _saddle]:
		NoiseGLSL.pack(noise, into)
