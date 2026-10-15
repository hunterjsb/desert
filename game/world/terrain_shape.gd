class_name TerrainShape
extends RefCounted
## The ground's one function. The visible mesh, the collision and every placed
## object read height_at(); nothing computes height any other way.
##
## Shaped dunes (every style but Noise) are ramps measured in true metres,
## joined with min and max, which never steepen what they join: slip faces lie
## at SLIP and nothing on the ground passes sand's 33° (look/dunes/measure
## checks). They face the run's mean wind, so they hold still while the day's
## wind swings.

enum Style { NOISE, RIDGES, CRESCENTS, SCALLOPED, REGIONS }

## Slip faces, as rise per metre: 31.5°, under sand's 33° so the land beneath
## and the turning crests never tip one past it.
const SLIP := 0.6128
## Rounds crests and toes over about this much height, m, so 1 m samples
## don't facet them.
const CREST_ROUND := 1.6
const TOE_ROUND := 1.2
## The land under the dunes: broad basins and rises, about 1° at most.
const LAND_WAVELENGTH := 7000.0
const LAND_HEIGHT := 12.0
## Sand supply: dune seas where it's high, hard flats and corridors where low.
const SAND_WAVELENGTH := 2600.0

## Ridges across the wind, and their windward ramp at full sand: 14°.
const RIDGE_SPACING := 260.0
const RIDGE_RISE := 0.2493
## Crest lines wander this far, m, and over this length along a crest.
const MEANDER := 70.0
const MEANDER_WAVELENGTH := 600.0
## The meander changes this much slower down the wind than along a crest, so
## neighbouring crests wander together, as real ones do.
const MEANDER_STRETCH := 0.3
## Crests rise and dip along their length over about this far, m.
const SADDLE_WAVELENGTH := 900.0
## A second set of crests grows in patches between the first and wanders on
## its own: where it runs into one, the crest forks.
const FORK_PATCH_WAVELENGTH := 700.0
const FORK_ROUND := 4.0

## Crescents: at most one per cell, horns downwind. Cells and radii are down
## the wind and across it, m; the windward cone rises at 12°.
const CRESCENT_CELL := Vector2(280.0, 260.0)
const CRESCENT_RADIUS := Vector2(40.0, 105.0)
const CRESCENT_RISE := 0.2126
## Across the wind a crescent is this much wider than long: squashed, never
## stretched, so its slopes only get gentler.
const CRESCENT_WIDTH := 1.3
## Packed crescents, every cell full and their horns joining into scalloped ridges.
const SCALLOP_CELL := Vector2(210.0, 170.0)
const SCALLOP_RADIUS := Vector2(80.0, 105.0)
## Rows of them wander less than ridges, or the crescents would smear.
const SCALLOP_MEANDER := 40.0
## Share of a cell a centre may wander from its middle.
const JITTER := 0.2

var _style: int
var _noise := FastNoiseLite.new()
var _amplitude: float

var _seed: int
## Downwind, a unit vector in world x and z.
var _down := Vector2.RIGHT
var _land := FastNoiseLite.new()
var _sand := FastNoiseLite.new()
var _meander := FastNoiseLite.new()
var _fork_meander := FastNoiseLite.new()
var _fork_patch := FastNoiseLite.new()
var _saddle := FastNoiseLite.new()


func _init(run_seed: int, tuning: Tuning) -> void:
	_noise.seed = run_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0 / tuning.dune_wavelength
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = tuning.dune_octaves
	_amplitude = tuning.dune_amplitude
	_style = tuning.dune_style
	if _style == Style.NOISE:
		return
	_seed = run_seed
	_down = Vector2.from_angle(WeatherField.mean_heading(run_seed))
	_field(_land, 11, LAND_WAVELENGTH, 2)
	_field(_sand, 12, SAND_WAVELENGTH, 2)
	_field(_meander, 13, MEANDER_WAVELENGTH, 1)
	_field(_fork_meander, 14, MEANDER_WAVELENGTH * 0.8, 1)
	_field(_fork_patch, 15, FORK_PATCH_WAVELENGTH, 1)
	_field(_saddle, 16, SADDLE_WAVELENGTH, 1)


func _field(noise: FastNoiseLite, salt: int, wavelength: float, octaves: int) -> void:
	noise.seed = _seed + salt
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 1.0 / wavelength
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves


## World coordinates in metres. FastNoiseLite takes 32-bit inputs, so detail
## coarsens after ~1000 km of travel, but every reader still agrees exactly.
func height_at(x: float, z: float) -> float:
	if _style == Style.NOISE:
		return _noise.get_noise_2d(x, z) * _amplitude
	var land := _land.get_noise_2d(x, z)
	# Down the wind, and across it.
	var u := x * _down.x + z * _down.y
	var v := z * _down.x - x * _down.y
	var dunes := 0.0
	if _style == Style.RIDGES:
		dunes = _ridges(u, v, _sand_at(x, z, land))
	elif _style == Style.CRESCENTS:
		dunes = _crescents(u, v, CRESCENT_CELL, CRESCENT_RADIUS, false)
	elif _style == Style.SCALLOPED:
		dunes = _crescents(u, v, SCALLOP_CELL, SCALLOP_RADIUS, true)
	else:
		# Ridges in the dune seas, crescents straying out of them onto the flats.
		var sea := smoothstep(0.35, 1.0, _sand_at(x, z, land))
		dunes = _crescents(u, v, CRESCENT_CELL, CRESCENT_RADIUS, false)
		if sea > 0.0:
			dunes = maxf(dunes, _ridges(u, v, sea))
	return land * LAND_HEIGHT + dunes


## How much sand lies here, 0 to 1. It gathers in the basins.
func _sand_at(x: float, z: float, land: float) -> float:
	return clampf(0.5 + 0.9 * _sand.get_noise_2d(x, z) - 0.4 * land, 0.0, 1.0)


## Ridges across the wind, bigger and closer together the more sand there is,
## rising and dipping along each crest.
func _ridges(u: float, v: float, sand: float) -> float:
	var saddle := 0.65 + 0.35 * _saddle.get_noise_2d(u * MEANDER_STRETCH, v)
	var flat := lerpf(0.55, 0.05, sand)
	var h := _ridge_set(u, v, _meander, RIDGE_RISE * sand * saddle, flat)
	var fork := smoothstep(0.05, 0.45, _fork_patch.get_noise_2d(u, v)) * sand
	if fork > 0.0:
		# Joined rounded, so a fork's slip face meets the ridge it cuts in a
		# curve, not a crease; the rounding fades with the fork, leaving no step.
		h = -_rounded_min(-h, -_ridge_set(u + 0.5 * RIDGE_SPACING, v, _fork_meander, RIDGE_RISE * fork * saddle, flat),
			FORK_ROUND * fork)
	return h


## One set of asymmetric ridges: a windward ramp at `rise`, a rounded crest,
## a SLIP face, then `flat` of each period bare before the next. Distances are
## true metres: where the meander turns or bunches crests, the period is
## measured across them, not along the wind.
func _ridge_set(u: float, v: float, meander: FastNoiseLite, rise: float, flat: float) -> float:
	var bent := _bend(u, v, meander, MEANDER)
	var span := RIDGE_SPACING / bent.y
	var p := bent.x / RIDGE_SPACING
	var t := p - floorf(p)
	# Just past a lee foot the last dune's slip face runs on below the sand,
	# so the period's wrap is seamless.
	return _dune(span * (t - flat), span * (1.0 - t), rise, -span * t)


## The wind coordinate with crest lines wandered by `meander`; how much that
## stretches distances across the crests, which a ridge's ramps shrink by; and
## the most it stretches them any way, which a crescent's do.
func _bend(u: float, v: float, meander: FastNoiseLite, far: float) -> Vector3:
	var su := u * MEANDER_STRETCH
	var w := meander.get_noise_2d(su, v) * far
	var wu := 1.0 + meander.get_noise_2d(su + MEANDER_STRETCH, v) * far - w
	var wv := meander.get_noise_2d(su, v + 1.0) * far - w
	var across := wu * wu + wv * wv
	# The largest singular value of the bend's Jacobian [[wu, wv], [0, 1]].
	var trace := across + 1.0
	return Vector3(u + w, sqrt(across), sqrt(0.5 * trace + sqrt(maxf(0.25 * trace * trace - wu * wu, 0.0))))


## A dune's cross-section from metres past its windward foot and metres short
## of its lee foot (and of the last one's, past it): the ramp at `rise` meets
## the slip face at a rounded crest. Rounding shrinks with the dune, so dunes
## fading out leave no step behind.
func _dune(up: float, down: float, rise: float, past := -INF) -> float:
	var crest := maxf(_rounded_min(up * rise, down * SLIP, CREST_ROUND), past * SLIP)
	return _rounded_max0(crest, TOE_ROUND * clampf(rise / 0.05, 0.02, 1.0))


## Crescents, each from its own cell, as big and as many as the sand there
## allows. Packed, every cell has one, in staggered rows that wander like
## ridges, so the horns join into scalloped crests. The nearest two rows, and
## the nearest two cells in each (three when packed), are every crescent that
## can reach this point.
func _crescents(u: float, v: float, cell: Vector2, radius: Vector2, packed: bool) -> float:
	var bent := _bend(u, v, _meander, SCALLOP_MEANDER) if packed else Vector3(u, 1.0, 1.0)
	var cu := floori(bent.x / cell.x - 0.5)
	var h := 0.0
	for i in 2:
		var row := cu + i
		var shift := 0.5 * (row & 1) if packed else 0.0
		var cv := floori(v / cell.y - shift) - 1 if packed else floori(v / cell.y - 0.5)
		for j in 3 if packed else 2:
			h = maxf(h, _crescent(bent.x, v, bent.z, row, cv + j, shift, cell, radius, packed))
	return h


## Two circles: a windward cone, and a bowl cut from its downwind side for the
## slip face, which leaves the horns. Distances are divided by the bend's
## stretch, so the slopes stay true.
func _crescent(u: float, v: float, stretch: float, cu: int, cv: int, shift: float, cell: Vector2, radius: Vector2,
		packed: bool) -> float:
	var r := _cell_random(cu, cv)
	var centre := Vector2(cu + 0.5 + ((r & 255) / 255.0 - 0.5) * 2.0 * JITTER,
		cv + 0.5 + shift + ((r >> 8 & 255) / 255.0 - 0.5) * 2.0 * JITTER) * cell
	var a := (u - centre.x) / stretch
	var b := (v - centre.y) / (CRESCENT_WIDTH * stretch)
	var reach := a * a + b * b
	# Out of reach of the biggest this cell could hold: skip the sand lookup.
	if reach >= radius.y * radius.y:
		return 0.0
	var x := centre.x * _down.x - centre.y * _down.y
	var z := centre.x * _down.y + centre.y * _down.x
	var sand := _sand_at(x, z, _land.get_noise_2d(x, z))
	var chance := (r >> 16 & 255) / 255.0
	if not packed and chance > sand * 1.4 - 0.15:
		return 0.0
	var pick := (r >> 24 & 255) / 255.0
	var size := lerpf(radius.x, radius.y, pick * sand if not packed else lerpf(0.3, 1.0, sand) * (0.7 + 0.3 * pick))
	var lee := a - size * 0.5
	return _dune(size - sqrt(reach), sqrt(lee * lee + b * b) - size * 0.72, CRESCENT_RISE)


## 32 random bits for a cell, from the seed.
func _cell_random(cu: int, cv: int) -> int:
	var h := ((cu * 73856093) ^ (cv * 19349663) ^ (_seed * 83492791)) & 0xffffffff
	h = (h ^ (h >> 16)) * 0x45d9f3b & 0xffffffff
	h = (h ^ (h >> 16)) * 0x45d9f3b & 0xffffffff
	return h ^ (h >> 16)


## min, and max with 0, with the corner rounded over k: a blend of the two
## slopes, so never steeper than either.
static func _rounded_min(a: float, b: float, k: float) -> float:
	var h := maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * k * 0.25


static func _rounded_max0(a: float, k: float) -> float:
	var h := maxf(k - absf(a), 0.0) / k
	return maxf(a, 0.0) + h * h * k * 0.25
