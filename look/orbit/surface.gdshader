shader_type spatial;
render_mode unshaded;
uniform vec3 sun_direction = vec3(1.0, 0.0, 0.0);
uniform vec3 seed_offset;
uniform vec3 rift[32];
uniform int rift_count = 0;
varying vec3 globe;

uint hash_cell(ivec3 cell) {
	uvec3 p = uvec3(cell);
	uint h = p.x * 1597334677u ^ p.y * 3812015801u ^ p.z * 2798796415u;
	h = (h ^ (h >> 16u)) * 2246822519u;
	return h ^ (h >> 13u);
}
float lattice(ivec3 p) { return float(hash_cell(p) & 0x00ffffffu) / 16777215.0; }
float noise3(vec3 p) {
	ivec3 k = ivec3(floor(p));
	vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(lattice(k), lattice(k + ivec3(1,0,0)), f.x), mix(lattice(k + ivec3(0,1,0)), lattice(k + ivec3(1,1,0)), f.x), f.y),
		mix(mix(lattice(k + ivec3(0,0,1)), lattice(k + ivec3(1,0,1)), f.x), mix(lattice(k + ivec3(0,1,1)), lattice(k + ivec3(1,1,1)), f.x), f.y), f.z);
}
float terrain(vec3 p) {
	float h = 0.0; float w = 0.53;
	for (int i = 0; i < 5; i++) { h += noise3(p) * w; p = p * 2.07 + vec3(13.1, 7.3, 2.9); w *= 0.48; }
	return h;
}
void vertex() { globe = normalize(VERTEX); }
void fragment() {
	vec3 p = normalize(globe);
	float broad = terrain(p * 6.0 + seed_offset);
	float detail = terrain(p * 48.0 + seed_offset);
	float scar_distance = 2.0;
	for (int i = 0; i < 31; i++) {
		if (i + 1 >= rift_count) { break; }
		vec3 ab = rift[i + 1] - rift[i];
		float along = clamp(dot(p - rift[i], ab) / max(dot(ab, ab), 0.00000001), 0.0, 1.0);
		scar_distance = min(scar_distance, distance(p, normalize(rift[i] + ab * along)));
	}
	float scar = 1.0 - smoothstep(0.003, 0.027, scar_distance);
	float rock = smoothstep(0.43, 0.61, broad + detail * 0.12);
	vec3 sand = mix(vec3(0.30, 0.18, 0.09), vec3(0.62, 0.42, 0.24), broad);
	vec3 albedo = mix(sand, vec3(0.095, 0.078, 0.06), rock * 0.9);
	albedo = mix(albedo, vec3(0.095, 0.067, 0.05), scar * (0.6 + detail * 0.35));
	float relief = broad * 0.0025 + detail * 0.0015 - scar * 0.001;
	vec3 dx = dFdx(p); vec3 dy = dFdy(p);
	vec3 a = cross(dy, p); vec3 b = cross(p, dx);
	float det = dot(dx, a);
	vec3 gradient = sign(det) * (dFdx(relief) * a + dFdy(relief) * b);
	vec3 bumped = normalize(max(abs(det), 0.000000000001) * p - gradient * 0.45);
	float incidence = dot(p, normalize(sun_direction));
	float lit = smoothstep(-0.018, 0.055, incidence) * pow(max(dot(bumped, normalize(sun_direction)), 0.0), 0.8);
	vec3 eye = normalize((inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz - p * 1000.0);
	float edge = pow(1.0 - max(dot(p, eye), 0.0), 3.5);
	vec3 light = albedo * vec3(1.12, 0.98, 0.81) * (lit * 1.25 + 0.003);
	light += vec3(0.48, 0.28, 0.12) * edge * smoothstep(-0.15, 0.3, incidence) * 0.32;
	ALBEDO = light;
}
