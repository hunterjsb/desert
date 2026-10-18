class_name Plume
extends MultiMeshInstance3D
## A plume as it looks from where you stand: a live vent's, or a gas pocket's
## blowing out. Gas shows only by what rides it: a vent's ash, dark and soon
## fallen out, steam where the air is cold enough to hold it, and the pale
## sulphate haze its gas makes over minutes; a pocket's dust, the sand it
## blew out. It rises as a buoyant plume does in wind (Briggs's rise: bent
## over by the wind, levelling where the air's stability stops it, and there
## spreading out as an umbrella) and rides the field's own drift away, so its
## tail curls as the wind turns. Here, each frame, its streakline (where what
## left at each age is now, how wide and what it carries) is worked out from
## the time, the source and the weather alone; the shader hangs one draw of
## soft puffs on it, each a parcel that left at a moment. Nothing in the world
## reads it. Past the camera's reach it's the same puffs drawn nearer and
## smaller; storms between hide what's under their roofs, and what towers
## over them shows.

const SHADER := preload("res://game/weather/plume.gdshader")
## How many plumes can be drawn at once, the nearest sources first.
const AT_ONCE := 3
## The streakline: this many points, the oldest this many s, crowded toward
## the source by this power.
const POINTS := 24
const OLDEST := 600.0
const CROWD := 1.6
## The puffs hung on it, by kind in the shader's order: [how many, youngest
## s, oldest s]: ash falling out under it, the steam and gas at the mouth, the
## column, the bent-over body, the thinning tail. Ages count from the source,
## the falling ash's from when it left the column.
const FAMILIES := [[36, 0.0, 150.0], [28, 0.0, 14.0], [64, 0.0, 80.0], [72, 60.0, 300.0], [48, 260.0, 600.0]]
## Parcels are numbered round this many, so a family's ids never run out.
const PARCELS := 1048576.0
## What leaves rises from this wide, m.
const MOUTH := 6.0
## The air's stability, its buoyancy frequency by day and by night, 1/s.
const STABILITY := Vector2(0.009, 0.016)
## A rising plume widens by this share of its rise, and downwind spreads by
## this share of how far it's gone. Levelled, it spreads out sideways as a
## current in the stable air does, at this share of its stability times its
## height, m/s: what makes a burst's umbrella.
const WIDEN := 0.4
const SPREAD := 0.04
const UMBRELLA := 0.25
## How thick it is through its depth: at this depth, m, and wind, m/s,
## seeping, this optical depth; thinner as it deepens or the wind stretches
## it, by this power of the two.
const THICK := Vector3(30.0, 10.0, 8.0)
const THINS := 0.7
## Ash falls out of it over this many s, a pocket's dust over the second; the
## gas makes its haze over this many; steam lasts from the first in the heat
## to the second in the cold, s, and shows below the first air temperature,
## fully below the second, °C. How thick each looks for what it is: ash or
## dust, steam, haze.
const ASH_FALLS := Vector2(90.0, 50.0)
const HAZE_FORMS := 120.0
const STEAM_LASTS := Vector2(15.0, 240.0)
const STEAM_AIR := Vector2(30.0, -5.0)
const SHOWS := Vector3(1.0, 1.5, 0.6)
## A pocket's dust is this many times as thick as a seep's ash for its lift.
const DUSTY := 4.0
## What a vent's ash looks like, and a pocket's dust, linear.
const ASH_TONE := Vector3(0.075, 0.068, 0.062)
const DUST_TONE := Vector3(0.36, 0.25, 0.15)
## The line changes slowly, its young end fastest in a burst: of its first
## this many points one is worked out again every other frame, and of the rest
## one every this many frames, a quarter as often once you're this far off, m;
## the air's stability and warmth this often, s.
const YOUNG := 6
const OLD_EVERY := 8
const FAR_OFF := 3000.0
const AIR_EVERY := 10.0
## Its source moving further than this is a jump, m, not the sheet's seams.
const JUMP := 5.0
## Storms between you and it, and their shadow on it, are read at these ages,
## s, one read every fourth frame; the storm field this near its threshold
## counts as part way in.
const READS := [0.0, 40.0, 150.0, 400.0]
const VEIL_EDGE := 0.006
## Past this the puffs are drawn nearer and smaller, m: the camera's far plane.
## Past the skyline's reach it's a landmark, as the skyline's are: the haze
## takes it more slowly than the air between would (Skyline.LANDMARK_FALL).
const NEAR_REACH := 4200.0
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
## width; what it carries, as optical depths through it of ash or dust, steam
## and haze, and its depth, m; the storms' veil between you and it, and the
## sun left on it.
var line := PackedVector4Array()
var matter := PackedVector4Array()
var seen := PackedVector4Array()
## How hard its source is venting now, as a share of the rift's seep, and its
## ash share.
var venting := Vector2.ZERO
## Main-thread time it took this frame, and the most any has, ms.
var frame_ms := 0.0
var slowest_ms := 0.0

## The plume laying its vent's ash on the sand, if any.
static var _depositor: Plume

var _world: World
var _weather: Weather
var _tuning: Tuning
var _total := 0
var _veil := PackedFloat32Array()
var _sun := PackedFloat32Array()
var _read := 0
var _next_young := 0
var _next_old := 0
var _stable := 0.012
var _cold := 0.0
var _air_read_at := -INF
var _frames := 0
var _distance := 0.0
var _last_t := -INF
## The line or the reads have changed since they were last handed the shader.
var _changed := true
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
	material.set_shader_parameter("noise", Paint.noise())
	var families := PackedVector4Array()
	for each: Array in FAMILIES:
		families.append(Vector4(_total, each[0], each[1], each[2]))
		_total += each[0]
	material.set_shader_parameter("families", families)
	material.set_shader_parameter("total", _total)
	material.set_shader_parameter("oldest", OLDEST)
	material.set_shader_parameter("crowd", CROWD)
	material.set_shader_parameter("reach", Vector3(NEAR_REACH, _tuning.plume_fade_m.x, _tuning.plume_fade_m.y))
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
## in that wind, and spread out once it's levelled. The air's stability and
## its warmth for steam change slowly, so they're read only now and then.
func _streak(t: float, which := PackedInt32Array()) -> void:
	var geology := _world.shape.history.geology
	var field := _weather.field
	var g := _world.gravity / _tuning.gravity
	var dusty: bool = source.state == Geology.POCKET
	if which.is_empty() or absf(t - _air_read_at) > AIR_EVERY:
		_air_read_at = t
		var moon := _world.moon
		_stable = stability(_weather.day, t, moon.latitude, moon.longitude, g)
		# A pocket's gas comes up cold and dry: dust, no steam, little haze.
		_cold = 0.0 if dusty else smoothstep(STEAM_AIR.x, STEAM_AIR.y,
			_weather.temperature_under(field.storm_at(root.x, root.z, t), t))
	var lasts := lerpf(STEAM_LASTS.x, STEAM_LASTS.y, _cold)
	var falls := ASH_FALLS.y if dusty else ASH_FALLS.x
	venting = geology.venting(source, t)
	var now := air_now(field, Vector2(root.x, root.z), t)
	for k in (range(POINTS) if which.is_empty() else which):
		var age := OLDEST * pow(float(k) / (POINTS - 1), CROWD)
		var v := venting if k == 0 else geology.venting(source, t - age)
		var parcel := parcel_at(field, _tuning, Vector2(root.x, root.z), t, age, v.x, _stable, g, now)
		var deep := parcel[1].x
		# Thinner as it deepens and the wind draws it out; less than mass alone
		# says, since what's left is the finest and shows the most.
		var thick := THICK.z * v.x * pow(THICK.x * THICK.y / (deep * parcel[1].y), THINS) * (DUSTY if dusty else 1.0)
		var ash := v.y * exp(-age / falls) * SHOWS.x
		var steam := _cold * exp(-age / lasts) * SHOWS.y
		var haze := (1.0 - exp(-age / HAZE_FORMS)) * (1.0 - 0.5 * v.y) * SHOWS.z * (0.2 if dusty else 1.0)
		line[k] = parcel[0]
		matter[k] = Vector4(thick * ash, thick * steam, thick * haze, deep)
	_changed = true
	if which.is_empty():
		for i in READS.size() * 2:
			_read_storms(t)
	var blowing := field.steady_wind_at(root.x, root.z, t)
	material.set_shader_parameter("wind", Vector3(blowing.x, 0.0, blowing.y))
	material.set_shader_parameter("now_mix", Vector4(venting.x if not dusty else 0.0, venting.y, _cold, 0.0))
	material.set_shader_parameter("ash_tone", DUST_TONE if dusty else ASH_TONE)


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
## either side of its age.
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
## itself: nothing through a storm's dust, all of it over a storm's roof.
static func seen_through(field: WeatherField, tuning: Tuning, from: Vector3, to: Vector3, t: float) -> float:
	var through := 1.0
	var flat := Vector2(to.x - from.x, to.z - from.z).length()
	var count := clampi(ceili(flat / 800.0), 2, 10)
	for k in range(1, count + 1):
		var at := from.lerp(to, float(k) / count)
		var dust := smoothstep(-VEIL_EDGE, VEIL_EDGE, field.raw_storm_at(at.x, at.z, t))
		var roofed := 1.0 - smoothstep(tuning.wall_height - tuning.wall_roof_soft,
			tuning.wall_height + tuning.wall_roof_soft, at.y)
		through *= 1.0 - dust * roofed
	return through


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
		if p.y > high.y and matter[k].x + matter[k].y + matter[k].z > 0.05:
			high = p
	return high


func _upload() -> void:
	var camera := _world.player.camera.global_position
	var at := Vector3(_world.engine_x(root.x), root.y, _world.engine_z(root.z))
	var young := at + Vector3(line[0].x, line[0].y, line[0].z)
	var old := at + Vector3(line[POINTS - 1].x, line[POINTS - 1].y, line[POINTS - 1].z)
	material.set_shader_parameter("root", at)
	if _changed:
		_changed = false
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


## The ash the vent has laid on the sand round its mouth and down the wind:
## one vent's at a time, the plume's that's near enough to lay it.
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
