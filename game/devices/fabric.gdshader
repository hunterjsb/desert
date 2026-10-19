shader_type spatial;
render_mode cull_disabled, shadows_disabled;

// Fabric laced across a frame's face, on a grid standing out of it along +Z:
// the load the air puts across it (Faces) draws it taut and bellies it the way
// the air presses, deepest in the middle, the lacing holding its edges; slack,
// it flutters in the air going past, faster and harder the more of it. It
// takes no shadows: its own would band across a belly this deep.

uniform vec2 size = vec2(0.94, 0.94);
uniform vec3 canvas : source_color = vec3(0.78, 0.7, 0.55);

// How hard the air presses across it, signed out of its face: 1 is taut.
instance uniform float load = 0.0;
// The air going past it, m/s.
instance uniform float air = 0.0;
instance uniform float age = 0.0;

varying vec2 at;
// How far it's drawn taut, and how far from its lacing a place on it is, 0 to 1.
varying float taut;
varying float inward;

// How far it stands out of its face at a place on it, m.
float lift(vec2 uv, float belly, float stir, float rate) {
	vec2 p = uv * 3.14159;
	float held = sin(p.x) * sin(p.y);
	float flutter = stir * 0.03 * sin(TIME * rate + uv.x * 11.0 + uv.y * 4.0)
		+ stir * 0.015 * sin(TIME * rate * 1.7 - uv.y * 9.0);
	return (belly + flutter) * held;
}

void vertex() {
	at = UV;
	float pressed = clamp(abs(load), 0.0, 1.0);
	float belly = sign(load) * 0.1 * sqrt(pressed);
	float stir = (1.0 - pressed) * smoothstep(0.3, 5.0, air);
	float rate = 4.0 + air * 0.9;
	float here = lift(UV, belly, stir, rate);
	VERTEX.z += here;
	taut = sqrt(pressed);
	inward = sin(UV.x * 3.14159) * sin(UV.y * 3.14159);
	// Its slope either way across it, for the light: UV runs down its face.
	float e = 0.02;
	float along = (lift(UV + vec2(e, 0.0), belly, stir, rate) - here) / (e * size.x);
	float down = (lift(UV + vec2(0.0, e), belly, stir, rate) - here) / (e * size.y);
	NORMAL = normalize(vec3(-along, down, 1.0));
}

void fragment() {
	// Darker where it's worn; drawn taut, the cloth pulled in at its lacing
	// shades darker than its full belly.
	vec3 base = mix(canvas, canvas * vec3(0.78, 0.66, 0.5), age * 0.6);
	ALBEDO = base * mix(1.0, mix(0.72, 1.06, inward), taut);
	ROUGHNESS = 0.95;
	BACKLIGHT = vec3(0.3);
}
