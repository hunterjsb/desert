shader_type spatial;
// The colonial ruin as poured, overbuilt concrete. Formwork seams in a grid,
// a faded painted band at head height, by each corner the contractor's tag
// and its stencilled number beside a member state's seal (early marks don't
// match), the foot stained where the sand drifts, and the windward faces
// scoured pale. Read from the ruin's own plan frame, where the
// floor's top is at 0.

uniform vec3 concrete : source_color = vec3(0.64, 0.58, 0.5);
uniform vec3 band : source_color = vec3(0.2, 0.38, 0.4);
uniform vec3 wind_dir = vec3(0.0, 0.0, 1.0);
uniform sampler2D noise : repeat_enable, filter_linear_mipmap;
// The worn shader's maker's marks, whose deep row is the colonial one: the
// contractor's tag is the first column, the member state's seal the last.
uniform sampler2D marks : hint_default_black, repeat_disable, filter_linear_mipmap;
// Half its plan to the outer faces, m: where the stencils go.
uniform vec2 half_plan = vec2(9.0, 6.0);

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

// Edges `e` soft, a pixel's footprint, so they don't crawl as you move.
float bar(vec2 p, vec2 lo, vec2 hi, vec2 e) {
	vec2 inside = smoothstep(lo - e, lo + e, p) * (1.0 - smoothstep(hi - e, hi + e, p));
	return inside.x * inside.y;
}

// "07" as a stencil cuts it, 0.84 by 0.6 m, p from its lower left.
float stencil(vec2 p, vec2 e) {
	float zero = max(max(bar(p, vec2(0.0), vec2(0.36, 0.07), e), bar(p, vec2(0.0, 0.53), vec2(0.36, 0.6), e)),
		max(bar(p, vec2(0.0, 0.1), vec2(0.07, 0.5), e), bar(p, vec2(0.29, 0.1), vec2(0.36, 0.5), e)));
	float seven = max(bar(p, vec2(0.48, 0.53), vec2(0.84, 0.6), e), bar(p, vec2(0.77, 0.0), vec2(0.84, 0.5), e));
	return max(zero, seven);
}

void fragment() {
	float coarse = tri(lp, ln, 0.35);
	float fine = tri(lp, ln, 2.5);
	float grain = tri(lp, ln, 13.0);
	bool wall = abs(ln.y) < 0.5;
	float along = abs(ln.x) > 0.5 ? lp.z : lp.x;
	// Formwork: lifts every 0.75 m, panels every 1.5 m, tie holes at the corners.
	// Each softens with a pixel's footprint and fades once it's thinner than
	// one, as the sand's ripples do: lines finer than a pixel shimmer.
	float px_y = fwidth(lp.y);
	float px_a = fwidth(along);
	float lift = abs(fract(lp.y / 0.75 + 0.5) - 0.5) * 0.75;
	float panel = abs(fract(along / 1.5 + 0.5) - 0.5) * 1.5;
	float seam_lift = (1.0 - smoothstep(0.004, 0.012 + px_y, lift)) * (1.0 - smoothstep(0.012, 0.04, px_y));
	float seam_panel = (1.0 - smoothstep(0.004, 0.012 + px_a, panel)) * (1.0 - smoothstep(0.012, 0.04, px_a));
	float seam = wall ? max(seam_lift, seam_panel) : 0.0;
	float px = max(px_y, px_a);
	float tie = wall ? (1.0 - smoothstep(0.015, 0.025 + px, length(vec2(panel - 0.25, lift - 0.2))))
		* (1.0 - smoothstep(0.015, 0.05, px)) : 0.0;
	vec3 col = concrete * (0.86 + 0.2 * coarse + 0.08 * grain);
	float in_band = smoothstep(1.95 - px_y, 1.95 + px_y, lp.y) * (1.0 - smoothstep(2.2 - px_y, 2.2 + px_y, lp.y));
	float painted = wall ? in_band * smoothstep(0.35, 0.55, fine + 0.3 * coarse) : 0.0;
	col = mix(col, band * (0.9 + 0.2 * grain), painted * 0.85);
	// On an outer face, read left to right from outside, 1.6 m in from its
	// corner, with the tag beside it, 0.7 by 0.35 m, and the seal, 0.4 across.
	vec2 out_n = vec2(ln.x, ln.z);
	float reach = abs(out_n.x) > 0.5 ? half_plan.x : half_plan.y;
	float right = lp.x * out_n.y - lp.z * out_n.x;
	float across = abs(out_n.x) > 0.5 ? half_plan.y : half_plan.x;
	vec2 on_tag = vec2(right - (across - 3.4), 1.675 - lp.y) / vec2(0.7, 0.35);
	vec2 in_tag = clamp(on_tag, 0.0, 1.0);
	float tag = texture(marks, in_tag / vec2(6.0, 3.0) + vec2(0.0, 2.0 / 3.0)).r;
	float tag_e = max(fwidth(tag), 0.08);
	vec2 on_seal = vec2(right - (across - 4.3), 1.7 - lp.y) / vec2(0.8, 0.4);
	vec2 in_seal = clamp(on_seal, 0.0, 1.0);
	float seal = texture(marks, (in_seal + vec2(5.0, 2.0)) / vec2(6.0, 3.0)).r;
	float seal_e = max(fwidth(seal), 0.08);
	vec2 px_mark = vec2(fwidth(right), px_y) * 0.75;
	if (wall && abs(dot(lp.xz, out_n) - reach) < 0.05) {
		float mark = stencil(vec2(right - (across - 2.44), lp.y - 1.2), px_mark);
		mark = max(mark, all(equal(in_tag, on_tag)) ? smoothstep(0.5 - tag_e, 0.5 + tag_e, tag + 0.2 * (grain - 0.5)) : 0.0);
		col = mix(col, vec3(0.25, 0.22, 0.2), mark * smoothstep(0.25, 0.6, fine + 0.2 * coarse) * 0.8);
		// Another hand's paint, in the band's colour.
		float sealed = all(equal(in_seal, on_seal)) ? smoothstep(0.5 - seal_e, 0.5 + seal_e, seal + 0.2 * (grain - 0.5)) : 0.0;
		col = mix(col, band * 0.85, sealed * smoothstep(0.3, 0.65, fine + 0.2 * coarse) * 0.6);
	}
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
