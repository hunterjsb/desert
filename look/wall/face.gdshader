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

const int STEPS = 128;

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
		scene += sun_disc * (smoothstep(0.99994, 0.99997, c) + 0.015 * pow(max(c, 0.0), 700.0) + 0.003 * pow(max(c, 0.0), 40.0));
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
	// Stagger starts inside the storm a little, so steps never line up into bands.
	t += t == 0.0 ? 0.5 * fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715)))) : 0.0;
	vec3 light = vec3(0.0);
	float trans = 1.0;
	// Where the ray first meets the face; the ground dust runs up to it.
	float face_t = min(scene_t, 4000.0);
	if (t >= 0.0) {
		float cos_sun = dot(rd, sun_dir);
		float phase = mix(1.0, phase_hg(cos_sun, 0.6), 0.45);
		// Sky light comes from above and in front of the face.
		vec3 open_dir = normalize(vec3(0.0, 0.8, 0.6));
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
			// Small octaves only where their texels are bigger than a few pixels.
			vec2 lod = vec2(1.0 - smoothstep(500.0, 1600.0, t), 1.0 - smoothstep(120.0, 450.0, t));
			sigma = storm_density(qo + qd * t, lod, edge);
			if (edge < 0.0) {
				// Clear air: the edge is roughly the distance to the face. Strides
				// also grow with distance, so rays grazing along the face still
				// reach it far off instead of running out of steps.
				outside = true;
				prev_t = t;
				t += max(fine, max(-edge * 0.45, t * 0.03));
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
				t = hi;
				sigma = storm_density(qo + qd * t, lod, edge);
			}
			if (outside) {
				face_t = min(face_t, t);
			}
			outside = false;
			vec3 q = qo + qd * t;
			// Thin dust and a spent budget both take longer strides, so rays
			// skimming the face still reach what's behind.
			float dt = fine * (sigma < 0.01 ? 2.5 : 1.0) * (1.0 + float(i) / 48.0);
			if (sigma > 1.0e-4) {
				// One tap toward the sun and one toward the open sky: billows shade
				// each other. Far off the taps reach further, so shading follows
				// the big masses rather than every lump.
				float top;
				float reach = max(1.0, t / 1500.0);
				float e_sun = storm_edge(q + sq * 45.0 * reach, vec2(0.0), top) / reach;
				float e_open = storm_edge(q + open_dir * 40.0 * reach, vec2(0.0), top) / reach;
				// Shading stays soft: the wall reads as one mass, the billows as
				// relief moving within it.
				float sun_t = sun_through(storm_sun_path(q, sq)) * mix(0.35, 1.0, exp(-max(e_sun, 0.0) * 0.04));
				float open = exp(-max(e_open, 0.0) * 0.02);
				float sky = mix(storm_glow, 1.0, open) * mix(0.6, 1.0, smoothstep(0.0, 600.0, q.y));
				// Thick parcels shade themselves; thin ones glow.
				sky *= mix(1.25, 0.8, smoothstep(0.05, 0.25, sigma));
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
	vec3 color = light + trans * scene;
	if (storm_skirt > 0.0) {
		float tau = storm_skirt_depth(qo, qd, face_t);
		vec3 qs = qo + qd * face_t;
		qs.y = 3.0;
		float sun_t = sun_through(storm_sun_path(qs, sq));
		vec3 s = dust_albedo * (sun_light * sun_t * mix(1.0, phase_hg(dot(rd, sun_dir), 0.6), 0.45) + sky_light);
		s = mix(s, haze_color, haze_at(face_t * 0.7, 0.0));
		float a = 1.0 - exp(-tau);
		color = mix(color, s, a);
	}
	ALBEDO = color;
	ALPHA = 1.0;
}
