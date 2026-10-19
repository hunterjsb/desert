class_name Plume
extends MeshInstance3D
## A plume as it looks from where you stand: a live vent's, or a gas pocket's
## blowing out. The vents let out mostly gas, hot and invisible, and what shows
## is the sand and dust it sweeps up from round the mouth and lifts: a vast
## column of the storms' own dust, towering over the haze far off and, near,
## only the air thickening round you. It rises as a buoyant plume does in wind
## (Briggs's rise: bent over by the wind, levelling where the air's stability
## stops it, and there spreading out as an umbrella) and rides the field's own
## drift away, so its tail curls as the wind turns. Here, each frame, its
## streakline (where what left at each age is now, how wide and how much dust
## it carries) is worked out from the time, the source and the weather alone;
## the shader marches the column round it as the storm walls are marched,
## billowed and lit as they are. Nothing in the world reads it. Storms between
## hide what's under their roofs, and what towers over them shows.

const SHADER := preload("res://game/weather/plume.gdshader")
## How many plumes can be drawn at once, the nearest sources first.
const AT_ONCE := 3
## The streakline: this many points, the oldest this many s, crowded toward
## the source by this power; the column is drawn through these of them, all
## of its young end, where a burst's column stands, and every few of its tail.
const POINTS := 24
const OLDEST := 600.0
const CROWD := 1.6
const COLUMN := [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 19, 23]
## What leaves rises from this wide, m: the gas sweeps up the sand round its
## mouth, not just what's in its throat.
const MOUTH := 150.0
## The air's stability, its buoyancy frequency by day and by night, 1/s.
const STABILITY := Vector2(0.009, 0.016)
## A rising plume widens by this share of its rise, and downwind spreads by
## this share of how far it's gone. Levelled, it spreads out sideways as a
## current in the stable air does, at this share of its stability times its
## height, m/s: what makes a burst's umbrella.
const WIDEN := 0.25
const SPREAD := 0.04
const UMBRELLA := 0.25
## How thick its dust is through its depth: at this depth, m, and wind, m/s,
## seeping, this optical depth; thinner as it deepens or the wind stretches
## it, by this power of the two, since what's left is the finest and shows
## the most.
const THICK := Vector3(30.0, 10.0, 8.0)
const THINS := 0.7
## A pocket's blowout throws up the sand it bursts through: this many times a
## vent's dust for its lift.
const DUSTY := 12.0
## The sand falls out of it by e over this many s, leaving this share, the
## fine dust that stays up; its oldest fifth fades out. The gas gathers it up
## round the mouth as it rises, all of it by this many s.
const FALLS := Vector2(150.0, 0.35)
const GATHERS := 60.0
## A burst's ash, its faint trace: how much of a burst's core it darkens at
## most, falling out by e over this many s.
const ASHEN := Vector2(0.3, 90.0)
## Two points of the column whose sources vented more than this many times
## apart aren't drawn as one stretch: a burst began between them, and its
## first gas joining them is thin.
const JOINS := 4.0
## The line changes slowly, its young end fastest in a burst: of its first
## this many points one is worked out again every other frame, and of the rest
## one every this many frames, a quarter as often once you're this far off, m;
## the air's stability this often, s.
const YOUNG := 6
const OLD_EVERY := 8
const FAR_OFF := 3000.0
const AIR_EVERY := 10.0
## Its source moving further than this is a jump, m, not the sheet's seams.
const JUMP := 5.0
## Storms between you and it past the storm map, and their shadow on it, are
## read at these ages, s, one read every fourth frame.
const READS := [0.0, 40.0, 150.0, 400.0]
## Past this the column is drawn nearer and smaller, m: the camera's far
## plane. Past the skyline's reach the haze takes it as if it were only as far
## as distance to this power says, more slowly than the air between would.
const NEAR_REACH := 4200.0
const FAR_FALL := 0.3
## Its billows stand out past its width by this share of it at most (the
## shader's).
const BILLOWS := 0.39
## Stood in, its dust closes in from this share of its width outside its edge
## to all of it this share inside, all round you once this many m of it would
## hide what's behind; and you see through it as through a storm's (3 over
## its dust a metre), never less far than the first, m, or further than the
## second.
const AIR_EDGE := Vector2(0.3, 0.2)
const AIR_THICK := 300.0
const SEEN_IN := Vector2(60.0, 4000.0)
## A storm's dust between: the field this near its threshold counts as part
## way in, and none lies further out than its value over this, its steepest a
## metre; so the march strides by that, never less than the first, m, nor
## more than the second, the third times at most.
const VEIL_EDGE := 0.006
const STEEPEST := 4.0e-4
const SEEN_STEPS := Vector3i(80, 1500, 48)
## A vent's ash fan on the sand runs down the long-term wind, by e this often,
## m; laid within this far of you, the far ring's reach.
const FAN := 260.0
const FAN_SHOWN := 3200.0

var material := ShaderMaterial.new()
## What it's drawing, a live vent or a pocket from Geology, or {}; where it
## rises on the ground, world metres; and which way a vent's slot runs there,
## world x and z.
var source := {}
var root := Vector3.ZERO
var slot := Vector2(0.0, 1.0)
## The streakline: each point's place from the root, m in engine axes, and
## width; the optical depth of its dust through it, its depth, m, its ash's
## darkening, and how hard its source vented as it left; the storms' veil
## between you and it, and the sun left on it.
var line := PackedVector4Array()
var matter := PackedVector4Array()
var seen := PackedVector4Array()
## How hard its source is venting now, as a share of the rift's seep, and its
## ash share.
var venting := Vector2.ZERO
## How far into its dust the camera stands, 0 to 1, and how far it sees there, m.
var air := 0.0
var seen_m := INF
## Main-thread time it took this frame, and the most any has, ms.
var frame_ms := 0.0
var slowest_ms := 0.0

## The plume laying its vent's ash on the sand, if any.
static var _depositor: Plume

var _world: World
var _weather: Weather
var _tuning: Tuning
var _veil := PackedFloat32Array()
var _sun := PackedFloat32Array()
var _read := 0
var _next_young := 0
var _next_old := 0
var _stable := 0.012
var _air_read_at := -INF
var _frames := 0
var _distance := 0.0
var _last_t := -INF
## The line or the reads have changed since they were last handed the shader.
var _changed := true
## The column as the shader reads it: each point's place and width; its dust
## a metre, depth for its width, veil and sun; its ash; and its bounds.
var _shape := PackedVector4Array()
var _dust := PackedVector4Array()
var _ashen := PackedVector2Array()
var _lo := Vector3.ZERO
var _hi := Vector3.ZERO
## The storm map's textures as last handed the shader.
var _map_a: Texture2D
var _map_b: Texture2D
## What the sand was last told of this plume's ash, if it's this plume's.
var _laid_ash := Vector3.INF
## The storm map's first moment when the storms were last read in full.
var _map_t0 := -INF
## The sheet as the root was last found from: its follows and units laid.
var _found_at := Vector2i(-1, -1)
var _found_for := {}


func setup(world: World, weather: Weather) -> void:
	_world = world
	_weather = weather
	_tuning = world.tuning
	material.shader = SHADER
	# After the storm pass, which overwrites the scene, and before the dust round you.
	material.render_priority = -50
	material.set_shader_parameter("storm_noise", weather.face.material.get_shader_parameter("storm_noise"))
	material.set_shader_parameter("storm_height", _tuning.wall_height)
	material.set_shader_parameter("storm_roof_soft", _tuning.wall_roof_soft)
	material.set_shader_parameter("dust_albedo", _linear(_tuning.wall_dust_color))
	material.set_shader_parameter("storm_glow", _tuning.wall_glow)
	material.set_shader_parameter("far_fade", Vector2(_tuning.wall_fade_begin, _tuning.wall_fade_end))
	material.set_shader_parameter("reach", Vector3(NEAR_REACH, _tuning.plume_fade_m.x, _tuning.plume_fade_m.y))
	material.set_shader_parameter("landmark", Vector2(_tuning.skyline_m, FAR_FALL))
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	mesh = box
	# Placed in the shader, so never culled.
	custom_aabb = AABB(Vector3.ONE * -1.0e5, Vector3.ONE * 2.0e5)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line.resize(POINTS)
	matter.resize(POINTS)
	seen.resize(POINTS)
	seen.fill(Vector4(1.0, 1.0, 0.0, 0.0))
	_shape.resize(COLUMN.size())
	_dust.resize(COLUMN.size())
	_ashen.resize(COLUMN.size())
	_veil.resize(READS.size())
	_sun.resize(READS.size())
	_veil.fill(1.0)
	_sun.fill(1.0)
	visible = false


## Each frame, before the plumes draw: the sources in sight, nearest first, to
## as many plumes as there are, each keeping its source while it's in sight.
static func assign(plumes: Array[Plume], world: World) -> void:
	var geology := world.shape.history.geology
	var t := world.time
	var here := Sphere.point(world.moon.latitude, world.moon.longitude)
	var sighted: Array[Array] = []
	for each in geology.live() + geology.pockets(t, t):
		var by := Sphere.angle(here, each.p) * geology.radius
		if by < world.tuning.plume_fade_m.y + 2000.0:
			sighted.append([by, each])
	sighted.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var wanted := sighted.slice(0, plumes.size()).map(func(s: Array) -> Dictionary: return s[1])
	var free: Array[Plume] = []
	for plume in plumes:
		if plume.source.is_empty() or not wanted.any(func(w: Dictionary) -> bool: return w.id == plume.source.id):
			plume.source = {}
			free.append(plume)
	for each: Dictionary in wanted:
		if not plumes.any(func(p: Plume) -> bool: return p.source.get("id") == each.id) and not free.is_empty():
			free.pop_front().source = each


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
		_frames += 1
		if whole:
			_streak(_world.time)
		elif _frames % 2 == 0:
			# Its young end changes fast in a burst, the rest slowly.
			var which := PackedInt32Array([_next_young])
			_next_young = (_next_young + 1) % YOUNG
			if _frames % OLD_EVERY == 0 and _distance < FAR_OFF or _frames % (OLD_EVERY * 4) == 0:
				which.append(YOUNG + _next_old)
				_next_old = (_next_old + 1) % (POINTS - YOUNG)
			_streak(_world.time, which)
		elif _frames % 4 == 1:
			_read_storms(_world.time)
		_upload()
		if whole or _frames % 4 == 3:
			_around()
	else:
		air = 0.0
		seen_m = INF
	_last_t = _world.time
	frame_ms = (Time.get_ticks_usec() - started) / 1000.0
	slowest_ms = maxf(slowest_ms, frame_ms)


## Its source's place on the ground, found afresh as the sheet changes: false
## if it has none, or it's out of sight.
func _follow() -> bool:
	var sites := _world.shape.sites
	if source.is_empty() or not sites.anchored():
		_deposit(false)
		return false
	var at := Vector2i(sites.follows, sites.laid)
	if source != _found_for or at != _found_at:
		_found_for = source
		_found_at = at
		_root()
	var camera := _world.player.camera.global_position
	var off := Vector2(_world.world_x(camera.x) - root.x, _world.world_z(camera.z) - root.z)
	_distance = off.length()
	_deposit(source.state == Geology.LIVE_VENT and _distance < FAN_SHOWN)
	if _frames % 15 == 0:
		_dev(off)
	return _distance < _tuning.plume_fade_m.y


## Where it rises: a vent's mouth where it's laid, else where the sheet would
## lay its source from where you are.
func _root() -> void:
	var sites := _world.shape.sites
	var guess := sites.anchor().place(source.p)
	slot = Vector2.from_angle(sites.anchor().ground_bearing(source.bearing) - PI * 0.5)
	root = Vector3(guess.x, _world.shape.dunes(guess.x, guess.y), guess.y)
	if source.state != Geology.LIVE_VENT:
		return
	for site in sites.query(Rect2(guess - Vector2.ONE * 150.0, Vector2.ONE * 300.0)):
		var mouth := site as VentMouth
		if mouth != null and mouth.stands():
			root = Vector3(mouth.x, mouth.pad(), mouth.z)
			var along := mouth.to_world(Vector2(0.0, 1.0)) - Vector2(mouth.x, mouth.z)
			slot = along.normalized()


## The streakline at world time t: the points of it given, or all of them.
## Each is what left `age` s ago, as hard as it was venting then, carried by
## the drift since and a front's outflow, risen as far as its buoyancy took it
## in that wind, and spread out once it's levelled. The air's stability
## changes slowly, so it's read only now and then.
func _streak(t: float, which := PackedInt32Array()) -> void:
	var geology := _world.shape.history.geology
	var field := _weather.field
	var g := _world.gravity / _tuning.gravity
	if which.is_empty() or absf(t - _air_read_at) > AIR_EVERY:
		_air_read_at = t
		var moon := _world.moon
		_stable = stability(_weather.day, t, moon.latitude, moon.longitude, g)
	venting = geology.venting(source, t)
	var now := air_now(field, Vector2(root.x, root.z), t)
	for k in (range(POINTS) if which.is_empty() else which):
		var age := OLDEST * pow(float(k) / (POINTS - 1), CROWD)
		var v := venting if k == 0 else geology.venting(source, t - age)
		var parcel := parcel_at(field, _tuning, Vector2(root.x, root.z), t, age, v.x, _stable, g, now)
		var deep := parcel[1].x
		var thick := THICK.z * v.x * pow(THICK.x * THICK.y / (deep * parcel[1].y), THINS) \
			* (DUSTY if source.state == Geology.POCKET else 1.0) \
			* (FALLS.y + (1.0 - FALLS.y) * exp(-age / FALLS.x)) * (1.0 - smoothstep(0.8, 1.0, age / OLDEST)) \
			* smoothstep(-GATHERS * 0.25, GATHERS, age)
		var ash := ASHEN.x * clampf((v.y - Geology.ASH.x) / (Geology.ASH.y - Geology.ASH.x), 0.0, 1.0) \
			* exp(-age / ASHEN.y)
		line[k] = parcel[0]
		matter[k] = Vector4(thick, deep, ash, v.x)
	_changed = true
	if which.is_empty():
		for i in READS.size() * 2:
			_read_storms(t)


## What left a source at world x and z `age` s before t, `hard` times the
## seep: [its place from the source, m, and its width; its depth, m, and the
## wind it rode, m/s]. Carried by the field's drift since and a front's
## outflow along it, risen as its buoyancy took it, spread out once levelled.
static func parcel_at(field: WeatherField, tuning: Tuning, at: Vector2, t: float, age: float, hard: float,
		n: float, g: float, now := Vector4(NAN, 0.0, 0.0, 0.0)) -> Array[Vector4]:
	if is_nan(now.x):
		now = air_now(field, at, t)
	var then := t - age
	var push := field.prevailing_at(t).normalized() * tuning.storm_outflow_speed
	var drift := field.drift_at(then)
	var gone := Vector2(now.x - drift.x, now.y - drift.y) + push * age * 0.5 * (now.z + field.outflow_of(field.raw_storm_at(at.x, at.y, then)))
	var speed := maxf(gone.length() / age if age > 0.0 else now.w, 0.5)
	var f := tuning.plume_buoyancy * hard * g
	if f <= 0.0 or age <= 0.0:
		var still := MOUTH + SPREAD * gone.length()
		return [Vector4(gone.x, 0.0, gone.y, still), Vector4(still, speed, 0.0, 0.0)]
	var third := pow(f, 1.0 / 3.0)
	var level := minf(2.6 * pow(f / (speed * n * n), 1.0 / 3.0), 5.0 * pow(f, 0.25) * pow(n, -0.75))
	var bent := 1.6 * third * pow(speed * age, 2.0 / 3.0) / speed
	var rise := bent / pow(1.0 + pow(bent / level, 3.0), 1.0 / 3.0)
	var levelled := pow(0.85 * level * pow(speed, 1.0 / 3.0) / (1.6 * third), 1.5)
	var deep := MOUTH + WIDEN * rise + SPREAD * gone.length()
	var width := deep + UMBRELLA * n * level * maxf(age - levelled, 0.0)
	return [Vector4(gone.x, rise, gone.y, width), Vector4(deep, speed, 0.0, 0.0)]


## The air at a source now, once for a whole line: the drift so far, world x
## and z, a front's outflow there, and the steady wind's speed.
static func air_now(field: WeatherField, at: Vector2, t: float) -> Vector4:
	var drift := field.drift_at(t)
	return Vector4(drift.x, drift.y, field.outflow_at(at.x, at.y, t), field.steady_wind_at(at.x, at.y, t).length())


## The air's stability where you stand at t, its buoyancy frequency, 1/s:
## steadier by night. It's gravity's too, so how high a plume levels doesn't
## change with gravity (g, as a share of the tuning's); only how hard it
## climbs at first does.
static func stability(day: DayCycle, t: float, latitude: float, longitude: float, g: float) -> float:
	var up := smoothstep(-0.05, 0.25, day.sun_direction(t, latitude, longitude).y)
	return lerpf(STABILITY.y, STABILITY.x, up) * sqrt(g)


## How high a buoyant plume has risen `age` s out, m: bent over by the wind
## as F^1/3 x^2/3 / u, and levelling where the air's stability stops it,
## lower in a stronger wind (Briggs). f is its buoyancy flux, m⁴/s³; u the
## wind, m/s; n the air's buoyancy frequency, 1/s.
static func rise_in(f: float, u: float, age: float, n: float) -> float:
	if age <= 0.0 or f <= 0.0:
		return 0.0
	var bent := 1.6 * pow(f, 1.0 / 3.0) * pow(u * age, 2.0 / 3.0) / u
	var level := level_of(f, u, n)
	return bent / pow(1.0 + pow(bent / level, 3.0), 1.0 / 3.0)


## Where it levels, m: in the wind, or in still air, whichever is lower.
static func level_of(f: float, u: float, n: float) -> float:
	return minf(2.6 * pow(f / (u * n * n), 1.0 / 3.0), 5.0 * pow(f, 0.25) * pow(n, -0.75)) if f > 0.0 else 0.0


## How old what left is once it's all but levelled, s: from there it spreads.
static func levelled_at(f: float, u: float, n: float) -> float:
	if f <= 0.0:
		return INF
	return pow(0.85 * level_of(f, u, n) * pow(u, 1.0 / 3.0) / (1.6 * pow(f, 1.0 / 3.0)), 1.5)


## One read in turn: whether storms stand between you and the line at an
## age, or how much sun they leave on it there; every point takes the reads
## either side of its age. The shader hides what's behind a storm the storm
## map holds itself; these are for what's past it.
func _read_storms(t: float) -> void:
	var i := (_read / 2) % READS.size()
	var at := _point(READS[i])
	var camera := _world.player.camera.global_position
	var eye := Vector3(_world.world_x(camera.x), camera.y, _world.world_z(camera.z))
	if _read % 2 == 0:
		_veil[i] = seen_through(_weather.field, _tuning, eye, at, t) * (1.0 - _weather.seen_storm)
	elif _weather.day.sunlight(t, _world.moon.latitude, _world.moon.longitude) <= 0.0:
		_sun[i] = 1.0
	else:
		var moon := _world.moon
		var sun := _weather.day.sun_direction(t, moon.latitude, moon.longitude)
		# The storm map reaches only so far round you; past it, sunlit.
		var mapped := Vector2(at.x - eye.x, at.z - eye.z).length() < _tuning.storm_map_reach * 0.9
		_sun[i] = _weather.face.sun_at(Vector3(_world.engine_x(at.x), at.y, _world.engine_z(at.z)), sun) \
			if mapped else 1.0
	_read += 1
	for k in POINTS:
		var age := OLDEST * pow(float(k) / (POINTS - 1), CROWD)
		var j := 0
		while j < READS.size() - 2 and age > READS[j + 1]:
			j += 1
		var w := clampf((age - READS[j]) / (READS[j + 1] - READS[j]), 0.0, 1.0)
		seen[k] = Vector4(lerpf(_veil[j], _veil[j + 1], w), lerpf(_sun[j], _sun[j + 1], w), 0.0, 0.0)
	_changed = true


## How much of what's at a world place, metres with its height, shows from an
## eye at another past the storms on the line between, 0 to 1, by the field
## itself: a storm's dust takes what's behind it as the air in one does, all
## of it past a few hundred metres, and only what's over its roof (its
## billows' tops too) shows. The march strides through clear air by how far
## the field says the nearest dust must be, so no storm is stepped over.
static func seen_through(field: WeatherField, tuning: Tuning, from: Vector3, to: Vector3, t: float) -> float:
	var top := tuning.wall_height + tuning.wall_roof_soft + StormFace.ROOF_OVER
	var low := tuning.wall_height - tuning.wall_roof_soft
	var rise := to.y - from.y
	var start := 0.0
	var end := 1.0
	if absf(rise) > 1.0e-3:
		var at_top := (top - from.y) / rise
		if rise > 0.0:
			end = minf(end, at_top)
		else:
			start = maxf(start, at_top)
	elif from.y >= top:
		return 1.0
	var length := from.distance_to(to)
	if end <= start or length < 1.0e-3:
		return 1.0
	var dust_m := 0.0
	var s := start
	for i in SEEN_STEPS.z:
		var at := from.lerp(to, s)
		var raw := field.raw_storm_at(at.x, at.z, t)
		var step := clampf(absf(raw) / STEEPEST, SEEN_STEPS.x, SEEN_STEPS.y)
		step = minf(step, (end - s) * length)
		dust_m += smoothstep(-2.0 * VEIL_EDGE, 0.0, raw) * (1.0 - smoothstep(low, top, at.y)) * step
		if dust_m >= Weather.STORM_FOG.y:
			return 0.0
		s += step / length
		if s >= end - 1.0e-6:
			break
	return 1.0 - smoothstep(Weather.STORM_FOG.x, Weather.STORM_FOG.y, dust_m)


## The streakline's place at an age, world metres.
func _point(age: float) -> Vector3:
	var x := pow(clampf(age / OLDEST, 0.0, 1.0), 1.0 / CROWD) * (POINTS - 1)
	var k := mini(floori(x), POINTS - 2)
	var p := line[k].lerp(line[k + 1], x - k)
	return root + Vector3(p.x, p.y, p.z)


## The streakline's highest point now, world metres: what shows furthest.
func top() -> Vector3:
	var high := root
	for k in POINTS:
		var p := root + Vector3(line[k].x, line[k].y, line[k].z)
		if p.y > high.y and matter[k].x > 0.05:
			high = p
	return high


## How far into its dust the camera stands, as the shader would find it: its
## depth inside the column's smooth surface, nearest stretch first.
func _around() -> void:
	var camera := _world.player.camera.global_position
	var p := Vector3(_world.world_x(camera.x), camera.y, _world.world_z(camera.z)) - root
	if p != p.clamp(_lo, _hi):
		air = 0.0
		seen_m = INF
		return
	var best := INF
	var at := 0
	var along := 0.0
	for j in COLUMN.size() - 1:
		if _ashen[j].y < 0.5:
			continue
		var a := _shape[j]
		var b := _shape[j + 1]
		var ab := Vector3(b.x - a.x, b.y - a.y, b.z - a.z)
		var h := clampf((p - Vector3(a.x, a.y, a.z)).dot(ab) / maxf(ab.length_squared(), 1.0e-3), 0.0, 1.0)
		var q := p - Vector3(a.x, a.y, a.z) - ab * h
		q.y /= maxf(lerpf(_dust[j].y, _dust[j + 1].y, h), 0.2)
		var d := q.length() - lerpf(a.w, b.w, h)
		if d < best:
			best = d
			at = j
			along = h
	var width := lerpf(_shape[at].w, _shape[at + 1].w, along)
	var dust := lerpf(_dust[at].x, _dust[at + 1].x, along)
	air = smoothstep(-AIR_EDGE.x * width, AIR_EDGE.y * width, -best) * (1.0 - exp(-dust * AIR_THICK))
	seen_m = clampf(3.0 / maxf(dust, 1.0e-6), SEEN_IN.x, SEEN_IN.y)


func _upload() -> void:
	var at := Vector3(_world.engine_x(root.x), root.y, _world.engine_z(root.z))
	material.set_shader_parameter("root", at)
	var map := _weather.map
	var values := _weather.face.uniforms
	if values.is_empty():
		return
	var fresh := map.texture_a != _map_a or map.texture_b != _map_b
	if fresh:
		_map_a = map.texture_a
		_map_b = map.texture_b
		material.set_shader_parameter("storm_map_a", _map_a)
		material.set_shader_parameter("storm_map_b", _map_b)
		material.set_shader_parameter("storm_map_extent", values.storm_map_extent)
		material.set_shader_parameter("storm_map_cells", values.storm_map_cells)
	# They move a fifth of a metre a frame: every other frame will do.
	if fresh or _frames % 2 == 0:
		for key: String in ["storm_map_blend", "storm_map_shift", "storm_air", "storm_map_ready"]:
			material.set_shader_parameter(key, values[key])
		material.set_shader_parameter("storm_time", _world.time)
	if not _changed:
		return
	_changed = false
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for j in COLUMN.size():
		var k: int = COLUMN[j]
		var p := line[k]
		var deep := matter[k].y
		_shape[j] = p
		var squash := clampf(deep / p.w, 0.2, 1.0)
		_dust[j] = Vector4(matter[k].x / (2.0 * deep), squash, seen[k].x, seen[k].y)
		var next: int = COLUMN[mini(j + 1, COLUMN.size() - 1)]
		var apart := maxf(matter[k].w, matter[next].w) / maxf(minf(matter[k].w, matter[next].w), 1.0e-3)
		_ashen[j] = Vector2(matter[k].z, 1.0 if apart < JOINS else 0.0)
		var out := Vector3(p.w, p.w * squash, p.w) * (1.0 + BILLOWS)
		lo = lo.min(Vector3(p.x, p.y, p.z) - out)
		hi = hi.max(Vector3(p.x, p.y, p.z) + out)
	_lo = lo
	_hi = hi
	material.set_shader_parameter("shape", _shape)
	material.set_shader_parameter("dust", _dust)
	material.set_shader_parameter("ashen", _ashen)
	material.set_shader_parameter("box_lo", _lo)
	material.set_shader_parameter("box_hi", _hi)


## The ash the vent has laid on the sand round its mouth and down the wind,
## the long record of its old eruptions: one vent's at a time, the plume's
## that's near enough to lay it.
func _deposit(shown: bool) -> void:
	if not shown and _depositor != self:
		return
	var sand := _world.terrain.sand_material as ShaderMaterial
	if sand == null:
		return
	if shown and (_depositor == null or _depositor == self or not is_instance_valid(_depositor)
			or _depositor._distance > _distance):
		_depositor = self
		var ash := Vector3(root.x, root.z, FAN)
		if ash != _laid_ash:
			_laid_ash = ash
			sand.set_shader_parameter("vent_ash", ash)
			sand.set_shader_parameter("vent_slot", slot)
	elif not shown:
		_depositor = null
		_laid_ash = Vector3.INF
		sand.set_shader_parameter("vent_ash", Vector3.ZERO)


func _dev(off: Vector2) -> void:
	var state := "blowing" if source.state == Geology.POCKET else ("bursting" if venting.x > 1.6 else "seeping")
	Dev.put("weather/" + ("pocket" if source.state == Geology.POCKET else "vent"), "%.1fkm %s %s" % [
		off.length() / 1000.0, Radio.compass(rad_to_deg(atan2(-off.x, off.y))), state])


static func _linear(c: Color) -> Vector3:
	var l := c.srgb_to_linear()
	return Vector3(l.r, l.g, l.b)
