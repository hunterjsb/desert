class_name Weather
extends Node
## The weather as everything in the world feels it, and as it looks from where
## the player stands. Every system asks felt_*() at its own position and never
## reads the field directly. Shelters (running shields' bubbles) edit the
## answers here, so everything agrees about where a bubble is.
##
## The game plays by the field at the player: in_storm, harm, the far ring,
## wind. The senses follow seen_storm, the dust at the camera as the screen
## draws it, so the light drops exactly when the dust visibly swallows you.
## Light passes through a bubble, so inside one the air is clear but the light
## is the storm's. This is the one owner of the sun, sky, haze and the storm
## walls' light.

## Planetshine: the night side still catches light off the planet.
const NIGHT_LIGHT := 0.08
## How far ahead the readout forecasts, and the shortest change it can see.
const FORECAST_HORIZON := 3600.0
const FORECAST_STEP := 5.0
## A clear day's light, which storms dim.
const SUN_COLOR := Color(1.0, 0.95, 0.86)
const AMBIENT_COLOR := Color(0.8, 0.72, 0.62)
const AMBIENT_ENERGY := 0.75
## Light that has come through a storm's dust is reddened by it, as the dust is.
const STORM_TINT := Color(0.95, 0.8, 0.62)
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
## draws, with shelters clear. What the senses follow.
var seen_storm := 0.0
## The same as if no shelter stood: what the light follows.
var seen_shade := 0.0
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
var _shelters: Array[Node] = []
var _shelters_seen := -1


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	field = WeatherField.new(world.run_seed, _tuning)
	day = DayCycle.new(_tuning)
	map = StormMap.new(world, field)
	_environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	_sun = world.get_node("Sun")
	_sun_energy = _sun.light_energy
	# The storm pass draws the disc, so a wall can cover it.
	_sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_haze_color = _environment.fog_light_color
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	_environment.fog_density = _tuning.haze_strength
	face.setup(world, field, map)


## Each felt_*() reads now, or a given world time t: power ticks read theirs.
## Shelter is always as it stands now.
func felt_storm(at: Vector3, t := NAN) -> float:
	return field_storm(at, t) * (1.0 - shelter_at(at, &"storm"))


## Horizontal wind, m/s, in engine axes.
func felt_wind(at: Vector3, t := NAN) -> Vector3:
	return field_wind(at, t) * (1.0 - shelter_at(at, &"wind"))


## Sunlight reaching a place, 0 to 1: the sky's share after the storm takes
## its own. Light passes through a shield, so shelter changes nothing here.
func felt_light(at: Vector3, t := NAN) -> float:
	return day.sunlight(_when(t), _world.moon.latitude) \
		* (1.0 - _tuning.storm_darkness * field_storm(at, t))


## The storm the field makes at a place, as if no shelter stood.
func field_storm(at: Vector3, t := NAN) -> float:
	return field.storm_at(_world.world_x(at.x), _world.world_z(at.z), _when(t))


## The wind the field blows at a place, as if no shelter stood: what the dust
## outside a bubble rides.
func field_wind(at: Vector3, t := NAN) -> Vector3:
	var w := field.wind_at(_world.world_x(at.x), _world.world_z(at.z), _when(t))
	return Vector3(w.x, 0.0, w.y)


## The air's temperature at a place, °C, as if no shelter stood: the day's
## swing round its mean, wider toward the poles and blanketed by the storm's dust.
func field_temperature(at: Vector3, t := NAN) -> float:
	var swing := _tuning.temperature_swing \
		* (1.0 + _tuning.temperature_pole_widen * absf(sin(_world.moon.latitude))) \
		* (1.0 - _tuning.temperature_storm_blanket * field_storm(at, t))
	return _tuning.temperature_mean + swing * cos(TAU * (day.time_of_day(_when(t)) - _tuning.temperature_peak))


## The temperature as a place feels it, °C: a bubble holds its share of the
## way from the air outside to its own inside.
func felt_temperature(at: Vector3, t := NAN) -> float:
	return lerpf(field_temperature(at, t), _tuning.sheltered_temperature, shelter_at(at, &"temperature"))


## How sheltered a place is from a harm (&"wind", &"storm", &"temperature"),
## 0 to 1: the most that any shelter whose live radius it's within blocks of
## it, so nested bubbles give each harm the best of them. Asked of the
## distance, never of events.
func shelter_at(at: Vector3, harm: StringName) -> float:
	var best := 0.0
	for shelter: Shelter in shelters():
		if at.distance_squared_to(shelter.global_position) < shelter.radius * shelter.radius:
			best = maxf(best, shelter.blocks.get(harm, 0.0))
	return best


## Every shelter in the world, standing or down, gathered again only when one
## comes or goes: ropes and loose bodies ask many times a tick.
func shelters() -> Array[Node]:
	if _shelters_seen != Shelter.changes and is_inside_tree():
		_shelters_seen = Shelter.changes
		_shelters = get_tree().get_nodes_in_group(Shelter.GROUP)
	return _shelters


func _when(t: float) -> float:
	return _world.time if is_nan(t) else t


## The clock jumped: forecast again on the next tick.
func forecast_now() -> void:
	_forecast_due = 0.0
	next_change_time = INF


func _ready() -> void:
	# After the player moves, before the world shifts and the clock moves on.
	process_physics_priority = 100


func _physics_process(delta: float) -> void:
	var player := _world.player.global_position
	# A bubble shelters you from the storm, not the place: you're still in it.
	storm = field_storm(player)
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
	var holes := PackedVector4Array()
	var glows := PackedFloat32Array()
	for shelter: Shelter in shelters():
		if shelter.carves() and holes.size() < Shelter.MAX:
			var c := shelter.global_position
			holes.append(Vector4(c.x, c.y, c.z, shelter.radius))
			glows.append(shelter.glow)
	face.sync(_world.time, holes, glows)
	atmosphere.carve(holes)


## How much the wind grabs a body: its own say if it has one, else its
## biggest face at the world's rate.
func catch_of(body: CollisionObject3D) -> float:
	if not body.has_meta(&"wind_catch"):
		body.set_meta(&"wind_catch", _tuning.wind_catch_per_m2 * biggest_face(body))
	return body.get_meta(&"wind_catch")


## The biggest face of each of a body's shapes, summed, m².
static func biggest_face(body: Node) -> float:
	var total := 0.0
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		var size := shape.shape.get_debug_mesh().get_aabb().size
		total += maxf(size.x * size.y, maxf(size.y * size.z, size.x * size.z))
	return total


## Loose bodies feel drag: a push along the air's speed past them, growing
## with its square, so a breeze leaves a box be and a storm slides it.
func _blow_loose_bodies() -> void:
	for child in _world.content.get_children():
		var body := child as RigidBody3D
		if body == null or body.freeze:
			continue
		var catch := catch_of(body)
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
	seen_shade = face.open_at(eye)
	seen_sun = maxf(face.sun_at(eye, sun), 0.02)
	seen_front = face.front_at(eye).x if map.ready else -INF

	# The light dims in stages: a wall blots out the sun, then towers over half
	# the sky, then swallows you. Inside, the light is the storm glowing from
	# above, so the sun light turns overhead and soft: dunes keep their shape
	# while their shadows go. A bubble clears the air, not the light.
	var towering := atan2(_tuning.wall_height - eye.y, maxf(-seen_front, 1.0)) / (PI * 0.5)
	var coverage := lerpf(clampf(towering, 0.0, 1.0) * 0.5, 1.0, seen_shade)
	var dim := lerpf(1.0, 1.0 - _tuning.storm_darkness, seen_shade)
	var sky_left := 1.0 - 0.55 * coverage
	var overhead := Vector3(sun.x * 0.15, 1.0, sun.z * 0.15).normalized()
	var light_from := sun.slerp(overhead, seen_shade * risen)
	_sun.global_basis = Basis.looking_at(-light_from, Vector3.UP if absf(light_from.y) < 0.9 else Vector3.FORWARD)
	_sun.light_energy = _sun_energy * risen * maxf(seen_sun, seen_shade * 0.6) * dim
	var tint := Color.WHITE.lerp(STORM_TINT, seen_shade)
	_sun.light_color = SUN_COLOR * tint
	_environment.ambient_light_color = AMBIENT_COLOR * tint
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
	# The light round the camera, which a shell's glass catches.
	face.set_light("shell_light", _linear(_environment.ambient_light_color) * _environment.ambient_light_energy)

	# Outside a bubble the dust is the storm's own: it rides the field's wind
	# and thickens with the storm, and the bubble only carves it out.
	var grains := _linear(SAND) * (sun_light * maxf(seen_sun, seen_shade * 0.6) * 0.6 + sky_light * sky_left) * dim
	var near := exp(minf(seen_front, 0.0) / 350.0) if map.ready else 0.0
	atmosphere.show_weather(camera, _world.height_under(eye), field_wind(_world.player.global_position),
		shelter_at(eye, &"storm"), seen_shade, near, grains, face.sigma() * seen_shade, _world.time_warp > 0.0, delta)


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
	Dev.put("weather/shel", "in" if shelter_at(_world.player.global_position, &"storm") > 0.0 else "-")
	var eta := next_change_time - t
	Dev.put("weather/next", "%s %s" % ["clr" if in_storm else "stm",
		">1h" if eta == INF else "%d:%02d" % [floori(eta / 60.0), floori(fmod(eta, 60.0))]])
	Dev.put("weather/sun", "%d%%" % roundi(felt_light(_world.player.global_position) * 100.0))
	Dev.put("weather/temp", "%d°C" % roundi(felt_temperature(_world.player.global_position)))
	Dev.put("weather/map", "%.1fms %d jumps" % [map.max_upload_ms, map.rebuilds])


static func _linear(color: Color) -> Vector3:
	var c := color.srgb_to_linear()
	return Vector3(c.r, c.g, c.b)
