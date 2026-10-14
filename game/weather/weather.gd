class_name Weather
extends Node
## The weather as everything in the world feels it, and as it looks from where
## the player stands. Every system asks felt_*() at its own position and never
## reads the field directly, so when shelter arrives (the bubble shield) it
## edits the answers here and everything agrees about where the bubble is.

## Planetshine: the night side still catches light off the planet.
const NIGHT_LIGHT := 0.08
## How far ahead the readout forecasts, and the shortest change it can see.
const FORECAST_HORIZON := 3600.0
const FORECAST_STEP := 5.0

var field: WeatherField
var day: DayCycle
## The weather at the player this frame, which the screen shows.
var storm := 0.0
var in_storm := false
var wind := Vector3.ZERO
## World time the storm state at the player next flips; INF beyond the horizon.
var next_change_time := INF

@onready var wall: StormWall = $StormWall

var _world: World
var _tuning: Tuning
var _environment: Environment
var _sun: DirectionalLight3D
var _sun_energy: float
var _haze_color: Color
var _forecast_due := 0.0


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	field = WeatherField.new(world.run_seed, _tuning)
	day = DayCycle.new(_tuning)
	_environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	_sun = world.get_node("Sun")
	_sun_energy = _sun.light_energy
	_haze_color = _environment.fog_light_color
	wall.setup(world, field)


func felt_storm(at: Vector3) -> float:
	return field.storm_at(_world.world_x(at.x), _world.world_z(at.z), _world.time)


## Horizontal wind, m/s, in engine axes.
func felt_wind(at: Vector3) -> Vector3:
	var w := field.wind_at(_world.world_x(at.x), _world.world_z(at.z), _world.time)
	return Vector3(w.x, 0.0, w.y)


## Sunlight reaching a place, 0 to 1: the sky's share after the storm takes its own.
func felt_light(at: Vector3) -> float:
	return day.sunlight(_world.time, _world.moon.latitude) \
		* (1.0 - _tuning.storm_darkness * felt_storm(at))


func _ready() -> void:
	# After the player moves, before the world shifts and the clock moves on.
	process_physics_priority = 100


func _physics_process(delta: float) -> void:
	var player := _world.player.global_position
	storm = felt_storm(player)
	in_storm = storm > 0.0
	wind = felt_wind(player)
	var x := _world.player_world_x()
	var z := _world.player_world_z()
	var t := _world.time
	_forecast_due -= delta
	if _forecast_due <= 0.0 or t >= next_change_time:
		_forecast_due = 1.0
		next_change_time = t + field.next_change(x, z, t, FORECAST_HORIZON, FORECAST_STEP)
	_blow_loose_bodies()
	wall.step(x, z, t)
	_show()
	_report()


## Loose bodies feel drag: a push along the air's speed past them, growing
## with its square, so a breeze leaves a box be and a storm slides it.
func _blow_loose_bodies() -> void:
	for child in _world.content.get_children():
		var body := child as RigidBody3D
		if body == null or body.freeze:
			continue
		var catch: float = body.get_meta(&"wind_catch", _tuning.loose_wind_catch)
		var past := felt_wind(body.global_position) - body.linear_velocity
		past.y = 0.0
		body.apply_central_force(past * past.length() * catch)


func _show() -> void:
	var t := _world.time
	var sun := day.sun_direction(t, _world.moon.latitude)
	_sun.global_basis = Basis.looking_at(-sun, Vector3.UP if absf(sun.y) < 0.9 else Vector3.FORWARD)
	var clear := 1.0 - _tuning.storm_darkness * storm
	_sun.light_energy = _sun_energy * smoothstep(-0.02, 0.1, sun.y) * clear
	var brightness := lerpf(NIGHT_LIGHT, 1.0, smoothstep(-0.1, 0.2, sun.y)) * clear
	_environment.background_energy_multiplier = brightness
	_environment.ambient_light_energy = brightness
	_environment.fog_light_color = _haze_color.lerp(_tuning.storm_fog_color, storm) * brightness
	# Visibility falls geometrically, so it collapses within seconds of the front.
	var visibility := _tuning.haze_end * pow(_tuning.storm_visibility / _tuning.haze_end, storm)
	_environment.fog_depth_end = visibility
	_environment.fog_depth_begin = _tuning.haze_begin * (visibility / _tuning.haze_end) * (1.0 - storm)
	_environment.fog_sky_affect = lerpf(0.6, 1.0, storm)
	_world.terrain.show_far(not in_storm)
	wall.visible = not in_storm
	wall.set_light(brightness, _tuning.storm_fog_color)


func _report() -> void:
	var t := _world.time
	var hours := day.time_of_day(t) * 24.0
	Dev.put("weather/time", "day %d, %02d:%02d" % [day.day(t), floori(hours), floori(fmod(hours, 1.0) * 60.0)])
	# Compass bearing the wind comes from; north is -z.
	var from := fposmod(rad_to_deg(atan2(-wind.x, wind.z)), 360.0)
	Dev.put("weather/wind", "%.1f m/s from %03d" % [wind.length(), roundi(from) % 360])
	Dev.put("weather/storm", "%d%%" % roundi(storm * 100.0) if in_storm else "clear")
	var nearest := INF
	for d in wall.distances:
		if d > 0.0:
			nearest = minf(nearest, d)
	Dev.put("weather/wall", "on you" if in_storm else ("none in sight" if nearest == INF else "%d m" % nearest))
	var eta := next_change_time - t
	Dev.put("weather/next", "%s in %s" % ["clears" if in_storm else "storm",
		"over an hour" if eta == INF else "%d:%02d" % [floori(eta / 60.0), floori(fmod(eta, 60.0))]])
	Dev.put("weather/sunlight", "%d%%" % roundi(felt_light(_world.player.global_position) * 100.0))
