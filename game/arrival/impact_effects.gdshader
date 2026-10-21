shader_type canvas_item;
uniform vec4 aperture = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 sand : source_color = vec4(0.0);
uniform float heat = 0.0;
uniform float dust = 0.0;
uniform float passage = 0.0;

uint hash_cell(ivec2 cell) {
	uvec2 p = uvec2(cell);
	uint h = p.x * 1597334677u ^ p.y * 3812015801u;
	h = (h ^ (h >> 16u)) * 2246822519u;
	return h ^ (h >> 13u);
}
float lattice(ivec2 p) { return float(hash_cell(p) & 0x00ffffffu) / 16777215.0; }
float cloud(vec2 p) {
	ivec2 at = ivec2(floor(p));
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(lattice(at), lattice(at + ivec2(1,0)), f.x),
		mix(lattice(at + ivec2(0,1)), lattice(at + ivec2(1,1)), f.x), f.y);
}
void fragment() {
	vec2 q = (UV - aperture.xy) / max(aperture.zw, vec2(0.0001));
	float inside = step(0.0, q.x) * step(q.x, 1.0) * step(0.0, q.y) * step(q.y, 1.0);
	float edge = min(min(q.x, 1.0 - q.x), min(q.y, 1.0 - q.y));
	float rim = 1.0 - smoothstep(0.0, 0.12, edge);
	vec2 ray = (q - vec2(0.5, 0.85)) * vec2(1.3, 1.0);
	vec2 flow = ray * (8.0 / (1.0 + passage * 2.0)) - vec2(0.0, passage * 1.7);
	float grain = cloud(flow) * 0.7 + cloud(flow * 2.7 + vec2(7.0, 3.0)) * 0.3;
	float grit = dust * (0.82 + 0.18 * grain);
	float glow = heat * rim * (0.65 + 0.35 * grain);
	vec3 dust_color = sand.rgb * mix(0.75, 1.45, grain);
	vec3 hot = mix(vec3(1.0, 0.16, 0.025), vec3(1.0, 0.63, 0.16), grain);
	float alpha = 1.0 - (1.0 - grit) * (1.0 - glow);
	vec3 color = (dust_color * grit + hot * glow * (1.0 - grit)) / max(alpha, 0.0001);
	COLOR = vec4(color, alpha * inside);
}
