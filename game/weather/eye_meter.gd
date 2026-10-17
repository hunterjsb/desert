class_name EyeMeter
extends CompositorEffect
## How bright the frame is, as an eye takes it in, read off the scene's light
## before the tonemap, so the exposure it leads to never feeds back into it.
## Two numbers, in stops (log2 of luminance): the frame's mean light, all the
## light reaching the eye, which is what a pupil follows, so a headlamp's pool
## or Tu's disc in view holds it partly closed; and its brightest 64-pixel
## patch's mean (the most of it Tu's disc fills at night), so the eye can keep
## that short of white. Two compute passes sum them on the GPU and the sixteen
## bytes come back a frame or two later, never stalling one. Inert without a
## GPU, as headless.

## Called with each frame's reading: its mean light and its brightest patch, stops.
var on_reading: Callable

## Pixels a side of each group's tile, and the most groups a frame: enough for
## 5120x3200 drawn.
const TILE := 64
const MOST_GROUPS := 4096

const SOURCE := """
#version 450
// Pass 0: one thread a 4x4 block; a 16x16 group, one tile, sums its light into
// its own slot. Pass 1: one group sums the slots and finds the brightest tile.
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
layout(rgba16f, set = 0, binding = 0) uniform restrict readonly image2D color;
layout(set = 0, binding = 1, std430) restrict buffer Partials {
	vec4 partials[];
};
layout(set = 0, binding = 2, std430) restrict writeonly buffer Total {
	vec4 total;
};
layout(push_constant, std430) uniform Params {
	ivec2 size;
	int stage;
	int groups;
} params;

// Light summed, the brightest tile's mean (pass 1), and pixels.
shared vec3 sums[256];

void reduce(uint i) {
	for (uint step = 128; step > 0; step >>= 1) {
		barrier();
		if (i < step) {
			vec3 other = sums[i + step];
			sums[i] = vec3(sums[i].x + other.x, max(sums[i].y, other.y), sums[i].z + other.z);
		}
	}
	barrier();
}

void main() {
	uint i = gl_LocalInvocationIndex;
	vec3 mine = vec3(0.0);
	if (params.stage == 0) {
		ivec2 base = ivec2(gl_GlobalInvocationID.xy) * 4;
		if (base.x < params.size.x && base.y < params.size.y) {
			for (int y = 0; y < 4; y++) {
				for (int x = 0; x < 4; x++) {
					vec3 c = imageLoad(color, min(base + ivec2(x, y), params.size - 1)).rgb;
					mine.x += dot(c, vec3(0.2126, 0.7152, 0.0722));
				}
			}
			mine.z = 16.0;
		}
		sums[i] = mine;
		reduce(i);
		if (i == 0) {
			partials[gl_WorkGroupID.y * gl_NumWorkGroups.x + gl_WorkGroupID.x] = vec4(sums[0], 0.0);
		}
	} else {
		for (int g = int(i); g < params.groups; g += 256) {
			vec4 tile = partials[g];
			mine = vec3(mine.x + tile.x, max(mine.y, tile.x / max(tile.z, 1.0)), mine.z + tile.z);
		}
		sums[i] = mine;
		reduce(i);
		if (i == 0) {
			total = vec4(sums[0], 0.0);
		}
	}
}
"""

var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _partials: RID
var _total: RID


func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	_rd = RenderingServer.get_rendering_device()
	if _rd != null:
		RenderingServer.call_on_render_thread(_build)


func _build() -> void:
	var source := RDShaderSource.new()
	source.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	source.source_compute = SOURCE
	var spirv := _rd.shader_compile_spirv_from_source(source)
	if spirv.compile_error_compute != "":
		push_error("eye meter: %s" % spirv.compile_error_compute)
		return
	_shader = _rd.shader_create_from_spirv(spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)
	_partials = _rd.storage_buffer_create(MOST_GROUPS * 16)
	_total = _rd.storage_buffer_create(16)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _rd != null:
		# Freeing the shader frees its pipeline.
		for rid: RID in [_shader, _partials, _total]:
			if rid.is_valid():
				_rd.free_rid(rid)


func _render_callback(_type: int, render_data: RenderData) -> void:
	var buffers := render_data.get_render_scene_buffers() as RenderSceneBuffersRD
	if not _pipeline.is_valid() or buffers == null:
		return
	var size := buffers.get_internal_size()
	var across := ceili(size.x / float(TILE))
	var down := ceili(size.y / float(TILE))
	if size.x == 0 or size.y == 0 or across * down > MOST_GROUPS:
		return
	var uniforms := UniformSetCacheRD.get_cache(_shader, 0, [
		_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, buffers.get_color_layer(0)),
		_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, _partials),
		_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2, _total)])
	var list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(list, _pipeline)
	_rd.compute_list_bind_uniform_set(list, uniforms, 0)
	for stage in 2:
		var push := PackedInt32Array([size.x, size.y, stage, across * down]).to_byte_array()
		_rd.compute_list_set_push_constant(list, push, push.size())
		if stage == 0:
			_rd.compute_list_dispatch(list, across, down, 1)
			_rd.compute_list_add_barrier(list)
		else:
			_rd.compute_list_dispatch(list, 1, 1, 1)
	_rd.compute_list_end()
	# Through the script's own function, which outlives this meter if its
	# world goes before the bytes come back.
	_rd.buffer_get_data_async(_total, EyeMeter._delivered.bind(weakref(self)), 0, 16)


static func _uniform(type: RenderingDevice.UniformType, binding: int, rid: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	uniform.add_id(rid)
	return uniform


static func _delivered(data: PackedByteArray, meter: WeakRef) -> void:
	var to: EyeMeter = meter.get_ref()
	if to == null or data.size() < 16 or not to.on_reading.is_valid():
		return
	var count := data.decode_float(8)
	var light := data.decode_float(0)
	var brightest := data.decode_float(4)
	# A frame that drew a NaN somewhere would blind the eye; it skips that one.
	if count > 0.0 and light > 0.0 and brightest > 0.0 and is_finite(light) and is_finite(brightest):
		to.on_reading.call(log(light / count) / Eye.LN2, log(brightest) / Eye.LN2)
