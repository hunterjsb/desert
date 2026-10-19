// A plume (Plume) as the storms are drawn: the column of dust a vent's gas
// lifts, marched as a volume round the streakline worked out on the main
// thread, its face billowed with the storm walls' noise and lit as they are,
// in the same haze. Near you it dissolves, and the air you stand in takes
// over (Weather's fog, Atmosphere's grit). A storm's dust between you and it
// hides it, from inside one all of it, and only what towers over a storm's
// roof shows over it.
shader_type spatial;
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_front, fog_disabled, shadows_disabled, skip_vertex_transform;

#include "res://game/weather/storm_field.gdshaderinc"

// Plume.COLUMN's size.
const int POINTS = 15;
// Steps through it at most, each this share of its width there, or of the
// distance, never under the third, m; and the share of its width its billows
// stand out past it at most (Plume.BILLOWS).
const int STEPS = 48;
const vec3 STEP = vec3(0.22, 0.004, 4.0);
const float BILLOWS = 0.39;
// Its shaded side keeps this share of the sun's light, scattered on through
// the dust, as a storm wall's does; and the shading flattens off over these,
// m, so it reads as one mass far off.
const float SHADED = 0.35;
const vec2 RELIEF = vec2(1000.0, 5000.0);
// The billows churn up the column this fast, m/s, and ride it in the air's
// frame. The noise's tile spans this many of its widths for the big ones,
// never under the second, m (a billow is about a fifth of a tile, as on a
// wall), the small ones a third of that; and they stand out this share of
// its width, the small this.
const float CHURN = 3.0;
const vec2 BILLOW_SIZE = vec2(4.0, 800.0);
const vec2 BILLOW_RISE = vec2(0.35, 0.15);
// The noise mostly sits near its middle, a crease to storm_billow: a wall's
// big amplitudes hide that, but on a column it would leave smooth stretches,
// so its billow is read this much harder, unclamped, so none goes flat.
const float BILLOW_CONTRAST = 1.6;
// Its face softens over this share of its width; however dense, its dust
// takes this many optical depths a width at most, so a face builds over a
// few steps and shows its billows, not where a step happened to land.
const float SKIN = 0.2;
const float DENSEST = 2.5;
// Near you it isn't drawn: it dissolves over these, m, into the air round you.
const vec2 NEAR = vec2(120.0, 500.0);
// Twin of storm_face's roof_max over the wall: rays above it meet no dust, m.
const float ROOF_OVER = 400.0;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 root;
// Each point of the column: its place from the root, m, and its width; its
// dust a metre at its core, its depth for its width, how much shows past
// storms the storm map doesn't reach, and the sun left on it there; its ash,
// and whether the stretch on to the next is drawn (0 where a burst began
// between them, whose first gas, thin, joins the two).
uniform vec4 shape[POINTS];
uniform vec4 dust[POINTS];
uniform vec2 ashen[POINTS];
// Its bounds from the root, m.
uniform vec3 box_lo;
uniform vec3 box_hi;
// Drawn nearer past the first, m; dissolving into the distance between the others.
uniform vec3 reach = vec3(4200.0, 30000.0, 45000.0);
// Past the skyline's reach, m, a landmark: the haze takes it as if it were
// only as far as distance to this power says.
uniform vec2 landmark = vec2(3000.0, 0.3);
// The storm walls fade out between these: past them the main thread's reads
// say what storms hide it.
uniform vec2 far_fade = vec2(11000.0, 15000.0);

// Light, from Weather, as the storm walls take it.
uniform vec3 sun_dir = vec3(0.0, 0.5, -0.86);
uniform vec3 sun_light = vec3(2.0);
uniform vec3 sky_light = vec3(0.8);
uniform vec3 ring_light = vec3(0.0);
uniform vec3 tu_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 tu_light = vec3(0.0);
uniform vec3 dust_albedo = vec3(0.55, 0.3, 0.14);
uniform float storm_glow = 0.3;
uniform vec3 haze_color = vec3(0.7, 0.55, 0.4);
uniform vec3 haze = vec3(400.0, 9000.0, 0.7);
uniform float haze_height = 700.0;
// Basalt ash, its faint trace at a burst's core.
const vec3 ASH = vec3(0.075, 0.068, 0.062);

float phase_hg(float c, float g) {
	float g2 = g * g;
	return (1.0 - g2) / pow(1.0 + g2 - 2.0 * g * c, 1.5);
}

// Twins of storm_face.gdshader's.
float ring_phase(float c) {
	return 0.65 * phase_hg(c, 0.85) + 0.35 * phase_hg(c, 0.45);
}

float sun_through(float path) {
	return min(1.0, exp(-0.004 * path) + 0.3 * exp(-0.0008 * path));
}

float haze_at(float t, float h) {
	return smoothstep(haze.x, haze.y, t) * haze.z * exp(-max(h, 0.0) / haze_height);
}

// First t along the ray where a storm's dust is, behind its billowed face
// and under its billowed top as the storm pass draws them, up to t_end; or
// far off. The front's distance strides it through clear air.
float storm_first(vec3 ro, vec3 rd, float t_end) {
	if (storm_map_ready <= 0.0) {
		return 1.0e9;
	}
	float roof = storm_height + storm_roof_soft + ROOF_OVER;
	float t = 0.0;
	for (int i = 0; i < 32; i++) {
		vec3 p = ro + rd * t;
		if (p.y > roof) {
			if (rd.y >= 0.0) {
				return 1.0e9;
			}
			t = (roof - ro.y) / rd.y;
			p = ro + rd * t;
		}
		if (t > t_end) {
			return 1.0e9;
		}
		vec3 f = storm_front(p.xz);
		float d = f.x + STORM_REACH;
		if (d > 0.0) {
			float top;
			float edge = f.x + storm_bulge(p, vec2(0.0), storm_head_field(p), top);
			if (edge > 0.0 && p.y < top + 0.5 * storm_roof_soft) {
				return t;
			}
			d = min(edge, -1.0);
		}
		t += clamp(-d * 0.8, 20.0 + t * 0.01, 2000.0);
	}
	return 1.0e9;
}

// Metres inside the column's smooth surface at p, t along the ray (negative
// outside), by its nearest stretch of those whose sphere the ray is in there
// (spans, where along the ray it's in each); that stretch's offset from its
// axis, width, dust, depth for its width, which it is and how far along; and
// how far it's safe to stride, m: as near as any stretch's billows may come,
// or the next sphere starts.
float column(vec3 p, float t, vec2 spans[POINTS - 1], out vec3 q, out float width, out float sigma, out float squash,
		out int k, out float along, out float clear) {
	float best = 1.0e9;
	clear = 1.0e9;
	q = vec3(0.0);
	width = 1.0;
	sigma = 0.0;
	squash = 1.0;
	k = 0;
	along = 0.0;
	for (int j = 0; j < POINTS - 1; j++) {
		if (t < spans[j].x || t > spans[j].y) {
			if (spans[j].x > t) {
				clear = min(clear, spans[j].x - t);
			}
			continue;
		}
		vec3 a = root + shape[j].xyz;
		vec3 ab = shape[j + 1].xyz - shape[j].xyz;
		float h = clamp(dot(p - a, ab) / max(dot(ab, ab), 1.0e-3), 0.0, 1.0);
		vec3 off = p - a - ab * h;
		float w = mix(shape[j].w, shape[j + 1].w, h);
		// Levelled, it's deeper than wide no longer: an umbrella, flat.
		float sq = max(mix(dust[j].y, dust[j + 1].y, h), 0.2);
		float d = length(vec3(off.x, off.y / sq, off.z)) - w;
		// Measured flattened, a distance is too long by up to 1 / sq.
		clear = min(clear, (d - w * BILLOWS) * sq);
		if (d < best) {
			best = d;
			q = off;
			width = w;
			squash = sq;
			sigma = mix(dust[j].x, dust[j + 1].x, h);
			k = j;
			along = h;
		}
	}
	return -best;
}

// storm_billow's domes and creases, read harder.
float harder(float n) {
	float x = (2.0 * n - 1.0) * BILLOW_CONTRAST;
	return (sqrt(x * x + 0.02) - 0.35) / BILLOW_CONTRAST;
}

// How far its billowed face stands out past its smooth one at p, in widths:
// the storm walls' billows, big ones about its width across churning slowly
// up it, smaller ones on them.
float billow(vec3 p, float width) {
	vec3 q = vec3(p.x + storm_air.x, p.y - storm_time * CHURN, p.z + storm_air.y);
	float big = max(width * BILLOW_SIZE.x, BILLOW_SIZE.y);
	vec4 w = texture(storm_noise, STORM_TILT_B * q / (big * 1.6));
	vec3 qw = q + (w.rga - 0.5) * big * 0.12;
	float n1 = texture(storm_noise, STORM_TILT_A * qw / big).g;
	float n2 = texture(storm_noise, STORM_TILT_B * (qw - vec3(0.0, storm_time * CHURN, 0.0)) / (big * 0.33)).b;
	return BILLOW_RISE.x * harder(n1) + BILLOW_RISE.y * harder(n2);
}



// The light a step of it sends back toward the eye, as a storm wall's: the
// sun's through what of the column lies its way, and through any storm's;
// the sky's, less deep inside; the ring's thrown forward; Tu's at night;
// and the haze between.
// The column's way at a point, from its neighbours either side.
vec3 tangent(int j) {
	vec3 d = shape[min(j + 1, POINTS - 1)].xyz - shape[max(j - 1, 0)].xyz;
	return length(d) > 1.0e-3 ? normalize(d) : vec3(0.0, 1.0, 0.0);
}

vec3 lit(vec3 p, vec3 rd, float t, vec3 q, float width, float squash, float sigma, float inside, float bulge, int k,
		float along) {
	float c = dot(rd, sun_dir);
	// Its way here, turning smoothly from one stretch to the next.
	vec3 axis = normalize(mix(tangent(k), tangent(k + 1), along));
	// The sun's way out of the column from here, as through one this wide
	// and, levelled, this flat.
	vec3 flat_by = vec3(1.0, 1.0 / squash, 1.0);
	vec3 across = (sun_dir - axis * dot(sun_dir, axis)) * flat_by;
	vec3 qf = q * flat_by;
	float a2 = dot(across, across);
	float qa = dot(qf, across);
	float out_m = a2 > 1.0e-4 ? (-qa + sqrt(max(qa * qa - a2 * (dot(qf, qf) - width * width), 0.0))) / a2 : width;
	float relief = 1.0 - 0.6 * smoothstep(RELIEF.x, RELIEF.y, t);
	float own = mix(1.0 - (1.0 - SHADED) * relief, 1.0, exp(-sigma * max(out_m, 0.0)));
	// Billows shade each other, as on a wall: how far in the face still is a
	// little way toward the sun; far off, it's one mass.
	vec3 out_dir = length(q) > 1.0e-3 ? normalize(q) : vec3(0.0, 1.0, 0.0);
	if (t < RELIEF.y) {
		float reach_m = 0.08 * width;
		float toward = inside - dot(out_dir, sun_dir) * reach_m + width * (billow(p + sun_dir * reach_m, width) - bulge);
		own *= mix(1.0 - 0.65 * relief, 1.0, exp(-max(toward, 0.0) / reach_m));
	}
	float storms = t < far_fade.y && storm_map_ready > 0.0
		? sun_through(storm_sun_path(p, storm_front(p.xz), sun_dir)) : mix(dust[k].w, dust[k + 1].w, along);
	float sun = own * storms;
	// Deep in its billows the open sky is hidden, as in a wall's.
	float open = mix(1.0, exp(-max(inside, 0.0) / (40.0 * max(1.0, t / 1500.0))), relief);
	// The creases between billows see less of the sky than their domes.
	float sky = mix(storm_glow, 1.0, open) * mix(0.6, 1.0, smoothstep(0.0, 600.0, p.y - root.y))
		* mix(1.0 - 0.4 * relief, 1.0, smoothstep(-0.05, 0.35, bulge));
	float tu_lit = mix(0.3, 1.0, clamp(dot(out_dir, tu_dir) * 0.6 + 0.5, 0.0, 1.0)) * step(0.0, tu_dir.y);
	vec3 albedo = mix(dust_albedo, ASH, mix(ashen[k].x, ashen[k + 1].x, along) * exp(-max(inside, 0.0) / width));
	vec3 s = albedo * (sun_light * sun * mix(1.0, phase_hg(c, 0.6), 0.45) + sky_light * sky
		+ ring_light * ring_phase(c) * sun + tu_light * tu_lit);
	float seen_as = t > landmark.x ? landmark.x * pow(t / landmark.x, landmark.y) : t;
	return mix(s, haze_color, haze_at(seen_as, p.y));
}

void vertex() {
	vec3 lo = root + box_lo;
	vec3 hi = root + box_hi;
	vec3 at = mix(lo, hi, VERTEX + 0.5);
	vec3 eye = CAMERA_POSITION_WORLD;
	// Past the camera's reach, nearer and smaller: the same on screen.
	float far = distance(eye, 0.5 * (lo + hi)) + 0.5 * length(hi - lo);
	float pull = far > reach.x ? reach.x / far : 1.0;
	VERTEX = (VIEW_MATRIX * vec4(eye + (at - eye) * pull, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec2 ndc = SCREEN_UV * 2.0 - 1.0;
	vec4 near_p = INV_PROJECTION_MATRIX * vec4(ndc, 1.0, 1.0);
	vec3 rd = normalize((INV_VIEW_MATRIX * vec4(normalize(near_p.xyz / near_p.w), 0.0)).xyz);
	vec3 ro = CAMERA_POSITION_WORLD;
	float z = texture(depth_tex, SCREEN_UV).r;
	float scene_t = 1.0e9;
	if (z > 0.0) {
		vec4 vp = INV_PROJECTION_MATRIX * vec4(ndc, z, 1.0);
		scene_t = length(vp.xyz / vp.w);
	}
	// The stretches of the column the ray passes, each in its own sphere, and
	// where along the ray it's among them.
	int passes = 0;
	float t_in = 1.0e9;
	float t_out = 0.0;
	vec2 spans[POINTS - 1];
	for (int j = 0; j < POINTS - 1; j++) {
		spans[j] = vec2(1.0e9, -1.0);
		if (ashen[j].y < 0.5) {
			continue;
		}
		vec3 a = root + shape[j].xyz;
		vec3 b = root + shape[j + 1].xyz;
		float r = 0.5 * distance(a, b) + max(shape[j].w, shape[j + 1].w) * (1.0 + BILLOWS);
		vec3 oc = ro - 0.5 * (a + b);
		float bb = dot(oc, rd);
		float disc = bb * bb - dot(oc, oc) + r * r;
		if (disc > 0.0 && -bb + sqrt(disc) > 0.0) {
			passes |= 1 << j;
			spans[j] = vec2(max(-bb - sqrt(disc), 0.0), -bb + sqrt(disc));
			t_in = min(t_in, max(-bb - sqrt(disc), 0.0));
			t_out = max(t_out, -bb + sqrt(disc));
		}
	}
	t_out = min(min(t_out, scene_t), reach.z);
	// A storm's dust between hides what's behind it.
	t_out = min(t_out, storm_first(ro, rd, min(t_out, far_fade.y)));
	if (passes == 0 || t_out <= t_in) {
		discard;
	}
	float jitter = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	// Nothing of it is drawn this near.
	float t = max(t_in, NEAR.x);
	bool started = false;
	vec3 light = vec3(0.0);
	float trans = 1.0;
	vec3 s = vec3(0.0);
	for (int i = 0; i < STEPS; i++) {
		if (t >= t_out) {
			break;
		}
		vec3 p = ro + rd * t;
		vec3 q;
		float width;
		float sigma;
		float squash;
		int k;
		float along;
		float clear;
		float inside = column(p, t, spans, q, width, sigma, squash, k, along, clear);
		// Coarse while it's still dissolving near you.
		float dt = max(max(width * STEP.x, t * STEP.y), STEP.z) * (t < NEAR.y ? 2.0 : 1.0);
		if (clear > 10.0) {
			// Clear of all of it: on by how far it must be.
			t += clear * 0.9;
			continue;
		}
		float bulge = billow(p, width);
		float face = inside + width * bulge;
		if (!started) {
			// The first step among it is staggered, so the rest never line up into bands.
			started = true;
			dt *= 0.5 + jitter;
		}
		float veil = mix(1.0, mix(dust[k].z, dust[k + 1].z, along), smoothstep(far_fade.x, far_fade.y, t));
		float d = min(sigma, DENSEST / width) * smoothstep(0.0, width * SKIN, face) * smoothstep(NEAR.x, NEAR.y, t)
			* (1.0 - smoothstep(reach.y, reach.z, t)) * veil;
		if (d > 1.0e-6) {
			float a = 1.0 - exp(-d * dt);
			// The light changes slowly along the ray: every third step will do.
			if (s == vec3(0.0) || i % 3 == 0) {
				s = lit(p, rd, t, q, width, squash, sigma, face, bulge, k, along);
			}
			light += trans * a * s;
			trans *= 1.0 - a;
			if (trans < 0.02) {
				break;
			}
		}
		t += dt;
	}
	float alpha = 1.0 - trans;
	if (alpha < 0.003) {
		discard;
	}
	ALBEDO = light / alpha;
	ALPHA = alpha;
}
