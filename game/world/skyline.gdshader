shader_type spatial;
// What stands far off (Skyline): a stand-in's boxes, unit cubes sized to
// each and drawn at their own size in their coat's finish, or a line of
// bushes draped on the far ground, each vertex carrying its spread from the
// line's foot. Lit as the ground is. Nothing is drawn thinner on screen than
// thinnest_px, so what's kilometres off holds steady instead of breaking into
// bits as you move; a box widened past its own size on screen is drawn as
// much fainter, so it weighs on the eye as much as it would, and a lattice
// lets the sky through. A box drawn over its own built ground, where the real
// thing stands too, comes in across the hand-over as the real thing dithers
// away (Structure.view).
render_mode blend_mix, depth_draw_never, cull_back, skip_vertex_transform;

uniform float thinnest_px = 1.5;
uniform bool draped = false;
// A line's leaves, linear, and how thick it's drawn at the least, px.
uniform vec3 leaf = vec3(0.21, 0.27, 0.22);
uniform float line_px = 3.0;
// Where the real thing hands over to its stand-in, m: all real before the
// first, all stand-in past the second.
uniform vec2 handover = vec2(420.0, 500.0);

varying vec4 tone;
varying vec3 finish;

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
		tone = vec4(leaf, 1.0);
		finish = vec3(0.0, 0.9, 0.2);
	} else {
		vec3 centre = MODEL_MATRIX[3].xyz;
		mat3 axes = mat3(MODEL_MATRIX[0].xyz, MODEL_MATRIX[1].xyz, MODEL_MATRIX[2].xyz);
		float least = thinnest_px * pixel_at(centre, PROJECTION_MATRIX, VIEWPORT_SIZE, CAMERA_POSITION_WORLD);
		// Widened across the line of sight only, each way the screen runs:
		// how deep it is never shows.
		vec3 sight = normalize(centre - CAMERA_POSITION_WORLD);
		vec3 across = cross(sight, vec3(0.0, 1.0, 0.0));
		across = length(across) > 1e-3 ? normalize(across) : vec3(1.0, 0.0, 0.0);
		vec3 up = cross(across, sight);
		float wide = abs(dot(axes[0], across)) + abs(dot(axes[1], across)) + abs(dot(axes[2], across));
		float tall = abs(dot(axes[0], up)) + abs(dot(axes[1], up)) + abs(dot(axes[2], up));
		float by_wide = max(least / max(wide, 1e-4), 1.0);
		float by_tall = max(least / max(tall, 1e-4), 1.0);
		mat3 widen = mat3(1.0) + (by_wide - 1.0) * outerProduct(across, across) + (by_tall - 1.0) * outerProduct(up, up);
		world = centre + widen * (axes * VERTEX);
		tone = COLOR;
		tone.a /= by_wide * by_tall;
		if (INSTANCE_CUSTOM.x > 0.5) {
			tone.a *= smoothstep(handover.x, handover.y, length(CAMERA_POSITION_WORLD - centre));
		}
		finish = vec3(INSTANCE_CUSTOM.yz, 0.5);
	}
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(normal, 0.0)).xyz);
}

void fragment() {
	ALBEDO = tone.rgb;
	ALPHA = tone.a;
	METALLIC = finish.x;
	ROUGHNESS = finish.y;
	SPECULAR = finish.z;
}
