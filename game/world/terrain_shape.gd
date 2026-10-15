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
## exactly, crests included.

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


static func _field(noise: FastNoiseLite, noise_seed: int, wavelength: float, octaves: int) -> void:
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 1.0 / wavelength
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves


## World coordinates in metres. FastNoiseLite takes 32-bit inputs, so detail
## coarsens after ~1000 km of travel, but every reader still agrees exactly.
func height_at(x: float, z: float) -> float:
	var i := floorf(x)
	var j := floorf(z)
	var fx := x - i
	var fz := z - j
	if fx == 0.0 and fz == 0.0:
		return sample(i, j)
	return across(fx, fz, sample(i + 1.0, j), sample(i, j + 1.0),
		sample(i, j) if fx + fz <= 1.0 else sample(i + 1.0, j + 1.0))


## Between lattice points: the triangle a point falls in, split from (i+1, j)
## to (i, j+1) as the mesh and collision split each square. east is (i+1, j),
## south (i, j+1), and corner (i, j) when fx + fz <= 1, else (i+1, j+1).
static func across(fx: float, fz: float, east: float, south: float, corner: float) -> float:
	if fx + fz <= 1.0:
		return corner + fx * (east - corner) + fz * (south - corner)
	return corner + (1.0 - fx) * (south - corner) + (1.0 - fz) * (east - corner)


## The ground at a lattice point.
func sample(x: float, z: float) -> float:
	var land := _land.get_noise_2d(x, z)
	# Down the wind, and across it.
	var u := x * _down.x + z * _down.y
	var v := z * _down.x - x * _down.y
	return land * _land_height + _ridges(u, v, _sand_on(x, z, land))


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
