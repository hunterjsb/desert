shader_type spatial;
// The sand: the flat colour plus what makes dune shapes read. Slip faces are
// smooth avalanche sand, a shade deeper and warmer, so they read even under a
// noon sun that lights every face alike; gentler slopes carry wind ripples
// across the wind, faded out before they alias, over a longer swell that holds
// on further out; crests catch a thin highlight; and broad patches vary the
// colour so distance reads. Its own light() lights it as sand, not paint.

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
uniform float track_depth = 0.06;
// The share of light trodden sand loses, and how much less of the sky a mark
// sees: the night's only light is the sky's.
uniform float track_shade = 0.32;
uniform float track_occlusion = 0.35;
// Loose sand pushed up round a mark catches the light this much more.
uniform float track_rim = 0.25;
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
// Handed from fragment() to light(), which has no neighbours to measure the
// pixel by: the grain's facet (view space) and weight, and the sheen's share,
// its lobe's power and that lobe's peak.
varying vec4 glint_seen;
varying vec3 shine;

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

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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
// pixel holds, by its distance in pixels from the grain (to_px turns world
// xz into pixels).
vec4 glint(vec2 xz, vec2 origin_xz, float cell, int scale, mat2 to_px, vec3 normal) {
	vec2 local = xz / cell;
	vec2 id = floor(local) + floor(origin_xz / cell + 0.5);
	vec3 r;
	vec3 lean;
	hash6(ivec3(ivec2(id), scale), r, lean);
	vec2 off = to_px * ((0.25 + 0.5 * r.xy - fract(local)) * cell);
	float spot = 1.0 - smoothstep(0.7, 1.7, length(off));
	return vec4(normalize(normal + LEAN * (lean * 2.0 - 1.0)), spot * r.z * r.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float track_at(vec2 xz) {
	return clamp(textureLod(track_map, xz / track_extent + track_shift, 0.0).r - track_clock, 0.0, 1.0);
}

bool in_tracks(vec2 xz) {
	vec2 off = abs(xz - track_window.xy);
	return max(off.x, off.y) < track_window.z;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (in_tracks(world_pos.xz)) {
		// The deepest mark within half a lattice square, so one between
		// vertices still lifts the sand round it.
		vec2 xz = world_pos.xz;
		float near = max(track_at(xz), max(max(track_at(xz + vec2(0.5, 0.0)), track_at(xz - vec2(0.5, 0.0))),
			max(track_at(xz + vec2(0.0, 0.5)), track_at(xz - vec2(0.0, 0.5)))));
		VERTEX.y += track_lift * near;
	}
}

void fragment() {
	vec3 n = normalize(world_normal);
	vec2 at = world_pos.xz + origin;
	float grade = length(n.xz) / max(n.y, 0.05);
	// Steep and facing downwind: a slip face.
	float lee = smoothstep(0.42, 0.55, grade) * smoothstep(-0.2, 0.3, dot(normalize(n.xz + 1e-5), downwind));

	float broad = value_noise(at / 90.0) * 0.6 + value_noise(at / 23.0) * 0.4;
	vec3 colour = sand * mix(trough_shade, vec3(1.0), smoothstep(0.2, 0.8, broad) * 0.5 + 0.5);
	colour *= 1.0 + (value_noise(at / 7.0) - 0.5) * patchiness;
	colour *= mix(vec3(1.0), slip_shade, lee * 0.8);
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
	vec3 dpx = dFdx(world_pos);
	vec3 dpy = dFdy(world_pos);
	float bend = (dot(dFdx(world_normal), dpx) + dot(dFdy(world_normal), dpy)) / max(dot(dpx, dpx) + dot(dpy, dpy), 1e-4);
	colour *= 1.0 + crest_glow * smoothstep(0.06, 0.2, bend);

	// Ripples: a lopsided wave across the wind, wandering a little, gone on
	// slip faces and wherever a pixel spans more than about a tenth of one.
	vec2 across = vec2(-downwind.y, downwind.x);
	float phase = (dot(at, downwind) + 0.6 * sin(dot(at, across) * 0.9) + 1.5 * value_noise(at / 3.0)) / ripple_spacing;
	// Tracks: trodden sand is darker and sees less sky, a mark's walls tilt
	// the light, and the loose lip round it is lighter. Nothing glows: at
	// night and in a storm the contrast is the sand's own.
	float trodden = 0.0;
	vec3 dent = vec3(0.0);
	if (in_tracks(world_pos.xz)) {
		vec2 xz = world_pos.xz;
		float h = track_texel;
		float c = track_at(xz);
		float e = track_at(xz + vec2(h, 0.0));
		float w = track_at(xz - vec2(h, 0.0));
		float s = track_at(xz + vec2(0.0, h));
		float nn = track_at(xz - vec2(0.0, h));
		// The sand drawn depth * c lower: its slope is the depth's, inverted.
		dent = vec3(e - w, 0.0, s - nn) / (2.0 * h) * track_depth;
		// Any mark at all reads as trodden; a shallow one, half as dark.
		trodden = smoothstep(0.0, 0.2, c);
		float lip = clamp((e + w + s + nn) * 0.25 - c, 0.0, 1.0);
		colour *= mix(1.0, 1.0 - track_shade * (0.5 + 0.5 * smoothstep(0.0, 0.5, c)), trodden)
			* (1.0 + track_rim * smoothstep(0.0, 0.2, lip));
		AO = 1.0 - track_occlusion * smoothstep(0.0, 0.6, c);
	}

	float shown = 1.0 - smoothstep(0.06, 0.18, fwidth(phase));
	float fade = shown * (1.0 - lee) * (1.0 - trodden) * ripple_depth;
	float wave = phase * TAU;
	float slope = sin(wave) + 0.35 * sin(2.0 * wave);
	// The swell, wandering more and stronger in patches.
	float swell_phase = (dot(at, downwind) + 0.8 * sin(dot(at, across) * 0.23) + 2.5 * value_noise(at / 11.0)) / swell_spacing;
	float swell_shown = 1.0 - smoothstep(0.06, 0.18, fwidth(swell_phase));
	float swell = swell_shown * (1.0 - lee) * (1.0 - trodden) * swell_depth * (0.4 + 0.6 * broad);
	float swell_wave = swell_phase * TAU;
	slope = slope * fade + (sin(swell_wave) + 0.35 * sin(2.0 * swell_wave)) * swell;
	vec3 tilt = vec3(downwind.x, 0.0, downwind.y) * slope;
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
	float foot = max(length(dpx.xz), length(dpy.xz));
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

	ALBEDO = colour;
	ROUGHNESS = 1.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(rippled, 0.0)).xyz);
}

void light() {
	float nl = dot(NORMAL, LIGHT);
	float lit = max(nl, 0.0);
	float nv = max(dot(NORMAL, VIEW), 1e-3);
	vec3 incoming = LIGHT_COLOR * ATTENUATION;
	// Fujii's Oren-Nayar, as Lambert where grains hide nothing (s = 0). Only
	// a sky light under about 20 degrees: higher, or a lamp by your eye, it
	// flattens the ripples, as the full Moon looks flat; and Tu stands 30
	// degrees up where a run begins.
	float s = dot(LIGHT, VIEW) - nl * nv;
	float up = dot(LIGHT, VIEW_MATRIX[1].xyz);
	float rough = LIGHT_IS_DIRECTIONAL ? backscatter * (1.0 - smoothstep(0.17, 0.5, up)) : 0.0;
	float fon = 1.0 + rough * (s > 0.0 ? s / max(max(lit, nv), 1e-3) : s);
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
