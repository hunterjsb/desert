// The storm as the shaders see it: the field's own fronts, read off the storm
// map, with billowed faces, a hazy roof and a dense body. StormFace keeps a
// CPU twin of everything here that decides where the dust is.
//
// Positions are engine metres. The map and the billows both live in the air's
// frame (world minus the field's drift), so storms and their billows ride the
// wind together.

uniform sampler2D storm_map_a : filter_linear, repeat_disable;
uniform sampler2D storm_map_b : filter_linear, repeat_disable;
uniform float storm_map_blend;
// Engine xz + shift, over extent, is the map's uv.
uniform vec2 storm_map_shift;
uniform float storm_map_extent = 40000.0;
uniform int storm_map_cells = 128;
uniform float storm_map_ready = 0.0;
// Engine xz + this is the air frame, where billows are sampled.
uniform vec2 storm_air;
uniform float storm_time;
uniform float storm_height = 1800.0;
uniform float storm_roof_soft = 450.0;
// Extinction per metre inside: 3 / sigma is the visibility.
uniform float storm_sigma = 0.15;
// The prevailing wind's direction, and how far gusts inside have run through the air.
uniform vec2 storm_wind_dir = vec2(0.0, 1.0);
uniform vec2 storm_gust_shift;
uniform sampler3D storm_noise : filter_linear, repeat_enable;
// Dust running along the ground ahead of a face: extinction at its foot, how
// far ahead it reaches (e-fold, m) and how high (e-fold, m).
uniform float storm_skirt = 0.006;
uniform float storm_skirt_reach = 300.0;
uniform float storm_skirt_height = 10.0;

// Twins in StormMap and StormFace.
const float STORM_SLOPE_FLOOR = 2.0e-5;
const float STORM_FAR = 40000.0;
// How far a head swells out at mid height, metres.
const float STORM_SWELL = 180.0;
// Furthest a billow pokes ahead of its front: the billows' amplitudes (300,
// 70, 22 and 12 m) times a billow's peak (sqrt(1.02) - 0.35), plus a head's
// full swell. Less, and the march starts inside billows and slices them flat.
const float STORM_REACH = 450.0;
// A metre of body shades the sun like this many of roof.
const float STORM_BODY_WEIGHT = 25.0;
// Metres over which a face thickens to full density.
const float STORM_SKIN = 30.0;

// Each octave reads the tiling noise through its own tilt, at angles with no
// rational slope, so no pattern ever lines up and repeats along a face.
const mat3 STORM_TILT_A = mat3(vec3(0.8253, 0.0, -0.5646), vec3(0.2134, 0.9259, 0.3119), vec3(0.5228, -0.3779, 0.7642));
const mat3 STORM_TILT_B = mat3(vec3(0.6967, 0.3307, 0.6366), vec3(-0.4258, 0.9047, 0.0144), vec3(-0.5711, -0.2689, 0.7756));

// Signed metres to the nearest front (positive inside) and the unit normal
// pointing into the storm, from the field's value and slope at this place.
vec3 storm_front(vec2 p) {
	vec2 uv = (p + storm_map_shift) / storm_map_extent;
	vec4 m = mix(texture(storm_map_a, uv), texture(storm_map_b, uv), storm_map_blend);
	float steep = length(m.yz);
	float d = clamp(m.x / max(steep, STORM_SLOPE_FLOOR), -STORM_FAR, STORM_FAR);
	return vec3(d, steep > 0.0 ? m.yz / steep : vec2(0.0));
}

// The same, filtered here in full float. Hardware filtering weighs texels in
// 1/256 steps, a metre or so of the map; that vanishes under the billows but
// shows as tiles where the ground's light leans hard on the distance.
vec3 storm_front_exact(vec2 p) {
	vec2 at = (p + storm_map_shift) / storm_map_extent * float(storm_map_cells) - 0.5;
	ivec2 i = ivec2(floor(at));
	vec2 w = at - vec2(i);
	ivec2 top = ivec2(storm_map_cells - 1);
	ivec2 i0 = clamp(i, ivec2(0), top);
	ivec2 i1 = clamp(i + 1, ivec2(0), top);
	vec4 a = mix(mix(texelFetch(storm_map_a, i0, 0), texelFetch(storm_map_a, ivec2(i1.x, i0.y), 0), w.x),
		mix(texelFetch(storm_map_a, ivec2(i0.x, i1.y), 0), texelFetch(storm_map_a, i1, 0), w.x), w.y);
	vec4 b = mix(mix(texelFetch(storm_map_b, i0, 0), texelFetch(storm_map_b, ivec2(i1.x, i0.y), 0), w.x),
		mix(texelFetch(storm_map_b, ivec2(i0.x, i1.y), 0), texelFetch(storm_map_b, i1, 0), w.x), w.y);
	vec4 m = mix(a, b, storm_map_blend);
	float steep = length(m.yz);
	float d = clamp(m.x / max(steep, STORM_SLOPE_FLOOR), -STORM_FAR, STORM_FAR);
	return vec3(d, steep > 0.0 ? m.yz / steep : vec2(0.0));
}

// Optical depth of the ground dust along a ray from 0 to tb, in closed form:
// exponential in height and in distance ahead of the front, which is taken as
// straight where the ray ends. Streaks race along the ground with the wind.
float storm_skirt_depth_curved(vec3 ro, vec3 rd, float tb, vec3 frame) {
	vec3 pb = ro + rd * tb;
	vec3 f = storm_front_exact(pb.xz);
	float slope = dot(f.yz, rd.xz);
	float ahead_o = f.x - slope * tb;
	float k = slope / storm_skirt_reach - rd.y / storm_skirt_height;
	float at_b = storm_skirt * exp(min(f.x, 0.0) / storm_skirt_reach - max(pb.y, 0.0) / storm_skirt_height);
	float at_o = storm_skirt * exp(min(ahead_o, 0.0) / storm_skirt_reach - max(ro.y, 0.0) / storm_skirt_height);
	// A monotonic density integrates to between its end values times the length.
	float tau = clamp(abs(k) < 1.0e-5 ? at_b * tb : (at_b - at_o) / k,
		min(at_b, at_o) * tb, max(at_b, at_o) * tb);
	if (frame.z > 0.0) {
		// Four bounded quadrature taps lift dust samples back to the weather sheet.
		// Keep the one front lookup and the exact flat integral for other consumers.
		vec4 taps = vec4(-0.861136312, -0.339981044, 0.339981044, 0.861136312);
		vec4 weights = vec4(0.347854845, 0.652145155, 0.652145155, 0.347854845);
		float curved = 0.0;
		float straight = 0.0;
		for (int i = 0; i < 4; i++) {
			float along = tb * (0.5 + 0.5 * taps[i]);
			vec3 p = ro + rd * along;
			vec2 off = p.xz - frame.xy;
			float h = p.y + dot(off, off) / (2.0 * frame.z);
			float front = min(ahead_o + slope * along, 0.0) / storm_skirt_reach;
			straight += weights[i] * exp(front - max(p.y, 0.0) / storm_skirt_height);
			curved += weights[i] * exp(front - max(h, 0.0) / storm_skirt_height);
		}
		// A ratio preserves the existing integral as curvature tends to zero.
		tau *= straight > 0.0 ? curved / straight : 1.0;
		vec2 off = pb.xz - frame.xy;
		pb.y += dot(off, off) / (2.0 * frame.z);
	}
	vec2 a = pb.xz + storm_air - storm_gust_shift;
	vec2 across = vec2(-storm_wind_dir.y, storm_wind_dir.x);
	float streak = texture(storm_noise, vec3(dot(a, across) / 180.0, pb.y / 40.0,
		dot(a, storm_wind_dir) / 1300.0)).b;
	// Streaks only read near the ground close by, and stay gentle: pushed
	// harder, the noise's texel grid shows as tiles on the sand.
	float contrast = exp(-tb / 250.0);
	return tau * mix(1.0, mix(0.7, 1.35, streak), contrast) * storm_map_ready;
}

float storm_skirt_depth(vec3 ro, vec3 rd, float tb) {
	return storm_skirt_depth_curved(ro, rd, tb, vec3(0.0));
}

// Metres of full-density roof above h: the sun's path out over the top.
float storm_roof_path(float h) {
	float lo = storm_height - storm_roof_soft;
	float hi = storm_height + storm_roof_soft;
	if (h >= hi) {
		return 0.0;
	}
	if (h <= lo) {
		return lo - h + storm_roof_soft;
	}
	float x = hi - h;
	return x * x / (4.0 * storm_roof_soft);
}

// Metres of roof-thin dust between p and the sun. It leaves through the face
// if the sun is on the clear side, else over the roof; the body is far denser
// than the roof, so a metre of it counts many times. f is the depth behind the
// face (from the front, or from the billows where they're known) and the
// front's normal into the storm.
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

// Billow noise: rounded domes with sharp creases between them, the cauliflower
// of a dust head. n is a smooth noise in 0..1.
float storm_billow(float n) {
	float x = 2.0 * n - 1.0;
	return sqrt(x * x + 0.02) - 0.35;
}

// The head's shape, which changes slowly along a front: here it leans well
// back, there it swells at mid height, and its nose rides up off the ground
// by more or less. A wall seen edge-on shows the furthest billow along
// kilometres of face, the same at every height, so a vertical face draws a
// ruled line; a head that leans, swells and lifts its nose draws a curve.
// The head's slow field at an engine-space point: one read per sample, which
// the shading taps a few tens of metres away share.
vec4 storm_head_field(vec3 p) {
	return texture(storm_noise, vec3(p.x + storm_air.x, 0.0, p.z + storm_air.y) * (1.0 / 9000.0));
}

float storm_head(vec4 s, float h) {
	float swell = clamp((s.r - 0.5) * 3.0, -1.0, 1.0);
	float lean = 0.12 + clamp((s.a - 0.5) * 3.0, -1.0, 1.0) * 0.12;
	float nose = 90.0 * clamp((s.g - 0.5) * 3.0 + 0.5, 0.0, 1.0);
	return STORM_SWELL * swell * sin(3.14159 * clamp(h / storm_height, 0.0, 1.0))
		- lean * max(h - 120.0, 0.0) - nose * exp(-max(h, 0.0) / 90.0);
}

// How far the billowed face pokes out past the front at p, in metres, and the
// top of the wall there. Big billows rise slowly, smaller puffs rise faster and
// drift; a moving warp makes them churn instead of scroll. lod.x keeps the
// small puffs, lod.y the smallest, which only read up close.
float storm_bulge(vec3 p, vec2 lod, vec4 head, out float top) {
	float t = storm_time;
	vec3 q = vec3(p.x + storm_air.x, p.y, p.z + storm_air.y);
	vec4 w = texture(storm_noise, STORM_TILT_B * vec3(q.x + t * 3.0, q.y - t * 1.5, q.z) * (1.0 / 3700.0));
	vec3 qw = q + (w.rga - 0.5) * vec3(260.0, 140.0, 160.0);
	float b1 = storm_billow(texture(storm_noise, STORM_TILT_A * vec3(qw.x, qw.y - t * 2.2, qw.z) * (1.0 / 2300.0)).g);
	float b2 = storm_billow(texture(storm_noise, STORM_TILT_B * vec3(qw.x + t * 0.8, qw.y - t * 4.0, qw.z - t * 1.0) * (1.0 / 760.0)).g);
	float bulge = 300.0 * b1 + mix(30.0, 70.0, lod.x) * b2;
	if (lod.x > 0.0) {
		float b3 = storm_billow(texture(storm_noise, STORM_TILT_A * vec3(qw.x - t * 1.4, qw.y - t * 6.0, qw.z - t * 2.0) * (1.0 / 240.0)).b);
		bulge += lod.x * 22.0 * b3;
	}
	if (lod.y > 0.0) {
		float b4 = storm_billow(texture(storm_noise, STORM_TILT_B * vec3(qw.x + t * 2.5, qw.y - t * 7.5, qw.z - t * 3.0) * (1.0 / 75.0)).b);
		bulge += lod.y * 12.0 * b4;
	}
	// Broad rounded heads that dissolve upward, never a crisp skyline.
	top = storm_height + 600.0 * (w.r - 0.5) + 220.0 * b1;
	return bulge + storm_head(head, p.y);
}

// How far p sits inside its storm's dust, in metres, behind the billowed face
// and under the roof (negative = out in clear air), and behind the face alone;
// and the dust there. f is storm_front at p; gusts is how strongly the parcels
// show, 0 to 1.
float storm_density(vec3 p, vec3 f, vec2 lod, vec4 head, float gusts, out float edge, out float behind) {
	float top;
	edge = f.x + storm_bulge(p, lod, head, top);
	behind = edge;
	// A soft skin: the outer metres are thin enough to see into.
	float body = smoothstep(0.0, STORM_SKIN, edge);
	float roof = smoothstep(top + storm_roof_soft, top - storm_roof_soft, p.y);
	// Above the roof is clear air too: the edge counts it, so a ray climbing
	// over a storm strides by its height above the dust, not in small steps.
	edge = min(edge, top + storm_roof_soft - p.y);
	float sigma = storm_sigma * body * roof * storm_map_ready;
	if (gusts > 0.0 && edge > 10.0 && sigma > 0.0) {
		// Gusts inside: parcels of thicker and thinner dust racing past.
		vec3 q = vec3(p.x + storm_air.x - storm_gust_shift.x, p.y, p.z + storm_air.y - storm_gust_shift.y);
		float g = texture(storm_noise, q * (1.0 / 140.0)).a * 0.6
			+ texture(storm_noise, (q + vec3(0.0, storm_time * 2.0, 0.0)) * (1.0 / 38.0)).b * 0.4;
		sigma *= mix(1.0, 0.25 + 1.5 * smoothstep(0.25, 0.75, g), gusts * smoothstep(10.0, 40.0, edge));
	}
	return sigma;
}
