class_name Wear
extends Node
## The elements wearing down devices left outside a bubble. Each loses
## durability to the felt storm, and to felt wind past what it can stand, so
## whatever a bubble shelters, parts and all, doesn't wear. Placeholder
## numbers, until parts wear on their own. On power's tick of world time, so
## F5 wears as it charges and the frame rate never changes a device's life.
## A running shield counts the storm it holds off, and you the time you've
## been under a bubble without a break: the shield's deeds.

## The wind past wind_harm_speed at which wind_wreck_minutes holds, m/s.
const WIND_SPAN := 10.0

## Seconds of world time you've been under a bubble, unbroken.
var sheltered := 0.0

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
		if device is ShieldGenerator:
			_held(device, seconds, t)
	_under(seconds)


## The full storm a running shield holds off, minutes of it, kept on the
## shield: its load, so an anomaly's counts as what it really was.
func _held(shield: ShieldGenerator, step: float, t: float) -> void:
	if not shield.running():
		return
	shield.held_minutes += shield.particle_load(t) * step / 60.0
	Deeds.measure(_world, &"shield_storm", shield.held_minutes)


## A whole day under a bubble, without once stepping out.
func _under(step: float) -> void:
	var player := _world.player
	if player.vitals.dead or _world.weather.shelter_at(player.global_position, &"storm") <= 0.0:
		sheltered = 0.0
		return
	sheltered += step
	Deeds.measure(_world, &"shield_day", sheltered / 60.0)


## The share of a new device's life the weather at a place takes a second,
## now or at world time t: an anomaly's, as it really is.
func rate_at(at: Vector3, t := NAN) -> float:
	# Inside a bubble that keeps out all of both, nothing's left to wear it.
	var weather := _world.weather
	if weather.shelter_at(at, &"wind") == 1.0 and weather.shelter_at(at, &"storm") == 1.0:
		return 0.0
	var tuning := _world.tuning
	var hidden := weather.hidden(at, t)
	var past := maxf(weather.felt_wind(at, t).length() - tuning.wind_harm_speed, 0.0) * hidden.y
	return weather.felt_storm(at, t) * hidden.x / (tuning.storm_wreck_minutes * 60.0) \
		+ past / (WIND_SPAN * tuning.wind_wreck_minutes * 60.0)
