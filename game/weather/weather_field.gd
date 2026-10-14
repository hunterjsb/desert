class_name WeatherField
extends RefCounted
## The weather's one function pair. storm_at() and wind_at() are pure in the
## seed, the place and the time, so any moment can be sampled, the future
## included; that is what makes forecasts free. Nothing computes storminess or
## wind any other way. Places are world metres, times are run seconds.

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

	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	_mean = Vector2.from_angle(rng.randf() * TAU) * tuning.prevailing_speed
	var period := tuning.prevailing_sway_minutes * 60.0
	# Counter-rotating, at periods that never line up.
	_sway.append(Vector3(tuning.prevailing_sway, TAU / period, rng.randf() * TAU))
	_sway.append(Vector3(tuning.prevailing_sway * 0.6, -TAU / (period * 2.7), rng.randf() * TAU))


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
	return clampf(raw_storm_at(x, z, t) / _ramp, 0.0, 1.0)


## The wind, m/s, in world x and z: the prevailing wind, gusts that ride it,
## and outflow blowing hardest just ahead of a front and inside it.
func wind_at(x: float, z: float, t: float) -> Vector2:
	var prevailing := prevailing_at(t)
	var raw := raw_storm_at(x, z, t)
	var outflow := clampf((raw + _lead) / (_lead + _ramp), 0.0, 1.0)
	var d := drift_at(t)
	var gust := _gust.get_noise_3d(x - d.x, z - d.y, t * _gust_evolve) \
		* lerpf(_gust_strength, _gust_storm_strength, outflow)
	return (prevailing + prevailing.normalized() * _outflow * outflow) * (1.0 + gust)


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
