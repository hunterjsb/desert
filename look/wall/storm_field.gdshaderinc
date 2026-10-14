// The storm as one field: a front line, a billowing face, a hazy roof and a body.
// Every shader that draws the storm reads it from here; storm.gd keeps a CPU twin
// of the smooth parts (front, roof, sun path) for distances and light.
//
// Storm frame: u along the front, h above the base, s along the heading. The
// field moves with the front, so billows travel with it and never slide off.

uniform vec3 storm_anchor;
uniform vec2 storm_dir = vec2(0.0, 1.0);
// 1 / (2R): the front bows out toward where it is heading.
uniform float storm_bend = 6.0e-6;
uniform vec4 storm_lobe_a;
uniform vec4 storm_lobe_k;
uniform vec4 storm_lobe_p;
uniform float storm_time;
uniform float storm_height = 1800.0;
uniform float storm_roof_soft = 220.0;
// Extinction per metre inside: 3 / sigma is the visibility, about 20 m.
uniform float storm_sigma = 0.15;
// Wind inside, relative to the front, in the storm frame.
uniform vec3 storm_gust = vec3(1.5, 1.0, 12.0);
uniform sampler3D storm_noise : filter_linear, repeat_enable;

// Furthest a billow pokes ahead of the front line.
const float STORM_REACH = 190.0;
const float STORM_BODY_WEIGHT = 25.0;

vec3 storm_frame(vec3 p) {
	vec2 d = p.xz - storm_anchor.xz;
	return vec3(dot(d, vec2(-storm_dir.y, storm_dir.x)), p.y - storm_anchor.y, dot(d, storm_dir));
}

vec3 storm_frame_dir(vec3 v) {
	return vec3(dot(v.xz, vec2(-storm_dir.y, storm_dir.x)), v.y, dot(v.xz, storm_dir));
}

float storm_front(float u) {
	return -u * u * storm_bend + dot(storm_lobe_a, sin(storm_lobe_k * u + storm_lobe_p));
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

// Metres of roof-thin dust between q and the sun (sq is the sun in the storm frame).
// It leaves through the face if the sun is on the clear side, else over the roof;
// the body is far denser than the roof, so a metre of it counts many times.
float storm_sun_path(vec3 q, vec3 sq) {
	float depth = storm_front(q.x) - q.z;
	float up = max(sq.y, 0.02);
	if (depth <= 0.0) {
		if (sq.z >= -0.001) {
			return 0.0;
		}
		return storm_roof_path(q.y + depth / sq.z * up) / up;
	}
	float out_top = storm_roof_path(q.y) / up;
	return sq.z > 0.001 ? min(out_top, depth / sq.z * STORM_BODY_WEIGHT) : out_top;
}

// The billowed face: how far q sits behind it, in metres (negative = ahead).
// Big billows rise slowly, smaller puffs rise faster and drift; a moving warp
// makes them churn instead of scroll. lod.x keeps the small puffs, lod.y the
// smallest, which only read up close.
float storm_edge(vec3 q, vec2 lod, out float top) {
	float t = storm_time;
	vec4 w = texture(storm_noise, vec3(q.x + t * 3.0, q.y - t * 1.5, q.z) * (1.0 / 3100.0));
	vec3 qw = q + (w.rga - 0.5) * vec3(320.0, 260.0, 200.0);
	float g1 = texture(storm_noise, vec3(qw.x, qw.y - t * 2.2, qw.z) * (1.0 / 2300.0)).g;
	float g2 = texture(storm_noise, vec3(qw.x + t * 0.8, qw.y - t * 4.0, qw.z - t * 1.0) * (1.0 / 760.0)).g;
	float bulge = 250.0 * (g1 - 0.5) + 95.0 * (g2 - 0.5);
	if (lod.x > 0.0) {
		float g3 = texture(storm_noise, vec3(qw.x - t * 1.4, qw.y - t * 6.0, qw.z - t * 2.0) * (1.0 / 240.0)).b;
		bulge += lod.x * 34.0 * (g3 - 0.5);
	}
	if (lod.y > 0.0) {
		float g4 = texture(storm_noise, vec3(qw.x + t * 2.5, qw.y - t * 7.5, qw.z - t * 3.0) * (1.0 / 75.0)).g;
		bulge += lod.y * 12.0 * (g4 - 0.5);
	}
	top = storm_height + 520.0 * (g1 - 0.5) + 170.0 * (g2 - 0.5);
	// Leans back a little with height, like the head of a gravity current.
	return storm_front(q.x) - q.z + bulge - 0.07 * max(q.y - 120.0, 0.0);
}

float storm_density(vec3 q, vec2 lod, out float edge) {
	float top;
	edge = storm_edge(q, lod, top);
	// A soft skin: the outer tens of metres are thin enough to see into.
	float body = smoothstep(0.0, 55.0, edge);
	float roof = smoothstep(top + storm_roof_soft, top - storm_roof_soft, q.y);
	float sigma = storm_sigma * body * roof;
	if (lod.y > 0.0 && edge > 10.0 && sigma > 0.0) {
		// Gusts inside: parcels of thicker and thinner dust racing past.
		vec3 flow = storm_gust * storm_time;
		float g = texture(storm_noise, (q - flow) * (1.0 / 140.0)).a * 0.6
			+ texture(storm_noise, (q - flow * 1.3 + vec3(0.0, storm_time * 2.0, 0.0)) * (1.0 / 38.0)).b * 0.4;
		sigma *= mix(1.0, 0.25 + 1.5 * smoothstep(0.25, 0.75, g), lod.y * smoothstep(10.0, 40.0, edge));
	}
	return sigma;
}
