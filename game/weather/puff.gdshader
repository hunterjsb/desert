// Big soft parcels of dust tearing past inside the storm: what shows the wind
// when everything further than a few metres is murk. A shelter cuts them off
// at its shell, so they press on it from outside.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled, skip_vertex_transform;

#include "res://game/weather/shelter.gdshaderinc"

uniform vec3 dust_light = vec3(0.5, 0.35, 0.22);
uniform float camera_sigma = 0.0;
uniform float opacity = 0.15;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying float v_dist;
// Metres of dust between the camera and the puff, less what runs through shelters.
varying float v_dust;
varying float v_fade;
varying float v_shade;
varying vec3 v_world;

void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	float size = length(MODEL_MATRIX[0].xyz);
	vec3 p = center + (INV_VIEW_MATRIX[0].xyz * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y) * size;
	VERTEX = (VIEW_MATRIX * vec4(p, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_dist = length(CAMERA_POSITION_WORLD - center);
	v_dust = v_dist - shelter_length(CAMERA_POSITION_WORLD, (center - CAMERA_POSITION_WORLD) / max(v_dist, 1.0e-4), v_dist);
	v_fade = sin(INSTANCE_CUSTOM.y * PI) * COLOR.a;
	v_shade = fract(sin(float(INSTANCE_ID) * 12.9898) * 43758.5453);
	v_world = p;
}

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float a = smoothstep(1.0, 0.1, r);
	a *= a * opacity * v_fade;
	a *= exp(-camera_sigma * v_dust) * smoothstep(1.5, 5.0, v_dist);
	// Soft where it meets the ground, so no puff shows a hard cut.
	float z = texture(depth_tex, SCREEN_UV).r;
	vec4 scene = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, z, 1.0);
	a *= clamp((VERTEX.z - scene.z / scene.w) / 2.5, 0.0, 1.0);
	ALBEDO = dust_light * mix(0.55, 1.6, v_shade);
	// Soft against a shell, as dust would be, not cut flat by it.
	ALPHA = a * smoothstep(0.0, 4.0, shelter_clearance(v_world));
}
