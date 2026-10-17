// Storm walls and everything inside them, as one full-screen pass: a ray per
// pixel through the storm field, composited over the scene it reads back. The
// same field is drawn from the horizon to inside, so a face never changes
// renderer on the way in.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled, blend_mix;

#include "res://game/weather/storm_field.gdshaderinc"
#include "res://game/weather/shelter.gdshaderinc"

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
// Tu, which hides it: Tu's direction, the cosines of its edge outside and in,
// and how much of the sun shows past it, which the sun's glow follows.
uniform vec3 tu_dir = vec3(0.0, -1.0, 0.0);
uniform vec2 tu_edge = vec2(2.0, 3.0);
uniform float sun_shown = 1.0;
// The eclipse's ring of fire, a light from the sun's bearing like the sun's
// own; none outside an eclipse.
uniform vec3 ring_light = vec3(0.0);

// The shells round shelters, from Weather: each one's glow (1 steady, more
// as it blooms, less as it flickers), the light round the camera that their
// glass catches, and the shield's own colour.
uniform float shell_glow[SHELTER_MAX];
uniform vec3 shell_light = vec3(0.5);
// Sand Game's shield blue.
uniform vec3 shell_color = vec3(0.05, 0.41, 0.73);
// Past a shell the dust's gust parcels fade in over this far, so the murk
// pressed on the glass is even and the streaks on it carry the detail.
const float SHELL_CALM = 15.0;

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

// The ring's red light, thrown forward grain to grain, carries far deeper
// into the dust. Twin in StormFace.
float ring_through(float path) {
	return exp(-0.00015 * path);
}

// Dust throws light forward: the ring's makes a halo about its bearing and a
// broader glow round that. Twin in puff.gdshader and streak.gdshader.
float ring_phase(float c) {
	return 0.65 * phase_hg(c, 0.85) + 0.35 * phase_hg(c, 0.45);
}

// First t from t0 where the ray may be in a storm, or -1. The field's distance
// estimate strides through clear air, but it is first order: round a storm's
// end it overestimates, and a stride that leaps the storm whole makes the next
// pixel see the wall behind instead, a cut straight up the screen. So strides
// are capped, and wherever the ray closes on a front then turns away between
// two samples, the gap between them is walked finely.
float storm_entry(vec3 ro, vec3 rd, float t0, float t_end) {
	float t = t0;
	float prev = t0;
	float d_prev = 0.0;
	float slope_prev = 0.0;
	for (int i = 0; i < 64; i++) {
		vec3 f = storm_front((ro + rd * t).xz);
		float d = f.x + STORM_REACH;
		float slope = dot(f.yz, rd.xz);
		if (d <= 0.0 && i > 0 && slope_prev > 0.0 && slope < 0.0) {
			// The tangents from both ends meet at the nearest approach between.
			float tm = clamp((d - d_prev + slope_prev * prev - slope * t) / (slope_prev - slope), prev, t);
			if (d_prev + slope_prev * (tm - prev) > 0.0) {
				for (int k = 1; k <= 8; k++) {
					float tk = mix(prev, t, float(k) / 9.0);
					if (storm_front((ro + rd * tk).xz).x + STORM_REACH > 0.0) {
						t = tk;
						d = 1.0;
						break;
					}
				}
			}
		}
		if (d > 0.0) {
			if (i == 0) {
				return t0;
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
		d_prev = d;
		slope_prev = slope;
		t = min(t + clamp(-d * 0.6, max(25.0, t * 0.04), max(150.0, t * 0.05)), t_end);
	}
	return -1.0;
}

// Past any shelter the ray is inside at t: on to the far shell of each, until
// clear of them all.
float hole_exit(float t, vec2 spans[SHELTER_MAX]) {
	for (int k = 0; k < SHELTER_MAX; k++) {
		float past = t;
		for (int i = 0; i < shelter_count; i++) {
			if (t >= spans[i].x && t < spans[i].y) {
				past = max(past, spans[i].y);
			}
		}
		if (past == t) {
			break;
		}
		t = past;
	}
	return t;
}

// The nearest shell the ray enters past t; far off if none.
float hole_entry(float t, vec2 spans[SHELTER_MAX]) {
	float at = 1.0e9;
	for (int i = 0; i < shelter_count; i++) {
		if (spans[i].x > t && spans[i].y > spans[i].x) {
			at = min(at, spans[i].x);
		}
	}
	return at;
}

// The nearest shell crossing past t: where (far off if none), which shelter,
// and 1 if the ray enters it there, -1 if it leaves.
vec3 shell_after(float t, vec2 spans[SHELTER_MAX]) {
	vec3 best = vec3(1.0e9, 0.0, 0.0);
	for (int i = 0; i < shelter_count; i++) {
		if (spans[i].y > spans[i].x) {
			if (spans[i].x > t && spans[i].x < best.x) {
				best = vec3(spans[i].x, float(i), 1.0);
			}
			if (spans[i].y > t && spans[i].y < best.x) {
				best = vec3(spans[i].y, float(i), -1.0);
			}
		}
	}
	return best;
}

// A shell where the ray crosses it: faint glass in the shield's colour,
// brightest edge-on, and the storm's dust pressed on its outside. dust is the
// density just outside (1 is a storm's body) and lit its light. Returns the
// light it adds and how much of what's behind it hides.
vec4 shell_look(vec3 ro, vec3 rd, float tc, int i, float dust, vec3 lit) {
	vec3 p = ro + rd * tc;
	float r = shelters[i].w;
	vec3 n = (p - shelters[i].xyz) / r;
	// Nested inside another shelter, a shell has clear air on both sides.
	vec3 beyond = p + n * 0.05;
	for (int j = 0; j < shelter_count; j++) {
		vec3 d = beyond - shelters[j].xyz;
		if (j != i && dot(d, d) < shelters[j].w * shelters[j].w) {
			dust = 0.0;
		}
	}
	float facing = abs(dot(rd, n));
	float rim = 1.0 - facing;
	// Wind round a sphere runs along the meridians from the windward pole to
	// the lee, so the dust streams that way: streaks fanning out from where it
	// strikes, racing round and closing up behind. The meridian's arc from the
	// windward pole, and where round the pole it runs, place the streaks.
	vec3 wind = vec3(storm_wind_dir.x, 0.0, storm_wind_dir.y);
	float a = dot(n, wind);
	vec3 around = n - wind * a;
	float arc = r * acos(clamp(-a, -1.0, 1.0));
	// Fine and long: a hand's width across, metres along, racing at gust speed.
	vec2 round = vec2(around.y, dot(around, vec3(-wind.z, 0.0, wind.x))) * 6.0;
	float comb = texture(storm_noise, vec3(round, arc / 45.0 - storm_time * 0.45)).b * 0.65
		+ texture(storm_noise, vec3(round * 0.37, arc / 18.0 - storm_time * 0.9)).g * 0.35;
	// Thickest where it strikes, and while a bloom shoves the dust outward;
	// seen edge-on, the ray runs a long way through it.
	float flare = shell_glow[i] - 1.0;
	float coat = dust * (0.03 + 0.5 * smoothstep(0.5, 0.7, comb)) * (1.2 - 0.4 * a) * (1.0 + 0.25 * flare)
		/ max(facing, 0.15);
	float film = 1.0 - exp(-coat);
	float glass = 0.015 + 0.3 * pow(rim, 4.0);
	// A flicker dims it below steady, never past dark.
	vec3 sheen = shell_color * max(shell_light * 0.8 * rim * rim + 0.03 * (0.15 + pow(rim, 3.0))
		+ 0.04 * flare * (0.3 + rim * rim), vec3(0.0));
	// Grains on the glass are close and dense, so they catch more light than the murk.
	return vec4(film * lit * 1.6 + (1.0 - film) * sheen, 1.0 - (1.0 - film) * (1.0 - glass));
}

// Draws the shells the ray crosses past done, up to upto, nearest first, and
// returns how far it got. A shell entered is coated by the dust before it
// (dust_in, lit_in); one left, by the dust after it (dust_out, lit_out).
float draw_shells(vec3 ro, vec3 rd, vec2 spans[SHELTER_MAX], float done, float upto, float dust_in,
		vec3 lit_in, float dust_out, vec3 lit_out, inout vec3 light, inout float trans) {
	for (int k = 0; k < 2 * SHELTER_MAX; k++) {
		vec3 c = shell_after(done, spans);
		if (c.x > upto) {
			break;
		}
		vec4 shell = c.z > 0.0 ? shell_look(ro, rd, c.x, int(c.y), dust_in, lit_in)
			: shell_look(ro, rd, c.x, int(c.y), dust_out, lit_out);
		light += trans * shell.rgb;
		trans *= 1.0 - shell.a;
		done = c.x;
	}
	return done;
}

// Where a shell meets the sand, or anything standing in it, a thin band
// glows, as on Sand Game's shield.
vec3 shell_band(vec3 pg) {
	vec3 band = vec3(0.0);
	for (int i = 0; i < shelter_count; i++) {
		float d = abs(distance(pg, shelters[i].xyz) - shelters[i].w);
		band += shell_color * shell_glow[i] * (0.35 * exp(-d * 12.0) + 0.04 * exp(-d * 1.5));
	}
	return band;
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
	// Where the ray runs through each shelter: the march steps over them, and
	// draws their shells where it crosses.
	vec2 spans[SHELTER_MAX];
	for (int i = 0; i < SHELTER_MAX; i++) {
		spans[i] = i < shelter_count ? shelter_span(i, ro, rd) : vec2(0.0);
	}

	vec3 scene = texture(screen_tex, SCREEN_UV).rgb;
	if (z <= 0.0) {
		float c = dot(rd, sun_dir);
		float behind = smoothstep(tu_edge.x, tu_edge.y, dot(rd, tu_dir));
		scene += sun_disc * (smoothstep(0.99994, 0.99997, c) * (1.0 - behind)
			+ sun_shown * (0.015 * pow(max(c, 0.0), 700.0) + 0.003 * pow(max(c, 0.0), 40.0)));
	} else {
		if (storm_map_ready > 0.0) {
			// A storm's shadow on the ground, relative to the light already there.
			vec3 pg = ro + rd * scene_t;
			float tp = sun_through(storm_sun_path(pg, storm_front_exact(pg.xz), sun_dir));
			float lit = 1.0 - sun_share + sun_share * tp;
			scene *= lit / (1.0 - sun_share + sun_share * camera_sun);
		}
		scene += shell_band(ro + rd * scene_t);
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
	float t = t_end > 0.0 && storm_map_ready > 0.0 ? storm_entry(ro, rd, 0.0, t_end) : -1.0;
	// Stagger starts inside a storm a little, so steps never line up into bands.
	float jitter = 0.5 * fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	t += t == 0.0 ? jitter : 0.0;
	vec3 light = vec3(0.0);
	float trans = 1.0;
	// Where the ray first meets a face; the ground dust runs up to it.
	float face_t = min(scene_t, 4000.0);
	// Shells are drawn in order along the ray; up to here, they're done.
	float shells_done = 0.0;
	if (t >= 0.0) {
		float cos_sun = dot(rd, sun_dir);
		float phase = mix(1.0, phase_hg(cos_sun, 0.6), 0.45);
		vec3 ring_seen = ring_light * ring_phase(cos_sun);
		bool ring_on = ring_light.r > 0.0;
		float prev_t = t;
		vec4 head = vec4(0.5);
		// Step at which the march reached the storm it's in now.
		int since = 0;
		bool outside = true;
		float edge = -1.0;
		float sigma = 0.0;
		vec3 s = vec3(0.0);
		// The dust of the last step, which coats a shell the ray enters next.
		float dust_before = 0.0;
		vec3 lit_before = vec3(0.0);
		// Just out through a shell, where the march starts afresh, and where.
		bool through = false;
		float shell_t = -1.0e9;
		for (int i = 0; i < STEPS; i++) {
			// No dust inside a shelter: on from its far shell.
			float past = hole_exit(t, spans);
			if (past > t) {
				t = past;
				prev_t = t;
				through = true;
				shell_t = t;
			}
			if (t > t_end) {
				break;
			}
			// Fine near the camera, a few metres through the face, coarser far off.
			float fine = min(0.75 + t * 0.06, max(4.0, t * 0.004));
			// Small octaves only where their texels are bigger than a few pixels.
			vec2 lod = vec2(1.0 - smoothstep(500.0, 1600.0, t), 1.0 - smoothstep(120.0, 450.0, t));
			vec3 p = ro + rd * t;
			vec3 f = storm_front(p.xz);
			if (f.x + STORM_REACH < 0.0) {
				edge = f.x + STORM_REACH;
				sigma = 0.0;
			} else {
				head = storm_head_field(p);
				sigma = storm_density(p, f, lod, head, lod.y * smoothstep(0.0, SHELL_CALM, t - shell_t), edge);
			}
			if (edge < 0.0) {
				outside = true;
				// Out through a shell into clear air: no dust on that side of it.
				shells_done = draw_shells(ro, rd, spans, shells_done, t, dust_before, lit_before, 0.0, vec3(0.0),
					light, trans);
				dust_before = 0.0;
				through = false;
				if (f.x + STORM_REACH < 0.0) {
					// Past this storm's reach: look for the next one along the ray.
					float next = storm_entry(ro, rd, t, t_end);
					if (next < 0.0) {
						break;
					}
					prev_t = next;
					t = min(next + fine, hole_entry(next, spans));
					since = i;
					continue;
				}
				// Among the billows: the edge is roughly the distance to the face.
				// Strides grow with distance, and with a long run beside one
				// storm, so a ray grazing kilometres along its side still takes a
				// few dozen steps; the bisection above finds a surface exactly.
				// They stop at a shell, so a face is never looked for inside one.
				prev_t = t;
				t = min(t + max(fine, max(-edge * 0.45, t * 0.05)) * (1.0 + float(i - since) / 24.0),
					hole_entry(t, spans));
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
					if (storm_front(pm.xz).x + storm_bulge(pm, lod, head, top) < 0.0) {
						lo = mid;
					} else {
						hi = mid;
					}
				}
				t = hi;
				p = ro + rd * t;
				f = storm_front(p.xz);
				sigma = storm_density(p, f, lod, head, lod.y * smoothstep(0.0, SHELL_CALM, t - shell_t), edge);
			}
			if (outside) {
				face_t = min(face_t, t);
			}
			outside = false;
			// Thin dust and a long run in one storm take longer strides: the
			// thinner, the longer, so a kilometre of roof haze doesn't eat the
			// budget, and rays skimming a face still reach what's behind. The
			// run counts from this storm only: carried over from one passed on
			// the way, every ray that grazed it would sample the next wall
			// coarser than its neighbour, and the edge of that graze shows as
			// a straight cut.
			float thin = clamp(0.015 / max(sigma, 1.0e-4), 1.0, 6.0);
			float dt = fine * thin * (1.0 + float(i - since) / 48.0);
			if (through) {
				// Out through a shell the dust starts exactly there; the first
				// step is staggered instead, so steps never line up into bands.
				dt *= 0.5 + jitter;
				through = false;
			}
			// Steps stop at a shell, so the dust ends exactly on it.
			float t_next = min(t + dt, hole_entry(t, spans));
			dt = t_next - t;
			sigma *= 1.0 - smoothstep(far_fade.x, far_fade.y, t);
			bool shell_here = shell_after(shells_done, spans).x <= t;
			if (sigma > 1.0e-4) {
				float a = 1.0 - exp(-sigma * dt);
				// A wisp that adds next to nothing keeps the last light worked out;
				// it's refreshed every few steps, so a long run of thin dust
				// can't drift far from it.
				if (trans * a > 0.006 || (i & 3) == 0 || s == vec3(0.0) || shell_here) {
					// One tap toward the sun and one toward the open sky: billows shade
					// each other. Far off the taps reach further, so shading follows
					// the big masses rather than every lump. Both read the front
					// here and lean on its slope, rather than fetching the map again.
					float reach = max(1.0, t / 1500.0);
					vec3 open_dir = normalize(vec3(-f.y * 0.6, 0.8, -f.z * 0.6));
					vec3 to_sun = sun_dir * 45.0 * reach;
					vec3 to_open = open_dir * 40.0 * reach;
					float top;
					float e_sun = (f.x + dot(f.yz, to_sun.xz) + storm_bulge(p + to_sun, vec2(0.0), head, top)) / reach;
					float e_open = (f.x + dot(f.yz, to_open.xz) + storm_bulge(p + to_open, vec2(0.0), head, top)) / reach;
					// Shading stays soft, and flattens further off, so a wall reads as
					// one mass whichever way the sun falls, the billows as relief
					// moving within it.
					float relief = 1.0 - 0.6 * smoothstep(1000.0, 5000.0, t);
					// Depth for the sun counts from the billowed surface, so a lump set
					// back behind the front is lit like any other part of the face.
					float path = storm_sun_path(p, vec3(edge, f.yz), sun_dir);
					float sunward = mix(1.0 - 0.65 * relief, 1.0, exp(-max(e_sun, 0.0) * 0.04));
					float open = mix(1.0, exp(-max(e_open, 0.0) * 0.02), relief);
					float sky = mix(storm_glow, 1.0, open) * mix(0.6, 1.0, smoothstep(0.0, 600.0, p.y));
					// Thick parcels shade themselves; thin ones glow.
					sky *= mix(1.25, 0.8, smoothstep(0.05, 0.25, sigma));
					// The ring's light comes through scattered, so the billows don't shade it.
					s = dust_albedo * (sun_light * sun_through(path) * phase * sunward + sky_light * sky);
					if (ring_on) {
						s += dust_albedo * ring_seen * ring_through(path);
					}
					s = mix(s, haze_color, haze_at(t, p.y));
				}
				// Shells crossed on the way here sit in front of this step's dust.
				if (shell_here) {
					shells_done = draw_shells(ro, rd, spans, shells_done, t, dust_before, lit_before,
						sigma / storm_sigma, s, light, trans);
				}
				light += trans * a * s;
				trans *= 1.0 - a;
				if (trans < 0.004) {
					// Opaque: nothing behind shows, not even the sun.
					light += trans * s;
					trans = 0.0;
					break;
				}
			} else if (shell_here) {
				shells_done = draw_shells(ro, rd, spans, shells_done, t, dust_before, lit_before, 0.0, vec3(0.0),
					light, trans);
			}
			dust_before = sigma / storm_sigma;
			lit_before = s;
			t = t_next;
		}
		if (trans > 0.0 && edge > 30.0 && t < t_end) {
			// Out of steps deep in the body: the rest of the ray is more of the same.
			float a = 1.0 - exp(-sigma * (t_end - t));
			light += trans * a * s;
			trans *= 1.0 - a;
		}
	}
	// Shells past all the dust, in clear air.
	if (trans > 0.0) {
		draw_shells(ro, rd, spans, shells_done, scene_t, 0.0, vec3(0.0), 0.0, vec3(0.0), light, trans);
	}
	vec3 color = light + trans * scene;
	if (storm_skirt > 0.0 && storm_map_ready > 0.0) {
		float tau = storm_skirt_depth(ro, rd, face_t) * (1.0 - smoothstep(far_fade.x, far_fade.y, face_t));
		// None of the ground's dust is inside a shelter.
		tau *= 1.0 - shelter_length(ro, rd, face_t) / max(face_t, 1.0e-3);
		vec3 ps = ro + rd * face_t;
		ps.y = 3.0;
		float path = storm_sun_path(ps, storm_front_exact(ps.xz), sun_dir);
		float c = dot(rd, sun_dir);
		vec3 s = dust_albedo * (sun_light * sun_through(path) * mix(1.0, phase_hg(c, 0.6), 0.45)
			+ ring_light * ring_through(path) * ring_phase(c) + sky_light);
		s = mix(s, haze_color, haze_at(face_t * 0.7, 0.0));
		color = mix(color, s, 1.0 - exp(-tau));
	}
	ALBEDO = color;
	ALPHA = 1.0;
}
