class_name WindMap
extends RefCounted
## The wind as the GPU draws with it: a texture round you, baked every frame
## by a compute pass on the main RenderingDevice from twins of the functions
## the game plays by. Each 2 m texel holds the field's wind on the ground (r,
## g: m/s in world x and z, wind_at's), the lee's share there (b: Lee.exact
## along that wind, so it turns with it) and how hard the wind moves sand
## (a: past sand's threshold, out of the lee, by the hour; a front's outflow
## drives it day or night). The open air's wind is rg * (1 - lee_wind * b),
## as Weather.open_wind. For looks only: nothing the game plays by reads it
## back. Inert without a GPU, as headless.
##
## The lee reads the ground from a wrapped kilometre of 2 m heights, the
## dunes' own twin (no structures), filled only where the window moves on.

## Texels a side and their size, m: 256 m round you.
const CELLS := 128
const TEXEL := 2.0
## Heights a side, TEXEL apart: the map, and the lee's reach upwind of its edge.
const GROUND := 512
const GROUP := 8

const HEAD := """
#version 450
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
const int GROUND = %d;
const float TEXEL = %.1f;
"""
## The params block both passes read, in _pack()'s order: the window, the
## sand's threshold and the hour's share, then the twins' own.
const PARAMS := "layout(set = 0, binding = 1, std140) uniform Params { ivec4 window; vec4 moves; %s %s %s } p;\n"

const HEIGHTS_MAIN := """
layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D heights;
// World samples (TEXEL apart) to fill: the first's index, and how many.
layout(push_constant, std430) uniform Fill {
	ivec4 rect;
} fill;

void main() {
	ivec2 id = ivec2(gl_GlobalInvocationID.xy);
	if (id.x >= fill.rect.z || id.y >= fill.rect.w) {
		return;
	}
	ivec2 at = fill.rect.xy + id;
	imageStore(heights, at & (GROUND - 1), vec4(dunes(vec2(at) * TEXEL)));
}
"""

const WIND_GROUND := """
layout(rgba16f, set = 0, binding = 0) uniform restrict writeonly image2D wind_map;
layout(set = 0, binding = 2) uniform sampler2D heights;

// Lee._ground() from the heights: at, metres from the window's first sample.
float ground(vec2 at) {
	vec2 g = at / TEXEL;
	ivec2 c = ivec2(floor(g));
	vec2 f = g - vec2(c);
	// w: c, z: c + (1, 0), x: c + (0, 1), y: c + (1, 1).
	vec4 q = textureGather(heights, (vec2((c + p.window.zw) & (GROUND - 1)) + 1.0) / float(GROUND));
	if (f.x + f.y <= 1.0) {
		return q.w + f.x * (q.z - q.w) + f.y * (q.x - q.w);
	}
	return q.y + (1.0 - f.x) * (q.x - q.y) + (1.0 - f.y) * (q.z - q.y);
}
"""

const WIND_MAIN := """
void main() {
	ivec2 id = ivec2(gl_GlobalInvocationID.xy);
	vec3 blowing = wind_on(p.air.xy + TEXEL * vec2(id));
	vec2 wind = blowing.xy;
	float speed = length(wind);
	// Still air has no upwind.
	float lee = speed * speed < 1.0e-6 ? 0.0 : lee_share(TEXEL * vec2(id + p.window.xy - p.window.zw), -wind / speed);
	float moves = smoothstep(p.moves.x, p.moves.y, speed) * (1.0 - lee) * max(p.moves.z, blowing.z);
	imageStore(wind_map, id, vec4(wind, lee, moves));
}
"""

## The heights have never been filled.
const UNFILLED := Vector2i(-0x40000000, -0x40000000)

## What shaders sample, once the map exists.
var texture: Texture2DRD
## The last bake's first texel and first height, world indices TEXEL apart.
var corner := Vector2i.ZERO
var first := Vector2i.ZERO
## Times the passes on the GPU into gpu_ms, ms, for a look-test.
var measure := false
var gpu_ms := 0.0

var _world: World
var _rd: RenderingDevice
var _heights_shader: RID
var _heights_pipeline: RID
var _wind_shader: RID
var _wind_pipeline: RID
var _map: RID
var _heights: RID
var _sampler: RID
var _params: RID
var _fill_set: RID
var _bake_set: RID
var _materials: Array[ShaderMaterial] = []
var _window := Vector4.INF
## The params that hold still, after those that move, and the field and lee
## they were packed from.
var _still := PackedByteArray()
var _still_of: Array = []
## The heights' first sample as filled, a world index TEXEL apart.
var _filled := UNFILLED


func _init(world: World) -> void:
	_world = world
	_rd = RenderingServer.get_rendering_device()
	if _rd != null:
		RenderingServer.call_on_render_thread(_build.bind(_pack(0.0).size()))


## Feeds a shader that includes wind_map.gdshaderinc, a spatial or a particle one.
func feed(material: Material) -> void:
	var shader := material as ShaderMaterial
	if shader != null and not _materials.has(shader):
		_materials.append(shader)
		if texture != null:
			shader.set_shader_parameter("wind_map", texture)
			shader.set_shader_parameter("wind_window", _window)


## Every drawn frame, after the world has moved and shifted: centres the map
## on you at whole texels, so it never swims, and bakes it for now.
func bake() -> void:
	if not _wind_pipeline.is_valid():
		return
	if texture == null:
		texture = Texture2DRD.new()
		texture.texture_rd_rid = _map
		for material in _materials:
			material.set_shader_parameter("wind_map", texture)
	corner = Vector2i(roundi(_world.player_world_x() / TEXEL), roundi(_world.player_world_z() / TEXEL)) \
		- Vector2i(CELLS / 2, CELLS / 2)
	first = corner + Vector2i(CELLS / 2 - GROUND / 2, CELLS / 2 - GROUND / 2)
	# Texel centres sit on the map's whole texels; its edge is half one out.
	var edge := Vector2(_world.engine_x(corner.x * TEXEL), _world.engine_z(corner.y * TEXEL)) - Vector2.ONE * TEXEL * 0.5
	var window := Vector4(edge.x, edge.y, CELLS * TEXEL, 1.0)
	if window != _window:
		_window = window
		for material in _materials:
			material.set_shader_parameter("wind_window", window)
	RenderingServer.call_on_render_thread(_dispatch.bind(_pack(_world.time), _to_fill(first), measure))
	if measure:
		_read_time()


## The params block for the map where it stands, at time t: what moves
## packed each frame, what holds still only when the field or lee is new.
func _pack(t: float) -> PackedByteArray:
	var weather := _world.weather
	var tuning := _world.tuning
	var bytes := PackedInt32Array([corner.x, corner.y, first.x, first.y]).to_byte_array()
	bytes.append_array(PackedFloat32Array([tuning.transport_wind.x, tuning.transport_wind.y, day_share(t), 0.0]).to_byte_array())
	bytes.append_array(weather.field.wind_now(corner.x * TEXEL, corner.y * TEXEL, t).to_byte_array())
	if _still_of != [weather.field, weather.lee, _world.shape.landforms.revision]:
		_still_of = [weather.field, weather.lee, _world.shape.landforms.revision]
		_filled = UNFILLED
		var into := StreamPeerBuffer.new()
		weather.field.pack_wind(into)
		weather.lee.pack_lee(into)
		_world.shape.pack_dunes(into)
		_still = into.data_array
	bytes.append_array(_still)
	return bytes


## How readily the wind lifts sand at this hour, 0 to 1: most in the
## afternoon's heat, dying after sunset, least before dawn.
func day_share(t: float) -> float:
	var moon := _world.moon
	var day := _world.weather.day
	var sun := day.sun_direction(t, moon.latitude, moon.longitude)
	var warm := 0.5 + 0.5 * cos(TAU * (day.time_of_day(t, moon.longitude) - _world.tuning.temperature_peak))
	return lerpf(_world.tuning.transport_night, 1.0, smoothstep(-0.05, 0.3, sun.y) * warm)


## The rectangles of heights the window has moved onto since last filled.
func _to_fill(to: Vector2i) -> Array[Vector4i]:
	var rects: Array[Vector4i] = []
	var moved := to - _filled
	if absi(moved.x) >= GROUND or absi(moved.y) >= GROUND:
		rects.append(Vector4i(to.x, to.y, GROUND, GROUND))
	else:
		if moved.x != 0:
			rects.append(Vector4i(to.x + (GROUND - moved.x if moved.x > 0 else 0), to.y, absi(moved.x), GROUND))
		if moved.y != 0:
			rects.append(Vector4i(to.x, to.y + (GROUND - moved.y if moved.y > 0 else 0), GROUND, absi(moved.y)))
	_filled = to
	return rects


## The map and the heights as they stand on the GPU, for a look-test to check
## against the CPU: [the map, RGBA half floats; the heights, 32-bit floats,
## each wrapped by its world index].
func read_back() -> Array:
	var got := []
	RenderingServer.call_on_render_thread(func() -> void:
		got.append(_rd.texture_get_data(_map, 0))
		got.append(_rd.texture_get_data(_heights, 0)))
	return got


func finish() -> void:
	if texture != null:
		texture.texture_rd_rid = RID()
	if _rd == null:
		return
	var rd := _rd
	# Freeing a shader frees its pipelines; not bound to this, which may be gone when it runs.
	var gone: Array[RID] = [_heights_shader, _wind_shader, _map, _heights, _sampler, _params]
	RenderingServer.call_on_render_thread(func() -> void:
		for rid in gone:
			if rid.is_valid():
				rd.free_rid(rid))
	_wind_pipeline = RID()


func _build(params_size: int) -> void:
	var common := HEAD % [GROUND, TEXEL] + NoiseGLSL.SOURCE \
		+ PARAMS % [WeatherField.WIND_PARAMS, Lee.LEE_PARAMS, TerrainShape.DUNES_PARAMS]
	_heights_shader = _compile(common + TerrainShape.DUNES_GLSL + HEIGHTS_MAIN)
	_wind_shader = _compile(common + WIND_GROUND + Lee.LEE_GLSL + WeatherField.WIND_GLSL + WIND_MAIN)
	if not _heights_shader.is_valid() or not _wind_shader.is_valid():
		return
	var format := RDTextureFormat.new()
	format.width = CELLS
	format.height = CELLS
	format.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	_map = _rd.texture_create(format, RDTextureView.new())
	format.width = GROUND
	format.height = GROUND
	format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	_heights = _rd.texture_create(format, RDTextureView.new())
	var wrap := RDSamplerState.new()
	wrap.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	wrap.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	_sampler = _rd.sampler_create(wrap)
	_params = _rd.uniform_buffer_create(params_size)
	_fill_set = _rd.uniform_set_create([_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, [_heights]),
		_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 1, [_params])], _heights_shader, 0)
	_bake_set = _rd.uniform_set_create([_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, [_map]),
		_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 1, [_params]),
		_uniform(RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE, 2, [_sampler, _heights])], _wind_shader, 0)
	_heights_pipeline = _rd.compute_pipeline_create(_heights_shader)
	_wind_pipeline = _rd.compute_pipeline_create(_wind_shader)


func _compile(source: String) -> RID:
	var code := RDShaderSource.new()
	code.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	code.source_compute = source
	var spirv := _rd.shader_compile_spirv_from_source(code)
	if spirv.compile_error_compute != "":
		push_error("wind map: %s" % spirv.compile_error_compute)
		return RID()
	return _rd.shader_create_from_spirv(spirv)


func _dispatch(params: PackedByteArray, rects: Array[Vector4i], timed: bool) -> void:
	_rd.buffer_update(_params, 0, params.size(), params)
	if timed:
		_rd.capture_timestamp("wind map")
	if not rects.is_empty():
		var list := _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(list, _heights_pipeline)
		_rd.compute_list_bind_uniform_set(list, _fill_set, 0)
		for rect in rects:
			var push := PackedInt32Array([rect.x, rect.y, rect.z, rect.w]).to_byte_array()
			_rd.compute_list_set_push_constant(list, push, push.size())
			_rd.compute_list_dispatch(list, ceili(rect.z / float(GROUP)), ceili(rect.w / float(GROUP)), 1)
		_rd.compute_list_end()
	var list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(list, _wind_pipeline)
	_rd.compute_list_bind_uniform_set(list, _bake_set, 0)
	_rd.compute_list_dispatch(list, CELLS / GROUP, CELLS / GROUP, 1)
	_rd.compute_list_end()
	if timed:
		_rd.capture_timestamp("wind map done")


## The last timed frame's passes, from the GPU's own clock.
func _read_time() -> void:
	var start := -1
	for i in _rd.get_captured_timestamps_count():
		var name := _rd.get_captured_timestamp_name(i)
		if name == "wind map":
			start = i
		elif name == "wind map done" and start >= 0:
			# Nanoseconds.
			gpu_ms = (_rd.get_captured_timestamp_gpu_time(i) - _rd.get_captured_timestamp_gpu_time(start)) / 1.0e6


static func _uniform(type: RenderingDevice.UniformType, binding: int, ids: Array[RID]) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	for id in ids:
		uniform.add_id(id)
	return uniform
