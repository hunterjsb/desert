// Spheres of clear air round running shields, which no dust enters: centre
// (engine metres) and live radius, filled by Weather from its shelters.
// Twins: Weather.shelter_at and StormFace.seen_at.

const int SHELTER_MAX = 8;
uniform vec4 shelters[SHELTER_MAX];
uniform int shelter_count = 0;

// Where a ray from ro along unit rd runs inside shelter i: (in, out), with
// out <= in if it misses.
vec2 shelter_span(int i, vec3 ro, vec3 rd) {
	vec3 oc = ro - shelters[i].xyz;
	float b = dot(oc, rd);
	float h = b * b - dot(oc, oc) + shelters[i].w * shelters[i].w;
	if (h <= 0.0) {
		return vec2(0.0);
	}
	h = sqrt(h);
	return vec2(-b - h, -b + h);
}

// Metres from p out to the nearest shell, negative inside a shelter.
float shelter_clearance(vec3 p) {
	float clear = 1.0e9;
	for (int i = 0; i < shelter_count; i++) {
		clear = min(clear, distance(p, shelters[i].xyz) - shelters[i].w);
	}
	return clear;
}

// Metres of the ray from 0 to t that run through shelters. Bubbles nest, so
// one wholly inside another adds nothing; partial overlaps count twice.
float shelter_length(vec3 ro, vec3 rd, float t) {
	float total = 0.0;
	for (int i = 0; i < shelter_count; i++) {
		bool nested = false;
		for (int j = 0; j < shelter_count; j++) {
			nested = nested || (j != i && distance(shelters[i].xyz, shelters[j].xyz) + shelters[i].w <= shelters[j].w);
		}
		vec2 s = clamp(shelter_span(i, ro, rd), 0.0, t);
		total += nested ? 0.0 : max(s.y - s.x, 0.0);
	}
	return min(total, t);
}
