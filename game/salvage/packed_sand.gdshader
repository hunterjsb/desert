shader_type spatial;
// Sand the storms packed into a wreck's hold (Wreckage), a slice at a time:
// fine grain, and the thin darker lines each storm left as it laid a layer,
// level in the world whatever way the hold leans.

uniform vec3 sand : source_color = vec3(0.72, 0.57, 0.39);

varying vec3 world;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float grain = noise(world * 40.0) * 0.5 + noise(world * 9.0) * 0.5;
	// A storm's layer every few centimetres, wavering a little.
	float y = world.y * 9.0 + noise(world * vec3(1.5, 0.0, 1.5)) * 1.2;
	float line = smoothstep(0.82, 0.95, fract(y)) * (0.5 + 0.5 * noise(vec3(floor(y), 0.0, 0.0) * 3.1));
	vec3 c = sand * (0.88 + 0.16 * grain);
	c = mix(c, c * vec3(0.78, 0.72, 0.66), line * 0.55);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.2;
}
