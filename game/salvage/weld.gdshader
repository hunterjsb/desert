shader_type spatial;
// A plate's weld beads, one instance a cell of seam (Wreckage): the custom
// data's red is how hot it is from the cutter, green how far it's cut. Uncut,
// a dull bead; cutting, it glows from dull red to white; cut through, a dark
// kerf whose glow cools away.

uniform vec3 bead : source_color = vec3(0.42, 0.39, 0.34);
uniform vec3 kerf : source_color = vec3(0.03, 0.025, 0.02);

varying vec4 data;

void vertex() {
	data = INSTANCE_CUSTOM;
}

void fragment() {
	float heat = clamp(data.r, 0.0, 1.0);
	float cut = clamp(data.g, 0.0, 1.0);
	ALBEDO = mix(bead, kerf, step(0.999, cut));
	// Part cut: a little brighter, scored.
	ALBEDO = mix(ALBEDO, ALBEDO * 1.35, cut * (1.0 - step(0.999, cut)));
	METALLIC = 0.5;
	ROUGHNESS = 0.55;
	vec3 red = vec3(1.0, 0.18, 0.02);
	vec3 orange = vec3(1.0, 0.55, 0.12);
	vec3 white = vec3(1.0, 0.92, 0.75);
	vec3 glow = mix(red, orange, smoothstep(0.2, 0.6, heat));
	glow = mix(glow, white, smoothstep(0.75, 1.0, heat));
	EMISSION = glow * heat * heat * 4.0;
}
