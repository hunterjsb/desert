// Storm walls and everything inside them, as one full-screen pass: a ray per
// pixel through the storm field, composited over the scene it reads back. The
// same field is drawn from the horizon to inside, so a face never changes
// renderer on the way in.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled, blend_mix;

#include "res://game/weather/storm_field.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

// Light, from Weather.
uniform vec3 sun_dir = vec3(0.0, 0.5, -0.86);
uniform vec3 sun_light = vec3(2.0);
uniform vec3 sky_light = vec3(0.8);
uniform vec3 dust_albedo = vec3(0.55, 0.3, 0.14);
// How bright the heart of a storm stays, from light scattered many times.
uniform float storm_glow = 0.3;
uniform vec3 haze_color = vec3(0.7, 0.55, 0.4);
// begin, end, strength: the environment's depth fog, so a wall's foot sits in
// the same haze as the ground beside it.
uniform vec3 haze = vec3(400.0, 9000.0, 0.7);
uniform float haze_height = 700.0;
// Walls dissolve into the haze between these distances.
uniform vec2 far_fade = vec2(11000.0, 15000.0);
// The ground is lit partly by the sun; a storm's shadow takes away that part.
uniform float sun_share = 0.7;
uniform float camera_sun = 1.0;
// The sun's disc is drawn here, not by the sky, so a wall can cover it.
uniform vec3 sun_disc = vec3(14.0, 12.5, 10.5);

const int STEPS = 128;

float phase_hg(float c, float g) {
	float g2 = g * g;
	return (1.0 - g2) / pow(1.0 + g2 - 2.0 * g * c, 1.5);
}

float haze_at(float t, float h) {
	return smoothstep(haze.x, haze.y, t) * haze.z * exp(-max(h, 0.0) / haze_height);
}

// Twin in StormFace.
float sun_through(float path) {
	// Two scattering orders: the straight path, then light that bounced through.
	return min(1.0, exp(-0.004 * path) + 0.3 * exp(-0.0008 * path));
}

// First t where the ray may be in a storm, or -1. The field is smooth, so its
// distance estimate strides through clear air, then bisection finds the spot.
float storm_entry(vec3 ro, vec3 rd, float t_end) {
	float t = 0.0;
	float prev = 0.0;
	for (int i = 0; i < 64; i++) {
		float d = storm_front((ro + rd * t).xz).x + STORM_REACH;
		if (d > 0.0) {
			if (i == 0) {
				return 0.0;
			}
			float lo = prev;
			float hi = t;
			for (int j = 0; j < 7; j++) {
				float mid = 0.5 * (lo + hi);
				if (storm_front((ro + rd * mid).xz).x + STORM_REACH > 0.0) {
					hi = mid;
				} else {
					lo = mid;
				}
			}
			return lo;
		}
		if (t >= t_end) {
			break;
		}
		prev = t;
		// A first-order distance can overshoot round a bend, so stride short of it.
		t = min(t + max(max(25.0, t * 0.04), -d * 0.6), t_end);
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

	vec3 scene = texture(screen_tex, SCREEN_UV).rgb;
	if (z <= 0.0) {
		float c = dot(rd, sun_dir);
		scene += sun_disc * (smoothstep(0.99994, 0.99997, c) + 0.015 * pow(max(c, 0.0), 700.0)
			+ 0.003 * pow(max(c, 0.0), 40.0));
	} else if (storm_map_ready > 0.0) {
		// A storm's shadow on the ground, relative to the light already there.
		vec3 pg = ro + rd * scene_t;
		float tp = sun_through(storm_sun_path(pg, storm_front(pg.xz), sun_dir));
		float lit = 1.0 - sun_share + sun_share * tp;
		scene *= lit / (1.0 - sun_share + sun_share * camera_sun);
	}

	// Rays that climb out over the roof never come back, and walls past the far
	// fade are haze.
	float roof_max = storm_height + storm_roof_soft + 400.0;
	float t_end = min(scene_t, far_fade.y);
	if (rd.y > 0.0) {
		t_end = min(t_end, max(0.0, (roof_max - ro.y) / rd.y));
	} else if (ro.y > roof_max) {
		t_end = 0.0;
	}
	float t = t_end > 0.0 && storm_map_ready > 0.0 ? storm_entry(ro, rd, t_end) : -1.0;
	// Stagger starts inside a storm a little, so steps never line up into bands.
	t += t == 0.0 ? 0.5 * fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715)))) : 0.0;
	vec3 light = vec3(0.0);
	float trans = 1.0;
	// Where the ray first meets a face; the ground dust runs up to it.
	float face_t = min(scene_t, 4000.0);
	if (t >= 0.0) {
		float cos_sun = dot(rd, sun_dir);
		float phase = mix(1.0, phase_hg(cos_sun, 0.6), 0.45);
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
			vec3 p = ro + rd * t;
			vec3 f = storm_front(p.xz);
			sigma = storm_density(p, f, lod, edge);
			if (edge < 0.0) {
				// Clear air: the edge is roughly the distance to the face. Strides
				// also grow with distance, so rays grazing along a face still
				// reach it far off instead of running out of steps.
				outside = true;
				prev_t = t;
				t += max(fine, max(-edge * 0.45, t * 0.03));
				continue;
			}
			if (outside && i > 0) {
				// Just stepped into a face: find its surface, so it never bands.
				float lo = prev_t;
				float hi = t;
				for (int j = 0; j < 6; j++) {
					float mid = 0.5 * (lo + hi);
					vec3 pm = ro + rd * mid;
					float top;
					if (storm_front(pm.xz).x + storm_bulge(pm, lod, top) < 0.0) {
						lo = mid;
					} else {
						hi = mid;
					}
				}
				t = hi;
				p = ro + rd * t;
				f = storm_front(p.xz);
				sigma = storm_density(p, f, lod, edge);
			}
			if (outside) {
				face_t = min(face_t, t);
			}
			outside = false;
			// Thin dust and a spent budget both take longer strides, so rays
			// skimming a face still reach what's behind.
			float dt = fine * (sigma < 0.01 ? 2.5 : 1.0) * (1.0 + float(i) / 48.0);
			sigma *= 1.0 - smoothstep(far_fade.x, far_fade.y, t);
			if (sigma > 1.0e-4) {
				// One tap toward the sun and one toward the open sky: billows shade
				// each other. Far off the taps reach further, so shading follows
				// the big masses rather than every lump. Both read the front
				// here and lean on its slope, rather than fetching the map again.
				float reach = max(1.0, t / 1500.0);
				vec3 open_dir = normalize(vec3(-f.y * 0.6, 0.8, -f.z * 0.6));
				vec3 to_sun = sun_dir * 45.0 * reach;
				vec3 to_open = open_dir * 40.0 * reach;
				float top;
				float e_sun = (f.x + dot(f.yz, to_sun.xz) + storm_bulge(p + to_sun, vec2(0.0), top)) / reach;
				float e_open = (f.x + dot(f.yz, to_open.xz) + storm_bulge(p + to_open, vec2(0.0), top)) / reach;
				// Shading stays soft: the wall reads as one mass, the billows as
				// relief moving within it.
				// Far off the relief flattens out, so a distant wall stays one mass
				// whichever way the sun falls on it.
				float relief = 1.0 - 0.6 * smoothstep(1000.0, 5000.0, t);
				// Depth for the sun counts from the billowed surface, so a lump set
				// back behind the front is lit like any other part of the face.
				float sun_t = sun_through(storm_sun_path(p, vec3(edge, f.yz), sun_dir))
					* mix(1.0 - 0.65 * relief, 1.0, exp(-max(e_sun, 0.0) * 0.04));
				float open = mix(1.0, exp(-max(e_open, 0.0) * 0.02), relief);
				float sky = mix(storm_glow, 1.0, open) * mix(0.6, 1.0, smoothstep(0.0, 600.0, p.y));
				// Thick parcels shade themselves; thin ones glow.
				sky *= mix(1.25, 0.8, smoothstep(0.05, 0.25, sigma));
				s = dust_albedo * (sun_light * sun_t * phase + sky_light * sky);
				s = mix(s, haze_color, haze_at(t, p.y));
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
	if (storm_skirt > 0.0 && storm_map_ready > 0.0) {
		float tau = storm_skirt_depth(ro, rd, face_t) * (1.0 - smoothstep(far_fade.x, far_fade.y, face_t));
		vec3 ps = ro + rd * face_t;
		ps.y = 3.0;
		float sun_t = sun_through(storm_sun_path(ps, storm_front(ps.xz), sun_dir));
		vec3 s = dust_albedo * (sun_light * sun_t * mix(1.0, phase_hg(dot(rd, sun_dir), 0.6), 0.45) + sky_light);
		s = mix(s, haze_color, haze_at(face_t * 0.7, 0.0));
		color = mix(color, s, 1.0 - exp(-tau));
	}
	ALBEDO = color;
	ALPHA = 1.0;
}
