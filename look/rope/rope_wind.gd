class_name RopeWind
extends WeatherField
## The run's own weather with the wind swapped for a chosen one, for judging
## rope by hand and for probes. Storms, drift and forecasts stay the run's.
## Install it as world.weather.field; everything reads wind through it.

## (x, z, t) -> wind in world x and z, m/s. Unset blows the real wind.
var override := Callable()

var _tuning: Tuning
var _eddies := FastNoiseLite.new()


func _init(run_seed: int, tuning: Tuning) -> void:
	super(run_seed, tuning)
	_tuning = tuning
	_eddies.seed = run_seed + 2
	_eddies.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_eddies.frequency = 1.0 / tuning.gust_wavelength


func wind_at(x: float, z: float, t: float) -> Vector2:
	if override.is_valid():
		return override.call(x, z, t)
	return super(x, z, t)


## The field's own wind, whatever the override says.
func real_wind_at(x: float, z: float, t: float) -> Vector2:
	return super.wind_at(x, z, t)


## A clear-day breeze, with the clear sky's gusts.
func breeze_speed() -> float:
	return _tuning.prevailing_speed * 0.8


## Inside a storm: the mean wind plus full outflow, before gusts.
func storm_speed() -> float:
	return _tuning.prevailing_speed + _tuning.storm_outflow_speed


## The worst the field can blow: both sways lined up with the mean, full
## outflow, and near the strongest storm gust on top.
func worst_gust() -> float:
	return (_tuning.prevailing_speed + _tuning.prevailing_sway * 1.6 + _tuning.storm_outflow_speed) \
		* (1.0 + _tuning.gust_storm_strength * 0.9)


## A wind of this speed along `toward`, its gusts riding it as the field's do;
## gusts is their size as a share of the speed.
func steady(toward: Vector2, speed: float, gusts: float) -> Callable:
	var along := toward.normalized() * speed
	var evolve := _tuning.gust_evolve_speed
	# Locals only: a lambda that reached `self` would hold this field in its own
	# override, a cycle that never frees.
	var eddies := _eddies
	return func(x: float, z: float, t: float) -> Vector2:
		return along * (1.0 + gusts * eddies.get_noise_3d(x - along.x * t, z - along.y * t, t * evolve))
