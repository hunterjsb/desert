shader_type fog;

// Export a color picker
uniform vec4 albedo_color : source_color = vec4(0.8, 0.7, 0.5, 1.0);uniform sampler2D noise_tex : repeat_enable;
uniform float noise_scale = 1.0;
uniform float flatness = 1.0;

void fog() {
	vec2 move_uv = vec2(0.2, 0.0) * TIME;
	float noise = texture(noise_tex, WORLD_POSITION.xz * noise_scale + move_uv).r;
	DENSITY = mix(1.0, noise, UVW.y * flatness);
	DENSITY *= step(0.0, -SDF);
	ALBEDO = albedo_color.rgb;
}