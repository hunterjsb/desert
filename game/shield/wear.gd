class_name Wear
extends Node
## The elements wearing down devices left outside a bubble. Each loses
## durability to the felt storm, and to felt wind past what it can stand, so
## whatever a bubble shelters, parts and all, doesn't wear. Placeholder
## numbers, until parts wear on their own. On power's tick of world time, so
## F5 wears as it charges and the frame rate never changes a device's life.

## The wind past wind_harm_speed at which wind_wreck_minutes holds, m/s.
const WIND_SPAN := 10.0

var _world: World
var _next := 0.0


func setup(world: World) -> void:
	_world = world
	_next = world.time


func _ready() -> void:
	# After power, before the world moves the clock on.
	process_physics_priority = 160


func _physics_process(_delta: float) -> void:
	var step := _world.tuning.power_tick
	# A jump in time (a scenario) isn't lived through.
	if _world.time < _next - step or _world.time - _next > 60.0:
		_next = _world.time
	while _next + step <= _world.time + 1e-9:
		_tick(step, _next)
		_next += step


## One tick lived by a sleep, which steps the clock itself (Sleep).
func live(seconds: float, t: float) -> void:
	_tick(seconds, t)
	_next = t + seconds


func _tick(seconds: float, t: float) -> void:
	for device in _world.devices():
		device.wear(rate_at(device.global_position, t) * seconds)


## The share of a new device's life the weather at a place takes a second,
## now or at world time t.
func rate_at(at: Vector3, t := NAN) -> float:
	# Inside a bubble that keeps out all of both, nothing's left to wear it.
	var weather := _world.weather
	if weather.shelter_at(at, &"wind") == 1.0 and weather.shelter_at(at, &"storm") == 1.0:
		return 0.0
	var tuning := _world.tuning
	var past := maxf(_world.weather.felt_wind(at, t).length() - tuning.wind_harm_speed, 0.0)
	return _world.weather.felt_storm(at, t) / (tuning.storm_wreck_minutes * 60.0) \
		+ past / (WIND_SPAN * tuning.wind_wreck_minutes * 60.0)
