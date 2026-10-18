class_name Plume
extends MultiMeshInstance3D
## A live vent's plume as it looks from where you stand. The vent's gas shows
## only by what rides it: its ash, dark and soon fallen out; steam, where the
## air is cold enough to hold it; and the pale sulphate haze the gas makes
## over minutes. It rises as a buoyant plume does in wind (Briggs's rise: bent
## over by the wind, levelling where the air's stability stops it) and rides
## the field's own drift away, so its tail curls as the wind turns. Here, each
## frame, its streakline (where what left the vent at each age is now, how
## wide and what it carries) is worked out from the time, the vent and the
## weather alone; the shader hangs one draw of soft puffs on it, each a parcel
## that left at a moment. Nothing in the world reads it. Past the camera's
## reach it's the same puffs drawn nearer and smaller, fading with the storm
## walls' haze; a storm between hides it.

const SHADER := preload("res://game/weather/plume.gdshader")
## The streakline: this many points, the oldest this many s, crowded toward
## the vent by this power.
const POINTS := 24
const OLDEST := 600.0
const CROWD := 1.6
## The puffs hung on it, by kind in the shader's order: [how many, youngest
## s, oldest s]: ash falling out under it, the steam and gas at the mouth, the
## column, the bent-over body, the thinning tail. Ages count from the vent,
## the falling ash's from when it left the column.
const FAMILIES := [[36, 0.0, 150.0], [28, 0.0, 14.0], [64, 0.0, 80.0], [72, 60.0, 300.0], [48, 260.0, 600.0]]
## Parcels are numbered round this many, so a family's ids never run out.
const PARCELS := 1048576.0
## What leaves the vent rises from this wide, m.
const MOUTH := 6.0
## The air's stability, its buoyancy frequency by day and by night, 1/s.
const STABILITY := Vector2(0.009, 0.016)
## A rising plume widens by this share of its rise, and downwind spreads by
## this share of how far it's gone.
const WIDEN := 0.4
const SPREAD := 0.04
## How thick it is across its middle: at this width, m, and wind, m/s,
## seeping, this optical depth; thinner as it widens or the wind stretches
## it, by this power of the two.
const THICK := Vector3(30.0, 10.0, 8.0)
const THINS := 0.7
## Ash falls out of it over this many s; the gas makes its haze over this
## many; steam lasts from the first in the heat to the second in the cold, s,
## and shows below the first air temperature, fully below the second, °C. How
## thick each looks for what it is: ash, steam, haze.
const ASH_FALLS := 90.0
const HAZE_FORMS := 120.0
const STEAM_LASTS := Vector2(15.0, 240.0)
const STEAM_AIR := Vector2(30.0, -5.0)
const SHOWS := Vector3(1.0, 1.5, 0.6)
## The line changes slowly, so this many of its points are worked out again
## a frame, and half as many once you're this far off, m.
const EACH_FRAME := 4
const FAR_OFF := 3000.0
## Its mouth moving further than this is a jump, m, not the sheet's seams.
const JUMP := 5.0
## Storms between you and it, and their shadow on it, are read at these ages,
## s, one read every other frame; a front this near the line counts as part
## way in, m.
const READS := [0.0, 40.0, 150.0, 400.0]
const VEIL_EDGE := 150.0
## Past this the puffs are drawn nearer and smaller, m: the camera's far plane.
## Past the skyline's reach it's a landmark, as the skyline's are: the haze
## takes it more slowly than the air between would (Skyline.LANDMARK_FALL).
const NEAR_REACH := 4200.0
## Its ash fan on the sand runs down the long-term wind, by e this often, m.
const FAN := 260.0

var material := ShaderMaterial.new()
## The live vent drawn now, or {}; its mouth's middle on the ground, world
## metres; and which way its slot runs there, world x and z.
var vent := {}
var root := Vector3.ZERO
var slot := Vector2(0.0, 1.0)
## The streakline: each point's place from the root, m in engine axes, and
## width; what it carries, as optical depths across its middle of ash, steam
## and haze, and how hard the vent was venting as it left; the storms' veil
## between you and it, and the sun left on it.
var line := PackedVector4Array()
var matter := PackedVector4Array()
var seen := PackedVector4Array()
## How hard the vent is venting now, as a share of its seep, and its ash share.
var venting := Vector2.ZERO
## Main-thread time it took this frame, and the most any has, ms.
var frame_ms := 0.0
var slowest_ms := 0.0

var _world: World
var _weather: Weather
var _tuning: Tuning
var _total := 0
var _veil := PackedFloat32Array()
var _sun := PackedFloat32Array()
var _read := 0
var _next := 0
var _frames := 0
var _distance := 0.0
var _last_t := -INF
## The storm map's first moment when the storms were last read in full.
var _map_t0 := -INF
## The sheet as the root was last found from: its follows and units laid.
var _found_at := Vector2i(-1, -1)


func setup(world: World, weather: Weather) -> void:
	_world = world
	_weather = weather
	_tuning = world.tuning
	material.shader = SHADER
	# After the storm pass, which overwrites the scene, and before the dust round you.
	material.render_priority = -50
	material.set_shader_parameter("noise", Paint.noise())
	var families := PackedVector4Array()
	for each: Array in FAMILIES:
		families.append(Vector4(_total, each[0], each[1], each[2]))
		_total += each[0]
	material.set_shader_parameter("families", families)
	material.set_shader_parameter("total", _total)
	material.set_shader_parameter("oldest", OLDEST)
	material.set_shader_parameter("crowd", CROWD)
	material.set_shader_parameter("reach", Vector3(NEAR_REACH, _tuning.wall_fade_begin, _tuning.wall_fade_end))
	material.set_shader_parameter("landmark", Vector2(_tuning.skyline_m, Skyline.LANDMARK_FALL))
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var puffs := MultiMesh.new()
	puffs.transform_format = MultiMesh.TRANSFORM_3D
	puffs.mesh = quad
	puffs.instance_count = _total
	# Placed in the shader, so never culled.
	puffs.custom_aabb = AABB(Vector3.ONE * -1.0e5, Vector3.ONE * 2.0e5)
	multimesh = puffs
	custom_aabb = puffs.custom_aabb
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line.resize(POINTS)
	matter.resize(POINTS)
	seen.resize(POINTS)
	_veil.resize(READS.size())
	_sun.resize(READS.size())
	_veil.fill(1.0)
	_sun.fill(1.0)
	visible = false


## Each tick, from Weather, as it lights the storm walls: the sun's way and
## light, the sky's, the eclipse ring's, the haze's colour and its depth fog
## (begin, end, strength), and Tu's way and its shine.
func light(sun: Vector3, sun_light: Vector3, sky_light: Vector3, ring_light: Vector3, haze_color: Vector3,
		haze: Vector3, tu: Vector3, tu_light: Vector3) -> void:
	material.set_shader_parameter("tu_dir", tu)
	material.set_shader_parameter("tu_light", tu_light)
	material.set_shader_parameter("sun_dir", sun)
	material.set_shader_parameter("sun_light", sun_light)
	material.set_shader_parameter("sky_light", sky_light)
	material.set_shader_parameter("ring_light", ring_light)
	material.set_shader_parameter("haze_color", haze_color)
	material.set_shader_parameter("haze", haze)


func _process(_delta: float) -> void:
	if _world == null:
		return
	var started := Time.get_ticks_usec()
	var was := visible
	var from := root
	visible = _follow()
	if visible:
		# A jump in time or place, a first sight, or a storm map made afresh
		# for one, works it all out at once; the sheet's seams don't.
		var whole := not was or root.distance_to(from) > JUMP or absf(_world.time - _last_t) > 1.0 \
			or absf(_weather.map.t0 - _map_t0) > 5.0
		if whole:
			_map_t0 = _weather.map.t0
		_streak(_world.time, POINTS if whole else (EACH_FRAME if _distance < FAR_OFF else EACH_FRAME / 2))
		_upload()
	_last_t = _world.time
	frame_ms = (Time.get_ticks_usec() - started) / 1000.0
	slowest_ms = maxf(slowest_ms, frame_ms)


## The live vent nearest you within the walls' far fade, and its mouth's
## place: false if there's none to draw.
func _follow() -> bool:
	var sites := _world.shape.sites
	if not sites.anchored():
		return false
	var geology := _world.shape.history.geology
	var here := Sphere.point(_world.moon.latitude, _world.moon.longitude)
	var nearest := {}
	var near := _tuning.wall_fade_end + 2000.0
	for each in geology.live():
		var by := Sphere.angle(here, each.p) * geology.radius
		if by < near:
			near = by
			nearest = each
	if nearest.is_empty():
		if not vent.is_empty():
			_deposit(false)
		vent = {}
		return false
	var at := Vector2i(sites.follows, sites.laid)
	if nearest != vent or at != _found_at:
		vent = nearest
		_found_at = at
		_root()
		_deposit(true)
	var camera := _world.player.camera.global_position
	var off := Vector2(_world.world_x(camera.x) - root.x, _world.world_z(camera.z) - root.z)
	_distance = off.length()
	_dev(off)
	return _distance < _tuning.wall_fade_end


## Where the vent's mouth is on the ground: the mouth itself where it's laid,
## else where the sheet would lay it from where you are.
func _root() -> void:
	var sites := _world.shape.sites
	var guess := sites.anchor().place(vent.p)
	slot = Vector2.from_angle(sites.anchor().ground_bearing(vent.bearing) - PI * 0.5)
	root = Vector3(guess.x, _world.shape.dunes(guess.x, guess.y), guess.y)
	for site in sites.query(Rect2(guess - Vector2.ONE * 150.0, Vector2.ONE * 300.0)):
		var mouth := site as VentMouth
		if mouth != null and mouth.stands():
			root = Vector3(mouth.x, mouth.pad(), mouth.z)
			var along := mouth.to_world(Vector2(0.0, 1.0)) - Vector2(mouth.x, mouth.z)
			slot = along.normalized()


## The streakline at world time t, `count` of its points a call in turn:
## each is what left the vent `age` s ago, as hard as it was venting then,
## carried by the drift since and a front's outflow, risen as far as its
## buoyancy took it in that wind.
func _streak(t: float, count := POINTS) -> void:
	var geology := _world.shape.history.geology
	var field := _weather.field
	var moon := _world.moon
	var g := _world.gravity / _tuning.gravity
	var day := smoothstep(-0.05, 0.25, _weather.day.sun_direction(t, moon.latitude, moon.longitude).y)
	# The air's stability is gravity's too, so how high a plume levels doesn't
	# change with it; only how hard it climbs at first does.
	var n := lerpf(STABILITY.y, STABILITY.x, day) * sqrt(g)
	var cold := smoothstep(STEAM_AIR.x, STEAM_AIR.y,
		_weather.temperature_under(field.storm_at(root.x, root.z, t), t))
	var lasts := lerpf(STEAM_LASTS.x, STEAM_LASTS.y, cold)
	var drift := field.drift_at(t)
	var outflow := field.outflow_at(root.x, root.z, t)
	var push := field.prevailing_at(t).normalized() * _tuning.storm_outflow_speed
	var blowing := field.steady_wind_at(root.x, root.z, t)
	venting = geology.venting(vent, t)
	for i in count:
		var k := (_next + i) % POINTS
		var age := OLDEST * pow(float(k) / (POINTS - 1), CROWD)
		var then := t - age
		var v := venting if k == 0 else geology.venting(vent, then)
		var gone := drift - field.drift_at(then) + push * age * 0.5 * (outflow + field.outflow_at(root.x, root.z, then))
		var speed := maxf(gone.length() / age if age > 0.0 else blowing.length(), 0.5)
		var rise := rise_in(_tuning.plume_buoyancy * v.x * g, speed, age, n)
		var width := MOUTH + WIDEN * rise + SPREAD * gone.length()
		# Thinner as it widens and the wind draws it out; less than mass alone
		# says, since what's left is the finest and shows the most.
		var thick := THICK.z * v.x * pow(THICK.x * THICK.y / (width * speed), THINS)
		var ash := v.y * exp(-age / ASH_FALLS) * SHOWS.x
		var steam := cold * exp(-age / lasts) * SHOWS.y
		var haze := (1.0 - exp(-age / HAZE_FORMS)) * (1.0 - 0.5 * v.y) * SHOWS.z
		line[k] = Vector4(gone.x, rise, gone.y, width)
		matter[k] = Vector4(thick * ash, thick * steam, thick * haze, v.x)
	_next = (_next + count) % POINTS
	_frames += 1
	if count == POINTS:
		for i in READS.size() * 2:
			_read_storms(t)
	elif _frames % 2 == 0:
		_read_storms(t)
	material.set_shader_parameter("wind", Vector3(blowing.x, 0.0, blowing.y))
	material.set_shader_parameter("now_mix", Vector4(venting.x, venting.y, cold, 0.0))


## How high a buoyant plume has risen `age` s out, m: bent over by the wind
## as F^1/3 x^2/3 / u, and levelling where the air's stability stops it,
## lower in a stronger wind (Briggs). f is its buoyancy flux, m⁴/s³; u the
## wind, m/s; n the air's buoyancy frequency, 1/s.
static func rise_in(f: float, u: float, age: float, n: float) -> float:
	if age <= 0.0 or f <= 0.0:
		return 0.0
	var bent := 1.6 * pow(f, 1.0 / 3.0) * pow(u * age, 2.0 / 3.0) / u
	var level := minf(2.6 * pow(f / (u * n * n), 1.0 / 3.0), 5.0 * pow(f, 0.25) * pow(n, -0.75))
	return bent / pow(1.0 + pow(bent / level, 3.0), 1.0 / 3.0)


## One read in turn: whether storms stand between you and the line at an
## age, or how much sun they leave on it there; every point takes the reads
## either side of its age.
func _read_storms(t: float) -> void:
	var i := (_read / 2) % READS.size()
	var at := _point(READS[i])
	if _read % 2 == 0:
		var camera := _world.player.camera.global_position
		_veil[i] = veil(Vector2(_world.world_x(camera.x), _world.world_z(camera.z)), Vector2(at.x, at.z), t)
	else:
		var moon := _world.moon
		var sun := _weather.day.sun_direction(t, moon.latitude, moon.longitude)
		_sun[i] = _weather.face.sun_at(Vector3(_world.engine_x(at.x), at.y, _world.engine_z(at.z)), sun)
	_read += 1
	for k in POINTS:
		var age := OLDEST * pow(float(k) / (POINTS - 1), CROWD)
		var j := 0
		while j < READS.size() - 2 and age > READS[j + 1]:
			j += 1
		var w := clampf((age - READS[j]) / (READS[j + 1] - READS[j]), 0.0, 1.0)
		seen[k] = Vector4(lerpf(_veil[j], _veil[j + 1], w), lerpf(_sun[j], _sun[j + 1], w), 0.0, 0.0)


## How much of what's at a world place shows from another past the storms on
## the line between, 0 to 1, by the field's fronts: nothing through a storm,
## and nothing from inside one's dust.
func veil(from: Vector2, to: Vector2, t: float) -> float:
	var map := _weather.map
	if not map.ready:
		return 1.0
	var through := 1.0 - _weather.seen_storm
	var count := clampi(ceili(from.distance_to(to) / 800.0), 2, 8)
	for k in range(1, count + 1):
		var at := from.lerp(to, float(k) / count)
		through *= smoothstep(VEIL_EDGE, -VEIL_EDGE, map.front_at(at.x, at.y, t).x)
	return through


## The streakline's place at an age, world metres.
func _point(age: float) -> Vector3:
	var x := pow(clampf(age / OLDEST, 0.0, 1.0), 1.0 / CROWD) * (POINTS - 1)
	var k := mini(floori(x), POINTS - 2)
	var p := line[k].lerp(line[k + 1], x - k)
	return root + Vector3(p.x, p.y, p.z)


func _upload() -> void:
	var camera := _world.player.camera.global_position
	var at := Vector3(_world.engine_x(root.x), root.y, _world.engine_z(root.z))
	var young := at + Vector3(line[0].x, line[0].y, line[0].z)
	var old := at + Vector3(line[POINTS - 1].x, line[POINTS - 1].y, line[POINTS - 1].z)
	material.set_shader_parameter("root", at)
	material.set_shader_parameter("slot_dir", Vector3(slot.x, 0.0, slot.y))
	material.set_shader_parameter("line", line)
	material.set_shader_parameter("matter", matter)
	material.set_shader_parameter("seen", seen)
	# Back to front along it: the far end's parcels first.
	material.set_shader_parameter("reverse", camera.distance_to(old) > camera.distance_to(young))
	var clocks := PackedVector2Array()
	for each: Array in FAMILIES:
		var cycle: float = _world.time / ((each[2] - each[1]) / each[0])
		clocks.append(Vector2(cycle - floorf(cycle), fmod(floorf(cycle), PARCELS)))
	material.set_shader_parameter("clocks", clocks)


## The ash the vent has laid on the sand round its mouth and down the wind.
func _deposit(shown: bool) -> void:
	var sand := _world.terrain.sand_material as ShaderMaterial
	if sand == null:
		return
	sand.set_shader_parameter("vent_ash", Vector3(root.x, root.z, FAN) if shown else Vector3.ZERO)
	sand.set_shader_parameter("vent_slot", slot)


func _dev(off: Vector2) -> void:
	var state := "bursting" if venting.x > 1.6 else "seeping"
	Dev.put("weather/vent", "%.1fkm %s %s" % [off.length() / 1000.0,
		Radio.compass(rad_to_deg(atan2(-off.x, off.y))), state])
