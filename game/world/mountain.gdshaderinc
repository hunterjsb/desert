// Sand thins over the high, sloping bedrock; sheltered summit flats retain it.
uniform vec3 mountain_rock : source_color = vec3(0.38, 0.34, 0.30);
uniform vec2 mountain_rock_height = vec2(60.0, 180.0);
vec3 mountain_colour(vec3 sand_colour, float height, vec3 normal) {
	float grade = length(normal.xz) / max(normal.y, 0.05);
	float bare = smoothstep(mountain_rock_height.x, mountain_rock_height.y, height) * smoothstep(0.04, 0.20, grade);
	float beds = 0.96 + 0.04 * cos(height * 0.09);
	return mix(sand_colour, mountain_rock * beds, bare);
}
