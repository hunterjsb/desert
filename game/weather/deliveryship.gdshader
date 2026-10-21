// What Godot doesn't give a thing high in the sky, drawn over the crop
// survey's worn paint as an overlay (material_overlay) so the worn shader is
// left as it is:
//   - the sunlit sand under it throwing light back up at its belly, and the
//     bright sky at its sides, from its own paint (the kit's vertex colour);
//   - the air between it and you, as a veil in the sky's own colour behind
//     it. The scene's fog is for looking across the ground; looking up you
//     cross far less dust, so deliveryship.gd draws the craft inside the
//     fog's start and works its veil out along the real line of sight.
// Premultiplied: what's under it keeps (1 - veil), plus this.
shader_type spatial;
render_mode blend_premul_alpha, unshaded, fog_disabled, depth_draw_never, cull_back;

// What the ground below throws up, and the sky's light from the side, linear.
uniform vec3 bounce = vec3(0.0);
uniform vec3 sky_side = vec3(0.0);
// The sky's colour behind it, and how much of it the air lays over it.
uniform vec3 veil_color = vec3(0.0);
uniform float veil = 0.0;

varying vec3 world_n;

void vertex() {
	world_n = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	vec3 n = normalize(world_n);
	float down = clamp(-n.y, 0.0, 1.0);
	float side = 1.0 - abs(n.y);
	vec3 lift = COLOR.rgb * (bounce * down + sky_side * side) * (1.0 - veil);
	ALBEDO = lift + veil_color * veil;
	ALPHA = veil;
}
