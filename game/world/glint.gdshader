shader_type spatial;
// A glint (Skyline): the sun off bare metal, glass or glaze, seen where the
// way it faces halves the angle between the sun and your eye, within how wide
// its sparkle sweeps. A smooth function of the sun, the surface and the eye:
// it swells as they line up, twinkles slowly as the angle between them keeps
// turning, and fades, never strobing; big enough at any distance to catch
// out of the corner of the eye. None in a storm, at it or on the way to it,
// and the haze dims it; but what a storm has just laid bare glints through
// its dust from near (dust_reach): the dust glows all round, so it shines
// whichever way it faces you, coming and going as the dust thickens and thins.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled,
	skip_vertex_transform;

#include "res://game/weather/storm_field.gdshaderinc"

// Toward the sun, engine axes; how much of it reaches here (risen, not
// behind Tu, no storm round you); its colour.
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform float glare = 0.0;
uniform vec3 sun_light = vec3(1.0, 0.95, 0.85);
// Pixels across as it lights and at its brightest.
uniform vec2 sparkle_px = vec2(8.0, 16.0);
uniform float brightness = 6.0;
// A twinkle for each this many degrees the angle turns: seconds, as the sun goes.
uniform float twinkle_degrees = 1.2;
// As a landmark's stand-in is drawn larger (skyline.gdshader), its glints ride with it.
uniform vec2 landmark_px = vec2(4.0, 14.0);
uniform float landmark_fall = 0.3;
uniform vec2 landmark_near = vec2(380.0, 560.0);
// The haze's begin and end, m, and the most of the view it hides.
uniform vec3 haze = vec3(400.0, 9000.0, 0.7);
// Seen through a storm's dust out to this far, m (0: never); and the world's clock, s.
uniform float dust_reach = 0.0;
uniform float dust_time = 0.0;

varying float shine;
varying float turn;

float pixel_at(vec3 at, mat4 projection, vec2 viewport, vec3 eye) {
	return 2.0 * length(eye - at) / (abs(projection[1][1]) * viewport.y);
}

void vertex() {
	vec3 at = MODEL_MATRIX[3].xyz;
	vec4 mark = COLOR;
	if (mark.w != 0.0) {
		vec3 foot = at + mark.xyz;
		float fd = length(CAMERA_POSITION_WORLD - foot);
		float r = smoothstep(landmark_near.x, landmark_near.y, fd);
		float fpx = pixel_at(foot, PROJECTION_MATRIX, VIEWPORT_SIZE, CAMERA_POSITION_WORLD);
		float s = mix(1.0, max(1.0, landmark_px.y * pow(1000.0 / max(fd, 1.0), landmark_fall) * fpx / abs(mark.w)), r);
		at = foot + (at - foot) * s;
	}
	vec3 to_eye = CAMERA_POSITION_WORLD - at;
	float d = length(to_eye);
	vec3 v = to_eye / max(d, 1.0e-3);
	vec3 n = normalize(INSTANCE_CUSTOM.xyz);
	// The cosine of how wide its sparkle sweeps.
	float edge = INSTANCE_CUSTOM.w;
	float a = dot(n, normalize(v + sun_dir));
	float g = smoothstep(edge, mix(edge, 1.0, 0.75), a) * step(0.0, dot(n, v)) * step(0.0, dot(n, sun_dir));
	float dust = 0.0;
	if (dust_reach > 0.0) {
		a = dot(n, v);
		g = smoothstep(0.0, 0.6, a) * (0.75 + 0.25 * sin(dust_time * 1.3 + dot(at, vec3(0.37, 0.11, 0.53)) * 3.0));
		dust = smoothstep(dust_reach * 0.5, dust_reach, d);
	} else if (storm_map_ready > 0.5) {
		for (int k = 0; k <= 4; k++) {
			vec3 p = mix(at, CAMERA_POSITION_WORLD, float(k) / 4.0);
			dust = max(dust, smoothstep(-150.0, 0.0, storm_front(p.xz).x));
		}
	}
	g *= glare * (1.0 - dust) * (1.0 - clamp((d - haze.x) / (haze.y - haze.x), 0.0, 1.0) * haze.z);
	turn = degrees(acos(clamp(a, -1.0, 1.0))) / twinkle_degrees;
	shine = g * (0.7 + 0.3 * cos(turn * TAU));
	float px = pixel_at(at, PROJECTION_MATRIX, VIEWPORT_SIZE, CAMERA_POSITION_WORLD);
	float size = g > 0.02 ? px * mix(sparkle_px.x, sparkle_px.y, sqrt(g)) * 0.5 : 0.0;
	// Off its own surface toward you by its own size, so what it lies on,
	// drawn however wide, never hides it.
	vec3 c = (VIEW_MATRIX * vec4(at + v * min(0.6 + size, d * 0.05), 1.0)).xyz;
	VERTEX = c + vec3(VERTEX.xy * size, 0.0);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	// Its rays turn a little as it twinkles.
	float spin = 0.3 * sin(turn * TAU * 0.5);
	vec2 r = mat2(vec2(cos(spin), sin(spin)), vec2(-sin(spin), cos(spin))) * q;
	float core = exp(-dot(q, q) * 9.0);
	float rays = exp(-abs(r.x) * 9.0) * (1.0 - abs(r.y)) + exp(-abs(r.y) * 9.0) * (1.0 - abs(r.x));
	ALBEDO = sun_light * brightness * shine * (core + rays);
}
