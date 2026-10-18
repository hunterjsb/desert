shader_type spatial;
// What stands far off (Skyline): a stand-in's boxes, unit cubes scaled to
// each, or a line of bushes draped on the far ground, each vertex carrying
// its spread from the line's foot. Lit as the ground is, and never thinner
// on screen than thinnest_px either way, so a mast or a line kilometres off
// holds steady instead of breaking into bits as you move.
render_mode cull_back;

uniform float thinnest_px = 1.5;
uniform bool draped = false;
// A line's leaves, linear.
uniform vec3 leaf = vec3(0.38, 0.46, 0.41);

varying vec3 tone;

// Metres a pixel spans at a world place.
float pixel_at(vec3 at, mat4 projection, vec2 viewport, vec3 eye) {
	return 2.0 * length(eye - at) / (projection[1][1] * viewport.y);
}

void vertex() {
	if (draped) {
		vec3 foot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float px = pixel_at(foot, PROJECTION_MATRIX, VIEWPORT_SIZE, CAMERA_POSITION_WORLD);
		vec3 spread = CUSTOM0.xyz;
		float reach = length(spread);
		VERTEX += reach > 0.0 ? spread * max(1.0, thinnest_px * px / reach) : vec3(0.0);
		tone = leaf;
	} else {
		float px = pixel_at(MODEL_MATRIX[3].xyz, PROJECTION_MATRIX, VIEWPORT_SIZE, CAMERA_POSITION_WORLD);
		vec3 size = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
		VERTEX *= max(vec3(1.0), thinnest_px * px / max(size, vec3(1.0e-4)));
		tone = COLOR.rgb;
	}
}

void fragment() {
	ALBEDO = tone;
	ROUGHNESS = 0.85;
	SPECULAR = 0.3;
}
