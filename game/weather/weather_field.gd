class_name WeatherField
extends RefCounted
## The weather's one function pair. storm_at() and wind_at() are pure in the
## seed, the place and the time, so any moment can be sampled, the future
## included; that is what makes forecasts free. Nothing computes storminess or
## wind any other way. Places are world metres, times are run seconds. The
## anomaly's hidden term rides the same air, read only where damage is dealt.

## Hearts drawn and kept, at most: a camp crosses a new patch every half hour.
const HEARTS_KEPT := 4096

var _storm := FastNoiseLite.new()
var _gust := FastNoiseLite.new()
var _threshold: float
var _ramp: float
var _lead: float
var _outflow: float
var _evolve: float
var _gust_strength: float
var _gust_storm_strength: float
var _gust_evolve: float
## The prevailing wind is a mean plus two slowly turning sway vectors. Each
## integrates in closed form, so the drift that carries storms is exact at any
## time. Their sum stays shorter than the mean, so the wind never reverses.
var _mean: Vector2
var _sway: Array[Vector3] = []
## The anomaly's lattice: patches of the moving air, spans of time, and the
## chance each pair holds one (anomalies_near).
var _seed: int
var _cell: float
var _span: float
var _chance: float
var _grace: float
var _radius: float
var _reach: float
var _hearts := {}


func _init(run_seed: int, tuning: Tuning) -> void:
	_storm.seed = run_seed
	_storm.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_storm.frequency = 1.0 / tuning.storm_wavelength
	_storm.fractal_type = FastNoiseLite.FRACTAL_FBM
	_storm.fractal_octaves = tuning.storm_octaves
	_gust.seed = run_seed + 1
	_gust.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_gust.frequency = 1.0 / tuning.gust_wavelength
	_threshold = tuning.storm_threshold
	_ramp = tuning.storm_ramp
	_lead = tuning.storm_outflow_lead
	_outflow = tuning.storm_outflow_speed
	_evolve = tuning.storm_evolve_speed
	_gust_strength = tuning.gust_strength
	_gust_storm_strength = tuning.gust_storm_strength
	_gust_evolve = tuning.gust_evolve_speed
	_seed = run_seed
	_radius = tuning.anomaly_radius_m
	# A heart reaches at most half a patch, and lives at most half a span, so
	# the two patches and spans nearest a place hold every one that reaches it.
	_cell = maxf(tuning.anomaly_cell_m, 2.0 * _radius)
	_span = 2.0 * tuning.anomaly_hours * 3600.0
	_chance = tuning.anomaly_chance
	_grace = tuning.anomaly_grace_days * tuning.day_minutes * 60.0
	_reach = tuning.anomaly_reach

	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	_mean = Vector2.from_angle(_heading(rng)) * tuning.prevailing_speed
	var period := tuning.prevailing_sway_minutes * 60.0
	# Counter-rotating, at periods that never line up.
	_sway.append(Vector3(tuning.prevailing_sway, TAU / period, rng.randf() * TAU))
	_sway.append(Vector3(tuning.prevailing_sway * 0.6, -TAU / (period * 2.7), rng.randf() * TAU))


## The run's long-term wind heading, radians: the dunes face it.
static func mean_heading(run_seed: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	return _heading(rng)


## The seed's first draw, so the weather and the dunes agree.
static func _heading(rng: RandomNumberGenerator) -> float:
	return rng.randf() * TAU


## How far the air, and every storm in it, has moved since the run began.
func drift_at(t: float) -> Vector2:
	var d := _mean * t
	for s in _sway:
		d += Vector2(sin(s.y * t + s.z) - sin(s.z), cos(s.z) - cos(s.y * t + s.z)) * (s.x / s.y)
	return d


## The prevailing wind, m/s, in world x and z. Storms ride it.
func prevailing_at(t: float) -> Vector2:
	var v := _mean
	for s in _sway:
		v += Vector2.from_angle(s.y * t + s.z) * s.x
	return v


## The storm field before the threshold: storms are where it's above zero.
func raw_storm_at(x: float, z: float, t: float) -> float:
	var d := drift_at(t)
	return _storm.get_noise_3d(x - d.x, z - d.y, t * _evolve) - _threshold


## Storm intensity, 0 in the clear and rising to 1 just past the front. Any
## value above 0 is inside a storm.
func storm_at(x: float, z: float, t: float) -> float:
	return storm_of(raw_storm_at(x, z, t))


## Storm intensity where the field before its threshold stands at `raw`.
func storm_of(raw: float) -> float:
	return clampf(raw / _ramp, 0.0, 1.0)


## How far a front's outflow has risen at a place, 0 to 1: from a lead ahead
## of the front to full just past it. The wind blows harder by it, and the
## sand it drives charges up, so a radio's static rises with it too.
func outflow_at(x: float, z: float, t: float) -> float:
	return outflow_of(raw_storm_at(x, z, t))


## A front's outflow where the field before its threshold stands at `raw`.
func outflow_of(raw: float) -> float:
	return clampf((raw + _lead) / (_lead + _ramp), 0.0, 1.0)


## The wind without its gusts, m/s, in world x and z: the prevailing wind and
## a front's outflow along it, what a forecast can speak of.
func steady_wind_at(x: float, z: float, t: float) -> Vector2:
	return _steady(t, outflow_at(x, z, t))


## The wind, m/s, in world x and z: the prevailing wind, gusts that ride it,
## and outflow blowing hardest just ahead of a front and inside it.
func wind_at(x: float, z: float, t: float) -> Vector2:
	var outflow := outflow_at(x, z, t)
	var d := drift_at(t)
	var gust := _gust.get_noise_3d(x - d.x, z - d.y, t * _gust_evolve) \
		* lerpf(_gust_strength, _gust_storm_strength, outflow)
	return _steady(t, outflow) * (1.0 + gust)


func _steady(t: float, outflow: float) -> Vector2:
	var prevailing := prevailing_at(t)
	return prevailing + prevailing.normalized() * _outflow * outflow


## Seconds from t until the storm state at a place flips, looking at most
## horizon ahead; INF if it holds that long. step bounds the shortest change seen.
func next_change(x: float, z: float, t: float, horizon: float, step: float) -> float:
	var stormy := raw_storm_at(x, z, t) > 0.0
	var ahead := step
	while ahead <= horizon:
		if (raw_storm_at(x, z, t + ahead) > 0.0) != stormy:
			var lo := ahead - step
			var hi := ahead
			while hi - lo > 0.05:
				var mid := (lo + hi) * 0.5
				if (raw_storm_at(x, z, t + mid) > 0.0) != stormy:
					hi = mid
				else:
					lo = mid
			return hi
		ahead += step
	return INF


## The anomaly's hidden term at a place, 0 to 1: how deep in one's heart it
## stands, rising from a reach ahead of its storm's front. The storm field
## stays the clean curve every forecast and instrument reads; only damage
## and the tells read this.
func anomaly_at(x: float, z: float, t: float) -> float:
	if t < _grace:
		return 0.0
	var d := drift_at(t)
	var u := x - d.x
	var v := z - d.y
	var best := 0.0
	var i0 := floori(u / _cell - 0.5)
	var j0 := floori(v / _cell - 0.5)
	var k0 := floori(t / _span - 0.5)
	for i in [i0, i0 + 1]:
		for j in [j0, j0 + 1]:
			for k in [k0, k0 + 1]:
				var heart := _heart(i, j, k)
				if not is_nan(heart.z):
					best = maxf(best, _share(heart, u, v, t))
	if best <= 0.0:
		return 0.0
	return best * smoothstep(-_reach, 0.0, raw_storm_at(x, z, t))


## Every anomaly whose heart is within `reach` m of a place at time t, as
## {x, z, radius, peak, strength, share}: its heart now in world metres, its
## reach, when it's at its full, how strong it stands now, and its share at
## the place, before its storm's. A map and the Walker's feed read this.
func anomalies_near(x: float, z: float, t: float, reach: float) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	if t < _grace:
		return found
	var d := drift_at(t)
	var u := x - d.x
	var v := z - d.y
	var k0 := floori(t / _span - 0.5)
	for i in range(floori((u - reach) / _cell), floori((u + reach) / _cell) + 1):
		for j in range(floori((v - reach) / _cell), floori((v + reach) / _cell) + 1):
			for k in [k0, k0 + 1]:
				var heart := _heart(i, j, k)
				var life := _life(heart, t)
				if life <= 0.0 or Vector2(heart.x - u, heart.y - v).length() > reach:
					continue
				found.append({"x": heart.x + d.x, "z": heart.y + d.y, "radius": _radius, "peak": heart.z,
					"strength": life, "share": _share(heart, u, v, t)})
	return found


## A heart's share at a place in the moving air's frame: its strength now,
## full within a quarter of its reach and none past it.
func _share(heart: Vector3, u: float, v: float, t: float) -> float:
	var off := Vector2(heart.x - u, heart.y - v).length() / _radius
	return 0.0 if off >= 1.0 else _life(heart, t) * (1.0 - smoothstep(0.25, 1.0, off))


## How strong a heart stands at time t: full for the middle third of its life.
func _life(heart: Vector3, t: float) -> float:
	if is_nan(heart.z):
		return 0.0
	var age := absf(t - heart.z) / (_span * 0.5)
	return 0.0 if age >= 1.0 else 1.0 - smoothstep(1.0 / 3.0, 1.0, age)


## A patch and span's heart, in the moving air's frame, and when it peaks; NAN
## if it holds none. Drawn from the seed alone, and kept once drawn.
func _heart(i: int, j: int, k: int) -> Vector3:
	var key := Vector3i(i, j, k)
	if _hearts.has(key):
		return _hearts[key]
	var h := hash([_seed, i, j, k])
	var heart := Vector3(NAN, NAN, NAN)
	var peak := (k + _unit(h, 3)) * _span
	# One that would show before the grace is over never forms.
	if _unit(h, 0) < _chance and peak - _span * 0.5 >= _grace:
		heart = Vector3((i + _unit(h, 1)) * _cell, (j + _unit(h, 2)) * _cell, peak)
	if _hearts.size() >= HEARTS_KEPT:
		_hearts.clear()
	_hearts[key] = heart
	return heart


## A cell's own draw, 0 to 1, from its hash.
static func _unit(h: int, n: int) -> float:
	return float(hash([h, n]) & 0xffffff) / float(0x1000000)
