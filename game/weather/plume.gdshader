// A live vent's plume (Plume): soft puffs hung on the streakline worked out
// each frame. Each puff is a parcel that left the vent at a moment; its
// place, width and what it carries are its age's on the line, so it rides
// with the air and nothing moves here but the clock. Instance order is age
// order, a family at a time, so the far end draws first either way round.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled, skip_vertex_transform;

const int POINTS = 24;
const int FAMILIES = 5;
// The families, in Plume's order.
const int FALLOUT = 0;
const int MOUTH = 1;
const int COLUMN = 2;
const int BODY = 3;
const int TAIL = 4;
// The mouth's slot runs this far either way, m (GeologyKit's).
const float SLOT = 6.0;

uniform vec3 root;
uniform vec4 line[POINTS];
uniform vec4 matter[POINTS];
uniform vec4 seen[POINTS];
uniform float oldest = 600.0;
uniform float crowd = 1.6;
// Each family's first instance, how many, and its youngest and oldest age, s;
// and how far its newest parcel is through its step, and which parcel it is.
uniform vec4 families[FAMILIES];
uniform vec2 clocks[FAMILIES];
uniform int total = 236;
uniform bool reverse = false;
uniform vec3 wind = vec3(10.0, 0.0, 0.0);
uniform vec3 slot_dir = vec3(0.0, 0.0, 1.0);
// Now: how hard it's venting, its ash share, and how cold the air is for steam.
uniform vec4 now_mix = vec4(1.0, 0.2, 0.0, 0.0);
// Drawn nearer past the first, m; dissolving into the haze between the others.
uniform vec3 reach = vec3(4200.0, 11000.0, 15000.0);
// Past the skyline's reach, m, it's a landmark as the skyline's are: the
// haze takes it as if it were only as far as distance to this power says,
// so it stands out of the haze where a dune would be lost in it.
uniform vec2 landmark = vec2(3000.0, 0.3);

// Light, from Weather.
uniform vec3 sun_dir = vec3(0.0, 0.5, -0.86);
uniform vec3 sun_light = vec3(2.0);
uniform vec3 sky_light = vec3(0.8);
uniform vec3 ring_light = vec3(0.0);
uniform vec3 tu_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 tu_light = vec3(0.0);
uniform vec3 haze_color = vec3(0.7, 0.55, 0.4);
uniform vec3 haze = vec3(400.0, 9000.0, 0.7);
uniform float haze_height = 700.0;

uniform sampler2D noise : repeat_enable, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

// What it carries, as each looks: basalt ash, or a pocket's dust; steam; and
// the pale blue of sulphate haze, which throws the light forward as droplets do.
uniform vec3 ash_tone = vec3(0.075, 0.068, 0.062);
const vec3 STEAM = vec3(0.82, 0.84, 0.86);
const vec3 HAZE = vec3(0.42, 0.48, 0.56);

varying vec3 v_mix;
varying float v_thick;
varying float v_show;
varying float v_sun;
varying float v_dist;
varying float v_height;
varying vec4 v_seed;
varying float v_soft;
varying vec3 v_to;
// The puff's own turn, so no two show the same billows.
varying vec2 v_turn;

float phase_hg(float c, float g) {
	float g2 = g * g;
	return (1.0 - g2) / pow(1.0 + g2 - 2.0 * g * c, 1.5);
}

// Twin of storm_face.gdshader's.
float ring_phase(float c) {
	return 0.65 * phase_hg(c, 0.85) + 0.35 * phase_hg(c, 0.45);
}

// Twin of storm_face.gdshader's.
float haze_at(float t, float h) {
	return smoothstep(haze.x, haze.y, t) * haze.z * exp(-max(h, 0.0) / haze_height);
}

float hash(uint x) {
	x ^= x >> 16u;
	x *= 2146121005u;
	x ^= x >> 15u;
	x *= 2221713035u;
	x ^= x >> 16u;
	return float(x) / 4294967295.0;
}

vec4 hash4(uint n) {
	return vec4(hash(n * 4u), hash(n * 4u + 1u), hash(n * 4u + 2u), hash(n * 4u + 3u));
}

// The streakline at an age: place from the root, width, what it carries, and
// what the storms leave of it.
vec4 at_age(float age, out vec4 m, out vec4 s) {
	float x = pow(clamp(age / oldest, 0.0, 1.0), 1.0 / crowd) * float(POINTS - 1);
	int k = min(int(x), POINTS - 2);
	float w = x - float(k);
	m = mix(matter[k], matter[k + 1], w);
	s = mix(seen[k], seen[k + 1], w);
	return mix(line[k], line[k + 1], w);
}

void vertex() {
	int id = reverse ? total - 1 - INSTANCE_ID : INSTANCE_ID;
	int f = 0;
	for (int i = 1; i < FAMILIES; i++) {
		if (float(id) >= families[i].x) {
			f = i;
		}
	}
	vec4 fam = families[f];
	float slot = float(id) - fam.x;
	float step_s = (fam.w - fam.z) / fam.y;
	float age = fam.z + (clocks[f].x + slot) * step_s;
	uint parcel = uint(mod(clocks[f].y - slot, 1048576.0)) + uint(f) * 1048576u;
	vec4 h = hash4(parcel);
	vec4 h2 = hash4(parcel + 7340032u);
	vec4 m;
	vec4 s;
	vec3 center;
	float size;
	// Across and up: a levelled plume spreads wider than it's deep.
	float squash = 1.0;
	float thick;
	vec3 mixes;
	float shade = 1.0;
	float fade;
	float stretch = 1.0;
	if (f == FALLOUT) {
		// Coarse ash leaves the column low down and falls out downwind.
		float left = 6.0 + h.x * 22.0;
		vec4 p = at_age(left, m, s);
		float fall = 3.0 + h.y * 6.0;
		vec3 aside = normalize(vec3(h.z - 0.5, 0.0, h.w - 0.5) + 1.0e-4) * p.w * 0.4 * h2.x;
		center = root + p.xyz + aside + wind * age * 0.75 - vec3(0.0, fall * age, 0.0);
		size = p.w * (0.12 + 0.12 * h2.y) * (1.0 + age / 60.0);
		thick = m.x * 0.35 * exp(-age / 50.0);
		mixes = vec3(1.0, 0.0, 0.0);
		fade = smoothstep(0.0, 8.0, age) * smoothstep(0.0, 10.0, center.y - root.y)
			* (1.0 - smoothstep(fam.w - 40.0, fam.w, age));
		stretch = 2.6;
	} else if (f == MOUTH) {
		// Gas and steam working out along the slot, up from the pit.
		vec3 across = normalize(cross(slot_dir, vec3(0.0, 1.0, 0.0)));
		float up = 26.0 * pow(age / fam.w, 0.7) * (0.6 + 0.4 * min(now_mix.x, 3.0));
		center = root + slot_dir * (h.x * 2.0 - 1.0) * SLOT + across * (h.y - 0.5) * 3.0
			+ vec3(0.0, up - 0.5, 0.0) + wind * age * 0.5;
		size = (1.4 + age * 0.45) * (0.8 + 0.4 * h.z);
		s = seen[0];
		float strength = min(now_mix.x, 3.0);
		thick = (0.25 + 1.2 * now_mix.z) * strength * 0.6;
		mixes = vec3(now_mix.y * 0.5, now_mix.z, 1.0 - now_mix.z);
		fade = smoothstep(0.0, 1.5, age) * (1.0 - smoothstep(fam.w - 6.0, fam.w, age));
	} else {
		vec4 p = at_age(age, m, s);
		vec4 m2;
		vec4 s2;
		vec4 a = at_age(age + 3.0, m2, s2);
		vec4 b = at_age(max(age - 3.0, 0.0), m2, s2);
		vec3 along = a.xyz - b.xyz;
		along = length(along) > 1.0e-3 ? normalize(along) : vec3(0.0, 1.0, 0.0);
		vec3 side = cross(along, vec3(0.0, 1.0, 0.0));
		side = length(side) > 1.0e-3 ? normalize(side) : vec3(1.0, 0.0, 0.0);
		vec3 lift = cross(side, along);
		// Parcels keep their place in the plume's cross-section, rolling slowly.
		float spin = h.x * TAU + age * 0.02;
		float out_by = sqrt(h.y) * 0.55;
		vec3 dir = side * cos(spin) + lift * sin(spin);
		center = root + p.xyz + (side * cos(spin) * p.w + lift * sin(spin) * m.w) * out_by;
		size = p.w * mix(0.75, 1.05, h.z) * (f == COLUMN ? 0.8 : (f == BODY ? 0.85 : 0.95));
		squash = clamp(m.w / max(p.w, 1.0e-3), 0.25, 1.0);
		thick = (m.x + m.y + m.z) * 0.45;
		mixes = m.xyz;
		// The far side from the sun is in the plume's own shade.
		vec3 sun_across = sun_dir - along * dot(sun_dir, along);
		float sunward = length(sun_across) > 1.0e-3 ? dot(dir, normalize(sun_across)) * out_by / 0.55 : 0.0;
		shade = exp(-(m.x + m.y + m.z) * 0.6 * (1.0 - sunward) * 0.5);
		vec2 ends = f == COLUMN ? vec2(2.0, 20.0) : (f == BODY ? vec2(20.0, 40.0) : vec2(40.0, 140.0));
		fade = smoothstep(fam.z, fam.z + ends.x, age) * (1.0 - smoothstep(fam.w - ends.y, fam.w, age));
	}
	float sum = mixes.x + mixes.y + mixes.z;
	v_mix = sum > 1.0e-5 ? mixes / sum : vec3(0.0, 0.0, 1.0);
	v_thick = thick;

	vec3 eye = CAMERA_POSITION_WORLD;
	vec3 to = center - eye;
	float dist = length(to);
	// Past the camera's reach, nearer and smaller: the same in the view.
	float scale = dist > reach.x ? reach.x / dist : 1.0;
	vec3 drawn = eye + to * scale;
	float drawn_size = size * scale;
	vec3 corner = drawn + (INV_VIEW_MATRIX[0].xyz * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y * stretch * squash)
		* drawn_size * 2.0;
	VERTEX = (VIEW_MATRIX * vec4(corner, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_to = to / max(dist, 1.0e-3);
	v_dist = dist > landmark.x ? landmark.x * pow(dist / landmark.x, landmark.y) : dist;
	v_height = center.y;
	v_soft = scale < 1.0 ? 0.0 : drawn_size * 0.5;
	v_show = fade * (1.0 - smoothstep(reach.y, reach.z, dist)) * smoothstep(size * 0.6, size * 1.8, dist) * s.x;
	v_sun = s.y * shade;
	v_seed = h2;
	float turn = h2.z * TAU + age * 0.04;
	v_turn = vec2(cos(turn), sin(turn));
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r2 = dot(q, q);
	if (r2 >= 1.0 || v_show <= 0.0) {
		discard;
	}
	vec2 off = v_seed.xy * 5.0;
	vec2 turned = mat2(vec2(v_turn.x, v_turn.y), vec2(-v_turn.y, v_turn.x)) * q;
	float n = texture(noise, turned * 0.25 + off).r * 0.55 + texture(noise, turned * 0.6 - off * 1.3).r * 0.45;
	float shape = smoothstep(1.0, 0.25, sqrt(r2) + (n - 0.5) * 1.1);
	// Lit as a ball across its face, wrapped, so the light's side reads.
	vec3 nv = vec3(q.x, -q.y, sqrt(1.0 - r2));
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(nv, 0.0)).xyz);
	float c = dot(v_to, sun_dir);
	float wet = v_mix.y + v_mix.z;
	float forward = mix(1.0, phase_hg(c, 0.55), 0.5 * wet);
	float lit = mix(0.3, 1.0, clamp(dot(nw, sun_dir) * 0.6 + 0.5, 0.0, 1.0));
	vec3 albedo = ash_tone * v_mix.x + STEAM * v_mix.y + HAZE * v_mix.z;
	float tu_lit = mix(0.3, 1.0, clamp(dot(nw, tu_dir) * 0.6 + 0.5, 0.0, 1.0)) * step(0.0, tu_dir.y);
	vec3 light = sun_light * v_sun * lit * forward + sky_light * (0.55 + 0.45 * max(nw.y, 0.0))
		+ ring_light * ring_phase(c) * wet + tu_light * tu_lit;
	vec3 color = mix(albedo * light, haze_color, haze_at(v_dist, v_height));
	float a = (1.0 - exp(-v_thick * (0.5 + n))) * shape * v_show;
	if (v_soft > 0.0) {
		// Soft where it meets the ground.
		float z = texture(depth_tex, SCREEN_UV).r;
		vec4 scene = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, z, 1.0);
		a *= clamp((VERTEX.z - scene.z / scene.w) / v_soft, 0.0, 1.0);
	}
	if (a < 0.004) {
		discard;
	}
	ALBEDO = color;
	ALPHA = a;
}
