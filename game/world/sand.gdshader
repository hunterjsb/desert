shader_type spatial;
// The sand: the flat colour plus what makes dune shapes read. Slip faces are
// smooth avalanche sand, a shade lighter and warmer; gentler slopes carry wind
// ripples across the wind, faded out before they alias; crests catch a thin
// highlight; and broad patches vary the colour so distance reads.

uniform vec3 sand : source_color = vec3(0.86, 0.72, 0.52);
uniform vec3 slip_sand : source_color = vec3(0.93, 0.77, 0.55);
uniform vec3 trough_sand : source_color = vec3(0.82, 0.67, 0.48);
// Downwind in world x and z; ripple crests run across it.
uniform vec2 downwind = vec2(1.0, 0.0);
// The engine origin's world position, m, so patterns hold still through origin shifts.
uniform vec2 origin = vec2(0.0);
uniform float ripple_spacing = 0.16;
uniform float ripple_depth = 0.12;
uniform float crest_glow = 0.12;
uniform float patchiness = 0.04;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(world_normal);
	vec2 at = world_pos.xz + origin;
	float grade = length(n.xz) / max(n.y, 0.05);
	// Steep and facing downwind: a slip face.
	float lee = smoothstep(0.42, 0.55, grade) * smoothstep(-0.2, 0.3, dot(normalize(n.xz + 1e-5), downwind));

	float broad = value_noise(at / 90.0) * 0.6 + value_noise(at / 23.0) * 0.4;
	vec3 colour = mix(trough_sand, sand, smoothstep(0.2, 0.8, broad) * 0.5 + 0.5);
	colour *= 1.0 + (value_noise(at / 7.0) - 0.5) * patchiness;
	colour = mix(colour, slip_sand, lee * 0.8);

	// Convex where the normal turns the way the surface runs: a crest.
	vec3 dpx = dFdx(world_pos);
	vec3 dpy = dFdy(world_pos);
	float bend = (dot(dFdx(world_normal), dpx) + dot(dFdy(world_normal), dpy)) / max(dot(dpx, dpx) + dot(dpy, dpy), 1e-4);
	colour *= 1.0 + crest_glow * smoothstep(0.06, 0.2, bend);

	// Ripples: a lopsided wave across the wind, wandering a little, gone on
	// slip faces and wherever a pixel spans more than about a tenth of one.
	vec2 across = vec2(-downwind.y, downwind.x);
	float phase = (dot(at, downwind) + 0.6 * sin(dot(at, across) * 0.9) + 1.5 * value_noise(at / 3.0)) / ripple_spacing;
	float fade = (1.0 - smoothstep(0.06, 0.18, fwidth(phase))) * (1.0 - lee) * ripple_depth;
	float wave = phase * TAU;
	float slope = sin(wave) + 0.35 * sin(2.0 * wave);
	vec3 tilt = vec3(downwind.x, 0.0, downwind.y) * slope * fade;
	vec3 rippled = normalize(n - tilt);

	ALBEDO = colour;
	ROUGHNESS = 1.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(rippled, 0.0)).xyz);
}
