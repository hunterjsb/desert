extends Node
## Look-test: the wind map (WindMap) over the deep dune sea on seed 1234, in
## light air, a breeze and a storm, seen straight down from high enough to
## hold the whole 256 m: the wind's arrows, the lee as the sand's vertex()
## reads it, and the sand the wind moves. Fog, the storm's dust and its
## darkness are off, so the map shows. It checks the map against the CPU:
## the wind against wind_at, the lee against Lee.exact (and the lattice's
## Lee.share beside it), the sand moved against its own formula, the heights
## against the dunes, a particle shader's process() and a spatial shader's
## vertex() and fragment() reading the map against the map read back, and
## times the passes on the GPU:
##   godot --path . --disable-vsync res://look/wind/wind.tscn -- --capture <dir>
## look/wind/shoot.sh runs it unseen and builds the sheet. Headless has no
## RenderingDevice, so this is the map's probe.

const SEED := 1234
## Light air, an ordinary breeze, the breeze some days on at the same hour
## with the wind turned furthest, and a storm: prevailing m/s, whether a storm
## covers everything, and whether to turn.
const WEATHERS := [["calm", 2.0, false, false], ["breeze", 10.0, false, false], ["turned", 10.0, false, true],
	["storm", 10.0, true, false]]
## Days on looked at for the turned wind.
const TURN_DAYS := 12
## Checked once more far out and late, where 32 bits are coarsest: m from the
## sea, and days on.
const FAR := Vector2(50000.0, -30000.0)
const FAR_DAYS := 40
const VIEWS := ["arrows", "lee", "sand"]
## The camera this far above the sand, looking straight down without
## perspective, the frame this high, m: the map's 256 m and a little round it.
const HEIGHT := 172.0
const FRAME := 276.0
## The local hour shot at.
const HOUR := 0.4
## Agreement wanted: the wind, m/s or this share of it; the lee, against
## Lee.exact; the sand moved; the heights, m; a shader's read of the map,
## against the map's texels blended on the CPU.
const WIND_OFF := 0.05
const WIND_SHARE := 0.005
const LEE_OFF := 0.03
const MOVES_OFF := 0.03
const HEIGHT_OFF := 0.02
## Far out the dunes' wander, a difference over 0.3 m of a noise read at 32
## bits, jitters by centimetres on the CPU as on the GPU.
const FAR_HEIGHT_OFF := 0.1
const READ_OFF := 0.02
## Every this many texels is checked against the CPU, and heights this sparse.
const STRIDE := 2
const HEIGHT_STRIDE := 8
const GPU_FRAMES := 120

const PROBE_PARTICLES := """
shader_type particles;
#include "res://game/weather/wind_map.gdshaderinc"
uniform vec2 probe_at;

void process() {
	vec4 w = wind_sample(probe_at);
	TRANSFORM = mat4(1.0);
	TRANSFORM[3].xyz = w.rgb;
	VELOCITY = vec3(0.0);
}
"""
const PROBE_SPATIAL := """
shader_type spatial;
render_mode unshaded, cull_disabled;
#include "res://game/weather/wind_map.gdshaderinc"
uniform vec2 probe_at;
uniform vec4 scale = vec4(1.0);
varying vec4 at_vertex;

void vertex() {
	at_vertex = wind_sample(probe_at);
}

void fragment() {
	vec4 at_fragment = wind_sample(probe_at);
	// The lee and the sand moved as vertex() read them, and the lee as fragment() did.
	ALBEDO = vec3(at_vertex.b, at_vertex.a, at_fragment.b);
}
"""

@onready var world: World = $World

var _out := ""
var _failed := PackedStringArray()


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.storm_threshold = 10.0
	tuning.storm_darkness = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_out = args[at + 1] if args.size() > at + 1 else "user://wind"
	_capture()


func _capture() -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	player.set_physics_process(false)
	player.flying = true
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	DirAccess.make_dir_recursive_absolute(_out)
	var map := world.weather.wind_map
	for i in 10:
		if map.texture != null:
			break
		await get_tree().process_frame
	if map.texture == null:
		print("wind: no wind map: no RenderingDevice, or its shaders didn't compile")
		print("wind: check FAIL")
		get_tree().quit(1)
		return
	world.weather.face.visible = false
	world.weather.atmosphere.visible = false
	(world.get_node("WorldEnvironment") as WorldEnvironment).environment.fog_enabled = false
	var sea: Vector2 = preload("res://look/dunes/dunes.gd").spots()["sea"]
	var t := _at_hour(HOUR)
	world.respawn(sea.x, sea.y, 0.0, t)
	world.time_warp = 0.0
	await _ground()
	var particles := _particles()
	var plate := _plate()
	map.feed(particles.process_material)
	map.feed((plate[1] as MeshInstance3D).material_override)
	var ground := world.height_at(sea.x, sea.y)
	player.global_position = Vector3(world.engine_x(sea.x), ground + HEIGHT, world.engine_z(sea.y)) - player.camera.position
	player.camera.rotation_degrees.x = -90.0
	player.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	player.camera.size = FRAME
	player.camera.far = HEIGHT * 4.0

	var tuning := world.tuning
	for weather: Array in WEATHERS:
		tuning.prevailing_speed = weather[1]
		tuning.prevailing_sway = weather[1] * 0.4
		tuning.storm_threshold = -2.0 if weather[2] else 10.0
		world.weather.field = WeatherField.new(world.run_seed, tuning)
		var when := _turned(t) if weather[3] else t
		world.time = when
		# North up, the map square in the frame.
		player.rotation.y = 0.0
		await _frames(6)
		var blowing := world.weather.field.prevailing_at(when)
		print("wind: %-6s %.1f m/s toward %.0f°, %.0f° round from the run's mean, at t %.0f s" % [weather[0],
			blowing.length(), rad_to_deg(blowing.angle()),
			rad_to_deg(angle_difference(WeatherField.mean_heading(world.run_seed), blowing.angle())), when])
		_check(weather[0], when)
		await _check_reads(weather[0], particles, plate)
		for view in VIEWS.size():
			_sand().set_shader_parameter("wind_view", view + 1)
			await _frames(3)
			get_viewport().get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [weather[0], VIEWS[view]]))
		_sand().set_shader_parameter("wind_view", 0)
	await _far(sea + FAR, t + FAR_DAYS * tuning.day_minutes * 60.0)
	await _gpu_cost()
	print("wind: check %s%s" % ["PASS" if _failed.is_empty() else "FAIL: " + ", ".join(_failed), _shared_gpu()])
	get_tree().quit(0 if _failed.is_empty() else 1)


## The breeze checked far out and late, unshot.
func _far(at: Vector2, t: float) -> void:
	var player := world.player
	world.respawn(at.x, at.y, 0.0, t)
	world.time_warp = 0.0
	await _ground()
	player.global_position = Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + HEIGHT, world.engine_z(at.y)) \
		- player.camera.position
	world.tuning.prevailing_speed = 10.0
	world.tuning.prevailing_sway = 4.0
	world.tuning.storm_threshold = 10.0
	world.weather.field = WeatherField.new(world.run_seed, world.tuning)
	await _frames(6)
	var d := world.weather.field.drift_at(t)
	print("wind: far    %.0f km out, %.0f s on, the air %.0f km drifted" % [at.length() / 1000.0, t, d.length() / 1000.0])
	_check("far", t, FAR_HEIGHT_OFF)


## The same hour some whole days on, where the wind has turned furthest from t's.
func _turned(t: float) -> float:
	var field := world.weather.field
	var day := world.tuning.day_minutes * 60.0
	var best := t
	for k in range(1, TURN_DAYS + 1):
		if absf(angle_difference(field.prevailing_at(t).angle(), field.prevailing_at(t + k * day).angle())) \
				> absf(angle_difference(field.prevailing_at(t).angle(), field.prevailing_at(best).angle())):
			best = t + k * day
	return best


## The map read back against the CPU's own answers at its texels.
func _check(name: String, t: float, heights_off := HEIGHT_OFF) -> void:
	var map := world.weather.wind_map
	var field := world.weather.field
	var lee := world.weather.lee
	var tuning := world.tuning
	var got: Array = map.read_back()
	var texels: PackedByteArray = got[0]
	var heights: PackedByteArray = got[1]
	var wind_off := 0.0
	var wind_share := 0.0
	var wind_ok := true
	var lee_offs := PackedFloat32Array()
	var lattice_offs := PackedFloat32Array()
	var moves_off := 0.0
	var day := map.day_share(t)
	for j in range(0, WindMap.CELLS, STRIDE):
		for i in range(0, WindMap.CELLS, STRIDE):
			var x := (map.corner.x + i) * WindMap.TEXEL
			var z := (map.corner.y + j) * WindMap.TEXEL
			var k := (j * WindMap.CELLS + i) * 8
			var gpu := Vector4(texels.decode_half(k), texels.decode_half(k + 2), texels.decode_half(k + 4), texels.decode_half(k + 6))
			var wind := field.wind_at(x, z, t)
			var off := Vector2(gpu.x, gpu.y).distance_to(wind)
			wind_off = maxf(wind_off, off)
			wind_share = maxf(wind_share, off / maxf(wind.length(), 1e-3))
			wind_ok = wind_ok and off <= maxf(WIND_OFF, WIND_SHARE * wind.length())
			var heading := wind.angle()
			var exact := lee.exact(x, z, heading) if wind.length_squared() >= 1e-6 else 0.0
			lee_offs.append(absf(gpu.z - exact))
			lattice_offs.append(absf(gpu.z - (lee.share(x, z, heading) if wind.length_squared() >= 1e-6 else 0.0)))
			var moves := smoothstep(tuning.transport_wind.x, tuning.transport_wind.y, wind.length()) * (1.0 - exact) \
				* maxf(day, field.outflow_at(x, z, t))
			moves_off = maxf(moves_off, absf(gpu.w - moves))
	var height_off := 0.0
	for b in range(0, WindMap.GROUND, HEIGHT_STRIDE):
		for a in range(0, WindMap.GROUND, HEIGHT_STRIDE):
			var at := map.first + Vector2i(a, b)
			var slot := Vector2i(posmod(at.x, WindMap.GROUND), posmod(at.y, WindMap.GROUND))
			var gpu := heights.decode_float((slot.y * WindMap.GROUND + slot.x) * 4)
			height_off = maxf(height_off, absf(gpu - world.shape.dunes(at.x * WindMap.TEXEL, at.y * WindMap.TEXEL)))
	lee_offs.sort()
	lattice_offs.sort()
	var n := lee_offs.size()
	print("wind: %-6s wind within %.4f m/s (%.2f%%) of wind_at; lee within %.4f of Lee.exact (99%% within %.4f), "
		% [name, wind_off, wind_share * 100.0, lee_offs[n - 1], lee_offs[int(n * 0.99)]]
		+ "%.3f of the lattice's Lee.share (99%% %.3f, mean %.4f); sand moved within %.4f; heights within %.4f m; day share %.2f"
		% [lattice_offs[n - 1], lattice_offs[int(n * 0.99)], _mean(lattice_offs), moves_off, height_off, day])
	_expect(wind_ok, "%s wind" % name)
	_expect(lee_offs[n - 1] <= LEE_OFF, "%s lee" % name)
	_expect(moves_off <= MOVES_OFF, "%s sand moved" % name)
	_expect(height_off <= heights_off, "%s heights" % name)


## A particle shader's process(), and a spatial shader's vertex() and
## fragment(), reading the map at a place between texels, against the map's
## texels there blended on the CPU.
func _check_reads(name: String, particles: GPUParticles3D, plate: Array) -> void:
	var map := world.weather.wind_map
	var texels: PackedByteArray = map.read_back()[0]
	# The lee's edge, half a lee, where it changes fastest; a little off its
	# texel's middle so the blend is read too.
	var edge := 0
	for k in WindMap.CELLS * WindMap.CELLS:
		if absf(texels.decode_half(k * 8 + 4) - 0.5) < absf(texels.decode_half(edge * 8 + 4) - 0.5):
			edge = k
	var at := (Vector2(map.corner) + Vector2(edge % WindMap.CELLS + 0.3, edge / WindMap.CELLS + 0.7)) * WindMap.TEXEL
	var engine := Vector2(world.engine_x(at.x), world.engine_z(at.y))
	(particles.process_material as ShaderMaterial).set_shader_parameter("probe_at", engine)
	var look := (plate[1] as MeshInstance3D).material_override as ShaderMaterial
	look.set_shader_parameter("probe_at", engine)
	particles.restart()
	await _frames(8)
	var want := _blend(texels, at)
	var box := particles.capture_aabb()
	var read := box.get_center()
	var off := Vector3(want.x, want.y, want.z).distance_to(read)
	var viewport: SubViewport = plate[0]
	var pixel := viewport.get_texture().get_image().get_pixel(1, 1).srgb_to_linear()
	var lee_vertex := absf(pixel.r - want.z)
	var moves_vertex := absf(pixel.g - want.w)
	var lee_fragment := absf(pixel.b - want.z)
	print("wind: %-6s particles' process() read (%.3f, %.3f, %.3f), the map there (%.3f, %.3f, %.3f), off %.4f, spread %.4f; "
		% [name, read.x, read.y, read.z, want.x, want.y, want.z, off, box.size.length()]
		+ "vertex() read the lee off %.4f and the sand moved off %.4f, fragment() the lee off %.4f"
		% [lee_vertex, moves_vertex, lee_fragment])
	_expect(off <= READ_OFF and box.size.length() <= READ_OFF, "%s particles" % name)
	_expect(lee_vertex <= READ_OFF and moves_vertex <= READ_OFF and lee_fragment <= READ_OFF, "%s spatial" % name)


## The map's texels at a world place blended as a linear filter blends them.
func _blend(texels: PackedByteArray, at: Vector2) -> Vector4:
	var map := world.weather.wind_map
	var f := at / WindMap.TEXEL - Vector2(map.corner)
	var i := floori(f.x)
	var j := floori(f.y)
	var u := f.x - i
	var v := f.y - j
	var texel := func(a: int, b: int) -> Vector4:
		var k := (b * WindMap.CELLS + a) * 8
		return Vector4(texels.decode_half(k), texels.decode_half(k + 2), texels.decode_half(k + 4), texels.decode_half(k + 6))
	return (texel.call(i, j) * (1.0 - u) + texel.call(i + 1, j) * u) * (1.0 - v) \
		+ (texel.call(i, j + 1) * (1.0 - u) + texel.call(i + 1, j + 1) * u) * v


## What the passes cost on the GPU, by its own clock: standing, moving a
## texel every frame (a strip of heights each), and the frame after a jump
## that fills them all.
func _gpu_cost() -> void:
	var map := world.weather.wind_map
	var player := world.player
	map.measure = true
	await _frames(5)
	var still := 0.0
	for i in GPU_FRAMES:
		await get_tree().process_frame
		still += map.gpu_ms
	var moving := 0.0
	for i in GPU_FRAMES:
		player.global_position.x += WindMap.TEXEL
		await get_tree().process_frame
		moving += map.gpu_ms
	var jump := 0.0
	player.global_position.x += 2000.0
	for i in 4:
		await get_tree().process_frame
		jump = maxf(jump, map.gpu_ms)
	map.measure = false
	# The main thread's share: packing, the shaders' window, recording the passes.
	var started := Time.get_ticks_usec()
	for i in GPU_FRAMES:
		map.bake()
	var cpu := (Time.get_ticks_usec() - started) / float(GPU_FRAMES)
	# Its shaders compiled from source, as a world loads.
	started = Time.get_ticks_usec()
	var spare := WindMap.new(world)
	var built := (Time.get_ticks_usec() - started) / 1000.0
	spare.finish()
	print("wind: gpu %.3f ms a frame standing, %.3f moving a texel a frame, %.3f the frame all heights refill; " % [
		still / GPU_FRAMES, moving / GPU_FRAMES, jump]
		+ "cpu %.0f µs a bake, %.0f ms to build as a world loads%s" % [cpu, built, _shared_gpu()])
	_expect(still / GPU_FRAMES <= 0.1 and moving / GPU_FRAMES <= 0.1, "gpu cost")


## A particle system whose process() reads the map at one place and stands
## every particle on what it read.
func _particles() -> GPUParticles3D:
	var shader := Shader.new()
	shader.code = PROBE_PARTICLES
	var motion := ShaderMaterial.new()
	motion.shader = shader
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.001
	var system := GPUParticles3D.new()
	system.amount = 16
	system.lifetime = 1.0
	system.local_coords = false
	system.process_material = motion
	system.draw_pass_1 = quad
	system.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Always in view, so always processed.
	system.visibility_aabb = AABB(Vector3.ONE * -1.0e5, Vector3.ONE * 2.0e5)
	add_child(system)
	return system


## A SubViewport of its own world holding a plate whose shader reads the map
## in vertex() and fragment(), filling every pixel with what it read.
func _plate() -> Array:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(4, 4)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.0
	camera.position = Vector3(0.0, 0.0, 2.0)
	viewport.add_child(camera)
	var shader := Shader.new()
	shader.code = PROBE_SPATIAL
	var look := ShaderMaterial.new()
	look.shader = shader
	var plate := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 4.0
	plate.mesh = quad
	plate.material_override = look
	viewport.add_child(plate)
	add_child(viewport)
	return [viewport, plate]


func _sand() -> ShaderMaterial:
	return world.terrain.sand_material as ShaderMaterial


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failed.append(what)


static func _mean(values: PackedFloat32Array) -> float:
	var sum := 0.0
	for v in values:
		sum += v
	return sum / maxi(values.size(), 1)


## The first world time from 0 on that's this local hour where a run begins.
func _at_hour(hour: float) -> float:
	var longitude := deg_to_rad(world.tuning.spawn_longitude_degrees)
	var now := world.weather.day.time_of_day(0.0, longitude)
	return fposmod(hour - now, 1.0) * world.tuning.day_minutes * 60.0


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var waited := Time.get_ticks_msec()
	while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 60000:
		await get_tree().process_frame


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""
