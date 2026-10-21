shader_type canvas_item;
uniform float strength = 0.0;
uniform float passage = 0.0;
uint hash_cell(ivec2 cell) {
	uvec2 p = uvec2(cell);
	uint h = p.x * 1597334677u ^ p.y * 3812015801u;
	h = (h ^ (h >> 16u)) * 2246822519u;
	return h ^ (h >> 13u);
}
float lattice(ivec2 p) { return float(hash_cell(p) & 0x00ffffffu) / 16777215.0; }
float dust(vec2 p) {
	ivec2 k = ivec2(floor(p));
	vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(lattice(k), lattice(k + ivec2(1,0)), f.x),
		mix(lattice(k + ivec2(0,1)), lattice(k + ivec2(1,1)), f.x), f.y);
}
void fragment() {
	vec2 flow = UV * vec2(7.0, 4.0) + vec2(passage * 0.12, -passage * 0.7);
	float cloud = dust(flow) * 0.7 + dust(flow * 2.1 + vec2(9.0, 5.0)) * 0.3;
	vec3 color = mix(vec3(0.22, 0.11, 0.045), vec3(0.68, 0.43, 0.20), cloud);
	float alpha = clamp(strength * (0.7 + cloud * 0.4) + smoothstep(0.75, 1.0, strength) * 0.4, 0.0, 1.0);
	COLOR = vec4(color, alpha);
}
