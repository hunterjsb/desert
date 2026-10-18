// Tu's clouds on its own sphere, by latitude and by longitude round its spin
// from a meridian fixed to it, at world time. The sky draws them; a look-test
// unrolls them. `fp` is a pixel's width on Tu's surface, in its radii: detail
// finer than two pixels fades to its mean, so nothing shimmers as Tu turns.

// Tu's palette (docs/art-direction.md), linear.
const vec3 ZONE = vec3(0.686, 0.686, 0.644);
const vec3 BELT = vec3(0.209, 0.254, 0.305);
const vec3 DEEP = vec3(0.076, 0.102, 0.133);
const vec3 OCHRE = vec3(0.503, 0.342, 0.181);
const vec3 CREAM = vec3(0.776, 0.730, 0.632);
const vec3 RUST = vec3(0.342, 0.107, 0.054);
// How fast the bands slide over Tu, radians a second: unseen within a
// minute, plain over a session.
const float DRIFT = 0.00004;
// The storm ovals: latitude, longitude, and half-sizes along and across,
// each drifting at its own rate (rad/s) and turning on its own (rad/s, an
// anticyclone's way). The first is the red spot.
const vec4 OVALS[4] = { vec4(-0.38, 0.35, 0.2, 0.12), vec4(0.52, -0.6, 0.1, 0.05),
	vec4(0.2, 0.9, 0.07, 0.038), vec4(-0.7, -0.15, 0.09, 0.045) };
const float OVAL_RATES[4] = { 1.5e-5, -2.5e-5, 3.0e-5, -1.8e-5 };
const float OVAL_TURNS[4] = { 0.0035, -0.006, -0.007, 0.006 };

float hash12(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

// Value noise that joins up every `period` cells along x, so a field laid
// round Tu's longitude has no seam when it turns into view.
float tu_noise(vec2 p, float period) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = mod(i.x, period);
	float b = mod(i.x + 1.0, period);
	return mix(mix(hash12(vec2(a, i.y)), hash12(vec2(b, i.y)), u.x),
		mix(hash12(vec2(a, i.y + 1.0)), hash12(vec2(b, i.y + 1.0)), u.x), u.y);
}

// How much of a feature this wide on Tu (in its radii) shows: none under
// a pixel, all of it from two.
float tu_shown(float wide, float fp) {
	return smoothstep(fp * 0.8, fp * 2.0, wide);
}

// Octaves doubling, so each still joins round; `cell` is the first one's
// cells across, on Tu. Each fades to its mean as it gets too fine to show.
float tu_fbm(vec2 p, float period, float cell, float fp, int octaves) {
	float sum = 0.5;
	float amp = 0.5;
	for (int i = 0; i < octaves; i++) {
		float keep = tu_shown(cell, fp);
		if (keep <= 0.0) {
			break;
		}
		sum += amp * keep * (tu_noise(p, period) - 0.5);
		p = p * 2.0 + vec2(0.0, 7.31);
		period *= 2.0;
		cell *= 0.5;
		amp *= 0.5;
	}
	return sum;
}

// Zones and belts across latitude: above nought a zone, below it a belt.
float tu_band(float y) {
	return sin(y * 13.0 + 0.4) * 0.5 + sin(y * 29.0 + 1.9) * 0.25 + sin(y * 61.0 + 0.7) * 0.1
		+ (tu_noise(vec2(3.1, y * 40.0), 1.0e4) - 0.5) * 0.5;
}

// An oval at q, in its half-sizes: a pale hollow round it, a dark collar,
// a darker ring just inside, two arms swirling in to a lighter core, the
// whole turning slowly. `px` is a pixel in its half-sizes across.
vec3 tu_oval(vec3 c, vec2 q, float turned, vec3 tint, vec3 core, float px) {
	float e = length(q);
	if (e > 1.8) {
		return c;
	}
	c = mix(c, mix(c, ZONE, 0.45), smoothstep(1.8, 1.35, e) * smoothstep(1.05, 1.3, e));
	float collar = smoothstep(1.3, 1.08, e) * smoothstep(0.85, 1.02, e);
	c = mix(c, mix(c, DEEP, 0.6), collar * tu_shown(0.25, px));
	if (e < 1.04) {
		// Two arms wound a turn and a bit from rim to core, pale lanes
		// along them and dark ones between, broken up along their length.
		float a = atan(q.y, q.x) - turned;
		float wind = sin(TAU * (a / TAU * 2.0 + e * 1.2)) + (tu_noise(vec2(a / TAU * 6.0 + e * 3.0, e * 6.0), 6.0) - 0.5) * 1.5;
		float shown = tu_shown(0.3, px) * smoothstep(0.08, 0.4, e);
		vec3 inside = mix(tint * 0.68, tint, smoothstep(0.98, 0.74, e) * tu_shown(0.25, px));
		inside = mix(inside, core, smoothstep(0.58, 0.1, e));
		inside = mix(inside, mix(core, CREAM, 0.3), smoothstep(0.35, 1.0, wind) * 0.45 * shown);
		inside *= 1.0 - 0.28 * smoothstep(-0.35, -1.0, wind) * shown;
		c = mix(c, inside, smoothstep(1.04, 0.94, e));
	}
	return c;
}

vec3 tu_clouds(float lat, float lon, float time, float fp) {
	float wind = sin(lat * 9.0 + 0.6) * 0.6 + sin(lat * 23.0) * 0.4;
	// Longitude in turns, each band slid round by its own wind.
	float x = (lon + time * DRIFT * wind) / TAU;
	// Where each oval stands, in its half-sizes; and the bands bent round
	// them as a stream round a stone, so they squeeze past each one.
	vec2 q[4];
	float y = lat;
	for (int i = 0; i < 4; i++) {
		vec4 at = OVALS[i];
		float along = mod(lon - at.y - OVAL_RATES[i] * time + PI, TAU) - PI;
		q[i] = vec2(along / at.z, (lat - at.x) / at.w);
		float r2 = dot(q[i], q[i]);
		y -= at.w * q[i].y / max(r2, 1.0) * exp(-r2 * 0.08);
	}
	// Eddies big and small, drawn out along longitude. The big ones alone
	// never fold a band back on itself, so small things riding one stay single.
	y += (tu_fbm(vec2(x * 10.0, lat * 9.0), 10.0, 0.11, fp, 3) - 0.5) * 0.09;
	float y0 = y;
	y += (tu_fbm(vec2(x * 31.0, lat * 34.0), 31.0, 0.03, fp, 3) - 0.5) * 0.035;
	// Where a zone meets a belt the jets shear, and waves break along the
	// edge here and there, curling over as they lean with it.
	float edge = exp(-pow(tu_band(y), 2.0) * 5.0);
	float rough = tu_noise(vec2(x * 12.0, y * 25.0), 12.0);
	float jitter = tu_noise(vec2(x * 9.0, y * 12.0 + 4.0), 9.0) * 3.0;
	y += edge * rough * rough * (0.016 * sin(TAU * (x * 36.0 + jitter) + y * 70.0) * tu_shown(0.07, fp)
		+ 0.007 * sin(TAU * (x * 90.0 + jitter * 2.0) + y * 170.0 + 1.3) * tu_shown(0.028, fp));
	float band = tu_band(y);
	vec3 c = mix(BELT, ZONE, smoothstep(-0.45, 0.45, band));
	c = mix(c, DEEP, smoothstep(0.5, 0.9, -band) * 0.6);
	c = mix(c, OCHRE, smoothstep(0.3, 0.9, sin(y * 7.0 + 2.3)) * smoothstep(0.3, -0.3, band) * 0.3);
	// Rifts: pale streaks torn slantwise through the belts.
	float rift = tu_fbm(vec2(x * 20.0 + y * 6.0, y * 40.0), 20.0, 0.025, fp, 3);
	c = mix(c, ZONE * 0.85, smoothstep(0.6, 0.72, rift) * smoothstep(0.1, -0.4, band) * 0.6);
	// Festoons: dark plumes trailing from the north equatorial belt toward
	// the equator, each its own length and hooked back by the shear, dark
	// at the root, wisping out, some missing.
	float s = (0.245 - y) / 0.175;
	if (s > -0.2 && s < 1.0) {
		float k = x * 13.0 - 0.55 * s * s;
		float n = mod(floor(k), 13.0);
		vec4 h = vec4(hash12(vec2(n, 1.0)), hash12(vec2(n, 2.0)), hash12(vec2(n, 3.0)), hash12(vec2(n, 4.0)));
		float f = fract(k) - 0.5 - (h.x - 0.5) * 0.3 - (h.y - 0.5) * 0.3 * s * s;
		float w = mix(0.07, 0.02, s) * (0.7 + 0.6 * h.z);
		float wisp = 0.4 + 1.2 * tu_fbm(vec2(x * 80.0, y * 40.0), 80.0, 0.025, fp, 2);
		float plume = exp(-f * f / (w * w)) * smoothstep(-0.2, 0.05, s) * smoothstep(0.35 + 0.65 * h.w, 0.1 + 0.3 * h.w, s);
		float root = exp(-f * f / 0.012) * smoothstep(-0.2, 0.0, s) * smoothstep(0.25, 0.0, s);
		float on = step(0.25, h.x * 0.6 + h.w * 0.4);
		c = mix(c, mix(BELT, DEEP, 0.5), clamp(plume * wisp, 0.0, 1.0) * on * 0.7 * tu_shown(w * 0.8, fp));
		c = mix(c, DEEP, root * on * 0.4 * tu_shown(0.05, fp));
	}
	// A string of small white ovals along the dark belt south of the red spot.
	float p = (y0 + 0.6) / 0.026;
	if (abs(p) < 2.0) {
		float k = x * 9.0;
		float n = mod(floor(k), 9.0);
		vec2 at = vec2((fract(k) - 0.5) * TAU / 9.0 / 0.05, p);
		if (hash12(vec2(n, 5.0)) > 0.3) {
			c = tu_oval(c, at, 0.0, CREAM, ZONE, fp / 0.026);
		}
	}
	// Filaments along the flow, plainest where it's bent round the red spot.
	float near = exp(-dot(q[0], q[0]) * 0.12);
	c *= mix(0.86, 0.74, near) + mix(0.28, 0.52, near) * tu_fbm(vec2(x * 24.0, y * 55.0), 24.0, 0.018, fp, 4);
	// The red spot's wake: where the bands shear past it they tear into a
	// churning trail behind it, widening as it goes.
	vec2 w = q[0];
	float back = -w.x;
	float wake = smoothstep(0.7, 1.3, back) * smoothstep(6.0, 2.0, back) * exp(-pow((w.y - 0.5) / (0.7 + 0.2 * back), 2.0));
	if (wake > 0.001) {
		float churn = tu_fbm(vec2(x * 30.0, y * 30.0), 30.0, 0.033, fp, 3);
		float torn = tu_fbm(vec2(x * 36.0 + churn * 2.5, (y + (churn - 0.5) * 0.12) * 36.0), 36.0, 0.028, fp, 4);
		vec3 trail = mix(mix(BELT, DEEP, 0.5), ZONE, smoothstep(0.44, 0.56, torn));
		trail = mix(trail, OCHRE, smoothstep(0.56, 0.7, churn) * 0.5);
		c = mix(c, trail, wake * 0.9);
	}
	// The poles: a deep, mottled haze.
	c = mix(c, DEEP * (0.8 + 0.4 * tu_fbm(vec2(x * 25.0, lat * 20.0), 25.0, 0.05, fp, 2)), smoothstep(0.95, 1.3, abs(lat)));
	c = tu_oval(c, q[0], OVAL_TURNS[0] * time, RUST, mix(RUST, OCHRE, 0.55), fp / OVALS[0].w);
	for (int i = 1; i < 4; i++) {
		c = tu_oval(c, q[i], OVAL_TURNS[i] * time, CREAM, mix(CREAM, ZONE, 0.6), fp / OVALS[i].w);
	}
	return c;
}
