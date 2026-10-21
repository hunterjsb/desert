shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec3 sun_direction;
varying vec3 globe;
void vertex() { globe = normalize(VERTEX); }
void fragment() {
	vec3 p = normalize(globe);
	vec3 eye = normalize((inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz - p * 1012.0);
	float facing = dot(p, eye);
	float rim = exp(-pow(facing / 0.14, 2.0));
	float sun = smoothstep(-0.2, 0.4, dot(p, sun_direction));
	ALBEDO = mix(vec3(0.18, 0.24, 0.30), vec3(0.82, 0.43, 0.15), sun);
	ALPHA = rim * sun * 0.48;
}
