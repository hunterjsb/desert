shader_type spatial;
render_mode cull_disabled;

// Fabric laced across a frame's face, on a grid standing out of it along +Z:
// the load the air puts across it (Faces) draws it taut and bellies it the way
// the air presses, deepest in the middle, the lacing holding its edges; slack,
// it flutters in the air going past, faster and harder the more of it.

uniform vec2 size = vec2(0.94, 0.94);
uniform vec3 canvas : source_color = vec3(0.78, 0.7, 0.55);

// How hard the air presses across it, signed out of its face: 1 is taut.
instance uniform float load = 0.0;
// The air going past it, m/s.
instance uniform float air = 0.0;
instance uniform float age = 0.0;

varying vec2 at;

void vertex() {
	at = UV;
	vec2 p = UV * 3.14159;
	float held = sin(p.x) * sin(p.y);
	float pressed = clamp(abs(load), 0.0, 1.0);
	float belly = sign(load) * 0.075 * sqrt(pressed);
	float stir = (1.0 - pressed) * smoothstep(0.5, 8.0, air);
	float rate = 4.0 + air * 0.9;
	float flutter = stir * 0.022 * sin(TIME * rate + UV.x * 11.0 + UV.y * 4.0)
		+ stir * 0.012 * sin(TIME * rate * 1.7 - UV.y * 9.0);
	VERTEX.z += (belly + flutter) * held;
	// The belly's slope, for the light across it.
	vec2 slope = belly * 3.14159 / size * vec2(cos(p.x) * sin(p.y), sin(p.x) * cos(p.y));
	NORMAL = normalize(vec3(-slope.x, slope.y, 1.0));
}

void fragment() {
	// A coarse weave, darker where it's worn.
	float weave = 0.04 * sin(at.x * 260.0) * sin(at.y * 260.0);
	vec3 base = canvas * (1.0 + weave);
	base = mix(base, base * vec3(0.78, 0.66, 0.5), age * 0.6);
	ALBEDO = base;
	ROUGHNESS = 0.95;
	BACKLIGHT = vec3(0.3);
}
