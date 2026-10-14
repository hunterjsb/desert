class_name Weather
extends Node
## The weather as everything in the world feels it, and as it looks from where
## the player stands. Every system asks felt_*() at its own position and never
## reads the field directly, so when shelter arrives (the bubble shield) it
## edits the answers here and everything agrees about where the bubble is.
##
## The game plays by the field at the player: in_storm, harm, the far ring,
## wind. The senses follow seen_storm, the dust at the camera as the screen
## draws it, so the light drops exactly when the dust visibly swallows you.
## This is the one owner of the sun, sky, haze and the storm walls' light.

## Planetshine: the night side still catches light off the planet.
const NIGHT_LIGHT := 0.08
## How far ahead the readout forecasts, and the shortest change it can see.
const FORECAST_HORIZON := 3600.0
const FORECAST_STEP := 5.0
## A clear day's light, which storms dim.
const SUN_COLOR := Color(1.0, 0.95, 0.86)
const AMBIENT_COLOR := Color(0.8, 0.72, 0.62)
const AMBIENT_ENERGY := 0.75
## The sand's colour, from the terrain's material: what blown grains look like.
const SAND := Color(0.86, 0.72, 0.52)
## The sun's disc, which the storm pass draws so a wall can cover it.
const SUN_DISC := Vector3(14.0, 12.5, 10.5)

var field: WeatherField
var day: DayCycle
var map: StormMap
## The weather at the player this tick, which the game plays by.
var storm := 0.0
var in_storm := false
var wind := Vector3.ZERO
## How far into the dust the camera is, 0 to 1, by the same billows the screen
## draws. What the senses follow.
var seen_storm := 0.0
## Sunlight reaching the camera past the storms, 0 to 1.
var seen_sun := 1.0
## Signed metres from the camera to the nearest front, positive inside.
var seen_front := -INF
## World time the storm state at the player next flips; INF beyond the horizon.
var next_change_time := INF

@onready var face: StormFace = $StormFace
@onready var atmosphere: Atmosphere = $Atmosphere

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
	map = StormMap.new(world, field)
	_environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	_sun = world.get_node("Sun")
	_sun_energy = _sun.light_energy
	_sun.light_color = SUN_COLOR
	# The storm pass draws the disc, so a wall can cover it.
	_sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_haze_color = _environment.fog_light_color
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	_environment.fog_density = _tuning.haze_strength
	face.setup(world, field, map)


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


## The clock jumped: forecast again on the next tick.
func forecast_now() -> void:
	_forecast_due = 0.0
	next_change_time = INF


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
	map.update(t, _world.time_warp)
	_show(delta)
	_report()


func _exit_tree() -> void:
	if map != null:
		map.finish()


## Every drawn frame, after the world has moved and shifted.
func _process(_delta: float) -> void:
	face.sync(_world.time)


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


func _show(delta: float) -> void:
	var t := _world.time
	var camera := _world.player.camera
	var eye := camera.global_position
	var sun := day.sun_direction(t, _world.moon.latitude)
	var risen := smoothstep(-0.02, 0.1, sun.y)
	var daylight := lerpf(NIGHT_LIGHT, 1.0, smoothstep(-0.1, 0.2, sun.y))
	seen_storm = face.seen_at(eye)
	seen_sun = maxf(face.sun_at(eye, sun), 0.02)
	seen_front = face.front_at(eye).x if map.ready else -INF

	# The light dims in stages: a wall blots out the sun, then towers over half
	# the sky, then swallows you. Inside, the light is the storm glowing from
	# above, so the sun light turns overhead and soft: dunes keep their shape
	# while their shadows go.
	var towering := atan2(_tuning.wall_height - eye.y, maxf(-seen_front, 1.0)) / (PI * 0.5)
	var coverage := lerpf(clampf(towering, 0.0, 1.0) * 0.5, 1.0, seen_storm)
	var dim := lerpf(1.0, 1.0 - _tuning.storm_darkness, seen_storm)
	var sky_left := 1.0 - 0.55 * coverage
	var overhead := Vector3(sun.x * 0.15, 1.0, sun.z * 0.15).normalized()
	var light_from := sun.slerp(overhead, seen_storm * risen)
	_sun.global_basis = Basis.looking_at(-light_from, Vector3.UP if absf(light_from.y) < 0.9 else Vector3.FORWARD)
	_sun.light_energy = _sun_energy * risen * maxf(seen_sun, seen_storm * 0.6) * dim
	_environment.ambient_light_color = AMBIENT_COLOR
	_environment.ambient_light_energy = AMBIENT_ENERGY * daylight * sky_left * dim
	_environment.background_energy_multiplier = daylight * lerpf(1.0, 0.45, coverage) * dim

	# The clear day's haze, dimmed with the light and browned by the dust. The
	# dust itself is the storm pass's; the haze only closes in behind it, never
	# within the few metres the dust leaves.
	var haze_light := daylight * sky_left * dim
	var haze_color := _haze_color.lerp(_tuning.storm_fog_color, seen_storm)
	_environment.fog_light_color = haze_color
	_environment.fog_light_energy = haze_light
	_environment.fog_depth_begin = lerpf(_tuning.haze_begin, 50.0, seen_storm)
	_environment.fog_depth_end = lerpf(_tuning.haze_end, 400.0, seen_storm)
	_world.terrain.show_far(not in_storm)

	var sun_light := _linear(SUN_COLOR) * _sun_energy * risen
	var sky_light := _linear(AMBIENT_COLOR) * AMBIENT_ENERGY * daylight
	face.set_light("sun_dir", sun)
	face.set_light("sun_light", sun_light)
	# A wall faces half the sky, so it gets less than open ground.
	face.set_light("sky_light", sky_light * 0.6)
	face.set_light("camera_sun", seen_sun)
	face.set_light("sun_disc", SUN_DISC * risen)
	face.set_light("haze_color", _linear(haze_color) * haze_light)
	face.set_light("haze", Vector3(_environment.fog_depth_begin, _environment.fog_depth_end,
		_environment.fog_density))

	var grains := _linear(SAND) * (sun_light * maxf(seen_sun, seen_storm * 0.6) * 0.6 + sky_light * sky_left) * dim
	var near := exp(minf(seen_front, 0.0) / 350.0) if map.ready else 0.0
	atmosphere.show_weather(camera, _world.height_under(eye), wind, seen_storm, near, grains,
		face.sigma() * seen_storm, _world.time_warp > 0.0, delta)


func _report() -> void:
	var t := _world.time
	var hours := day.time_of_day(t) * 24.0
	var warp := "" if _world.time_warp == 1.0 else " x%d" % _world.time_warp
	Dev.put("weather/t", "d%d %02d:%02d%s" % [day.day(t), floori(hours), floori(fmod(hours, 1.0) * 60.0), warp])
	# Compass bearing the wind comes from; north is -z.
	var from := fposmod(rad_to_deg(atan2(-wind.x, wind.z)), 360.0)
	Dev.put("weather/wind", "%.1fm/s %03d" % [wind.length(), roundi(from) % 360])
	Dev.put("weather/stm", "%d%%" % roundi(storm * 100.0) if in_storm else "clear")
	Dev.put("weather/wall", "-" if seen_front == -INF else ("in %dm" % roundi(seen_front)
		if seen_front >= 0.0 else "%dm" % roundi(-seen_front)))
	Dev.put("weather/seen", "%d%%" % roundi(seen_storm * 100.0))
	var eta := next_change_time - t
	Dev.put("weather/next", "%s %s" % ["clr" if in_storm else "stm",
		">1h" if eta == INF else "%d:%02d" % [floori(eta / 60.0), floori(fmod(eta, 60.0))]])
	Dev.put("weather/sun", "%d%%" % roundi(felt_light(_world.player.global_position) * 100.0))
	Dev.put("weather/map", "%.1fms %d jumps" % [map.max_upload_ms, map.rebuilds])


static func _linear(color: Color) -> Vector3:
	var c := color.srgb_to_linear()
	return Vector3(c.r, c.g, c.b)
