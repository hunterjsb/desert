// Dust streaks round the camera, stretched along their flight. They fade with
// the field's extinction at the camera, so particles and fog agree on how far
// you can see; none are inside a shelter, and none of the dust is either.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled, skip_vertex_transform;

#include "res://game/weather/shelter.gdshaderinc"

uniform vec3 dust_light = vec3(0.5, 0.35, 0.22);
uniform float camera_sigma = 0.0;
uniform float streak_length = 2.0;
uniform float streak_width = 0.04;
uniform float opacity = 0.3;

varying float v_dist;
// Metres of dust between the camera and the streak, less what runs through shelters.
varying float v_dust;
varying float v_fade;
varying vec3 v_world;

void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	// The process material aligns Y with the velocity.
	vec3 along = normalize(MODEL_MATRIX[1].xyz);
	float size = length(MODEL_MATRIX[0].xyz);
	vec3 to_camera = CAMERA_POSITION_WORLD - center;
	vec3 side = normalize(cross(along, to_camera));
	vec3 p = center + side * VERTEX.x * streak_width * size + along * VERTEX.y * streak_length * size;
	VERTEX = (VIEW_MATRIX * vec4(p, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(to_camera, 0.0)).xyz);
	v_dist = length(to_camera);
	v_dust = v_dist - shelter_length(CAMERA_POSITION_WORLD, -to_camera / max(v_dist, 1.0e-4), v_dist);
	v_fade = sin(INSTANCE_CUSTOM.y * PI) * COLOR.a;
	v_world = p;
}

void fragment() {
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	float lengthwise = 1.0 - abs(UV.y * 2.0 - 1.0);
	float a = across * across * lengthwise * opacity * v_fade;
	a *= exp(-camera_sigma * v_dust) * smoothstep(0.5, 2.5, v_dist);
	ALBEDO = dust_light;
	ALPHA = a * smoothstep(0.0, 0.2, shelter_clearance(v_world));
}
