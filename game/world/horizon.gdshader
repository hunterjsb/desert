shader_type spatial;
#include "res://game/world/mountain.gdshaderinc"
// Distant ground has no ripples, tracks or wind-map reads. The real terrain
// covers its lowered mesh inside the far ring; atmosphere supplies the haze.
uniform vec3 sand : source_color;
uniform float horizon_near = 2800.0;
uniform vec2 horizon_range = vec2(24000.0, 42000.0);
varying vec3 world_pos;
varying vec3 world_normal;
void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float distance = length(world_pos.xz - CAMERA_POSITION_WORLD.xz);
	if (distance < horizon_near) discard;
	float keep = 1.0 - smoothstep(horizon_range.x, horizon_range.y, distance);
	float pixel = mod(floor(FRAGCOORD.x), 4.0) + 4.0 * mod(floor(FRAGCOORD.y), 4.0);
	if (keep < (pixel + 0.5) / 16.0) discard;
	ALBEDO = mountain_colour(sand, world_pos.y, normalize(world_normal));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
