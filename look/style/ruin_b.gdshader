shader_type spatial;
// Look-test B: the colonial ruin as poured, overbuilt concrete. Formwork seams
// in a grid, a faded painted band at head height, the foot stained where the
// sand drifts, and the windward faces scoured pale. Read from the ruin's own
// plan frame, where the floor's top is at 0.

uniform vec3 concrete : source_color = vec3(0.64, 0.58, 0.5);
uniform vec3 band : source_color = vec3(0.2, 0.38, 0.4);
uniform vec3 wind_dir = vec3(0.0, 0.0, 1.0);
uniform sampler2D noise : repeat_enable, filter_linear_mipmap;

varying vec3 lp;
varying vec3 ln;
varying vec3 wn;

void vertex() {
	lp = VERTEX;
	ln = NORMAL;
	wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

float tri(vec3 p, vec3 n, float s) {
	vec3 w = abs(n) + 0.001;
	w /= w.x + w.y + w.z;
	return texture(noise, p.yz * s).r * w.x + texture(noise, p.xz * s).r * w.y + texture(noise, p.xy * s).r * w.z;
}

void fragment() {
	float coarse = tri(lp, ln, 0.35);
	float fine = tri(lp, ln, 2.5);
	float grain = tri(lp, ln, 13.0);
	bool wall = abs(ln.y) < 0.5;
	float along = abs(ln.x) > 0.5 ? lp.z : lp.x;
	// Formwork: lifts every 0.75 m, panels every 1.5 m, tie holes at the corners.
	float lift = abs(fract(lp.y / 0.75 + 0.5) - 0.5) * 0.75;
	float panel = abs(fract(along / 1.5 + 0.5) - 0.5) * 1.5;
	float seam = wall ? 1.0 - smoothstep(0.004, 0.012, min(lift, panel)) : 0.0;
	float tie = wall ? 1.0 - smoothstep(0.015, 0.025, length(vec2(panel - 0.25, lift - 0.2))) : 0.0;
	vec3 col = concrete * (0.86 + 0.2 * coarse + 0.08 * grain);
	float painted = wall && lp.y > 1.95 && lp.y < 2.2 ? smoothstep(0.35, 0.55, fine + 0.3 * coarse) : 0.0;
	col = mix(col, band * (0.9 + 0.2 * grain), painted * 0.85);
	float windward = clamp(dot(normalize(wn), -normalize(wind_dir)), 0.0, 1.0);
	col = mix(col, col * 1.12 + 0.03, windward * (0.5 + 0.5 * grain));
	col *= 1.0 - 0.45 * seam - 0.6 * tie;
	// Stained low, where the drift sits and the frost melts into it.
	float low = wall ? 1.0 - smoothstep(0.2, 1.1, lp.y + 0.3 * coarse) : 0.0;
	col = mix(col, col * vec3(0.78, 0.7, 0.62), low * 0.7);
	if (COLOR.r < 0.45) {
		col = concrete * vec3(0.72, 0.68, 0.64) * (0.85 + 0.25 * coarse);
	}
	ALBEDO = col;
	ROUGHNESS = 0.92;
}
