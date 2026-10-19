class_name Weather
extends Node
## The weather as everything in the world feels it, and as it looks from where
## the player stands. Every system asks felt_*() at its own position and never
## reads the field directly. Shelters (running shields' bubbles) and the
## ground's lee edit the answers here, so everything agrees about where a
## bubble is and where a dune breaks the wind.
##
## The game plays by the field at the player: in_storm, harm, the far ring,
## wind. The senses follow seen_storm, the dust at the camera as the screen
## draws it, so the light drops exactly when the dust visibly swallows you.
## Light passes through a bubble, so inside one the air is clear but the light
## is the storm's. This is the one owner of the sun, sky, haze and the storm
## walls' light, which a live vent's plume takes too; the sky view draws Tu and
## the stars in it, and the eye sets the exposure the camera sees it all by.

## Starlight and the air's own glow: all the light a far-side night has.
const NIGHT_LIGHT := 0.0005
## How far ahead the readout forecasts, and the shortest change it can see.
const FORECAST_HORIZON := 3600.0
const FORECAST_STEP := 5.0
## A clear day's light, which storms dim.
const SUN_COLOR := Color(1.0, 0.95, 0.86)
const AMBIENT_COLOR := Color(0.8, 0.72, 0.62)
## Light that has come through a storm's dust is reddened by it, as the dust is.
const STORM_TINT := Color(0.95, 0.8, 0.62)
## Grains in the air are lit from every side and throw the sun forward, so they
## show half again brighter than the same sand lying on the ground.
const GRAIN_GLOW := 1.5
## The sun's disc, which the storm pass draws so a wall can cover it.
const SUN_DISC := Vector3(14.0, 12.5, 10.5)
## The eclipse's ring of fire, Tu's air bending sunset light round its limb:
## its light at its flare as a share of the sun's, which a storm's dust throws
## forward into a halo; the share of that open ground and the air get, so
## totality stays night-dark; and its colour (docs/art-direction.md). The last
## sliver of sun before it, low on Tu's limb, goes this copper.
const RING_LIGHT := 0.02
const RING_ON_GROUND := 0.2
const RING_COLOR := Color("#ff5a1e")
const COPPER := Color(1.0, 0.55, 0.3)
## The ring's light low in the air all round the horizon, against its light on
## the ground.
const RING_HORIZON := 14.0

var field: WeatherField
var day: DayCycle
var map: StormMap
var sky: SkyView
## The plumes drawn now, each its own source's.
var plumes: Array[Plume] = []
var rumbles: Rumbles
var _plumes_due := 0.0
var _plumes_at := 0.0
var lee: Lee
var eye: Eye
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
## The light on open ground round the camera, 0 to 1 of the sun overhead and
## the whole sky's, as the screen lights it: what the suit's headlamp reads.
var seen_light := 1.0
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
var _meter: EyeMeter


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	field = WeatherField.new(world.run_seed, _tuning)
	day = DayCycle.new(_tuning)
	map = StormMap.new(world, field)
	lee = Lee.new(world)
	_environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	_sun = world.get_node("Sun")
	_sun_energy = _sun.light_energy
	# The storm pass draws the disc, so a wall can cover it.
	_sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_haze_color = _environment.fog_light_color
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	_environment.fog_density = _tuning.haze_strength
	_environment.tonemap_exposure = _tuning.exposure
	eye = Eye.new(_tuning)
	_meter = EyeMeter.new()
	_meter.on_reading = eye.see
	var effects: Array[CompositorEffect] = [_meter]
	world.player.camera.compositor = Compositor.new()
	world.player.camera.compositor.compositor_effects = effects
	face.setup(world, field, map)
	sky = SkyView.new()
	add_child(sky)
	sky.setup(world, day, _environment, face, _sun)
	for i in Plume.AT_ONCE:
		var plume := Plume.new()
		add_child(plume)
		plume.setup(world, self)
		plumes.append(plume)
	rumbles = Rumbles.new()
	add_child(rumbles)
	rumbles.setup(world, self)


## Each felt_*() reads now, or a given world time t: power ticks read theirs.
## Shelter is always as it stands now; the lee is the wind's at that time.
## A bubble keeps out its share of what the lee lets through.
func felt_storm(at: Vector3, t := NAN) -> float:
	return field_storm(at, t) * (1.0 - lee_at(at, &"storm", t)) * (1.0 - shelter_at(at, &"storm"))


## Horizontal wind, m/s, in engine axes.
func felt_wind(at: Vector3, t := NAN) -> Vector3:
	return open_wind(at, t) * (1.0 - shelter_at(at, &"wind"))


## The wind in the open air at a place, as if no bubble stood: the field's,
## less what the ground's lee takes. What the dust outside a bubble rides.
func open_wind(at: Vector3, t := NAN) -> Vector3:
	var blowing := field_wind(at, t)
	return blowing * (1.0 - _lee(at, blowing, _tuning.lee_wind))


## Sunlight reaching a place, 0 to 1: the sky's share after Tu and the storm
## take theirs. Light passes through a shield, so shelter changes nothing here.
func felt_light(at: Vector3, t := NAN) -> float:
	return day.sunlight(_when(t), _world.moon.latitude, _world.moon.longitude) \
		* (1.0 - _tuning.storm_darkness * field_storm(at, t))


## What an anomaly makes of a storm's damage at a place, now or at world
## time t: times what the clean curve deals, in particles (x) and in wind past
## what's stood (y); 1 and 1 outside one. The one door to its hidden term for
## everything that deals damage: wear, harm, crops and a shield's load. Every
## forecast and instrument reads the clean field instead.
func hidden(at: Vector3, t := NAN) -> Vector2:
	var h := field.anomaly_at(_world.world_x(at.x), _world.world_z(at.z), _when(t))
	return Vector2(lerpf(1.0, _tuning.anomaly_particles, h), lerpf(1.0, _tuning.anomaly_wind, h))


## The storm the field makes at a place, as if no shelter stood.
func field_storm(at: Vector3, t := NAN) -> float:
	return field.storm_at(_world.world_x(at.x), _world.world_z(at.z), _when(t))


## The wind the field blows at a place, as if no shelter stood.
func field_wind(at: Vector3, t := NAN) -> Vector3:
	var w := field.wind_at(_world.world_x(at.x), _world.world_z(at.z), _when(t))
	return Vector3(w.x, 0.0, w.y)


## The air's temperature at a place, °C, as if no shelter stood: the local
## day's swing round its mean, wider toward the poles, less while the eclipse
## lasts, and blanketed by the storm's dust.
func field_temperature(at: Vector3, t := NAN) -> float:
	return temperature_under(field_storm(at, t), t)


## The air's temperature, °C, under a storm of this intensity, as if no
## shelter stood: what a place's is, its storm known.
func temperature_under(storm: float, t := NAN) -> float:
	var moon := _world.moon
	var blanket := 1.0 - _tuning.temperature_storm_blanket * storm
	var swing := _tuning.temperature_swing \
		* (1.0 + _tuning.temperature_pole_widen * absf(sin(moon.latitude))) * blanket
	return _tuning.temperature_mean + swing * cos(TAU * (day.time_of_day(_when(t), moon.longitude) - _tuning.temperature_peak)) \
		- _tuning.eclipse_chill * day.eclipse_chill(_when(t), moon.latitude, moon.longitude) * blanket


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


## How much of a harm (&"wind", &"storm") the ground's lee keeps from a
## place, 0 to its most: read upwind along the wind blowing there at time t,
## so it turns with the wind. A place's, the same for all that stand there.
func lee_at(at: Vector3, harm: StringName, t := NAN) -> float:
	var most: float = _tuning.lee_wind if harm == &"wind" else (_tuning.lee_storm if harm == &"storm" else 0.0)
	return 0.0 if most == 0.0 else _lee(at, field_wind(at, t), most)


## The lee a place gets from the wind blowing there, up to `most`; none in
## still air, which has no upwind.
func _lee(at: Vector3, blowing: Vector3, most: float) -> float:
	if most == 0.0 or blowing.length_squared() < 1e-6:
		return 0.0
	return most * lee.share(_world.world_x(at.x), _world.world_z(at.z), atan2(blowing.z, blowing.x))


## Every shelter in the world, standing or down, gathered again only when one
## comes or goes: ropes and loose bodies ask many times a tick.
func shelters() -> Array[Node]:
	if _shelters_seen != Shelter.changes and is_inside_tree():
		_shelters_seen = Shelter.changes
		_shelters = get_tree().get_nodes_in_group(Shelter.GROUP)
	return _shelters


func _when(t: float) -> float:
	return _world.time if is_nan(t) else t


## The clock jumped: forecast again on the next tick, and the eye takes the
## cut as a cut.
func forecast_now() -> void:
	_forecast_due = 0.0
	next_change_time = INF
	eye.settle()


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
func _process(delta: float) -> void:
	# Before the plumes draw: each its source in sight, looked over a few
	# times a second, and at once after a jump.
	_plumes_due -= delta
	if _plumes_due <= 0.0 or absf(_world.time - _plumes_at) > 2.0:
		_plumes_due = 0.25
		Plume.assign(plumes, _world)
	_plumes_at = _world.time
	if _meter.enabled != _tuning.eye_adapts:
		_meter.enabled = _tuning.eye_adapts
		eye.settle()
	eye.adapt(delta)
	_environment.tonemap_exposure = _tuning.exposure * eye.exposure()
	var holes := PackedVector4Array()
	var glows := PackedFloat32Array()
	for shelter: Shelter in shelters():
		if shelter.carves() and holes.size() < Shelter.MAX:
			var c := shelter.global_position
			holes.append(Vector4(c.x, c.y, c.z, shelter.radius))
			glows.append(shelter.glow)
	face.sync(_world.time, holes, glows)
	atmosphere.carve(holes)


## The plume drawing a source of Geology's, by its id, or null.
func plume_for(id: StringName) -> Plume:
	for plume in plumes:
		if plume.source.get("id") == id:
			return plume
	return null


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
		var size := Catalog.bounds(shape.shape).size
		total += maxf(size.x * size.y, maxf(size.y * size.z, size.x * size.z))
	return total


## The wind's push on a body held still, N, by its catch and the felt wind's
## square: at its hardest over `span` s from world time t, read each second,
## so a step that long meets its gusts. What a line holding it bears.
func wind_load(body: CollisionObject3D, t := NAN, span := 0.0) -> float:
	var hardest := 0.0
	var k := 0
	while true:
		var at := minf(k, span)
		hardest = maxf(hardest, felt_wind(body.global_position, _when(t) + at).length_squared())
		if at >= span:
			break
		k += 1
	return catch_of(body) * hardest


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
	var here := camera.global_position
	var moon := _world.moon
	var sun := day.sun_direction(t, moon.latitude, moon.longitude)
	# Behind Tu the sun's light is gone, and the air's glow with it; at night
	# Tu-shine lights the near side.
	var shown := day.sun_shown(t)
	var up := smoothstep(-0.02, 0.1, sun.y)
	var risen := up * shown
	# Round Tu's limb the ring of fire lights what the sun no longer does.
	var ring_shown := day.ring_light(t) * up * RING_LIGHT
	var ring := ring_shown * RING_ON_GROUND
	var tu_light := day.tu_light(t, moon.latitude, moon.longitude) * _tuning.tu_shine_scale
	var sunlit := smoothstep(-0.1, 0.2, sun.y) * shown
	var daylight := sunlit + tu_light + ring + NIGHT_LIGHT
	seen_storm = face.seen_at(here)
	seen_shade = face.open_at(here)
	seen_sun = maxf(face.sun_at(here, sun), 0.02)
	seen_front = face.front_at(here).x if map.ready else -INF

	# The light dims in stages: a wall blots out the sun, then towers over half
	# the sky, then swallows you. Inside, the light is the storm glowing from
	# above, so the sun light turns overhead and soft: dunes keep their shape
	# while their shadows go. A bubble clears the air, not the light.
	var towering := atan2(_tuning.wall_height - here.y, maxf(-seen_front, 1.0)) / (PI * 0.5)
	var coverage := lerpf(clampf(towering, 0.0, 1.0) * 0.5, 1.0, seen_shade)
	var dim := lerpf(1.0, 1.0 - _tuning.storm_darkness, seen_shade)
	var sky_left := 1.0 - 0.55 * coverage
	var overhead := Vector3(sun.x * 0.15, 1.0, sun.z * 0.15).normalized()
	var light_from := sun.slerp(overhead, seen_shade * up)
	_sun.global_basis = Basis.looking_at(-light_from, Vector3.UP if absf(light_from.y) < 0.9 else Vector3.FORWARD)
	# The sun's light and the ring's come from about the same place.
	var direct := risen + ring
	_sun.light_energy = _sun_energy * direct * maxf(seen_sun, seen_shade * 0.6) * dim
	var tint := Color.WHITE.lerp(STORM_TINT, seen_shade)
	# The last sliver of the sun goes copper, and the sky it lights with it.
	var copper := pow(1.0 - shown, 1.5) * 0.9
	var sun_color := SUN_COLOR.lerp(COPPER, copper)
	# Where the light is Tu's, the sky and the haze that fill in are its cool;
	# where it's the ring's, its red.
	var fill := (Color.WHITE * NIGHT_LIGHT + Color.WHITE.lerp(COPPER, copper) * sunlit
		+ SkyView.TU_SHINE_COLOR * tu_light + RING_COLOR * ring) / daylight
	_sun.light_color = (sun_color * risen + RING_COLOR * ring) / maxf(direct, 1e-9) * tint
	_environment.ambient_light_color = AMBIENT_COLOR * tint * fill
	_environment.ambient_light_energy = _tuning.sky_fill * daylight * sky_left * dim
	seen_light = (_sun.light_energy / _sun_energy * maxf(light_from.y, 0.0) + _environment.ambient_light_energy) \
		/ (1.0 + _tuning.sky_fill)

	# The clear day's haze, dimmed with the light and browned by the dust. The
	# dust itself is the storm pass's; the haze only closes in behind it, never
	# within the few metres the dust leaves.
	var haze_light := daylight * sky_left * dim
	var haze_color := _haze_color.lerp(_tuning.storm_fog_color, seen_storm) * fill
	_environment.fog_light_color = haze_color
	_environment.fog_light_energy = haze_light
	_environment.fog_depth_begin = lerpf(_tuning.haze_begin, 50.0, seen_storm)
	_environment.fog_depth_end = lerpf(_tuning.haze_end, 400.0, seen_storm)
	_world.terrain.show_far(not in_storm)
	var air := lerpf(1.0, 0.45, coverage) * dim
	sky.show(t, here, sun, shown, Vector3(fill.r, fill.g, fill.b) * daylight * air,
		_linear(haze_color) * haze_light, tu_light, seen_shade, dim, _linear(RING_COLOR) * ring * RING_HORIZON * air)
	seen_light += sky.tu_seen / (1.0 + _tuning.sky_fill)

	var sun_light := _linear(sun_color) * _sun_energy * risen
	var ring_light := _linear(RING_COLOR) * _sun_energy * ring_shown
	var sky_light := _linear(AMBIENT_COLOR * fill) * _tuning.sky_fill * daylight
	face.set_light("sun_dir", sun)
	face.set_light("sun_light", sun_light)
	face.set_light("ring_light", ring_light)
	# A wall faces half the sky, so it gets less than open ground.
	face.set_light("sky_light", sky_light * 0.6)
	face.set_light("camera_sun", seen_sun)
	face.set_light("sun_disc", SUN_DISC * up)
	face.set_light("haze_color", _linear(haze_color) * haze_light)
	face.set_light("haze", Vector3(_environment.fog_depth_begin, _environment.fog_depth_end,
		_environment.fog_density))
	# The light round the camera, which a shell's glass catches.
	face.set_light("shell_light", _linear(_environment.ambient_light_color) * _environment.ambient_light_energy)
	var tu := day.tu_direction(t, moon.latitude, moon.longitude)
	for plume in plumes:
		plume.light(sun, sun_light, sky_light, ring_light, _linear(haze_color) * haze_light,
			Vector3(_environment.fog_depth_begin, _environment.fog_depth_end, _environment.fog_density),
			tu, _linear(SkyView.TU_SHINE_COLOR) * _sun_energy * tu_light)

	# Outside a bubble the dust is the storm's own: it rides the open air's
	# wind, slowed in a lee, and thickens with the storm, and the bubble only
	# carves it out.
	var grains := _linear(_tuning.sand_color) * GRAIN_GLOW \
		* (sun_light * maxf(seen_sun, seen_shade * 0.6) * 0.6 + sky_light * sky_left) * dim
	var near := exp(minf(seen_front, 0.0) / 350.0) if map.ready else 0.0
	var ring_grains := ring_light * face.ring_at(here, sun) if ring > 0.0 else Vector3.ZERO
	atmosphere.show_eclipse(sun, _linear(_tuning.sand_color) * GRAIN_GLOW * ring_grains, (1.0 - shown) * up, delta)
	atmosphere.show_weather(camera, _world.height_under(here), open_wind(_world.player.global_position),
		shelter_at(here, &"storm"), seen_shade, near, grains, face.sigma() * seen_shade, _world.time_warp > 0.0, delta)


func _report() -> void:
	var t := _world.time
	var hours := day.time_of_day(t, _world.moon.longitude) * 24.0
	var warp := "" if _world.time_warp == 1.0 else " x%d" % _world.time_warp
	Dev.put("weather/t", "d%d %02d:%02d%s" % [day.day(t, _world.moon.longitude, _world.began), floori(hours),
		floori(fmod(hours, 1.0) * 60.0), warp])
	# Compass bearing the wind comes from; north is -z.
	var from := fposmod(rad_to_deg(atan2(-wind.x, wind.z)), 360.0)
	Dev.put("weather/wind", "%.1fm/s %03d" % [wind.length(), roundi(from) % 360])
	Dev.put("weather/stm", "%d%%" % roundi(storm * 100.0) if in_storm else "clear")
	var anomaly := field.anomaly_at(_world.player_world_x(), _world.player_world_z(), t)
	Dev.put("weather/anom", "%d%%" % roundi(anomaly * 100.0) if anomaly > 0.0 else "-")
	Dev.put("weather/wall", "-" if seen_front == -INF else ("in %dm" % roundi(seen_front)
		if seen_front >= 0.0 else "%dm" % roundi(-seen_front)))
	Dev.put("weather/seen", "%d%%" % roundi(seen_storm * 100.0))
	Dev.put("weather/shel", "in" if shelter_at(_world.player.global_position, &"storm") > 0.0 else "-")
	var lee_cut := lee_at(_world.player.global_position, &"wind")
	Dev.put("weather/lee", "%d%%" % roundi(lee_cut * 100.0) if lee_cut > 0.0 else "-")
	var eta := next_change_time - t
	Dev.put("weather/next", "%s %s" % ["clr" if in_storm else "stm",
		">1h" if eta == INF else "%d:%02d" % [floori(eta / 60.0), floori(fmod(eta, 60.0))]])
	Dev.put("weather/sun", "%d%%" % roundi(felt_light(_world.player.global_position) * 100.0))
	Dev.put("weather/lit", "%d%%" % roundi(seen_light * 100.0))
	Dev.put("weather/eye", "x%.1f" % eye.exposure() if _tuning.eye_adapts else "off")
	Dev.put("weather/temp", "%d°C" % roundi(felt_temperature(_world.player.global_position)))
	Dev.put("weather/map", "%.1fms %d jumps" % [map.max_upload_ms, map.rebuilds])


static func _linear(color: Color) -> Vector3:
	var c := color.srgb_to_linear()
	return Vector3(c.r, c.g, c.b)
