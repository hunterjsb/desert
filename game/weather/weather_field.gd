class_name WeatherField
extends RefCounted
## The weather's one function pair. storm_at() and wind_at() are pure in the
## seed, the place and the time, so any moment can be sampled, the future
## included; that is what makes forecasts free. Nothing computes storminess or
## wind any other way. Places are world metres, times are run seconds.

var _storm := FastNoiseLite.new()
var _gust := FastNoiseLite.new()
var _shift := FastNoiseLite.new()
var _shift_m: float
var _shift_s: float
var _shift_lean: float
var _shift_swing: float
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


func _init(run_seed: int, tuning: Tuning) -> void:
	_storm.seed = run_seed
	_storm.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_storm.frequency = 1.0 / tuning.storm_wavelength
	_storm.fractal_type = FastNoiseLite.FRACTAL_FBM
	_storm.fractal_octaves = tuning.storm_octaves
	_gust.seed = run_seed + 1
	_gust.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_gust.frequency = 1.0 / tuning.gust_wavelength
	_shift.seed = run_seed + 2
	_shift.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_shift.frequency = 1.0
	_shift.fractal_octaves = 2
	_shift_m = tuning.dune_shift_m
	_shift_s = tuning.dune_shift_minutes * 60.0
	_shift_lean = tuning.dune_shift_lean
	_shift_swing = tuning.dune_shift_swing
	_threshold = tuning.storm_threshold
	_ramp = tuning.storm_ramp
	_lead = tuning.storm_outflow_lead
	_outflow = tuning.storm_outflow_speed
	_evolve = tuning.storm_evolve_speed
	_gust_strength = tuning.gust_strength
	_gust_storm_strength = tuning.gust_storm_strength
	_gust_evolve = tuning.gust_evolve_speed

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


## Where a storm's big dunes move at a place, -1 to 1: off it where it's
## above 0, onto it below. Patches of ground that change over minutes, so a
## storm lays one site bare while burying the next, and may turn on either.
func dune_shift_at(x: float, z: float, t: float) -> float:
	return clampf(_shift_lean + _shift.get_noise_3d(x / _shift_m, z / _shift_m, t / _shift_s) * _shift_swing,
		-1.0, 1.0)


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
