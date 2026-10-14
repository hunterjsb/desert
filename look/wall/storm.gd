class_name WallStorm
extends Node3D
## One storm front, rolling in. Owns the front's line and clock, the field's CPU
## twin (storm_field.gdshaderinc has the GPU side) and the shaders that draw it.
## Positions are world metres in 64-bit floats; the shaders get engine space.

## Twin of STORM_BODY_WEIGHT: a metre of body shades like this many of roof.
const BODY_WEIGHT := 25.0

## About 8 minutes from the horizon to you.
@export var speed := 10.0
## Real fronts slide along themselves a little as they come.
@export var drift := 1.5
@export var start_distance := 5000.0
## Compass heading the front travels toward, degrees from +Z.
@export var heading_degrees := 12.0
## Radius of the front's bow, metres. Big enough to fill any view.
@export var radius := 80000.0
@export var height := 1800.0
@export var roof_soft := 220.0
## Extinction per metre inside; visibility is about 3 / sigma.
@export var sigma := 0.15

var world: World
var dir := Vector2(0.0, 1.0)
var perp := Vector2(-1.0, 0.0)
## Seconds of storm time; freezes with pause, runs with the time scale.
var clock := 0.0

var _lobe_a := Vector4()
var _lobe_k := Vector4()
var _lobe_p := Vector4()
var _anchor_x := 0.0
var _anchor_z := 0.0
## Metres the front has been moved by jumps, along dir.
var _jumped := 0.0
var _materials: Array[ShaderMaterial] = []
## The noise texture's bytes, for sampling the field on the CPU exactly as the GPU does.
var _noise_bytes := PackedByteArray()

@onready var face: MeshInstance3D = $Face
## Sand snaking along the ground ahead of the face, as the outflow arrives.
@onready var streamers: GPUParticles3D = $Streamers
## Dust tearing past once you're in it.
@onready var dust: GPUParticles3D = $Dust


func setup(the_world: World, seed_value: int) -> void:
	world = the_world
	var a := deg_to_rad(heading_degrees)
	dir = Vector2(sin(a), cos(a))
	perp = Vector2(-dir.y, dir.x)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# Lobes kilometres wide, so no stretch of the front is a straight ruled line.
	var amplitudes := [240.0, 110.0, 45.0, 18.0]
	var wavelengths := [7000.0, 2700.0, 1100.0, 430.0]
	for i in 4:
		_lobe_a[i] = amplitudes[i]
		_lobe_k[i] = TAU / (wavelengths[i] * rng.randf_range(0.8, 1.25))
		_lobe_p[i] = rng.randf() * TAU
	var noise := _make_noise(seed_value)
	_materials.append(face.material_override as ShaderMaterial)
	for material in _materials:
		material.set_shader_parameter("storm_noise", noise)
	face.custom_aabb = AABB(Vector3.ONE * -1.0e5, Vector3.ONE * 2.0e5)
	restart()


func restart() -> void:
	clock = 0.0
	_jumped = 0.0
	# The front's centre starts straight up-heading of the player.
	var px := world.player_world_x()
	var pz := world.player_world_z()
	_anchor_x = px - dir.x * start_distance
	_anchor_z = pz - dir.y * start_distance
	jump_to(start_distance)


func advance(delta: float) -> void:
	clock += delta


## Moves the front so its face is this far from the player (negative: inside).
func jump_to(distance: float) -> void:
	_jumped += face_distance() - distance


## World position of the front's reference point now.
func anchor() -> Vector2:
	var along := speed * clock + _jumped
	return Vector2(_anchor_x + dir.x * along + perp.x * drift * clock,
		_anchor_z + dir.y * along + perp.y * drift * clock)


func front(u: float) -> float:
	var s := -u * u / (2.0 * radius)
	for i in 4:
		s += _lobe_a[i] * sin(_lobe_k[i] * u + _lobe_p[i])
	return s


## Storm-frame coordinates (u, h, s) of a world point.
func frame(world_x: float, height_m: float, world_z: float) -> Vector3:
	var a := anchor()
	var dx := world_x - a.x
	var dz := world_z - a.y
	return Vector3(dx * perp.x + dz * perp.y, height_m, dx * dir.x + dz * dir.y)


## Metres from the player to the face along the heading; negative once inside.
func face_distance() -> float:
	var q := frame(world.player_world_x(), 0.0, world.player_world_z())
	return q.z - front(q.x)


## Twin of storm_sun_path in the shader, without the billows.
func sun_path(q: Vector3, sun: Vector3) -> float:
	var sq := Vector3(sun.x * perp.x + sun.z * perp.y, sun.y, sun.x * dir.x + sun.z * dir.y)
	var depth := front(q.x) - q.z
	var up := maxf(sq.y, 0.02)
	if depth <= 0.0:
		if sq.z >= -0.001:
			return 0.0
		return _roof_path(q.y + depth / sq.z * up) / up
	var out_top := _roof_path(q.y) / up
	return minf(out_top, depth / sq.z * BODY_WEIGHT) if sq.z > 0.001 else out_top


## Twin of sun_through in face.gdshader.
func sun_through(path: float) -> float:
	return minf(1.0, exp(-0.004 * path) + 0.3 * exp(-0.0008 * path))


func _roof_path(h: float) -> float:
	var lo := height - roof_soft
	var hi := height + roof_soft
	if h >= hi:
		return 0.0
	if h <= lo:
		return lo - h + roof_soft
	return (hi - h) * (hi - h) / (4.0 * roof_soft)


## Twin of storm_edge at full detail (the camera's own spot): metres the point
## sits behind the billowed face.
func edge_at(q: Vector3) -> float:
	var t := clock
	var w := _sample(Vector3(q.x + t * 3.0, q.y - t * 1.5, q.z) / 3100.0)
	var qw := q + Vector3(w.r - 0.5, w.g - 0.5, w.a - 0.5) * Vector3(320.0, 260.0, 200.0)
	var g1 := _sample(Vector3(qw.x, qw.y - t * 2.2, qw.z) / 2300.0).g
	var g2 := _sample(Vector3(qw.x + t * 0.8, qw.y - t * 4.0, qw.z - t * 1.0) / 760.0).g
	var g3 := _sample(Vector3(qw.x - t * 1.4, qw.y - t * 6.0, qw.z - t * 2.0) / 240.0).b
	var g4 := _sample(Vector3(qw.x + t * 2.5, qw.y - t * 7.5, qw.z - t * 3.0) / 75.0).g
	var bulge := 250.0 * (g1 - 0.5) + 95.0 * (g2 - 0.5) + 34.0 * (g3 - 0.5) + 12.0 * (g4 - 0.5)
	return front(q.x) - q.z + bulge - 0.07 * maxf(q.y - 120.0, 0.0)


## Storm-frame point of the camera.
func camera_frame(camera: Camera3D) -> Vector3:
	var p := camera.global_position
	return frame(world.world_x(p.x), p.y, world.world_z(p.z))


## Wind at the player: a light breeze until the outflow ahead of the face takes
## over, turning to blow from the storm and rising.
func wind() -> Vector2:
	var outflow := exp(-maxf(face_distance(), 0.0) / 350.0)
	var breeze := dir.rotated(deg_to_rad(80.0))
	var turned := breeze.slerp(dir, smoothstep(0.05, 0.6, outflow))
	return turned * (3.0 + 20.0 * outflow)


## Trilinear, repeating, texel centres at (i + 0.5) / N: what the GPU does.
func _sample(p: Vector3) -> Color:
	const N := 64
	var f := p * N - Vector3(0.5, 0.5, 0.5)
	var b := f.floor()
	var fr := f - b
	var out := Color(0, 0, 0, 0)
	for corner in 8:
		var o := Vector3i(corner & 1, (corner >> 1) & 1, (corner >> 2) & 1)
		var x := posmod(int(b.x) + o.x, N)
		var y := posmod(int(b.y) + o.y, N)
		var z := posmod(int(b.z) + o.z, N)
		var wgt := (fr.x if o.x else 1.0 - fr.x) * (fr.y if o.y else 1.0 - fr.y) \
			* (fr.z if o.z else 1.0 - fr.z)
		var i := ((z * N + y) * N + x) * 4
		out += Color(_noise_bytes[i], _noise_bytes[i + 1], _noise_bytes[i + 2],
			_noise_bytes[i + 3]) * (wgt / 255.0)
	return out


## Keeps the near-camera dust round the camera, blowing with the wind. Emitters
## sit upwind by half a lifetime of travel, so the camera is mid-stream.
func follow(camera: Camera3D, wind_now: Vector2, inside: float, running: bool) -> void:
	var p := camera.global_position
	var blow := wind_now.length()
	var heading := Vector3(wind_now.x, 0.0, wind_now.y) / maxf(blow, 0.01)
	var outflow := exp(-maxf(face_distance(), 0.0) / 350.0)
	for system: GPUParticles3D in [streamers, dust]:
		var process := system.process_material as ParticleProcessMaterial
		process.direction = heading
		process.initial_velocity_min = blow * 0.8
		process.initial_velocity_max = blow * 1.15
		system.speed_scale = 1.0 if running else 0.0
		var material := (system.draw_pass_1 as QuadMesh).material as ShaderMaterial
		# About a twelfth of a second of motion blur.
		material.set_shader_parameter("streak_length", clampf(blow * 0.09, 0.4, 2.6))
	var ground := world.height_under(p)
	streamers.global_position = Vector3(p.x, ground + 0.35, p.z) - heading * blow * streamers.lifetime * 0.5
	dust.global_position = p - heading * blow * dust.lifetime * 0.5
	_set_ratio(streamers, smoothstep(0.1, 0.5, outflow) * (1.0 - 0.6 * inside))
	_set_ratio(dust, maxf(inside, 0.2 * smoothstep(0.55, 0.95, outflow)))


func set_dust(light: Vector3, camera_sigma: float) -> void:
	for system: GPUParticles3D in [streamers, dust]:
		var material := (system.draw_pass_1 as QuadMesh).material as ShaderMaterial
		material.set_shader_parameter("dust_light", light)
		material.set_shader_parameter("camera_sigma", camera_sigma)


func _set_ratio(system: GPUParticles3D, ratio: float) -> void:
	if absf(system.amount_ratio - ratio) > 0.01 or (ratio == 0.0) != (system.amount_ratio == 0.0):
		system.amount_ratio = ratio


## Pushes the field to every storm shader. Call once a frame, after the player moved.
func sync() -> void:
	var a := anchor()
	var engine_anchor := Vector3(world.engine_x(a.x), 0.0, world.engine_z(a.y))
	for material in _materials:
		material.set_shader_parameter("storm_anchor", engine_anchor)
		material.set_shader_parameter("storm_dir", dir)
		material.set_shader_parameter("storm_bend", 1.0 / (2.0 * radius))
		material.set_shader_parameter("storm_lobe_a", _lobe_a)
		material.set_shader_parameter("storm_lobe_k", _lobe_k)
		material.set_shader_parameter("storm_lobe_p", _lobe_p)
		material.set_shader_parameter("storm_time", clock)
		material.set_shader_parameter("storm_height", height)
		material.set_shader_parameter("storm_roof_soft", roof_soft)
		material.set_shader_parameter("storm_sigma", sigma)


func set_light(param: StringName, value: Variant) -> void:
	for material in _materials:
		material.set_shader_parameter(param, value)


## Four tiling noises in one 3D texture: R smooth (warp), G big puffs, B small
## puffs, A gusts. Puffs are inverted cellular, so billows come out round.
func _make_noise(seed_value: int) -> ImageTexture3D:
	const N := 64
	var layers: Array = []
	var kinds := [
		[FastNoiseLite.TYPE_PERLIN, 0.05, 3],
		[FastNoiseLite.TYPE_CELLULAR, 0.07, 2],
		[FastNoiseLite.TYPE_CELLULAR, 0.14, 2],
		[FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.08, 3],
	]
	for i in kinds.size():
		var noise := FastNoiseLite.new()
		noise.seed = seed_value + i
		noise.noise_type = kinds[i][0]
		noise.frequency = kinds[i][1]
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = kinds[i][2]
		noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
		var invert: bool = kinds[i][0] == FastNoiseLite.TYPE_CELLULAR
		layers.append(noise.get_seamless_image_3d(N, N, N, invert, 0.1, true))
	var slices: Array[Image] = []
	var bytes := PackedByteArray()
	bytes.resize(N * N * 4)
	_noise_bytes.resize(N * N * N * 4)
	for z in N:
		var r: PackedByteArray = layers[0][z].get_data()
		var g: PackedByteArray = layers[1][z].get_data()
		var b: PackedByteArray = layers[2][z].get_data()
		var a: PackedByteArray = layers[3][z].get_data()
		for i in N * N:
			bytes[i * 4] = r[i]
			bytes[i * 4 + 1] = g[i]
			bytes[i * 4 + 2] = b[i]
			bytes[i * 4 + 3] = a[i]
		slices.append(Image.create_from_data(N, N, false, Image.FORMAT_RGBA8, bytes))
		for i in bytes.size():
			_noise_bytes[z * N * N * 4 + i] = bytes[i]
	var texture := ImageTexture3D.new()
	texture.create(Image.FORMAT_RGBA8, N, N, N, false, slices)
	return texture
