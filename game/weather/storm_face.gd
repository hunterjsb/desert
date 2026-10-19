class_name StormFace
extends MeshInstance3D
## Draws every storm wall in view, and everything inside one, as a single
## full-screen pass (storm_face.gdshader) over the storm map. Keeps a CPU twin
## of where the dust is (storm_field.gdshaderinc), so the senses can follow the
## same billow that swallows the camera on screen.

## Twins of the shader's constants.
const BODY_WEIGHT := 25.0
const SKIN := 30.0
const SWELL := 180.0
const TILT_A := Basis(Vector3(0.8253, 0.0, -0.5646), Vector3(0.2134, 0.9259, 0.3119),
	Vector3(0.5228, -0.3779, 0.7642))
const TILT_B := Basis(Vector3(0.6967, 0.3307, 0.6366), Vector3(-0.4258, 0.9047, 0.0144),
	Vector3(-0.5711, -0.2689, 0.7756))
## The billow noise: 64 texels a side, tiling.
const NOISE := 64
## Twin of the shader's: the ring's light counts each metre of depth as this many.
const RING_DEPTH := 8.0
## Twin of the shader's roof_max: past this over the wall's height, softened
## roof and all, no ray meets dust, m.
const ROOF_OVER := 400.0

var material := ShaderMaterial.new()
## The storm map's uniforms as last handed the shader, which the plumes share.
var uniforms := {}

var _world: World
var _field: WeatherField
var _map: StormMap
var _tuning: Tuning
## The noise texture's bytes, for sampling it on the CPU exactly as the GPU does.
var _noise_bytes := PackedByteArray()


func setup(world: World, field: WeatherField, map: StormMap) -> void:
	_world = world
	_field = field
	_map = map
	_tuning = world.tuning
	material.shader = preload("res://game/weather/storm_face.gdshader")
	# First among the transparent passes: it reads the opaque scene back and
	# overwrites it, so anything see-through must draw after.
	material.render_priority = -100
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	mesh = quad
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Pinned to the screen in the shader; never culled.
	custom_aabb = AABB(Vector3.ONE * -1.0e5, Vector3.ONE * 2.0e5)
	material.set_shader_parameter("storm_noise", _make_noise(world.run_seed))
	material.set_shader_parameter("storm_height", _tuning.wall_height)
	material.set_shader_parameter("storm_roof_soft", _tuning.wall_roof_soft)
	material.set_shader_parameter("storm_sigma", sigma())
	material.set_shader_parameter("far_fade", Vector2(_tuning.wall_fade_begin, _tuning.wall_fade_end))
	material.set_shader_parameter("storm_glow", _tuning.wall_glow)
	material.set_shader_parameter("sun_share", _tuning.wall_sun_share)
	material.set_shader_parameter("dust_albedo", _linear(_tuning.wall_dust_color))


## Extinction per metre inside a storm: visibility is about 3 / sigma.
func sigma() -> float:
	return 3.0 / _tuning.storm_visibility


## Pushes the map, the clock and the shelters to the shader. Every frame,
## after the world moved. holes are each shelter's centre and live radius,
## glows how brightly its shell shows.
func sync(t: float, holes: PackedVector4Array, glows: PackedFloat32Array) -> void:
	var values := _map.uniforms(t)
	uniforms = values
	for key: String in values:
		material.set_shader_parameter(key, values[key])
	material.set_shader_parameter("storm_time", t)
	var wind := _field.prevailing_at(t)
	material.set_shader_parameter("storm_wind_dir", wind.normalized())
	material.set_shader_parameter("storm_gust_shift", gust_shift(t))
	material.set_shader_parameter("shelter_count", holes.size())
	material.set_shader_parameter("shelters", Shelter.padded(holes))
	var glow := glows.duplicate()
	glow.resize(Shelter.MAX)
	material.set_shader_parameter("shell_glow", glow)


## How far the gusts inside a storm have run through the air: the outflow on
## top of the drift, integrated in closed form like the drift itself.
func gust_shift(t: float) -> Vector2:
	return _field.drift_at(t) * (_tuning.storm_outflow_speed / maxf(_tuning.prevailing_speed, 0.1))


func set_light(param: StringName, value: Variant) -> void:
	material.set_shader_parameter(param, value)


## Twin of storm_front + storm_bulge at full detail: metres an engine-space
## point sits behind its billowed face (negative = ahead of it).
func edge_at(p: Vector3) -> float:
	var t := _world.time
	var front := _map.front_at(_world.world_x(p.x), _world.world_z(p.z), t)
	return front.x + _bulge(p, t)


## How far into the dust a point is, 0 to 1, as the shader draws it: none
## inside a shelter that stops the storm, whose sphere the dust never enters.
func seen_at(p: Vector3) -> float:
	return 0.0 if _world.weather.shelter_at(p, &"storm") >= 1.0 else open_at(p)


## The same with every shelter down: the storm's own dust there.
func open_at(p: Vector3) -> float:
	return smoothstep(0.0, SKIN, edge_at(p)) if _map.ready else 0.0


## Twin of sun_through(storm_sun_path()) as the march calls it: sunlight left
## at a point after the storms between it and the sun, 0 to 1, counting depth
## from the billowed surface.
func sun_at(p: Vector3, sun: Vector3) -> float:
	var path := _sun_path(p, sun)
	return minf(1.0, exp(-0.004 * path) + 0.3 * exp(-0.0008 * path))


## Twin of ring_through(ring_path()): the eclipse ring's red light left at a
## point, which carries far deeper into the dust than the sun's, in from the
## billowed face and down through the roof.
func ring_at(p: Vector3, sun: Vector3) -> float:
	if not _map.ready:
		return 1.0
	var depth := edge_at(p)
	return exp(-0.00015 * minf(_roof_path(p.y) / maxf(sun.y, 0.02), maxf(depth, 0.0) * RING_DEPTH))


## Twin of storm_sun_path: metres of roof-thin dust between a point and the sun.
func _sun_path(p: Vector3, sun: Vector3) -> float:
	if not _map.ready:
		return 0.0
	var f := _map.front_at(_world.world_x(p.x), _world.world_z(p.z), _world.time)
	var depth := f.x + _bulge(p, _world.time)
	var clear_side := -(sun.x * f.y + sun.z * f.z)
	var up := maxf(sun.y, 0.02)
	if depth <= 0.0:
		return 0.0 if clear_side >= -0.001 else _roof_path(p.y + depth / clear_side * up) / up
	var out_top := _roof_path(p.y) / up
	return minf(out_top, depth / clear_side * BODY_WEIGHT) if clear_side > 0.001 else out_top


## Signed metres from an engine-space point to the nearest front, without
## billows, and the unit normal into the storm.
func front_at(p: Vector3) -> Vector3:
	return _map.front_at(_world.world_x(p.x), _world.world_z(p.z), _world.time)


func _roof_path(h: float) -> float:
	var lo := _tuning.wall_height - _tuning.wall_roof_soft
	var hi := _tuning.wall_height + _tuning.wall_roof_soft
	if h >= hi:
		return 0.0
	if h <= lo:
		return lo - h + _tuning.wall_roof_soft
	return (hi - h) * (hi - h) / (4.0 * _tuning.wall_roof_soft)


## Twin of storm_bulge with both small octaves in, as at the camera.
func _bulge(p: Vector3, t: float) -> float:
	var drift := _field.drift_at(t)
	var q := Vector3(_world.world_x(p.x) - drift.x, p.y, _world.world_z(p.z) - drift.y)
	var w := _sample(TILT_B * Vector3(q.x + t * 3.0, q.y - t * 1.5, q.z) / 3700.0)
	var qw := q + Vector3(w.r - 0.5, w.g - 0.5, w.a - 0.5) * Vector3(260.0, 140.0, 160.0)
	var b1 := _billow(_sample(TILT_A * Vector3(qw.x, qw.y - t * 2.2, qw.z) / 2300.0).g)
	var b2 := _billow(_sample(TILT_B * Vector3(qw.x + t * 0.8, qw.y - t * 4.0, qw.z - t * 1.0) / 760.0).g)
	var b3 := _billow(_sample(TILT_A * Vector3(qw.x - t * 1.4, qw.y - t * 6.0, qw.z - t * 2.0) / 240.0).b)
	var b4 := _billow(_sample(TILT_B * Vector3(qw.x + t * 2.5, qw.y - t * 7.5, qw.z - t * 3.0) / 75.0).b)
	return 300.0 * b1 + 70.0 * b2 + 22.0 * b3 + 12.0 * b4 + _head(q, p.y)


## Twin of storm_head.
func _head(q: Vector3, h: float) -> float:
	var s := _sample(Vector3(q.x, 0.0, q.z) / 9000.0)
	var swell := clampf((s.r - 0.5) * 3.0, -1.0, 1.0)
	var lean := 0.12 + clampf((s.a - 0.5) * 3.0, -1.0, 1.0) * 0.12
	var nose := 90.0 * clampf((s.g - 0.5) * 3.0 + 0.5, 0.0, 1.0)
	return SWELL * swell * sin(3.14159 * clampf(h / _tuning.wall_height, 0.0, 1.0)) \
		- lean * maxf(h - 120.0, 0.0) - nose * exp(-maxf(h, 0.0) / 90.0)


static func _billow(n: float) -> float:
	var x := 2.0 * n - 1.0
	return sqrt(x * x + 0.02) - 0.35


## Trilinear, repeating, texel centres at (i + 0.5) / N: what the GPU does.
func _sample(p: Vector3) -> Color:
	var f := p * NOISE - Vector3(0.5, 0.5, 0.5)
	var b := f.floor()
	var fr := f - b
	var out := Color(0, 0, 0, 0)
	for corner in 8:
		var o := Vector3i(corner & 1, (corner >> 1) & 1, (corner >> 2) & 1)
		var x := posmod(int(b.x) + o.x, NOISE)
		var y := posmod(int(b.y) + o.y, NOISE)
		var z := posmod(int(b.z) + o.z, NOISE)
		var weight := (fr.x if o.x else 1.0 - fr.x) * (fr.y if o.y else 1.0 - fr.y) \
			* (fr.z if o.z else 1.0 - fr.z)
		var i := ((z * NOISE + y) * NOISE + x) * 4
		out += Color(_noise_bytes[i], _noise_bytes[i + 1], _noise_bytes[i + 2],
			_noise_bytes[i + 3]) * (weight / 255.0)
	return out


## Four tiling noises in one 3D texture: R warp, G big billows, B small billows,
## A gusts. All smooth: tiling blends a band at the edges, which leaves a crease
## in cellular noise but nothing visible in smooth noise.
func _make_noise(seed_value: int) -> ImageTexture3D:
	var layers: Array = []
	var kinds := [
		[FastNoiseLite.TYPE_PERLIN, 0.05, 3],
		[FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.06, 2],
		[FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.12, 2],
		[FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.08, 3],
	]
	for i in kinds.size():
		var noise := FastNoiseLite.new()
		noise.seed = seed_value + i
		noise.noise_type = kinds[i][0]
		noise.frequency = kinds[i][1]
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = kinds[i][2]
		layers.append(noise.get_seamless_image_3d(NOISE, NOISE, NOISE, false, 0.1, true))
	var slices: Array[Image] = []
	var bytes := PackedByteArray()
	bytes.resize(NOISE * NOISE * 4)
	_noise_bytes.resize(NOISE * NOISE * NOISE * 4)
	for z in NOISE:
		var r: PackedByteArray = layers[0][z].get_data()
		var g: PackedByteArray = layers[1][z].get_data()
		var b: PackedByteArray = layers[2][z].get_data()
		var a: PackedByteArray = layers[3][z].get_data()
		for i in NOISE * NOISE:
			bytes[i * 4] = r[i]
			bytes[i * 4 + 1] = g[i]
			bytes[i * 4 + 2] = b[i]
			bytes[i * 4 + 3] = a[i]
		slices.append(Image.create_from_data(NOISE, NOISE, false, Image.FORMAT_RGBA8, bytes))
		for i in bytes.size():
			_noise_bytes[z * NOISE * NOISE * 4 + i] = bytes[i]
	var texture := ImageTexture3D.new()
	texture.create(Image.FORMAT_RGBA8, NOISE, NOISE, NOISE, false, slices)
	return texture


static func _linear(color: Color) -> Vector3:
	var c := color.srgb_to_linear()
	return Vector3(c.r, c.g, c.b)
