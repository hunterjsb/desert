shader_type spatial;
// What stands far off (Skyline): a stand-in's boxes, unit cubes sized to
// each, or a line of bushes draped on the far ground, each vertex carrying
// its spread from the line's foot. Lit as the ground is, and never thinner
// on screen than thinnest_px either way, so what's kilometres off holds
// steady instead of breaking into bits as you move. A landmark's boxes
// (a mast, a tower) carry their foot and height: past the hand-over to the
// real thing they stand at least landmark_px wide and tall at a kilometre,
// shrinking more slowly than perspective beyond it, so the eye snags on one
// standing over the horizon.
render_mode cull_back, skip_vertex_transform;

uniform float thinnest_px = 2.0;
uniform bool draped = false;
// A line's leaves, linear, and how thick it's drawn at the least, px.
uniform vec3 leaf = vec3(0.21, 0.27, 0.22);
uniform float line_px = 3.0;
uniform vec2 landmark_px = vec2(4.0, 14.0);
// How a landmark's least size falls off with distance: as distance to this power.
uniform float landmark_fall = 0.3;
// Where the real thing hands over, m: the least size grows in between, and
// a landmark drawn over its own built ground goes before the first.
uniform vec2 landmark_near = vec2(380.0, 560.0);

varying vec3 tone;

// Metres a pixel spans at a world place. The projection's y is flipped for
// some renderers, so only its size counts.
float pixel_at(vec3 at, mat4 projection, vec2 viewport, vec3 eye) {
	return 2.0 * length(eye - at) / (abs(projection[1][1]) * viewport.y);
}

void vertex() {
	vec3 world;
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	if (draped) {
		vec3 foot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float px = pixel_at(foot, PROJECTION_MATRIX, VIEWPORT_SIZE, CAMERA_POSITION_WORLD);
		vec3 spread = CUSTOM0.xyz;
		float reach = length(spread);
		world = foot + (reach > 0.0 ? spread * max(1.0, line_px * px / reach) : vec3(0.0));
		tone = leaf;
	} else {
		vec3 centre = MODEL_MATRIX[3].xyz;
		mat3 axes = mat3(MODEL_MATRIX[0].xyz, MODEL_MATRIX[1].xyz, MODEL_MATRIX[2].xyz);
		float least = thinnest_px;
		vec4 mark = INSTANCE_CUSTOM;
		if (mark.w != 0.0) {
			vec3 foot = centre + mark.xyz;
			float d = length(CAMERA_POSITION_WORLD - foot);
			float r = smoothstep(landmark_near.x, landmark_near.y, d);
			float fall = pow(1000.0 / max(d, 1.0), landmark_fall);
			float px = pixel_at(foot, PROJECTION_MATRIX, VIEWPORT_SIZE, CAMERA_POSITION_WORLD);
			// Grown about its foot to stand as tall as a landmark must.
			float s = mix(1.0, max(1.0, landmark_px.y * fall * px / abs(mark.w)), r);
			centre = foot + (centre - foot) * s;
			axes *= s;
			least = mix(thinnest_px, landmark_px.x * fall, r);
			// Over its own built ground, it gives way to the real thing close in.
			if (mark.w < 0.0 && d < landmark_near.x) {
				axes = mat3(0.0);
			}
		}
		float px = pixel_at(centre, PROJECTION_MATRIX, VIEWPORT_SIZE, CAMERA_POSITION_WORLD);
		for (int i = 0; i < 3; i++) {
			float length_now = length(axes[i]);
			if (length_now > 0.0) {
				axes[i] *= max(1.0, least * px / length_now);
			}
		}
		world = centre + axes * VERTEX;
		tone = COLOR.rgb;
	}
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(normal, 0.0)).xyz);
}

void fragment() {
	ALBEDO = tone;
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
}
