shader_type spatial;
// Look-test D: cel shading. The sun lights a face in two flat steps and a
// warm rim, and the sky's ambient fills the shade, so a device reads as
// painted shapes rather than lit material.

uniform vec3 color : source_color = vec3(0.8, 0.75, 0.65);
uniform vec3 shade : source_color = vec3(0.55, 0.45, 0.5);
uniform float glow = 0.0;

void fragment() {
	ALBEDO = color;
	ROUGHNESS = 1.0;
	EMISSION = color * glow;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(0.0, 0.04, ndl) * mix(0.7, 1.0, smoothstep(0.45, 0.5, ndl)) * ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR * ALBEDO * mix(shade * 0.6, vec3(1.0), lit) / PI * 2.2;
	float rim = smoothstep(0.62, 0.68, 1.0 - dot(NORMAL, VIEW)) * lit;
	SPECULAR_LIGHT += LIGHT_COLOR * rim * 0.15;
}
