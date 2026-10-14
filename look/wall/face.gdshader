// The wall and everything inside it, as one full-screen pass: a ray per pixel
// through the storm field, composited over the scene it reads back. The same
// field is drawn from 5 km to inside, so the face never changes renderer.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled, blend_mix;

#include "res://look/wall/storm_field.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

// Light, from WallAtmosphere.
uniform vec3 sun_dir = vec3(0.0, 0.5, -0.86);
uniform vec3 sun_light = vec3(2.0);
uniform vec3 sky_light = vec3(0.8);
uniform vec3 dust_albedo = vec3(0.55, 0.3, 0.14);
// How bright the heart of the storm stays, from light scattered many times.
uniform float storm_glow = 0.18;
uniform vec3 haze_color = vec3(0.7, 0.55, 0.4);
// begin, end, strength, curve: the environment's depth fog, so the wall's base
// sits in the same haze as the ground beside it.
uniform vec4 haze = vec4(400.0, 9000.0, 0.7, 1.0);
uniform float haze_height = 700.0;
// The ground is lit partly by the sun; the storm's shadow takes away that part.
uniform float sun_share = 0.7;
uniform float camera_sun = 1.0;
// The sun's disc is drawn here, not by the sky, so the wall can cover it.
uniform vec3 sun_disc = vec3(14.0, 12.5, 10.5);

const int STEPS = 96;

float dither(vec2 p) {
	return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

float phase_hg(float c, float g) {
	float g2 = g * g;
	return (1.0 - g2) / pow(1.0 + g2 - 2.0 * g * c, 1.5);
}

float haze_at(float t, float h) {
	return pow(smoothstep(haze.x, haze.y, t), haze.w) * haze.z * exp(-max(h, 0.0) / haze_height);
}

float sun_through(float path) {
	// Two scattering orders: the straight path, then light that bounced through.
	return exp(-0.004 * path) + 0.3 * exp(-0.0008 * path);
}

// First t where the ray may be in the storm, or -1. The front is smooth, so
// coarse steps then bisection find it cheaply.
float storm_entry(vec3 qo, vec3 qd, float t_end) {
	float t = 0.0;
	float f = storm_front(qo.x) - qo.z + STORM_REACH;
	if (f > 0.0) {
		return 0.0;
	}
	for (int i = 0; i < 48; i++) {
		float tn = min(t + max(25.0, t * 0.12), t_end);
		vec3 q = qo + qd * tn;
		if (storm_front(q.x) - q.z + STORM_REACH > 0.0) {
			float lo = t;
			float hi = tn;
			for (int j = 0; j < 7; j++) {
				float mid = 0.5 * (lo + hi);
				vec3 qm = qo + qd * mid;
				if (storm_front(qm.x) - qm.z + STORM_REACH > 0.0) {
					hi = mid;
				} else {
					lo = mid;
				}
			}
			return lo;
		}
		if (tn >= t_end) {
			break;
		}
		t = tn;
	}
	return -1.0;
}

void vertex() {
	// Pinned to the screen; reverse-Z puts 1.0 at the near plane.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 ndc = SCREEN_UV * 2.0 - 1.0;
	float z = texture(depth_tex, SCREEN_UV).r;
	vec4 near_p = INV_PROJECTION_MATRIX * vec4(ndc, 1.0, 1.0);
	vec3 view_dir = normalize(near_p.xyz / near_p.w);
	float scene_t = 4.0e4;
	if (z > 0.0) {
		vec4 vp = INV_PROJECTION_MATRIX * vec4(ndc, z, 1.0);
		scene_t = length(vp.xyz / vp.w);
	}
	vec3 rd = normalize((INV_VIEW_MATRIX * vec4(view_dir, 0.0)).xyz);
	vec3 ro = CAMERA_POSITION_WORLD;
	vec3 qo = storm_frame(ro);
	vec3 qd = storm_frame_dir(rd);
	vec3 sq = storm_frame_dir(sun_dir);

	vec3 scene = texture(screen_tex, SCREEN_UV).rgb;
	if (z <= 0.0) {
		float c = dot(rd, sun_dir);
		scene += sun_disc * (smoothstep(0.99994, 0.99997, c) + 0.01 * pow(max(c, 0.0), 400.0));
	} else {
		// The storm's shadow on the ground, relative to the light already there.
		float tp = sun_through(storm_sun_path(qo + qd * scene_t, sq));
		float lit = 1.0 - sun_share + sun_share * min(tp, 1.0);
		scene *= lit / (1.0 - sun_share + sun_share * camera_sun);
	}

	// Rays that climb out over the roof never come back.
	float roof_max = storm_height + 600.0;
	float t_end = scene_t;
	if (qd.y > 0.0) {
		t_end = min(t_end, max(0.0, (roof_max - qo.y) / qd.y));
	} else if (qo.y > roof_max) {
		t_end = 0.0;
	}
	float t = t_end > 0.0 ? storm_entry(qo, qd, t_end) : -1.0;
	vec3 light = vec3(0.0);
	float trans = 1.0;
	if (t >= 0.0) {
		float cos_sun = dot(rd, sun_dir);
		float phase = mix(1.0, phase_hg(cos_sun, 0.6), 0.45);
		// Sky light comes from above and in front of the face.
		vec3 open_dir = normalize(vec3(0.0, 0.8, 0.6));
		float jitter = dither(FRAGCOORD.xy);
		float prev_t = t;
		bool outside = true;
		float edge = -1.0;
		float sigma = 0.0;
		vec3 s = vec3(0.0);
		for (int i = 0; i < STEPS; i++) {
			if (t > t_end) {
				break;
			}
			// Fine near the camera, a few metres through the face, coarser far off.
			float fine = min(0.5 + t * 0.05, max(4.0, t * 0.004));
			vec2 lod = vec2(1.0 - smoothstep(1500.0, 4000.0, t), 1.0 - smoothstep(150.0, 600.0, t));
			sigma = storm_density(qo + qd * t, lod, edge);
			if (edge < 0.0) {
				// Clear air: the edge is roughly the distance to the face.
				outside = true;
				prev_t = t;
				t += max(fine, -edge * 0.4);
				continue;
			}
			if (outside && i > 0) {
				// Just stepped into the face: find its surface, so it never bands.
				float lo = prev_t;
				float hi = t;
				for (int j = 0; j < 6; j++) {
					float mid = 0.5 * (lo + hi);
					float top;
					if (storm_edge(qo + qd * mid, lod, top) < 0.0) {
						lo = mid;
					} else {
						hi = mid;
					}
				}
				t = hi + fine * jitter;
				sigma = storm_density(qo + qd * t, lod, edge);
			}
			outside = false;
			vec3 q = qo + qd * t;
			float dt = sigma < 0.01 ? fine * 2.5 : fine;
			if (sigma > 1.0e-4) {
				// One tap toward the sun and one toward the open sky: billows shade each other.
				float top;
				float e_sun = storm_edge(q + sq * 45.0, vec2(0.0), top);
				float e_open = storm_edge(q + open_dir * 40.0, vec2(0.0), top);
				float sun_t = sun_through(storm_sun_path(q, sq)) * exp(-max(e_sun, 0.0) * 0.04);
				float open = exp(-max(e_open, 0.0) * 0.02);
				float sky = mix(storm_glow, 1.0, open) * mix(0.55, 1.0, smoothstep(0.0, 600.0, q.y));
				// Thick parcels shade themselves; thin ones glow.
				sky *= mix(1.6, 0.6, smoothstep(0.05, 0.25, sigma));
				s = dust_albedo * (sun_light * sun_t * phase + sky_light * sky);
				s = mix(s, haze_color, haze_at(t, q.y));
				float a = 1.0 - exp(-sigma * dt);
				light += trans * a * s;
				trans *= 1.0 - a;
				if (trans < 0.004) {
					// Opaque: nothing behind shows, not even the sun.
					light += trans * s;
					trans = 0.0;
					break;
				}
			}
			t += dt;
		}
		if (trans > 0.0 && edge > 30.0 && t < t_end) {
			// Out of steps deep in the body: the rest of the ray is more of the same.
			float a = 1.0 - exp(-sigma * (t_end - t));
			light += trans * a * s;
			trans *= 1.0 - a;
		}
	}
	ALBEDO = light + trans * scene;
	ALPHA = 1.0;
}
