class_name PlumeDraw
extends CompositorEffect
## The plumes (Plume) drawn as the storms are, after the storm pass: the column
## of dust each vent's gas lifts, marched per pixel at half the screen's size
## round the streaklines the main thread works out, its face billowed with
## the storm walls' own billows at its scale, lit and hazed as they are; then
## brought up to full size, each pixel from the half-size ones at its own
## depth, so a dune's edge in front of it stays sharp. Half the size is a
## quarter of the rays. Inert without a GPU, as headless.

## Most plumes drawn, and points along each (Plume's).
const PLUMES := 3
const POINTS := 15
## Vec4s of the shared light and storm map, and of each plume: its root, then
## its points' places and widths, their dust, and their ash and joins.
const SHARED := 14
const EACH := 1 + 3 * POINTS

const SOURCE := """
#version 450
// Stage 0, a thread a half-size pixel: the plumes along its ray, light and
// alpha, and the scene's distance there. Stage 1, a thread a pixel: the
// half-size pixels round it weighed by how near their distance is to its
// own, laid over the scene.
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform restrict image2D color;
layout(set = 0, binding = 1) uniform sampler2D depth_tex;
layout(rgba16f, set = 0, binding = 2) uniform restrict image2D half_light;
layout(r32f, set = 0, binding = 3) uniform restrict image2D half_far;
layout(set = 0, binding = 4) uniform sampler2D storm_map_a;
layout(set = 0, binding = 5) uniform sampler2D storm_map_b;
layout(set = 0, binding = 6) uniform sampler3D storm_noise;
layout(set = 0, binding = 7, std430) restrict readonly buffer Scene {
	vec4 v[];
} scene;

layout(push_constant, std430) uniform Params {
	mat4 inv_proj;
	// The camera's basis, its place in w.
	vec4 cam_x;
	vec4 cam_y;
	vec4 cam_z;
	ivec2 size;
	int stage;
	int count;
} params;

const int POINTS = 15;
const int SHARED = 14;
const int EACH = 1 + 3 * POINTS;

// The shared light, haze and storm map (PlumeDraw.frame's order).
#define SUN_DIR scene.v[0].xyz
#define STORM_GLOW scene.v[0].w
#define SUN_LIGHT scene.v[1].xyz
#define HAZE_HEIGHT scene.v[1].w
#define SKY_LIGHT scene.v[2].xyz
#define RING_LIGHT scene.v[3].xyz
#define TU_DIR scene.v[4].xyz
#define TU_LIGHT scene.v[5].xyz
#define DUST_ALBEDO scene.v[6].xyz
#define HAZE_COLOR scene.v[7].xyz
#define HAZE scene.v[8].xyz
#define FADE scene.v[9].xy
#define LANDMARK scene.v[9].zw
#define FAR_FADE scene.v[10].xy
#define STORM_HEIGHT scene.v[10].z
#define STORM_ROOF_SOFT scene.v[10].w
#define MAP_BLEND scene.v[11].x
#define MAP_READY scene.v[11].y
#define MAP_EXTENT scene.v[11].z
#define MAP_SHIFT scene.v[12].xy
#define STORM_AIR scene.v[12].zw
#define STORM_TIME scene.v[13].x
// How far into a plume's dust the camera stands, 0 to 1.
#define IN_DUST scene.v[13].y

// Twins of storm_field.gdshaderinc's.
const float STORM_SLOPE_FLOOR = 2.0e-5;
const float STORM_FAR = 40000.0;
const float STORM_BODY_WEIGHT = 25.0;
const mat3 STORM_TILT_A = mat3(vec3(0.8253, 0.0, -0.5646), vec3(0.2134, 0.9259, 0.3119), vec3(0.5228, -0.3779, 0.7642));
const mat3 STORM_TILT_B = mat3(vec3(0.6967, 0.3307, 0.6366), vec3(-0.4258, 0.9047, 0.0144), vec3(-0.5711, -0.2689, 0.7756));
// A storm's billows reach this far ahead of its front at most, m
// (storm_field's STORM_REACH), and its billowed tops this far over the wall
// (their slow swell, 300 m, a billow's 145, half the roof's softening).
const float STORM_AHEAD = 450.0;
const float STORM_TOPS = 670.0;

// Near you it isn't drawn: it dissolves over these, m, into the air round you.
const vec2 NEAR = vec2(120.0, 500.0);
// Steps through its dust at most, each this share of its width there, or of
// the distance, never under the third, m; strides through clear air between,
// at most, each as far as the nearest of its stretches allows, so where a
// ray meets the dust never depends on where it came within any one's bounds.
const int STEPS = 32;
const vec3 STEP = vec3(0.25, 0.004, 4.0);
const int STRIDES = 48;
// Through thin dust steps lengthen to about this optical depth each.
const float STEP_DEEP = 0.12;
// Its billows: the storm walls' own (storm_bulge's big octaves and warp),
// at its scale, a wall's biggest billow tile this many of its widths; and
// they stand out this share of its width at most (Plume.BILLOWS).
const float WALL_TILE = 3.0;
const float BILLOWS = 0.5;
// Its face softens over this share of its width, never less than the next,
// m; however dense, its dust takes this many optical depths a width at most,
// so a face builds over a few steps and shows its billows; where stretches
// meet, their dust blends over this share of the width.
const float SKIN = 0.1;
const float SKIN_LEAST = 60.0;
const float DENSEST = 5.0;
const float BLEND = 0.25;
// Its shaded side keeps this share of the sun, scattered on through the
// dust, as a storm wall's does; the shading flattens off over these, m.
const float SHADED = 0.3;
const vec2 RELIEF = vec2(1000.0, 5000.0);
// Basalt ash, its faint trace at a burst's core.
const vec3 ASH = vec3(0.075, 0.068, 0.062);

// The plumes, read once a group into its shared memory: every step reads them.
shared vec4 plumes[3 * EACH];

vec4 shape(int plume, int j) {
	return plumes[plume * EACH + 1 + j];
}

vec4 dust(int plume, int j) {
	return plumes[plume * EACH + 1 + POINTS + j];
}

vec4 ashen(int plume, int j) {
	return plumes[plume * EACH + 1 + 2 * POINTS + j];
}

vec3 root_of(int plume) {
	return plumes[plume * EACH].xyz;
}

float phase_hg(float c, float g) {
	float g2 = g * g;
	return (1.0 - g2) / pow(1.0 + g2 - 2.0 * g * c, 1.5);
}

float ring_phase(float c) {
	return 0.65 * phase_hg(c, 0.85) + 0.35 * phase_hg(c, 0.45);
}

float sun_through(float path) {
	return min(1.0, exp(-0.004 * path) + 0.3 * exp(-0.0008 * path));
}

float haze_at(float t, float h) {
	return smoothstep(HAZE.x, HAZE.y, t) * HAZE.z * exp(-max(h, 0.0) / HAZE_HEIGHT);
}

float storm_billow(float n) {
	float x = 2.0 * n - 1.0;
	return sqrt(x * x + 0.02) - 0.35;
}

vec3 storm_front(vec2 p) {
	vec2 uv = (p + MAP_SHIFT) / MAP_EXTENT;
	vec4 m = mix(texture(storm_map_a, uv), texture(storm_map_b, uv), MAP_BLEND);
	float steep = length(m.yz);
	float d = clamp(m.x / max(steep, STORM_SLOPE_FLOOR), -STORM_FAR, STORM_FAR);
	return vec3(d, steep > 0.0 ? m.yz / steep : vec2(0.0));
}

float storm_roof_path(float h) {
	float lo = STORM_HEIGHT - STORM_ROOF_SOFT;
	float hi = STORM_HEIGHT + STORM_ROOF_SOFT;
	if (h >= hi) {
		return 0.0;
	}
	if (h <= lo) {
		return lo - h + STORM_ROOF_SOFT;
	}
	float x = hi - h;
	return x * x / (4.0 * STORM_ROOF_SOFT);
}

float storm_sun_path(vec3 p, vec3 f, vec3 sun) {
	float clear_side = -dot(sun.xz, f.yz);
	float up = max(sun.y, 0.02);
	if (f.x <= 0.0) {
		if (clear_side >= -0.001) {
			return 0.0;
		}
		return storm_roof_path(p.y + f.x / clear_side * up) / up;
	}
	float out_top = storm_roof_path(p.y) / up;
	return clear_side > 0.001 ? min(out_top, f.x / clear_side * STORM_BODY_WEIGHT) : out_top;
}

vec4 storm_head_field(vec3 p) {
	return texture(storm_noise, vec3(p.x + STORM_AIR.x, 0.0, p.z + STORM_AIR.y) * (1.0 / 9000.0));
}

float storm_head(vec4 s, float h) {
	float swell = clamp((s.r - 0.5) * 3.0, -1.0, 1.0);
	float lean = 0.12 + clamp((s.a - 0.5) * 3.0, -1.0, 1.0) * 0.12;
	float nose = 90.0 * clamp((s.g - 0.5) * 3.0 + 0.5, 0.0, 1.0);
	return 180.0 * swell * sin(3.14159 * clamp(h / STORM_HEIGHT, 0.0, 1.0))
		- lean * max(h - 120.0, 0.0) - nose * exp(-max(h, 0.0) / 90.0);
}

// How far a storm's billowed face pokes out past its front at p, m, and its
// billowed top there (storm_bulge's big octaves and head).
float storm_bulge(vec3 p, out float top) {
	float t = STORM_TIME;
	vec3 q = vec3(p.x + STORM_AIR.x, p.y, p.z + STORM_AIR.y);
	vec4 w = texture(storm_noise, STORM_TILT_B * vec3(q.x + t * 3.0, q.y - t * 1.5, q.z) * (1.0 / 3700.0));
	vec3 qw = q + (w.rga - 0.5) * vec3(260.0, 140.0, 160.0);
	float b1 = storm_billow(texture(storm_noise, STORM_TILT_A * vec3(qw.x, qw.y - t * 2.2, qw.z) * (1.0 / 2300.0)).g);
	top = STORM_HEIGHT + 600.0 * (w.r - 0.5) + 220.0 * b1;
	return 300.0 * b1 + storm_head(storm_head_field(p), p.y);
}

// First t along the ray where a storm's dust is, up to t_end, or far off:
// behind its billowed face and under its billowed top, as the storm pass
// draws them. The front's distance strides it through clear air.
float storm_first(vec3 ro, vec3 rd, float t_end) {
	if (MAP_READY <= 0.0) {
		return 1.0e9;
	}
	float roof = STORM_HEIGHT + STORM_TOPS;
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
		float d = storm_front(p.xz).x;
		if (d + STORM_AHEAD > 0.0) {
			float top;
			float edge = d + storm_bulge(p, top);
			if (edge > 0.0 && p.y < top + 0.5 * STORM_ROOF_SOFT) {
				return t;
			}
			d = min(edge, -1.0) - STORM_AHEAD;
		}
		t += clamp(-(d + STORM_AHEAD) * 0.8, 50.0 + t * 0.02, 2000.0);
	}
	return 1.0e9;
}

// How far its billows stand out past its smooth face at p, in widths: the
// storm walls' own two big octaves under their slow warp, at its scale (a
// wall's biggest tile WALL_TILE of its widths), churning up it as a wall's do.
float billow(vec3 p, float width) {
	float s = 2300.0 / (WALL_TILE * width);
	float t = STORM_TIME;
	vec3 q = vec3(p.x + STORM_AIR.x, p.y, p.z + STORM_AIR.y) * s;
	vec4 w = texture(storm_noise, STORM_TILT_B * vec3(q.x + t * 3.0, q.y - t * 1.5, q.z) * (1.0 / 3700.0));
	vec3 qw = q + (w.rga - 0.5) * vec3(260.0, 140.0, 160.0);
	float b1 = storm_billow(texture(storm_noise, STORM_TILT_A * vec3(qw.x, qw.y - t * 2.2, qw.z) * (1.0 / 2300.0)).g);
	float b2 = storm_billow(texture(storm_noise, STORM_TILT_B * vec3(qw.x + t * 0.8, qw.y - t * 4.0, qw.z - t * 1.0) * (1.0 / 760.0)).g);
	return (300.0 * b1 + 70.0 * b2) / (s * width) * (BILLOWS / 0.34);
}

// The column at p, from its stretches whose bounds (spheres: centre, radius,
// negative for none) hold it, blended where they meet over a share of the width so
// none hands over to the next with a seam: how far inside its smooth face,
// m (negative outside). Out: the nearest stretch's offset from its axis,
// which it is and how far along; the blend's width, dust at its core and
// depth for its width; and how far it's safe to stride, m.
float column(int plume, vec3 p, vec4 spheres[POINTS - 1], out vec3 q, out float width, out float sigma,
		out float squash, out int k, out float along, out float clear) {
	vec3 root = root_of(plume);
	float best = 1.0e9;
	float total = 0.0;
	vec4 mixed = vec4(0.0);
	clear = 1.0e9;
	q = vec3(0.0);
	k = 0;
	along = 0.0;
	width = 1.0;
	sigma = 0.0;
	squash = 1.0;
	for (int j = 0; j < POINTS - 1; j++) {
		vec4 sphere = spheres[j];
		if (sphere.w < 0.0) {
			continue;
		}
		// Outside a stretch's bounds, how far they are is safe to stride.
		float to_sphere = distance(p, sphere.xyz) - sphere.w;
		if (to_sphere > 0.0) {
			clear = min(clear, to_sphere);
			continue;
		}
		vec4 a4 = shape(plume, j);
		vec4 b4 = shape(plume, j + 1);
		vec3 a = root + a4.xyz;
		vec3 ab = b4.xyz - a4.xyz;
		float h = clamp(dot(p - a, ab) / max(dot(ab, ab), 1.0e-3), 0.0, 1.0);
		vec3 off = p - a - ab * h;
		float w = mix(a4.w, b4.w, h);
		// Flattened, it lies within the round one, so that one's distance is safe.
		clear = min(clear, length(off) - w * (1.0 + BILLOWS));
		// Levelled, it's deeper than wide no longer: an umbrella, flat.
		float sq = max(mix(dust(plume, j).y, dust(plume, j + 1).y, h), 0.2);
		float d = length(vec3(off.x, off.y / sq, off.z)) - w;
		// Each near stretch weighs in by how near it is.
		float weight = exp(-max(d, -w) / (BLEND * w));
		total += weight;
		mixed += weight * vec4(w, sq, mix(dust(plume, j).x, dust(plume, j + 1).x, h), d);
		if (d < best) {
			best = d;
			q = off;
			k = j;
			along = h;
		}
	}
	if (total <= 0.0) {
		return -1.0e9;
	}
	mixed /= total;
	width = mixed.x;
	squash = mixed.y;
	sigma = mixed.z;
	return -mixed.w;
}

// Its dust a metre where it's this far inside its smooth face, m, its
// billows standing out bulge widths there.
float dust_at(float inside, float bulge, float width, float sigma) {
	return min(sigma, DENSEST / width) * smoothstep(0.0, max(width * SKIN, SKIN_LEAST), inside + bulge * width);
}

// The column's way at a point, from its neighbours either side.
vec3 tangent(int plume, int j) {
	vec3 d = shape(plume, min(j + 1, POINTS - 1)).xyz - shape(plume, max(j - 1, 0)).xyz;
	return length(d) > 1.0e-3 ? normalize(d) : vec3(0.0, 1.0, 0.0);
}

// The light a step of it sends back toward the eye, as a storm wall's: the
// sun's through what of the column lies its way (read a little way toward
// it) and through any storm; the sky's, less deep inside; the ring's thrown
// forward; Tu's at night; and the haze between.
vec3 lit(int plume, vec3 p, vec3 rd, float t, vec3 q, float width, float sigma, float inside, int k, float along,
		vec4 spheres[POINTS - 1]) {
	vec3 root = root_of(plume);
	float c = dot(rd, SUN_DIR);
	float relief = 1.0 - 0.6 * smoothstep(RELIEF.x, RELIEF.y, t);
	// Its own shadow: its dust half its width toward the sun, taken for the way out.
	float toward = 0.0;
	for (int i = 1; i <= (IN_DUST > 0.5 ? 0 : 1); i++) {
		float reach_m = width * 0.5;
		vec3 at = p + SUN_DIR * reach_m;
		vec3 q2;
		float w2;
		float s2;
		float sq2;
		int k2;
		float al2;
		float cl2;
		float in2 = column(plume, at, spheres, q2, w2, s2, sq2, k2, al2, cl2);
		toward += dust_at(in2, 0.5 * BILLOWS, w2, s2) * reach_m * 1.5;
	}
	float own = mix(1.0 - (1.0 - SHADED) * relief, 1.0, exp(-toward));
	float storms = t < FAR_FADE.y && MAP_READY > 0.0
		? sun_through(storm_sun_path(p, storm_front(p.xz), SUN_DIR)) : mix(dust(plume, k).w, dust(plume, k + 1).w, along);
	float sun = own * storms;
	// Deep in it the open sky is hidden, as in a wall.
	float open = mix(1.0, exp(-max(inside, 0.0) / (0.3 * width)), relief);
	float sky = mix(STORM_GLOW, 1.0, open) * mix(0.6, 1.0, smoothstep(0.0, 600.0, p.y - root.y));
	vec3 out_dir = length(q) > 1.0e-3 ? normalize(q) : vec3(0.0, 1.0, 0.0);
	float tu_lit = mix(0.3, 1.0, clamp(dot(out_dir, TU_DIR) * 0.6 + 0.5, 0.0, 1.0)) * step(0.0, TU_DIR.y);
	vec3 albedo = mix(DUST_ALBEDO, ASH, mix(ashen(plume, k).x, ashen(plume, k + 1).x, along) * exp(-max(inside, 0.0) / width));
	vec3 s = albedo * (SUN_LIGHT * sun * mix(1.0, phase_hg(c, 0.6), 0.45) + SKY_LIGHT * sky
		+ RING_LIGHT * ring_phase(c) * sun + TU_LIGHT * tu_lit);
	float seen_as = t > LANDMARK.x ? LANDMARK.x * pow(t / LANDMARK.x, LANDMARK.y) : t;
	return mix(s, HAZE_COLOR, haze_at(seen_as, p.y));
}

// How far along a ray a plume's bounds reach, or 0 if it misses them.
float meets(int plume, vec3 ro, vec3 rd) {
	vec3 root = root_of(plume);
	float out_t = 0.0;
	for (int i = 0; i < POINTS - 1; i++) {
		if (ashen(plume, i).y < 0.5) {
			continue;
		}
		vec4 a4 = shape(plume, i);
		vec4 b4 = shape(plume, i + 1);
		vec3 a = root + a4.xyz;
		vec3 b = root + b4.xyz;
		float r = 0.5 * distance(a, b) + max(a4.w, b4.w) * (1.0 + BILLOWS);
		vec3 oc = ro - 0.5 * (a + b);
		float bb = dot(oc, rd);
		float disc = bb * bb - dot(oc, oc) + r * r;
		if (disc > 0.0 && -bb + sqrt(disc) > 0.0) {
			out_t = max(out_t, -bb + sqrt(disc));
		}
	}
	return out_t;
}

// One plume along a ray, up to t_end: its light and how much of what's behind
// it still shows, and where it starts.
vec4 march(int plume, vec3 ro, vec3 rd, float t_end, float j, out float t_first) {
	vec3 root = root_of(plume);
	vec4 spheres[POINTS - 1];
	float t_in = 1.0e9;
	float t_out = 0.0;
	for (int i = 0; i < POINTS - 1; i++) {
		spheres[i] = vec4(0.0, 0.0, 0.0, -1.0);
		if (ashen(plume, i).y < 0.5) {
			continue;
		}
		vec4 a4 = shape(plume, i);
		vec4 b4 = shape(plume, i + 1);
		vec3 a = root + a4.xyz;
		vec3 b = root + b4.xyz;
		float r = 0.5 * distance(a, b) + max(a4.w, b4.w) * (1.0 + BILLOWS);
		spheres[i] = vec4(0.5 * (a + b), r);
		vec3 oc = ro - 0.5 * (a + b);
		float bb = dot(oc, rd);
		float disc = bb * bb - dot(oc, oc) + r * r;
		if (disc > 0.0 && -bb + sqrt(disc) > 0.0) {
			t_in = min(t_in, max(-bb - sqrt(disc), 0.0));
			t_out = max(t_out, -bb + sqrt(disc));
		}
	}
	t_first = t_in;
	t_out = min(min(t_out, t_end), FADE.y);
	if (t_out <= t_in) {
		return vec4(0.0, 0.0, 0.0, 1.0);
	}
	vec3 light = vec3(0.0);
	float trans = 1.0;
	vec3 s = vec3(0.0);
	// Stood in its dust, the haze hides its detail: fewer steps will do.
	int steps = IN_DUST > 0.5 ? STEPS * 2 / 3 : STEPS;
	// Next to nothing of it shows in the first fifth of its fading in.
	float t = max(t_in, mix(NEAR.x, NEAR.y, 0.2));
	int strides = 0;
	bool started = false;
	for (int i = 0; i < steps; i++) {
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
		float smooth_in = column(plume, p, spheres, q, width, sigma, squash, k, along, clear);
		if (clear > max(4.0, 0.02 * width)) {
			// Clear of all of it: on by how far it must be; a stride isn't a step.
			t += min(clear, 1.0e6) * 0.9;
			strides++;
			if (strides < STRIDES) {
				i--;
			}
			continue;
		}
		// Coarse while it's still dissolving near you, easing in as it does.
		float dt = max(max(width * STEP.x, t * STEP.y), STEP.z) * (2.0 - smoothstep(NEAR.x, NEAR.y, t));
		// Its billows matter only through its face: deeper in, its dust is all there.
		float bulge = smooth_in < width * (SKIN + 0.2) ? billow(p, width) : BILLOWS;
		float inside = smooth_in + bulge * width;
		float dense = dust_at(smooth_in, bulge, width, sigma);
		// Through thin dust a step can be longer, about this deep each at most.
		dt = max(dt, min(STEP_DEEP / max(dense, 1.0e-6), width * 0.8));
		// Fine through a dense face, so it shows its billows' shape.
		if (sigma * width > 0.5 * DENSEST && inside > -width * 0.05 && inside < width * SKIN * 2.0) {
			dt = min(dt, max(max(width * 0.06, t * 0.002), STEP.z));
		}
		if (!started) {
			// The first step among it is staggered, so the rest never line up into bands.
			started = true;
			dt *= 0.5 + j;
		}
		float veil = mix(1.0, mix(dust(plume, k).z, dust(plume, k + 1).z, along), smoothstep(FAR_FADE.x, FAR_FADE.y, t));
		float d = dense * smoothstep(NEAR.x, NEAR.y, t) * (1.0 - smoothstep(FADE.x, FADE.y, t)) * veil;
		if (d > 1.0e-6) {
			float a = 1.0 - exp(-d * dt);
			// The light changes slowly along the ray: every fourth step will do.
			if (s == vec3(0.0) || i % 4 == 0) {
				s = lit(plume, p, rd, t, q, width, sigma, inside, k, along, spheres);
			}
			light += trans * a * s;
			trans *= 1.0 - a;
			// Opaque, or so far into the haze there's no telling it from it.
			if (trans < 0.02 || haze_at(t, p.y) > 0.97) {
				break;
			}
		}
		t += dt;
	}
	return vec4(light, trans);
}

// The scene's distance at a pixel, m; far off where nothing was drawn.
float scene_far(ivec2 at) {
	vec2 uv = (vec2(at) + 0.5) / vec2(params.size);
	float z = texture(depth_tex, uv).r;
	if (z <= 0.0) {
		return 1.0e9;
	}
	vec4 p = params.inv_proj * vec4(uv * 2.0 - 1.0, z, 1.0);
	return length(p.xyz / p.w);
}

vec3 ray_at(vec2 uv) {
	vec4 p = params.inv_proj * vec4(uv * 2.0 - 1.0, 1.0, 1.0);
	vec3 v = normalize(p.xyz / p.w);
	return normalize(params.cam_x.xyz * v.x + params.cam_y.xyz * v.y + params.cam_z.xyz * v.z);
}

void main() {
	ivec2 id = ivec2(gl_GlobalInvocationID.xy);
	if (params.stage == 0) {
		for (int i = int(gl_LocalInvocationIndex); i < params.count * EACH; i += 64) {
			plumes[i] = scene.v[SHARED + i];
		}
		barrier();
		ivec2 half_size = (params.size + 1) / 2;
		if (id.x >= half_size.x || id.y >= half_size.y) {
			return;
		}
		ivec2 at = min(id * 2, params.size - 1);
		float scene_t = scene_far(at);
		vec3 ro = vec3(params.cam_x.w, params.cam_y.w, params.cam_z.w);
		vec3 rd = ray_at((vec2(at) + 0.5) / vec2(params.size));
		// A storm's dust between hides what's behind it, looked for only on
		// rays that meet a plume, and only as far as they reach.
		float reaches = 0.0;
		for (int i = 0; i < params.count; i++) {
			reaches = max(reaches, meets(i, ro, rd));
		}
		float t_end = reaches > 0.0 ? min(scene_t, storm_first(ro, rd, min(min(scene_t, reaches), FAR_FADE.y))) : 0.0;
		float j = fract(52.9829189 * fract(dot(vec2(id), vec2(0.06711056, 0.00583715))));
		// Nearest first: each in front of those further.
		vec4 got[3];
		float starts[3];
		for (int i = 0; i < 3; i++) {
			got[i] = vec4(0.0, 0.0, 0.0, 1.0);
			starts[i] = 1.0e9;
			if (i < params.count && t_end > 0.0) {
				got[i] = march(i, ro, rd, t_end, j, starts[i]);
			}
		}
		vec3 light = vec3(0.0);
		float trans = 1.0;
		for (int n = 0; n < 3; n++) {
			int pick = 0;
			float nearest = 2.0e9;
			for (int i = 0; i < 3; i++) {
				if (starts[i] < nearest) {
					nearest = starts[i];
					pick = i;
				}
			}
			if (nearest >= 1.0e9) {
				break;
			}
			light += trans * got[pick].rgb;
			trans *= got[pick].a;
			starts[pick] = 2.0e9;
		}
		imageStore(half_light, id, vec4(light, 1.0 - trans));
		imageStore(half_far, id, vec4(scene_t, 0.0, 0.0, 0.0));
		return;
	}
	if (id.x >= params.size.x || id.y >= params.size.y) {
		return;
	}
	float here = scene_far(id);
	ivec2 half_size = (params.size + 1) / 2;
	vec2 h = vec2(id) * 0.5 - 0.25;
	ivec2 base = ivec2(floor(h));
	vec2 w = h - vec2(base);
	vec4 sum = vec4(0.0);
	float weights = 0.0;
	vec4 nearest = vec4(0.0);
	float closest = 1.0e30;
	for (int y = 0; y < 2; y++) {
		for (int x = 0; x < 2; x++) {
			ivec2 at = clamp(base + ivec2(x, y), ivec2(0), half_size - 1);
			vec4 c = imageLoad(half_light, at);
			float f = imageLoad(half_far, at).r;
			// Alike in depth, a half-size pixel weighs in; across an edge, not.
			float apart = abs(f - here) / (0.05 * min(f, here) + 1.0);
			float weight = (x == 1 ? w.x : 1.0 - w.x) * (y == 1 ? w.y : 1.0 - w.y) * exp(-apart * 4.0);
			sum += c * weight;
			weights += weight;
			if (apart < closest) {
				closest = apart;
				nearest = c;
			}
		}
	}
	vec4 plume = weights > 1.0e-3 ? sum / weights : nearest;
	if (plume.a <= 0.0) {
		return;
	}
	vec4 under = imageLoad(color, id);
	imageStore(color, id, vec4(plume.rgb + under.rgb * (1.0 - plume.a), under.a));
}
"""

var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _scene: RID
var _depth_sampler: RID
var _map_sampler: RID
var _noise_sampler: RID
var _half_light: RID
var _half_far: RID
var _half_size := Vector2i.ZERO
var _mutex := Mutex.new()
## The frame as the main thread last handed it: the shared light and storm
## map and each plume's, how many plumes, and the storm map's and noise's
## textures.
var _frame := PackedFloat32Array()
## Its own GPU time, both passes, ms: the last frame's that came back.
var gpu_ms := 0.0
var _count := 0
var _textures: Array[RID] = []


func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	_rd = RenderingServer.get_rendering_device()
	if _rd != null:
		RenderingServer.call_on_render_thread(_build)


## From the main thread, each frame: what to draw (SHARED + count * EACH vec4s)
## and the storm map's two textures and the storm noise.
func show(frame: PackedFloat32Array, count: int, textures: Array[RID]) -> void:
	_mutex.lock()
	_frame = frame
	_count = count
	_textures = textures
	_mutex.unlock()


func _build() -> void:
	var source := RDShaderSource.new()
	source.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	source.source_compute = SOURCE
	var spirv := _rd.shader_compile_spirv_from_source(source)
	if spirv.compile_error_compute != "":
		push_error("plume draw: %s" % spirv.compile_error_compute)
		return
	_shader = _rd.shader_create_from_spirv(spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)
	_scene = _rd.storage_buffer_create((SHARED + PLUMES * EACH) * 16)
	var state := RDSamplerState.new()
	_depth_sampler = _rd.sampler_create(state)
	state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	_map_sampler = _rd.sampler_create(state)
	state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	_noise_sampler = _rd.sampler_create(state)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _rd != null:
		# Freeing the shader frees its pipeline.
		for rid: RID in [_shader, _scene, _depth_sampler, _map_sampler, _noise_sampler, _half_light, _half_far]:
			if rid.is_valid():
				_rd.free_rid(rid)


func _render_callback(_type: int, render_data: RenderData) -> void:
	var buffers := render_data.get_render_scene_buffers() as RenderSceneBuffersRD
	var data := render_data.get_render_scene_data()
	if not _pipeline.is_valid() or buffers == null or data == null:
		return
	_mutex.lock()
	var frame := _frame
	var count := _count
	var textures := _textures
	_mutex.unlock()
	if count == 0 or textures.size() < 3:
		return
	var size := buffers.get_internal_size()
	if size.x == 0 or size.y == 0:
		return
	var half := (size + Vector2i.ONE) / 2
	if half != _half_size:
		_half_size = half
		for rid: RID in [_half_light, _half_far]:
			if rid.is_valid():
				_rd.free_rid(rid)
		_half_light = _image(half, RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT)
		_half_far = _image(half, RenderingDevice.DATA_FORMAT_R32_SFLOAT)
	var bytes := frame.to_byte_array()
	_rd.buffer_update(_scene, 0, mini(bytes.size(), (SHARED + PLUMES * EACH) * 16), bytes)
	var rd_textures: Array[RID] = []
	for each in textures:
		rd_textures.append(RenderingServer.texture_get_rd_texture(each))
	for rid in rd_textures:
		if not rid.is_valid():
			return
	var uniforms := UniformSetCacheRD.get_cache(_shader, 0, [
		_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, [buffers.get_color_layer(0)]),
		_uniform(RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE, 1, [_depth_sampler, buffers.get_depth_layer(0)]),
		_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 2, [_half_light]),
		_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 3, [_half_far]),
		_uniform(RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE, 4, [_map_sampler, rd_textures[0]]),
		_uniform(RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE, 5, [_map_sampler, rd_textures[1]]),
		_uniform(RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE, 6, [_noise_sampler, rd_textures[2]]),
		_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 7, [_scene])])
	# Already as the GPU draws with it: depth reversed, y down.
	var to_view := data.get_cam_projection().inverse()
	var camera := data.get_cam_transform()
	var push := PackedFloat32Array()
	for c in 4:
		var column: Vector4 = to_view[c]
		push.append_array([column.x, column.y, column.z, column.w])
	var b := camera.basis
	push.append_array([b.x.x, b.x.y, b.x.z, camera.origin.x, b.y.x, b.y.y, b.y.z, camera.origin.y,
		b.z.x, b.z.y, b.z.z, camera.origin.z])
	# Its own time, read off the GPU a frame or so later.
	for i in _rd.get_captured_timestamps_count():
		if _rd.get_captured_timestamp_name(i) == "PlumeDraw end" and i > 0 \
				and _rd.get_captured_timestamp_name(i - 1) == "PlumeDraw start":
			gpu_ms = (_rd.get_captured_timestamp_gpu_time(i) - _rd.get_captured_timestamp_gpu_time(i - 1)) / 1.0e6
	_rd.capture_timestamp("PlumeDraw start")
	var list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(list, _pipeline)
	_rd.compute_list_bind_uniform_set(list, uniforms, 0)
	for stage in 2:
		var head := push.to_byte_array()
		head.append_array(PackedInt32Array([size.x, size.y, stage, count]).to_byte_array())
		_rd.compute_list_set_push_constant(list, head, head.size())
		var across := half if stage == 0 else size
		_rd.compute_list_dispatch(list, ceili(across.x / 8.0), ceili(across.y / 8.0), 1)
		if stage == 0:
			_rd.compute_list_add_barrier(list)
	_rd.compute_list_end()
	_rd.capture_timestamp("PlumeDraw end")


func _image(size: Vector2i, format: RenderingDevice.DataFormat) -> RID:
	var view := RDTextureFormat.new()
	view.width = size.x
	view.height = size.y
	view.format = format
	view.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	return _rd.texture_create(view, RDTextureView.new())


static func _uniform(type: RenderingDevice.UniformType, binding: int, rids: Array) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	for rid: RID in rids:
		uniform.add_id(rid)
	return uniform
