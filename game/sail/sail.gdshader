shader_type spatial;
render_mode cull_disabled;

// A sail's cloth on a unit grid: UV.x runs from the mast to its leech, UV.y
// from the boom to its head. Raised, it stands its full height, pressed it
// bellies to leeward; eased too far its luff lifts first, just behind the
// mast, the lifting spreading aft until the whole sail flogs. Torn, it's rags.

uniform float luff = 3.4;
uniform float foot = 2.3;
uniform float head = 1.0;
uniform vec3 cloth : source_color = vec3(0.86, 0.8, 0.68);
uniform vec3 seam : source_color = vec3(0.62, 0.36, 0.22);

instance uniform float raise = 1.0;
instance uniform float belly = 0.0;
instance uniform float flutter = 0.0;
instance uniform float torn = 0.0;
instance uniform float age = 0.0;

varying vec2 at;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	at = UV;
	float height = UV.y * luff * raise;
	float chord = mix(foot, head, UV.y);
	float full = sin(3.14159 * UV.x) * (0.35 + 0.65 * sin(3.14159 * clamp(UV.y * 1.15, 0.0, 1.0)));
	float luffing = clamp(flutter, 0.0, 1.0);
	float lifting = (1.0 - smoothstep(0.05, 0.2 + 0.8 * luffing, UV.x)) * smoothstep(0.0, 0.06, UV.x);
	float lifted = lifting * luffing;
	float ripple = flutter * (0.12 * lifting * sin(TIME * 19.0 + UV.y * 8.0 + UV.x * 14.0)
		+ 0.07 * luffing * luffing * UV.x * sin(TIME * 13.0 + UV.x * 9.0 + UV.y * 5.0));
	// Furled, what's left of it gathers along the boom.
	float gathered = 1.0 - smoothstep(0.0, 0.25, raise);
	VERTEX = vec3((belly * full * (1.0 - lifted) + ripple) * chord * (1.0 - gathered), height, -UV.x * chord);
	NORMAL = vec3(1.0, 0.0, belly * 0.6);
}

void fragment() {
	// Panels sewn across it, darker where the light comes through.
	float panel = step(0.97, fract(at.y * 7.0)) + step(0.985, fract(at.x * 3.0)) * 0.5;
	vec3 base = mix(cloth, seam, clamp(panel, 0.0, 1.0) * 0.6);
	base = mix(base, base * vec3(0.78, 0.66, 0.5), age * 0.6);
	if (torn > 0.0 && hash(floor(at * vec2(9.0, 14.0))) < torn) {
		discard;
	}
	ALBEDO = base;
	ROUGHNESS = 0.92;
	BACKLIGHT = vec3(0.35);
}
