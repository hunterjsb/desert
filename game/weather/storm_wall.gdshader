// The crude wall: flat dust, fading in out of the haze and up into the sky.
// The look-test is where the real face gets made.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_never;

uniform vec3 color : source_color = vec3(0.36, 0.25, 0.16);
uniform float reach = 4000.0;

void fragment() {
	float distance_from_eye = length(VERTEX);
	float emerge = clamp((reach - distance_from_eye) / (reach * 0.3), 0.0, 1.0);
	float top = 1.0 - smoothstep(0.55, 1.0, UV.y);
	ALBEDO = color;
	ALPHA = 0.95 * emerge * top;
}
