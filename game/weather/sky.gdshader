// Zan's sky as seen from where you stand: the dusty gradient and its haze, the
// stars turning about the pole, and Tu, a sphere each pixel's ray meets by its
// direction alone, so it never shifts as you move. Tu is lit by the real sun
// and seen through Zan's air, like the stars behind it. The sun's disc is the
// storm pass's, which draws over all of this.
shader_type sky;
// No debanding of its own: it would dither before the tonemap, where the eye
// opening on a dark night magnifies it. The project's dithers after.
render_mode disable_fog;

#include "res://game/weather/tu_clouds.gdshaderinc"

// The day's gradient, as the stock sky drew it.
uniform vec4 sky_top_color : source_color = vec4(0.385, 0.454, 0.55, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.86, 0.78, 0.66, 1.0);
uniform vec4 ground_bottom_color : source_color = vec4(0.2, 0.169, 0.133, 1.0);
uniform vec4 ground_horizon_color : source_color = vec4(0.86, 0.78, 0.66, 1.0);

// From SkyView each frame: how brightly the air glows, the haze's light and
// its share of the sky, and what a storm's dust lets through from beyond.
uniform vec3 sky_glow = vec3(1.0);
uniform vec3 haze_light = vec3(0.7, 0.54, 0.34);
uniform float haze_share = 0.6;
uniform float veil = 1.0;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
// Sunlight in space, which lights Tu whether or not the sun is up here.
uniform vec3 sun_light = vec3(1.0, 0.89, 0.71);
uniform vec3 tu_dir = vec3(-0.866, 0.5, 0.0);
uniform float tu_radius = 0.1165;
// Tu's spin axis, which is Zan's.
uniform vec3 tu_pole = vec3(0.0, 0.0, -1.0);
uniform float tu_time = 0.0;
// How far Tu has turned as seen from Zan (DayCycle.tu_turn), rad.
uniform float tu_spin = 0.0;
// From where you stand to the stars, which turn with the sun about Zan's pole.
uniform mat3 to_stars = mat3(1.0);
// The eclipse as it stands (DayCycle.eclipse): how far Tu's rim is backlit,
// the ring's flare, and the sun's centre from Tu's edge in its own radii, 1 at
// first contact and -1 at second; and the ring's light in Zan's air.
uniform vec3 eclipse = vec3(0.0, 0.0, 99.0);
uniform vec3 eclipse_air = vec3(0.0);
// The relay satellite, where it is from you and how brightly it shows: a
// point crossing the night, gone below the horizon or into Zan's shadow.
uniform vec3 relay_dir = vec3(0.0, -1.0, 0.0);
uniform float relay_light = 0.0;
// How far the relay shows by day too, 0 not at all to 1 as well as at night:
// only the nearest and brightest show against the day sky.
uniform float relay_day = 0.0;
// The other satellites (Constellation), each its own: where it is from you;
// its colour and how brightly it shows (a, 0 when it's down or in shadow);
// and its shape (Constellation.Shape) and size, in points; and how far it shows
// by day too, as relay_day.
const int SATELLITES = 16;
// By day a satellite bright enough to show is drawn this many times as bright,
// to stand out against the day sky as a night one does against the dark.
const float DAY_BOOST = 3.0;
uniform int sat_count = 0;
uniform vec3 sat_dir[SATELLITES];
uniform vec4 sat_color[SATELLITES];
uniform vec3 sat_form[SATELLITES];

// The rest of Tu's palette (docs/art-direction.md), linear.
const vec3 RIM = vec3(0.347, 0.527, 0.871);
const vec3 RING = vec3(1.0, 0.102, 0.013);
// Where the ring flares it burns hotter, orange toward gold; the diamond
// ring's bead is the sun's own light, bent; the corona is pearl.
const vec3 FLARE = vec3(1.0, 0.36, 0.07);
const vec3 BEAD = vec3(1.0, 0.8, 0.5);
const vec3 PEARL = vec3(0.88, 0.94, 1.0);
// The outer corona just past the sun's edge, as a share of its light.
const float CORONA = 0.4;
// How far out the ring's glow reaches, in Tu's radii.
const float REACH = 3.0;
// The sun's angular radius as the storm pass draws it.
const float SUN_RADIUS = 0.00942;
// Star cells along each face of a cube round the sky, and the share holding one.
const float CELLS = 90.0;
const float STARRED = 0.3;
// Zan's air between here and space, per airmass: thin and dusty, so what's
// low is dimmed and warmed, and the dust that hangs low reddens it more.
const vec3 EXTINCTION = vec3(0.07, 0.09, 0.13);
const vec3 LOW_DUST = vec3(0.0, 0.06, 0.16);

vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		sum += amp * noise(p);
		p = p * 2.03 + vec2(7.1, 3.7);
		amp *= 0.5;
	}
	return sum;
}

vec3 gradient(vec3 d) {
	float v = clamp(d.y, -1.0, 1.0);
	vec3 sky = mix(sky_top_color.rgb, sky_horizon_color.rgb, clamp(pow(1.0 - v, 4.0), 0.0, 1.0));
	vec3 ground = mix(ground_bottom_color.rgb, ground_horizon_color.rgb, clamp(pow(1.0 + v, 30.0), 0.0, 1.0));
	return mix(ground, sky, step(0.0, d.y));
}

// What of the light from beyond gets through the air, looking this far up.
vec3 through_air(float up) {
	float h = max(up, 0.0);
	float airmass = 1.0 / (h + 0.045 * exp(-12.0 * h));
	return exp(-EXTINCTION * airmass - LOW_DUST * max(airmass - 2.0, 0.0)) * smoothstep(-0.02, 0.0, up);
}

// The fixed field: a cube round the sky in cells, a few holding one star kept
// clear of its cell's edges, bright ones rare; and the pole marks, a bright
// star at the north and a close pair at the south.
// A satellite's shape round its centre, uv in points across the sky: a
// point, a cross of panels, a bar, a ring, a pair, or a diamond.
float satellite(vec2 uv, int shape) {
	float r2 = dot(uv, uv);
	float core = exp(-r2 * 0.8);
	if (shape == 1) {
		return core + 0.5 * (exp(-uv.y * uv.y * 3.0) * exp(-abs(uv.x) * 0.7)
			+ exp(-uv.x * uv.x * 3.0) * exp(-abs(uv.y) * 0.7));
	} else if (shape == 2) {
		return core + 0.6 * exp(-uv.y * uv.y * 3.0) * smoothstep(3.6, 2.4, abs(uv.x));
	} else if (shape == 3) {
		float r = sqrt(r2);
		return 0.8 * exp(-(r - 2.2) * (r - 2.2) * 2.5) + 0.3 * exp(-r2 * 1.5);
	} else if (shape == 4) {
		vec2 a = uv - vec2(1.6, 0.0);
		vec2 b = uv + vec2(1.6, 0.0);
		return exp(-dot(a, a) * 0.8) + exp(-dot(b, b) * 0.8);
	} else if (shape == 5) {
		float m = abs(uv.x) + abs(uv.y);
		return exp(-m * m * 0.5);
	}
	return core;
}

vec3 stars(vec3 s, float px) {
	vec3 a = abs(s);
	float face;
	vec2 uv;
	if (a.x >= a.y && a.x >= a.z) {
		face = s.x > 0.0 ? 0.0 : 1.0;
		uv = s.yz / a.x;
	} else if (a.y >= a.z) {
		face = s.y > 0.0 ? 2.0 : 3.0;
		uv = s.xz / a.y;
	} else {
		face = s.z > 0.0 ? 4.0 : 5.0;
		uv = s.xy / a.z;
	}
	vec2 cell = floor((uv * 0.5 + 0.5) * CELLS);
	vec3 h = hash33(vec3(cell, face * 131.0 + 17.0));
	vec3 light = vec3(0.0);
	if (h.z < STARRED) {
		vec2 at = (cell + 0.25 + 0.5 * h.xy) / CELLS * 2.0 - 1.0;
		float sign_of = mod(face, 2.0) < 0.5 ? 1.0 : -1.0;
		vec3 star = face < 1.5 ? vec3(sign_of, at) : face < 3.5 ? vec3(at.x, sign_of, at.y) : vec3(at, sign_of);
		float m = hash12(cell * 1.7 + face);
		float bright = 0.003 + 0.02 * pow(m, 4.0) + 0.07 * pow(m, 24.0);
		vec3 tint = mix(vec3(1.0, 0.84, 0.68), vec3(0.78, 0.86, 1.0), hash12(cell + face * 9.0));
		float off = length(s - normalize(star)) / px;
		light += tint * bright * exp(-off * off * 1.4);
	}
	float north = length(s - vec3(0.0, 0.0, 1.0)) / px;
	float south_a = length(s - normalize(vec3(0.0058, 0.0, -1.0))) / px;
	float south_b = length(s - normalize(vec3(-0.0046, 0.0035, -1.0))) / px;
	light += vec3(0.9, 0.95, 1.0) * 1.2 * exp(-north * north * 0.5);
	light += vec3(1.0, 0.9, 0.8) * 0.5 * (exp(-south_a * south_a * 0.7) + exp(-south_b * south_b * 0.7));
	return light;
}

void sky() {
	vec3 d = EYEDIR;
	vec3 base = mix(gradient(d) * sky_glow, haze_light, haze_share);
	if (eclipse_air.r > 0.0) {
		// The ring's light scattered in Zan's thin air: a band low round the
		// whole horizon, where the most air lies, brightest under the ring.
		float under = 0.5 + 0.5 * dot(normalize(d.xz + 1.0e-5), normalize(sun_dir.xz + 1.0e-5));
		base += eclipse_air * exp(-max(d.y, 0.0) * 9.0) * smoothstep(-0.1, 0.0, d.y) * (0.6 + 0.4 * under * under);
	}
	float glow = max(sky_glow.r, max(sky_glow.g, sky_glow.b));
	if (AT_CUBEMAP_PASS) {
		COLOR = base;
	} else {
		float px = max(length(fwidth(d)), 1.0e-5);
		vec3 air = through_air(d.y);
		// Low down the dust softens Tu as it dims it.
		float low = 1.0 - smoothstep(0.02, 0.25, d.y);
		vec3 beyond = vec3(0.0);
		float cover = 0.0;
		float c = dot(d, tu_dir);
		float r = tu_radius;
		if (c > cos(r * 1.25) && d.y > -0.02) {
			// The ray meets a unit sphere this far off, or grazes it.
			float dist = 1.0 / sin(r);
			float b = c * dist;
			float h = max(b * b - dist * dist + 1.0, 0.0);
			vec3 n = normalize(d * (b - sqrt(h)) - tu_dir * dist);
			float soft = px * 1.5 + 0.004 * r * low * 8.0;
			cover = smoothstep(cos(r + soft), cos(r - soft), c);
			// Tu's own latitude and longitude, from the meridian facing Zan,
			// turned back by Tu's spin to the clouds' own.
			vec3 toward = normalize(-tu_dir - tu_pole * dot(-tu_dir, tu_pole));
			float lat = asin(clamp(dot(n, tu_pole), -1.0, 1.0));
			float lon = atan(dot(n, cross(tu_pole, toward)), dot(n, toward));
			float mu = clamp(dot(n, -d), 0.0, 1.0);
			float lit = dot(n, sun_dir);
			// A pixel's width where the ray meets Tu, foreshortened toward the
			// limb; fwidth's sum of both ways makes px about 1.4 pixels. The
			// night face keeps only its broad bands, so in the eclipse only
			// the ring holds the eye.
			float fp = px * 0.7 * (b - sqrt(h)) / max(mu, 0.2);
			fp = max(fp, 0.08 * smoothstep(0.05, -0.12, lit));
			vec3 albedo = tu_clouds(lat, lon - tu_spin, tu_time, fp);
			albedo = mix(albedo, vec3(dot(albedo, vec3(0.333))), low * 0.5);
			// A deep atmosphere: a soft terminator, gentle limb darkening, a
			// thin bright rim on the lit side and a night face only just there.
			float shade = pow(max((lit + 0.06) / 1.06, 0.0), 1.15);
			vec3 face = albedo * sun_light * (shade * pow(mu, 0.35) + 0.0015);
			face += RIM * sun_light * pow(1.0 - mu, 6.0) * smoothstep(-0.15, 0.4, lit) * 0.3;
			beyond = face * cover;
			// Just past the limb the same air glows where the sun lights it.
			float past = (acos(clamp(c, -1.0, 1.0)) - r) / max(r * 0.02, px);
			vec3 limb = normalize(d - tu_dir * c);
			beyond += RIM * sun_light * 0.12 * exp(-max(past, 0.0)) * smoothstep(-0.1, 0.5, dot(limb, sun_dir))
				* (1.0 - cover);
		}
		float behind = eclipse.x;
		vec3 off_sun = sun_dir - tu_dir * dot(sun_dir, tu_dir);
		float off = length(off_sun);
		if (behind > 0.0 && c > cos(r * REACH) && d.y > -0.02) {
			// Backlit, Tu's rim is a ring of sunset light: a thin line of fire,
			// Tu's high haze lit just inside it, and a soft glow past it that
			// fades to nothing well inside the reach, so it never ends in an edge.
			float from_tu = acos(clamp(c, -1.0, 1.0));
			float past = (from_tu - r) / max(r * 0.02, px);
			vec3 limb = normalize(d - tu_dir * c);
			float side = off > 1.0e-4 ? 0.5 + 0.5 * dot(limb, off_sun / off) : 0.5;
			side = mix(0.5, side, smoothstep(0.0, 0.3 * r, off));
			// It flares in an arc where the sun goes in and comes out, the arc
			// spreading round the limb as it fades.
			float flare = 0.7 * eclipse.y * pow(side, mix(1.5, 6.0, eclipse.y));
			// Patchy, as the clouds along the limb are, and slowly boiling.
			vec3 e1 = normalize(tu_pole - tu_dir * dot(tu_pole, tu_dir));
			vec2 round = vec2(dot(limb, e1), dot(limb, cross(tu_dir, e1)));
			float patch = 0.55 + 0.9 * fbm(round * 5.0 + vec2(11.0 + tu_time * 0.05, 11.0 - tu_time * 0.03));
			float line = exp(-abs(past) * 0.7);
			float aura = (0.2 * exp(-past * 0.15) + 0.05 * exp(-past * 0.035)) * smoothstep(r * REACH, r * 1.5, from_tu);
			float lit = line + (past < 0.0 ? 0.3 * exp(past * 0.25) : aura);
			vec3 fire = mix(RING, FLARE, clamp(flare * 1.5, 0.0, 1.0) * line);
			beyond += fire * sun_light * behind * patch * lit * (0.07 + flare);
		}
		// The diamond ring: the last of the sun bent round the limb, a bead
		// blazing where it goes in and lingering a second or two; and again
		// where it comes out.
		float bead = smoothstep(1.0, -1.0, eclipse.z) * exp(-max(-1.0 - eclipse.z, 0.0) / 0.8);
		if (bead > 0.001 && off > 1.0e-4 && d.y > -0.02) {
			vec3 at = tu_dir * cos(r) + off_sun / off * sin(r);
			float from_bead = acos(clamp(dot(d, at), -1.0, 1.0)) / SUN_RADIUS;
			beyond += BEAD * sun_light * bead * (3.0 * exp(-from_bead * from_bead * 6.0)
				+ 0.3 * exp(-from_bead * 0.9) + 0.03 * exp(-from_bead * 0.2));
		}
		// The sun's corona, past its disc and wherever Tu doesn't hide it.
		float from_sun = acos(clamp(dot(d, sun_dir), -1.0, 1.0));
		vec3 corona = sun_light * 0.03 * pow(SUN_RADIUS / max(from_sun, SUN_RADIUS), 3.0);
		if (behind > 0.0) {
			// Behind Tu the outer corona shows: pearly streamers, longest along
			// the sun's equator, slowly changing.
			vec3 v = d - sun_dir * dot(d, sun_dir);
			vec3 a1 = normalize(tu_pole - sun_dir * dot(tu_pole, sun_dir));
			vec2 around = vec2(dot(v, a1), dot(v, cross(sun_dir, a1))) / max(length(v), 1.0e-6);
			float out_r = max(from_sun, SUN_RADIUS) / SUN_RADIUS;
			float streams = smoothstep(0.32, 0.68, fbm(around * (3.0 + 0.12 * out_r) + vec2(5.0, tu_time * 0.02)));
			corona += PEARL * sun_light * CORONA * behind * pow(out_r, -2.2) * (0.55 + 0.45 * around.y * around.y)
				* (0.3 + 1.5 * streams);
		}
		// Stars show once the air's glow is down, and never through Tu.
		float dark = 1.0 - smoothstep(0.003, 0.06, glow);
		vec3 field = dark > 0.0 && d.y > -0.02 ? stars(to_stars * d, px) * dark : vec3(0.0);
		// The satellites orbit Zan, far nearer than Tu: they show in front of it.
		vec3 orbiting = vec3(0.0);
		// Seen at night, or by day if near and bright enough; brighter against the day.
		float relay_seen = max(dark, relay_day);
		if (relay_light > 0.0 && relay_seen > 0.0) {
			float from_relay = length(d - relay_dir) / px;
			orbiting += vec3(1.0, 0.97, 0.9) * relay_light * relay_seen * mix(DAY_BOOST, 1.0, dark)
				* exp(-from_relay * from_relay * 0.8);
		}
		{
			for (int i = 0; i < sat_count; i++) {
				float seen = max(dark, sat_form[i].z);
				if (sat_color[i].a <= 0.0 || seen <= 0.0) {
					continue;
				}
				seen *= mix(DAY_BOOST, 1.0, dark);
				vec3 at = sat_dir[i];
				// Its own across and up on the sky, level with the horizon.
				vec3 across = cross(vec3(0.0, 1.0, 0.0), at);
				across = length(across) < 1.0e-4 ? vec3(1.0, 0.0, 0.0) : normalize(across);
				vec3 up = cross(at, across);
				vec3 off = d - at;
				if (dot(d, at) < 0.99) {
					continue;
				}
				vec2 uv = vec2(dot(off, across), dot(off, up)) / (px * sat_form[i].y);
				orbiting += sat_color[i].rgb * sat_color[i].a * seen * satellite(uv, int(sat_form[i].x));
			}
		}
		beyond += (field + corona) * (1.0 - cover) + orbiting;
		COLOR = base + air * veil * beyond;
	}
}
