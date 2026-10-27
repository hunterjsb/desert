shader_type spatial;
render_mode cull_disabled;

// The antenna kite's sail (AntennaKite; from the radio kit lab, look/radio_kit):
// UV.x across it (0 to 1), UV.y from its nose (0)
// to its trailing edge (1). Shortwave violet with survey-orange chevrons, a
// copper dipole sewn across its shoulder. Torn, cells of it go, the edges
// first (as the game's sail does); charged, its dipole and edges glow the
// pale violet of a corona discharge, flickering.

uniform vec3 cloth : source_color = vec3(0.5, 0.36, 0.78);
uniform vec3 chevron : source_color = vec3(0.86, 0.42, 0.1);
uniform vec3 copper : source_color = vec3(0.62, 0.36, 0.22);

instance uniform float torn = 0.0;
instance uniform float weathered = 0.0;
instance uniform float charge = 0.0;
uniform float billow = 1.0;

varying vec2 at;

// An integer hash: cells stay put however far from the origin.
float lattice(ivec2 p) {
	uint h = uint(p.x) * 374761393u + uint(p.y) * 668265263u;
	h = (h ^ (h >> 13u)) * 1274126177u;
	return float(h ^ (h >> 16u)) / 4294967295.0;
}

void vertex() {
	at = UV;
	// Bellied back between its spars, most at its middle.
	float across = UV.x * 2.0 - 1.0;
	VERTEX.z -= billow * 0.07 * (1.0 - across * across) * sin(3.14159 * clamp(UV.y * 1.1, 0.0, 1.0));
}

void fragment() {
	float across = abs(at.x * 2.0 - 1.0);
	// Chevrons down its middle, pointing at its nose.
	float v = fract(at.y * 3.0 + across * 0.9);
	float band = step(0.72, v) * step(across, 0.75);
	vec3 base = mix(cloth, chevron, band);
	// Seams: along its spine and across every third.
	float seam = step(0.985, 1.0 - abs(at.x - 0.5) * 2.0) + step(0.97, fract(at.y * 6.0)) * 0.6;
	base *= 1.0 - clamp(seam, 0.0, 1.0) * 0.25;
	// The dipole, sewn across its shoulder.
	float wire = 1.0 - smoothstep(0.004, 0.009, abs(at.y - 0.42));
	base = mix(base, copper, wire);
	// Sun-bleached and sand-scoured with age (`weathered`: the worn shader on
	// its spars has its own `age`).
	base = mix(base, base * vec3(0.85, 0.78, 0.66) + vec3(0.08, 0.06, 0.04), weathered * 0.7);
	// Torn: cells go, the edges' sooner (the wind works at an edge).
	ivec2 cell = ivec2(floor(at * vec2(11.0, 9.0)));
	float edge = max(smoothstep(0.7, 1.0, at.y), smoothstep(0.75, 1.0, across));
	float gone = lattice(cell) * (1.0 - 0.6 * edge);
	if (torn > 0.0 && gone < torn) {
		discard;
	}
	// Frayed: a fringe round each hole, darker.
	float near = 0.0;
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			ivec2 n = cell + ivec2(i, j);
			vec2 nat = (vec2(n) + 0.5) / vec2(11.0, 9.0);
			float n_edge = max(smoothstep(0.7, 1.0, nat.y), smoothstep(0.75, 1.0, abs(nat.x * 2.0 - 1.0)));
			if (torn > 0.0 && lattice(n) * (1.0 - 0.6 * n_edge) < torn) {
				vec2 inside = fract(at * vec2(11.0, 9.0)) - vec2(0.5) - vec2(float(i), float(j)) * 0.5;
				near = max(near, 1.0 - smoothstep(0.0, 0.18, max(abs(inside.x), abs(inside.y)) - 0.32));
			}
		}
	}
	base *= 1.0 - near * 0.35;
	ALBEDO = base;
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.4);
	// Corona: the dipole and its edges glow as charge gathers, flickering.
	float flicker = 0.6 + 0.4 * sin(TIME * 37.0 + at.x * 40.0) * sin(TIME * 23.0 + at.y * 31.0);
	float rim = max(wire, smoothstep(0.88, 1.0, across) + smoothstep(0.93, 1.0, at.y));
	EMISSION = vec3(0.75, 0.68, 1.0) * rim * charge * charge * flicker * 3.0;
}
