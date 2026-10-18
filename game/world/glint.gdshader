shader_type spatial;
// A glint (Skyline): the sun off bare metal, glass or glaze, seen where the
// way it faces halves the angle between the sun and your eye, within how wide
// its sparkle sweeps. A smooth function of the sun, the surface and the eye,
// so it swells and fades as either moves and never strobes; a few pixels
// across whatever the distance, so it reads kilometres off. None in a storm,
// at it or on the way to it, and the haze dims it.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled,
	skip_vertex_transform;

#include "res://game/weather/storm_field.gdshaderinc"

// Toward the sun, engine axes; how much of it reaches here (risen, not
// behind Tu, no storm round you); its colour.
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform float glare = 0.0;
uniform vec3 sun_light = vec3(1.0, 0.95, 0.85);
uniform float peak_px = 12.0;
uniform float brightness = 6.0;
// The haze's begin and end, m, and the most of the view it hides.
uniform vec3 haze = vec3(400.0, 9000.0, 0.7);

varying float shine;

void vertex() {
	vec3 at = MODEL_MATRIX[3].xyz;
	vec3 to_eye = CAMERA_POSITION_WORLD - at;
	float d = length(to_eye);
	vec3 v = to_eye / max(d, 1.0e-3);
	vec3 n = normalize(INSTANCE_CUSTOM.xyz);
	// The cosine of how wide its sparkle sweeps.
	float edge = INSTANCE_CUSTOM.w;
	float a = dot(n, normalize(v + sun_dir));
	float g = smoothstep(edge, mix(edge, 1.0, 0.75), a) * step(0.0, dot(n, v)) * step(0.0, dot(n, sun_dir));
	float dust = 0.0;
	if (storm_map_ready > 0.5) {
		for (int k = 0; k <= 4; k++) {
			vec3 p = mix(at, CAMERA_POSITION_WORLD, float(k) / 4.0);
			dust = max(dust, smoothstep(-150.0, 0.0, storm_front(p.xz).x));
		}
	}
	g *= glare * (1.0 - dust) * (1.0 - clamp((d - haze.x) / (haze.y - haze.x), 0.0, 1.0) * haze.z);
	shine = g;
	// Off its own surface toward you, so what it lies on never hides it.
	vec3 c = (VIEW_MATRIX * vec4(at + v * min(0.6, d * 0.02), 1.0)).xyz;
	float px = 2.0 * -c.z / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y);
	float size = g > 0.003 ? px * mix(3.0, peak_px, sqrt(g)) * 0.5 : 0.0;
	VERTEX = c + vec3(VERTEX.xy * size, 0.0);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float core = exp(-dot(q, q) * 10.0);
	float rays = exp(-abs(q.x) * 22.0) * (1.0 - abs(q.y)) + exp(-abs(q.y) * 22.0) * (1.0 - abs(q.x));
	ALBEDO = sun_light * brightness * shine * (core + 0.45 * rays);
}
