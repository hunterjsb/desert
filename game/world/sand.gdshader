shader_type spatial;
#include "res://game/world/surface_projection.gdshaderinc"
#include "res://game/world/mountain.gdshaderinc"
// The sand: the flat colour plus what makes dune shapes read. Slip faces are
// smooth avalanche sand, a shade deeper and warmer, so they read even under a
// noon sun that lights every face alike, streaked down the fall line by its
// grainflows; gentler slopes carry wind ripples across the wind, lopsided,
// forking and ending, faded out before they alias, their crests coarse and a
// shade darker, over a longer swell that holds on further out; crests catch a
// thin highlight; patches drawn out along the wind vary the colour so
// distance reads; and close up it's grainy. Its own light() lights it as
// sand, not paint. And it has volume: crests lighter and hollows darker,
// hollows seeing less sky, the crests' shadows past the sun's shadow map, and
// the ripples' own shadows and troughs.

uniform vec3 sand : source_color = vec3(0.71, 0.59, 0.43);
// Shares of the sand's colour each channel keeps on slip faces and in troughs.
uniform vec3 slip_shade = vec3(0.9, 0.8, 0.7);
uniform vec3 trough_shade = vec3(0.9, 0.85, 0.83);
// Downwind in world x and z; ripple crests run across it.
uniform vec2 downwind = vec2(1.0, 0.0);
// The engine origin's world position, m, so patterns hold still through origin shifts.
uniform vec2 origin = vec2(0.0);
uniform float ripple_spacing = 0.16;
uniform float ripple_depth = 0.12;
// Nearby crests cover their troughs along the view ray, fading from 2 to 6 m.
uniform float ripple_relief = 1.0;
// How lopsided ripples are on flats and on windward slopes, where the wind
// keeps them crisp: 0 a sine, toward 1 a sawtooth, steep on the lee.
uniform vec2 ripple_lean = vec2(0.4, 0.58);
// Defects, where a crest forks or ends: the share of 2.4 m cells holding a pair.
uniform float ripple_defects = 0.8;
// The coarse grains a ripple's crest gathers and the fines its trough holds:
// the share of each channel they take away and add.
uniform vec3 sorting = vec3(0.025, 0.045, 0.06);
// Grainflows down a slip face, their share either way; the small mottle of
// the sand everywhere, under a metre across; and the grains themselves,
// the spread (one standard deviation) of a 2 mm patch's lightness.
uniform float grainflow = 0.04;
uniform float mottle = 0.03;
uniform float grains = 0.07;
uniform float crest_glow = 0.12;
uniform float patchiness = 0.04;
// The swell: sand waves a dozen ripples long, gentler, so sand that has lost
// its ripples to distance still shows the wind's grain.
uniform float swell_spacing = 1.9;
uniform float swell_depth = 0.06;

// The light (light()). Grains shade each other, so sand glows powdery with a
// low sun behind you and dims looking into it (Fujii's Oren-Nayar): 0 is plain
// Lambert, 1 the roughest.
uniform float backscatter = 0.6;
// The sheen, the brighter of two, not both: the sun's broad glare off the
// grains, as off a sea ("ocean"); and the rim, light skimming off grains seen
// edge-on toward the sun, as Fresnel has it (1 is what Godot's own rough
// specular gave, which the ripples facing a low sun were read by).
uniform float ocean = 0.02;
uniform float ocean_power = 50.0;
uniform float rim = 1.0;
// Glitter: a grain's facet turned just right to flash the light at you.
uniform float glitter = 10.0;
// How deep in a storm the light is (Weather's seen_shade): in the dust the
// light comes from all round, so nothing glints or shines.
uniform float storm = 0.0;

// Volume. Each vertex carries its dune shading (TerrainShape.shade, CUSTOM0).
// Fine sand gathers on the crests and coarse in the hollows: the share each
// channel gains on a crest and loses in a hollow dune_relief m over or under
// its dunes' mean, paler up and redder down.
uniform vec3 dune_sorting = vec3(0.05, 0.08, 0.11);
uniform float dune_relief = 15.0;
// How much of the sky the crests round a hollow hide counts: 1 as they hide
// an even sky, more as a dusty one is brightest low down. A ripple's trough
// at its deepest loses this share of its sky. And the share of that the
// sun's light loses too: none in nature, but with the sun overhead nothing
// else shows the hollows and troughs.
uniform float dune_sky = 3.0;
uniform float ripple_sky = 0.25;
uniform float cavity_light = 0.35;
// The sun's shadow map ends this far off, m (Weather sets it), fading from
// 0.8 of it; past it the crests' horizons shade the sand, faded in from 0.6.
uniform float shadow_reach = 100.0;
// How soft the crests' and ripples' shadows are: the tangent of the angle
// a light fades over going under their horizon.
uniform float dune_penumbra = 0.02;
uniform float ripple_penumbra = 0.04;

// Tracks (game/world/tracks.gd): each texel holds the fill clock's reading at
// which its mark will be filled, so a mark's depth is that less the clock.
// Wrapped round on itself; uv = engine xz / extent + shift.
uniform sampler2D track_map : filter_linear, repeat_enable, hint_default_black;
uniform float track_clock = 1.0;
uniform vec2 track_shift = vec2(0.0);
uniform float track_extent = 512.0;
uniform float track_texel = 0.25;
// The window's middle in engine x and z, and its reach; none while negative.
uniform vec3 track_window = vec3(0.0, 0.0, -1.0);
// How deep a full mark is drawn, m: its walls tilt the light by it.
uniform float track_depth = 0.08;
// Additional depression and loose lip for a full sideways board gouge only.
uniform float track_gouge_depth = 0.08;
uniform float track_gouge_rim = 0.02;
// View-ray depth near you, fading before a mark becomes smaller than a pixel.
uniform float track_relief = 1.0;
// The share of light trodden sand loses, and how much less of the sky a mark
// sees: the night's only light is the sky's.
uniform float track_shade = 0.16;
uniform float track_occlusion = 0.35;
// Curvature at which displaced loose sand reaches its full lip height.
uniform float track_rim_shape = 0.08;
// The drawn sand stands this much higher round marks, m, so whatever rests
// in one sits in it: a 1 m lattice can't draw the dent itself.
uniform float track_lift = 0.03;

// A live vent's ash (Plume): dark cinder round its mouth, sulphur in its
// throat, and a fan of grey ash down the long-term wind, the record of its
// bursts. Its mouth's world x and z, and how far the fan runs (by e), m; none
// while that's 0. Its slot's way, world x and z.
uniform vec3 vent_ash = vec3(0.0);
uniform vec2 vent_slot = vec2(0.0, 1.0);
const vec3 CINDER = vec3(0.025, 0.021, 0.019);
const vec3 ASH_GREY = vec3(0.15, 0.145, 0.14);
const vec3 SULPHUR = vec3(0.69, 0.54, 0.1);

varying vec3 world_pos;
varying vec3 world_normal;
varying vec4 wind_vertex;
// Handed from fragment() to light(), which has no neighbours to measure the
// pixel by: the grain's facet (view space) and weight, and the sheen's share,
// its lobe's power and that lobe's peak.
varying vec4 glint_seen;
varying vec3 shine;
// Volume: the dune shading as baked; and for light(), the crests' horizon
// tangents up and down the wind, how far past the shadow map, and what of the
// hollows' occlusion all light takes; the way across them (view space); a
// ripple's depth under its crest, m, the crests either side, m, and its way
// (view space).
varying vec4 dune_shade;
varying vec2 crest_normal;
varying vec4 dune_light;
varying vec3 crest_way;
varying vec3 ripple_light;
varying vec3 ripple_way;
// Local track-wall horizons to east, west, south and north for light().
varying vec4 track_horizon;

// The finest glitter cell, m: a power of two, so a chunk holds whole cells
// and cells stay put through origin shifts.
const float GRAIN = 1.0 / 64.0;
// How many pixels a cell spans, each one chance of a glint, so how thick they
// lie; how far facets lean from the surface; and how closely one must face
// the half-way of light and eye to flash.
const float CELL_PIXELS = 12.0;
const float LEAN = 0.3;
const float GLINT_SHARP = 400.0;
// Grains are pale quartz: the sheen is the light's colour, warmed a little.
const vec3 SHEEN = vec3(1.0, 0.89, 0.77);

#include "res://game/weather/wind_map.gdshaderinc"

// A lattice point's number, 0 to 1. Integer: a sin hash came out unlike
// itself from one cell to the next this far from the origin, which tore the
// ripples along straight lines.
float lattice(ivec2 p) {
	uint h = (uint(p.x) * 1597334677u ^ uint(p.y) * 3812015801u) * 1597334677u;
	return float(h ^ (h >> 16u)) * (1.0 / 4294967295.0);
}

// Integer hash (PCG3D): sin-hashes band at the millions of cells glitter
// counts. Six numbers, 0 to 1, from each word's two halves.
void hash6(ivec3 p, out vec3 a, out vec3 b) {
	uvec3 v = uvec3(p) * 1664525u + 1013904223u;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v ^= v >> 16u;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	a = vec3(v >> 16u) * (1.0 / 65535.0);
	b = vec3(v & uvec3(65535u)) * (1.0 / 65535.0);
}

// One glitter scale's grain at this pixel: its facet and how much of it the
// pixel holds, by its distance in pixels from the grain (to_px turns a step
// in world x and z into pixels).
vec4 glint(vec2 xz, vec2 origin_xz, float cell, int scale, mat2 to_px, vec3 normal) {
	vec2 local = xz / cell;
	vec2 id = floor(local) + floor(origin_xz / cell + 0.5);
	vec3 r;
	vec3 lean;
	hash6(ivec3(ivec2(id), scale), r, lean);
	vec2 off = to_px * ((0.25 + 0.5 * r.xy - fract(local)) * cell);
	float spot = 1.0 - smoothstep(0.7, 1.7, length(off));
	// Few grains flash full; most, faintly.
	float bright = r.z * r.z;
	return vec4(normalize(normal + LEAN * (lean * 2.0 - 1.0)), spot * bright * bright);
}

// Ripple defects: each a pair of opposite twists of the ripples' phase, 5 to
// 12 crests apart, which adds one crest between them and leaves the rest be,
// faded out within the reach of the four cells round a pixel. Cycles.
const float DEFECT_CELL = 2.4;
const float DEFECT_REACH = 1.75;
float defects(vec2 at, vec2 across, float share) {
	vec2 corner = floor(at / DEFECT_CELL - 0.5);
	float twist = 0.0;
	for (int k = 0; k < 4; k++) {
		vec2 id = corner + vec2(float(k & 1), float(k >> 1));
		vec3 r;
		vec3 q;
		hash6(ivec3(ivec2(id), 99), r, q);
		vec2 off = at - (id + 0.5 + (r.xy - 0.5) * 0.5) * DEFECT_CELL;
		float far = dot(off, off);
		// Most pixels lie beyond most pairs' reach: they skip the twist.
		if (q.z > share || far > DEFECT_REACH * DEFECT_REACH) {
			continue;
		}
		float reach = mix(0.4, 0.95, q.x);
		vec2 half_way = normalize(across + downwind * (q.y - 0.5) * 1.6) * (r.z < 0.5 ? -reach : reach);
		vec2 a = off - half_way;
		vec2 b = off + half_way;
		twist += (1.0 - smoothstep(reach + 0.15, DEFECT_REACH, sqrt(far))) * atan(a.y * b.x - a.x * b.y, dot(a, b) + 1e-7);
	}
	return twist / TAU;
}

float value_noise(vec2 p) {
	ivec2 i = ivec2(floor(p));
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(lattice(i), lattice(i + ivec2(1, 0)), f.x),
		mix(lattice(i + ivec2(0, 1)), lattice(i + ivec2(1, 1)), f.x), f.y);
}

// Value noise and its gradient by p.
vec3 value_noise_d(vec2 p) {
	ivec2 i = ivec2(floor(p));
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = lattice(i);
	float b = lattice(i + ivec2(1, 0));
	float c = lattice(i + ivec2(0, 1));
	float k = a - b - c + lattice(i + ivec2(1, 1));
	return vec3(a + (b - a) * u.x + (c - a) * u.y + k * u.x * u.y,
		6.0 * f * (1.0 - f) * (vec2(b - a, c - a) + k * u.yx));
}

// Value noise over cells of the engine's xz, counted from the origin's own
// cell so it holds still through origin shifts, as the glitter's do.
float cell_noise(vec2 xz, float cell) {
	vec2 local = xz / cell;
	ivec2 i = ivec2(floor(local)) + ivec2(floor(origin / cell + 0.5));
	vec2 f = fract(local);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(lattice(i), lattice(i + ivec2(1, 0)), f.x),
		mix(lattice(i + ivec2(0, 1)), lattice(i + ivec2(1, 1)), f.x), f.y);
}

// Up to twice a full mark: a skid's gouge (Tracks.DEEPEST).
float track_at(vec2 xz) {
	return clamp(textureLod(track_map, xz / track_extent + track_shift, 0.0).r - track_clock, 0.0, 2.0);
}

// A step never reaches the board's deepest pressure; only a skid gets this extra depth.
float track_below(float pressure) {
	float deep = max(pressure - 1.0, 0.0);
	return track_depth * pressure + track_gouge_depth * deep * deep;
}

bool in_tracks(vec2 xz) {
	vec2 off = abs(xz - track_window.xy);
	return max(off.x, off.y) < track_window.z;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	dune_shade = CUSTOM0;
	crest_normal = downwind * cos(CUSTOM0.w) + vec2(-downwind.y, downwind.x) * sin(CUSTOM0.w);
	wind_vertex = wind_view_vertex(world_pos.xz);
	if (in_tracks(world_pos.xz)) {
		// The deepest mark within half a lattice square, so one between
		// vertices still lifts the sand round it.
		vec2 xz = world_pos.xz;
		float near = max(track_at(xz), max(max(track_at(xz + vec2(0.5, 0.0)), track_at(xz - vec2(0.5, 0.0))),
			max(track_at(xz + vec2(0.0, 0.5)), track_at(xz - vec2(0.0, 0.5)))));
		VERTEX.y += track_lift * near;
	}
	vec3 drawn = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(surface_project(drawn), 1.0)).xyz;
}

// Depth below a ripple's crest: the integral of its rounded sawtooth slope.
float ripple_below(float phase, float lean, float height) {
	float wave = phase * TAU;
	return max(height * (asin(lean) + atan(lean * sin(wave), 1.0 - lean * cos(wave))), 0.0);
}

void fragment() {

	vec3 n = normalize(world_normal);
	vec2 at = world_pos.xz + origin;
	vec2 across = vec2(-downwind.y, downwind.x);
	float grade = length(n.xz) / max(n.y, 0.05);
	float facing = dot(normalize(n.xz + 1e-5), downwind);
	// How far a pixel spans on the ground, m, by which detail fades out.
	vec3 dpx = dFdx(world_pos);
	vec3 dpy = dFdy(world_pos);
	float foot = max(length(dpx.xz), length(dpy.xz));
	// Steep and facing downwind: a slip face.
	float lee = smoothstep(0.42, 0.55, grade) * smoothstep(-0.2, 0.3, facing);

	// The wind draws sand sheets out along itself.
	vec2 along = vec2(dot(at, across), dot(at, downwind));
	float broad = value_noise(at / 90.0) * 0.6 + value_noise(along / vec2(16.0, 48.0)) * 0.4;
	vec3 colour = sand * mix(trough_shade, vec3(1.0), smoothstep(0.2, 0.8, broad) * 0.5 + 0.5);
	// Patches, drawn out down the wind as ribbons of coarser and finer sand.
	colour *= 1.0 + (value_noise(along / vec2(7.0, 30.0)) - 0.5) * 2.0 * patchiness;
	// The small mottle, faded as a pixel spans more of it.
	if (foot < 0.3) {
		colour *= 1.0 + (value_noise(at / 0.6) - 0.5) * 2.0 * mottle * (1.0 - smoothstep(0.15, 0.5, foot / 0.6));
	}
	colour *= mix(vec3(1.0), slip_shade, lee * 0.8);
	if (lee > 0.0) {
		// Grainflows run straight down the fall line, which turns with the
		// face: the two nearest of a fan of headings, blended. Tongues a hand
		// or two wide and a few metres long, and a metre wide and longer,
		// fresh in places and long smoothed in others.
		float fan = atan(dot(n.xz, across), dot(n.xz, downwind)) / 0.4;
		float k = floor(fan);
		float flow = 0.0;
		for (int i = 0; i < 2; i++) {
			float turn = (k + float(i)) * 0.4;
			vec2 fall = downwind * cos(turn) + across * sin(turn);
			vec2 q = vec2(dot(at, vec2(-fall.y, fall.x)), dot(at, fall));
			float tongue = (value_noise(q / vec2(1.1, 9.0) + 7.0) - 0.5) * (1.0 - smoothstep(0.15, 0.5, foot / 1.1));
			if (foot < 0.15) {
				tongue += (value_noise(q / vec2(0.3, 3.0)) - 0.5) * (1.0 - smoothstep(0.15, 0.5, foot / 0.3));
			}
			flow += tongue * (i == 0 ? 1.0 - smoothstep(0.25, 0.75, fan - k) : smoothstep(0.25, 0.75, fan - k));
		}
		float fresh = smoothstep(0.25, 0.75, value_noise(along / vec2(5.0, 14.0) + 3.0));
		colour *= 1.0 + flow * 2.0 * grainflow * lee * fresh;
	}
	if (vent_ash.z > 0.0) {
		vec2 off = at - vent_ash.xy;
		float down = dot(off, downwind);
		float aside = dot(off, vec2(-downwind.y, downwind.x));
		float from_slot = length(vec2(dot(off, vec2(vent_slot.y, -vent_slot.x)), max(abs(dot(off, vent_slot)) - 6.0, 0.0)));
		float cinder = 1.0 - smoothstep(16.0, 44.0, from_slot);
		float fan = exp(-max(down, 0.0) / vent_ash.z) * exp(-pow(aside / (35.0 + 0.35 * max(down, 0.0)), 2.0))
			* smoothstep(-60.0, 10.0, down);
		// Fresh sand slides down a slip face over it.
		float ash = clamp(max(cinder, 0.85 * fan) * (0.75 + 0.5 * value_noise(at / 9.0)), 0.0, 1.0) * (1.0 - 0.5 * lee);
		colour = mix(colour, mix(ASH_GREY, CINDER, cinder), ash);
		float crust = (1.0 - smoothstep(3.0, 8.0, from_slot)) * smoothstep(0.55, 0.7, value_noise(at / 1.7));
		colour = mix(colour, SULPHUR, crust * 0.8);
	}

	// Convex where the normal turns the way the surface runs: a crest.
	float bend = (dot(dFdx(world_normal), dpx) + dot(dFdy(world_normal), dpy)) / max(dot(dpx, dpx) + dot(dpy, dpy), 1e-4);
	colour *= 1.0 + crest_glow * smoothstep(0.06, 0.2, bend);

	float phase = dot(at, downwind) / ripple_spacing;
	// Tracks: trodden sand is darker and sees less sky, a mark's walls tilt
	// the light, and the loose lip round it is lighter. Nothing glows: at
	// night and in a storm the contrast is the sand's own.
	float trodden = 0.0;
	float compacted = 0.0;
	vec3 dent = vec3(0.0);
	track_horizon = vec4(0.0);
	if (in_tracks(world_pos.xz)) {
		vec2 xz = world_pos.xz;
		float h = track_texel;
		float c = track_at(xz);
		vec3 eye = INV_VIEW_MATRIX[3].xyz - world_pos;
		float close = 1.0 - smoothstep(2.0, 8.0, length(eye));
		float relief = track_relief * close;
		if (relief > 0.001 && c > 0.0) {
			// Looking into a dent meets its floor further along the ray. Bound
			// grazing views to keep the rim from swimming across the surface.
			vec3 view = normalize(eye);
			vec2 ray = -view.xz / max(dot(view, n), 0.3);
			vec2 offset = ray * track_below(c);
			// Limit the optical shift to one texel so a grazing floor stays
			// beside objects resting on the unchanged physical ground.
			xz += offset * min(1.0, track_texel / max(length(offset), 1e-5)) * relief;
			c = track_at(xz);
		}
		float e = track_at(xz + vec2(h, 0.0));
		float w = track_at(xz - vec2(h, 0.0));
		float s = track_at(xz + vec2(0.0, h));
		float nn = track_at(xz - vec2(0.0, h));
		float lip = clamp((e + w + s + nn) * 0.25 - c, 0.0, 1.0);
		dent = vec3(e - w, 0.0, s - nn) / (2.0 * h) * (track_depth + 2.0 * track_gouge_depth * max(c - 1.0, 0.0));
		if (close > 0.001 && c + e + w + s + nn > 0.0) {
			// The displaced sand is a signed height: compressed floor below,
			// loose lip above. Differences across it keep both rim slopes soft.
			float ee = track_at(xz + vec2(2.0 * h, 0.0));
			float ww = track_at(xz - vec2(2.0 * h, 0.0));
			float ss = track_at(xz + vec2(0.0, 2.0 * h));
			float north = track_at(xz - vec2(0.0, 2.0 * h));
			float es = track_at(xz + vec2(h, h));
			float en = track_at(xz + vec2(h, -h));
			float ws = track_at(xz + vec2(-h, h));
			float wn = track_at(xz - vec2(h, h));
			float peak = max(max(max(c, max(e, w)), max(s, nn)), max(max(ee, ww), max(ss, north)));
			float loose_height = track_lift + track_gouge_rim * smoothstep(1.0, 2.0, peak);
			float floor_height = -track_below(c) + loose_height * smoothstep(0.0, track_rim_shape, lip);
			vec4 depths = vec4(e, w, s, nn);
			vec4 rims = max(vec4(ee + c + es + en, ww + c + ws + wn,
				ss + c + es + ws, north + c + en + wn) * 0.25 - depths, vec4(0.0));
			vec4 pressed_depths = vec4(track_below(e), track_below(w), track_below(s), track_below(nn));
			vec4 heights = -pressed_depths + loose_height * smoothstep(vec4(0.0), vec4(track_rim_shape), rims);
			vec3 pressed = -vec3(heights.x - heights.y, 0.0, heights.z - heights.w) / (2.0 * h);
			dent = mix(dent, pressed, close);
			// The wide floor of a skid can be a metre from its walls.
			float reach = 4.0 * h;
			vec4 far_depths = vec4(track_at(xz + vec2(reach, 0.0)), track_at(xz - vec2(reach, 0.0)),
				track_at(xz + vec2(0.0, reach)), track_at(xz - vec2(0.0, reach)));
			vec4 far_heights = -vec4(track_below(far_depths.x), track_below(far_depths.y),
				track_below(far_depths.z), track_below(far_depths.w));
			track_horizon = max(max((heights - floor_height) / h,
				(far_heights - floor_height) / reach), vec4(0.0)) * close;
		}
		trodden = smoothstep(0.0, 0.3, c);
		compacted = smoothstep(0.0, 0.8, c);
		colour *= mix(1.0, 1.0 - track_shade * (0.5 + 0.5 * smoothstep(0.0, 0.8, c)), trodden);
		AO = 1.0;
		if (c > 0.0 || dot(track_horizon, vec4(1.0)) > 0.0) {
			// A broad floor still sees almost all the sky; its walls occlude
			// the edge, rather than giving the whole mark one dark pigment.
			vec4 horizons = track_horizon / max(close, 0.001);
			float hidden = 1.0 - dot(inversesqrt(vec4(1.0) + horizons * horizons), vec4(0.25));
			float distant_sky = 1.0 - 0.25 * track_occlusion * smoothstep(0.0, 0.9, c);
			AO = mix(distant_sky, max(1.0 - dune_sky * hidden, 0.0), close);
		}
	}

	// Ripples across the wind, gone wherever a pixel spans more than about a
	// quarter of one, easing to a plain wave first so nothing finer than a
	// pixel is drawn. Their heading and spacing drift over metres; they fork
	// and end; patchy, crisp on windward slopes, where the wind keeps them up,
	// and gone toward a slip face over a ragged line, where grainflows wipe
	// them out. The way they run tilts the light.
	float spans = fwidth(phase);
	float shown = 1.0 - smoothstep(0.09, 0.27, spans);
	float fade = shown * (1.0 - compacted);
	vec2 way = vec2(0.0);
	ripple_light = vec3(0.0, 1.0, 1.0);
	ripple_way = vec3(0.0, 1.0, 0.0);
	float trough = 0.0;
	if (fade > 0.0) {
		vec3 drift = value_noise_d(at / 9.0) * vec3(0.9, 0.1, 0.1) + value_noise_d(at / 2.3) * vec3(0.3, 0.13, 0.13);
		phase += drift.x / ripple_spacing + defects(at, across, ripple_defects);
		vec2 heading = downwind + drift.yz;
		if (grade > 0.25 && facing > -0.3) {
			fade *= 1.0 - smoothstep(0.32, 0.5, grade + 0.14 * (value_noise(at / 0.8) - 0.5)) * smoothstep(-0.3, 0.2, facing);
		}
		float windward = smoothstep(0.06, 0.2, grade) * smoothstep(0.0, 0.4, -facing);
		float strength = (0.55 + 0.75 * value_noise(at / 5.0 + 31.0)) * (0.9 + 0.2 * windward);
		// Lopsided: the slope of a rounded sawtooth, a long gentle windward
		// side and a short steep lee, scaled to keep the old wave's mean
		// square, 0.56.
		float lean = mix(ripple_lean.x, ripple_lean.y, windward) * (1.0 - 0.9 * smoothstep(0.08, 0.2, spans));
		float spacing_here = ripple_spacing / max(length(heading), 0.2);
		float height = 0.75 * sqrt(2.0 * (1.0 - lean * lean)) / lean * fade * strength * ripple_depth * spacing_here / TAU;
		vec3 eye = INV_VIEW_MATRIX[3].xyz - world_pos;
		float relief = ripple_relief * (1.0 - smoothstep(2.0, 6.0, length(eye)));
		if (relief > 0.001) {
			// The first crossing of the view ray and ripple, then three refinements.
			// A grazing view is bounded so the search cannot skip several crests.
			vec3 view = normalize(eye);
			vec2 ray = -view.xz / max(dot(view, n), 0.2);
			float phase_step = dot(ray, heading) / ripple_spacing;
			float deepest = 2.0 * height * asin(lean);
			float low = 0.0;
			float high = deepest;
			for (int i = 1; i <= 8; i++) {
				float depth = deepest * float(i) / 8.0;
				if (depth >= ripple_below(phase + phase_step * depth, lean, height)) {
					high = depth;
					break;
				}
				low = depth;
			}
			for (int i = 0; i < 3; i++) {
				float depth = (low + high) * 0.5;
				if (depth >= ripple_below(phase + phase_step * depth, lean, height)) {
					high = depth;
				} else {
					low = depth;
				}
			}
			vec2 offset = ray * ((low + high) * 0.5 * relief);
			phase += dot(offset, heading) / ripple_spacing;
			at += offset;
		}
		float wave = phase * TAU;
		float bow = cos(wave);
		float slope = (lean * lean - lean * bow) / (1.0 + lean * lean - 2.0 * lean * bow)
			* 0.75 * sqrt(2.0 * (1.0 - lean * lean)) / lean;
		// Coarse grains ride the crests, a shade darker and redder; fines lie
		// in the troughs. The crest is where the slope turns down.
		colour *= 1.0 - sorting * cos(wave + acos(lean)) * fade * strength;
		way = normalize(heading) * slope * fade * strength * ripple_depth;
		// Volume: the ripple's own height, the integral of that slope, for its
		// shadow and its trough's sky.
		float under = ripple_below(phase, lean, height);
		float since = fract(phase + acos(lean) / TAU);
		ripple_light = vec3(under, since * spacing_here, (1.0 - since) * spacing_here);
		vec2 runs = normalize(heading);
		ripple_way = mat3(VIEW_MATRIX) * vec3(runs.x, 0.0, runs.y);
		trough = under / max(2.0 * height * asin(lean), 1e-6) * fade;
	}
	// The swell, wandering more and stronger in patches.
	float swell_phase = (dot(at, downwind) + 0.8 * sin(dot(at, across) * 0.23) + 2.5 * value_noise(at / 11.0)) / swell_spacing;
	float swell_shown = 1.0 - smoothstep(0.06, 0.18, fwidth(swell_phase));
	float swell = swell_shown * (1.0 - lee) * (1.0 - compacted) * swell_depth * (0.4 + 0.6 * broad);
	float swell_wave = swell_phase * TAU;
	way += downwind * (sin(swell_wave) + 0.35 * sin(2.0 * swell_wave)) * swell;
	vec3 tilt = vec3(way.x, 0.0, way.y);
	vec3 rippled = normalize(n - tilt + dent);

	// What the ripples and swell no longer draw still scatters the light: the
	// slope variance they lose to distance widens the sheen (Toksvig), so far
	// dunes keep a soft sheen rather than a hard glare or none. 0.56 is the
	// mean square of the lopsided wave's slope.
	float lost = 0.56 * (ripple_depth * ripple_depth * (1.0 - shown * shown)
		+ swell_depth * swell_depth * (1.0 - swell_shown * swell_shown));
	float clear = 1.0 - storm;
	float power = ocean_power / (1.0 + ocean_power * lost);
	// Normalised Blinn-Phong, so a wider lobe is a dimmer one.
	shine = vec3((1.0 - 0.7 * trodden) * clear, power, ocean * (power + 8.0) / (8.0 * PI));

	// Glitter, after Wang and Bowles: cells sized to the pixel, each with one
	// jittered grain and its own facet. Two scales a factor of two apart,
	// blended by the footprint, so a cell never pops as you walk; and each
	// grain drawn round on screen a pixel or two across, so none is ever
	// smaller than a pixel to crawl. Gone with distance, on tracks (trodden
	// sand is rough) and in the dust.
	float level = max(log2(foot * CELL_PIXELS / GRAIN), 0.0);
	float scale = floor(level);
	float blend = level - scale;
	float near = (1.0 - smoothstep(0.03, 0.12, foot)) * (1.0 - trodden) * clear * clear;
	glint_seen = vec4(0.0);
	if (near > 0.0) {
		float det = dpx.x * dpy.z - dpy.x * dpx.z;
		mat2 to_px = mat2(vec2(dpy.z, -dpx.z), vec2(-dpy.x, dpx.x)) / (det < 0.0 ? min(det, -1e-14) : max(det, 1e-14));
		float cell = GRAIN * exp2(scale);
		vec4 fine = glint(world_pos.xz, origin, cell, int(scale), to_px, rippled);
		vec4 coarse = glint(world_pos.xz, origin, cell * 2.0, int(scale) + 1, to_px, rippled);
		fine.w *= 1.0 - blend;
		coarse.w *= blend;
		// A pixel seldom holds a grain of each: it takes the brighter.
		vec4 grain = fine.w > coarse.w ? fine : coarse;
		glint_seen = vec4(mat3(VIEW_MATRIX) * grain.xyz, grain.w * near);
	}

	// The grains, a few dozen to a pixel close up. A pixel's mean of n grains
	// varies as 1/sqrt(n), so cells two pixels or so across, stepped by powers
	// of two as the glitter's are and blended, vary the less the larger they
	// are: grainy at your feet, gone within 5 m, and never crawling.
	if (foot < 0.016) {
		const float SPECK = 1.0 / 512.0;
		float speck_level = max(log2(foot * 2.0 / SPECK), 0.0);
		float speck_scale = floor(speck_level);
		float speck_cell = SPECK * exp2(speck_scale);
		float speck = mix(cell_noise(world_pos.xz, speck_cell) - 0.5, (cell_noise(world_pos.xz, speck_cell * 2.0) - 0.5) * 0.5,
			speck_level - speck_scale);
		// 0.16 is value noise's own spread.
		colour *= 1.0 + speck / 0.16 * grains * exp2(-speck_scale) * (1.0 - smoothstep(0.008, 0.016, foot));
	}
	// Volume. The dunes: a crest stands lighter and a hollow darker, by its
	// height over its dunes' mean; a hollow sees less sky, by how far the
	// crests either side stand over the ground's own slope (a long trough's,
	// cosine-weighted); and past the sun's shadow map the crests shade it,
	// as light() reads their horizons. A ripple's trough sees less sky too.
	colour *= 1.0 + dune_sorting * clamp(dune_shade.x / dune_relief, -1.0, 1.0);
	vec2 across_crests = normalize(crest_normal);
	float rises = -dot(n.xz, across_crests) / max(n.y, 0.05);
	float over_back = max(dune_shade.y - max(-rises, 0.0), 0.0);
	float over_ahead = max(dune_shade.z - max(rises, 0.0), 0.0);
	float hidden = 1.0 - 0.5 * (inversesqrt(1.0 + over_back * over_back) + inversesqrt(1.0 + over_ahead * over_ahead));
	float occluded = max(1.0 - dune_sky * hidden, 0.0) * (1.0 - ripple_sky * trough);
	AO *= occluded;
	dune_light = vec4(dune_shade.yz, smoothstep(0.6, 0.8, -VERTEX.z / shadow_reach), mix(1.0, occluded, cavity_light));
	crest_way = mat3(VIEW_MATRIX) * vec3(across_crests.x, 0.0, across_crests.y);
	colour = mountain_colour(colour, world_pos.y, normalize(world_normal));
	ALBEDO = wind_view_colour(colour, world_pos.xz, wind_vertex);
	ROUGHNESS = 1.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(surface_normal(rippled, world_pos), 0.0)).xyz);
}

// Volume: the share of a directional light past occluders whose horizon
// tangents are `back` up the way (along < 0 has the light there) and `ahead`
// down it, `rise` and `along` the light's own up and along that way. Soft by
// the tangent of the angle the light is under its horizon, so a light just
// over a bare horizon is whole.
float lit_over(float rise, float along, float back, float ahead, float soft) {
	float steep = rise / max(abs(along), 1e-4);
	float horizon = along < 0.0 ? back : ahead;
	return smoothstep(-soft, 0.0, (steep - horizon) / (1.0 + max(steep * horizon, 0.0)));
}

void light() {
	float nl = dot(NORMAL, LIGHT);
	float lit = max(nl, 0.0);
	float nv = max(dot(NORMAL, VIEW), 1e-3);
	vec3 incoming = LIGHT_COLOR * ATTENUATION;
	// Volume: past the shadow map the crests shade the sand; near, the ripples
	// shade themselves.
	incoming *= dune_light.w;
	if (LIGHT_IS_DIRECTIONAL) {
		float rise = dot(LIGHT, VIEW_MATRIX[1].xyz);
		float crests = lit_over(rise, dot(LIGHT, crest_way), dune_light.x, dune_light.y, dune_penumbra);
		float ripples = lit_over(rise, dot(LIGHT, ripple_way), ripple_light.x / max(ripple_light.y, 1e-4),
			ripple_light.x / max(ripple_light.z, 1e-4), ripple_penumbra);
		float tracks = 1.0;
		if (dot(track_horizon, vec4(1.0)) > 0.0) {
			vec2 along = vec2(dot(LIGHT, VIEW_MATRIX[0].xyz), dot(LIGHT, VIEW_MATRIX[2].xyz));
			float wall_x = (along.x > 0.0 ? track_horizon.x : track_horizon.y) * abs(along.x);
			float wall_z = (along.y > 0.0 ? track_horizon.z : track_horizon.w) * abs(along.y);
			float wall = max(wall_x, wall_z);
			float floor_rise = rise + dot(world_normal.xz, along) / max(world_normal.y, 0.1);
			tracks = wall > 0.0 ? smoothstep(-ripple_penumbra, ripple_penumbra, floor_rise - wall) : 1.0;
		}
		incoming *= mix(1.0, crests, dune_light.z) * ripples * tracks;
	}
	// Fujii's Oren-Nayar, as Lambert where grains hide nothing (s = 0). Only
	// a sky light under about 20 degrees: higher, or a lamp by your eye, it
	// flattens the ripples, as the full Moon looks flat; and Tu stands 30
	// degrees up where a run begins. Facing the light it dims half as far:
	// quartz passes light on, and dunes into a low sun are read by it.
	float s = dot(LIGHT, VIEW) - nl * nv;
	float up = dot(LIGHT, VIEW_MATRIX[1].xyz);
	float rough = LIGHT_IS_DIRECTIONAL ? backscatter * (1.0 - smoothstep(0.17, 0.5, up)) : 0.0;
	float fon = 1.0 + rough * (s > 0.0 ? s / max(max(lit, nv), 1e-3) : 0.5 * s);
	DIFFUSE_LIGHT += incoming * lit * max(fon, 0.0) / PI;
	vec3 h = normalize(LIGHT + VIEW);
	float sea = shine.z * pow(max(dot(NORMAL, h), 0.0), shine.y);
	// Schlick's Fresnel over a lobe as wide as it gets (GGX at roughness 1).
	float fresnel = 0.04 + 0.96 * pow(1.0 - max(dot(LIGHT, h), 0.0), 5.0);
	float grazing = rim * fresnel * 0.5 / (PI * (lit + nv));
	SPECULAR_LIGHT += incoming * max(sea, grazing) * lit * shine.x * SHEEN;
	// Most pixels hold no grain: they skip it.
	if (glint_seen.w > 0.0) {
		float flash = glint_seen.w * pow(max(dot(reflect(-LIGHT, glint_seen.xyz), VIEW), 0.0), GLINT_SHARP);
		SPECULAR_LIGHT += incoming * flash * glitter * smoothstep(0.0, 0.1, nl);
	}
}
