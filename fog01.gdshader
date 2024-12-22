shader_type fog;

uniform sampler2D noise_tex:repeat_enable;
uniform float noise_scale = 1.0;
uniform float flatness = 1.0;

void fog() {
	vec2 move_uv = vec2(0.2, 0.0)*TIME;
	float noise = texture(noise_tex, WORLD_POSITION.xz*noise_scale + move_uv).r;
	DENSITY = mix(1.0, noise, UVW.y*flatness);
	DENSITY *= step(0.0, -SDF);
	ALBEDO = vec3(0.7, 0.6, 0.2);
}
