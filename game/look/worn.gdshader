shader_type spatial;
// Painted metal worn by this moon. Paint chips at edges and corners down to
// bare metal, and the old chips are red rust; faces turned to the prevailing
// wind are scoured pale and matte; sand settles on whatever faces up and in
// the low band at the foot. No UVs: everything is read from each piece's own
// frame, so primitives wear without unwrapping.
//
// A kit mesh merges a device's pieces into one draw, so each vertex carries
// its piece: CUSTOM0 the point in the piece's frame (w: 1 a box, 2 a drum),
// CUSTOM1 the piece's half extents (w: metalness), CUSTOM2 roughness, dust,
// glow and its share of the wear, CUSTOM3 its height over the whole thing's
// foot, COLOR its paint, and UV and UV2 a maker's mark painted on it: where on
// the mark, and which mark (0 for none) in what ink, plus four times one more
// than the atlas row it's from (none: its thing's era). A mesh without them,
// a look-test's loose piece, takes the uniforms instead.

uniform vec3 paint : source_color = vec3(0.72, 0.68, 0.58);
uniform vec3 bare : source_color = vec3(0.5, 0.49, 0.47);
uniform vec3 rust : source_color = vec3(0.4, 0.16, 0.07);
uniform vec3 dust : source_color = vec3(0.7, 0.57, 0.41);
uniform float paint_rough = 0.62;
uniform float paint_metal = 0.0;
// 0 is fresh from the crate (colonial stock, sealed away), 1 is a century outside.
uniform float wear = 0.45;
uniform float chip_width = 0.025;
uniform float dust_amount = 1.0;
// Downwind, world; faces turned against it take the sand.
uniform vec3 wind_dir = vec3(0.0, 0.0, 1.0);
uniform sampler2D noise : repeat_enable, filter_linear_mipmap;
// Maker's marks, a column each and a row per era, and below them the ages
// after's own (marks.py): red the mark's own ink, green a hand-mixed daub.
uniform sampler2D marks : hint_default_black, repeat_disable, filter_linear_mipmap;
const vec2 MARK_CELLS = vec2(6.0, 4.0);
const vec3 DARK_INK = vec3(0.007, 0.007, 0.006);
const vec3 PALE_INK = vec3(0.52, 0.48, 0.37);
// A scratch cuts through the paint to bright metal: heraldry cut into enamel.
const vec3 SCRATCH = vec3(0.7, 0.68, 0.64);
const vec3 DAUB = vec3(0.5, 0.13, 0.03);
// The piece's half extents in its own frame, so edges are found without UVs;
// round_xz measures x and z as a cylinder's radius.
instance uniform vec3 half_size = vec3(0.5);
instance uniform float round_xz = 0.0;
// How far this one thing has worn, scaling `wear`: a find's years, a device's
// soundness. `lit` lights its glowing pieces, while it runs.
instance uniform float age = 1.0;
instance uniform float lit = 0.0;
// Whose hands its mark is from: 0 a recent make, 1 the surface's, 2 the deep's.
instance uniform float era = 0.0;
// How far over its foot the sand stands now, m: a structure between states.
instance uniform float foot_shift = 0.0;

varying vec3 obj_pos;
varying vec3 obj_n;
varying vec3 world_n;
varying vec3 piece_pos;
varying vec4 piece;
varying vec4 finish;
varying float above;
varying vec4 stamp;

void vertex() {
	obj_pos = VERTEX;
	obj_n = NORMAL;
	world_n = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	bool kit = CUSTOM0.w > 0.5;
	piece_pos = kit ? CUSTOM0.xyz : VERTEX;
	piece = kit ? vec4(CUSTOM1.xyz, CUSTOM0.w > 1.5 ? 1.0 : 0.0) : vec4(half_size, round_xz);
	finish = kit ? vec4(CUSTOM1.w, CUSTOM2.x, CUSTOM2.y, CUSTOM2.w) : vec4(paint_metal, paint_rough, dust_amount, 1.0);
	above = kit ? CUSTOM3.x - foot_shift : piece_pos.y + piece.y;
	stamp = kit ? vec4(UV, UV2) : vec4(0.0);
	// The colour's alpha carries the piece's glow on.
	COLOR.a = kit ? CUSTOM2.z : 0.0;
}

float tri(vec3 p, vec3 n, float s) {
	vec3 w = abs(n) + 0.001;
	w /= w.x + w.y + w.z;
	return texture(noise, p.yz * s).r * w.x + texture(noise, p.xz * s).r * w.y + texture(noise, p.xy * s).r * w.z;
}

void fragment() {
	vec3 hs = piece.xyz;
	vec3 d = max(hs - abs(piece_pos), vec3(0.0));
	if (piece.w > 0.5) {
		float r = hs.x - length(piece_pos.xz);
		d = vec3(max(r, 0.0), d.y, 1e3);
	}
	float amount = wear * age * finish.w;
	vec3 base = paint * COLOR.rgb;
	// The nearest edge is where the two nearest faces meet: the middle distance.
	float lo = min(d.x, min(d.y, d.z));
	float hi = max(d.x, max(d.y, d.z));
	float edge_d = d.x + d.y + d.z - lo - hi;
	float corner = 1.0 - smoothstep(0.0, chip_width * 2.5, hi);
	float coarse = tri(obj_pos, obj_n, 2.3);
	float fine = tri(obj_pos, obj_n, 9.0);
	float grain = tri(obj_pos, obj_n, 31.0);
	// The mark went on with the paint, so it chips, scours and dusts with it;
	// its edges go ragged and it flakes away in patches as the years add up.
	vec2 on_mark = clamp(stamp.xy, 0.0, 1.0);
	float code = floor(stamp.w + 0.5);
	float ink_kind = mod(code, 4.0);
	float mark_row = code >= 4.0 ? floor(code / 4.0) - 1.0 : era;
	float mark_col = max(floor(stamp.z + 0.5) - 1.0, 0.0);
	// Past the sixth, the marks of the ages after, in their own row.
	if (mark_col > 5.5) {
		mark_col -= 6.0;
		mark_row = MARK_CELLS.y - 1.0;
	}
	vec2 cover = texture(marks, (vec2(mark_col, mark_row) + on_mark) / MARK_CELLS).rg;
	float marked = stamp.z > 0.5 && all(equal(on_mark, stamp.xy)) ? 1.0 : 0.0;
	vec2 cut = max(fwidth(cover) * 0.75, vec2(0.03));
	vec2 ink = max(smoothstep(0.5 - cut, 0.5 + cut, cover + (grain - 0.5) * (0.06 + 0.3 * amount)), cover * 0.25);
	ink *= marked * (1.0 - smoothstep(0.6, 1.4, amount * (0.5 + 0.8 * fine) + 0.25 * (coarse - 0.5)));
	base = mix(base, DAUB, ink.g);
	base = mix(base, ink_kind > 1.5 ? SCRATCH : (ink_kind > 0.5 ? PALE_INK : DARK_INK), ink.r);
	float cut_in = ink_kind > 1.5 ? ink.r : 0.0;
	vec3 wn = normalize(world_n);
	float windward = clamp(dot(wn, -normalize(wind_dir)), 0.0, 1.0);
	float edge = 1.0 - smoothstep(0.0, chip_width * (0.4 + 1.2 * coarse), edge_d);
	float worn = (edge * (0.55 + 0.9 * fine) + corner * 0.4 + windward * 0.35 * fine) * amount;
	// Softened by a pixel's footprint, so chips finer than one don't sparkle.
	float aa = fwidth(worn);
	float chip = smoothstep(0.5 - aa, 0.56 + aa, worn);
	float old = smoothstep(0.62, 0.8, worn + 0.25 * grain) * smoothstep(0.35, 0.65, coarse);
	// Scoured: pale, flat and fine-pitted where the sand strikes.
	float scour = windward * amount * (0.55 + 0.45 * grain);
	vec3 coat = mix(base, mix(base, vec3(dot(base, vec3(0.33))), 0.5) * 1.18, scour * 0.8);
	vec3 metal = mix(bare, rust, old);
	vec3 col = mix(coat, metal, chip);
	float rough = mix(mix(finish.y, 0.92, scour), mix(0.38, 0.9, old), chip);
	float metallic = mix(finish.x, mix(0.85, 0.0, old), chip);
	rough = mix(rough, 0.32, cut_in);
	metallic = mix(metallic, 0.9, cut_in);
	// Sand on what faces up, and in the low band at the foot; less on what
	// hasn't been out long.
	float up = smoothstep(0.55, 0.95, wn.y);
	float foot = 1.0 - smoothstep(0.0, 0.07, above);
	float sand = clamp((up * (0.25 + 0.4 * smoothstep(0.5, 0.75, coarse + 0.3 * grain)) + foot * (0.4 + 0.4 * fine)) * finish.z * (0.35 + 0.65 * min(age, 1.0)), 0.0, 1.0);
	col = mix(col, dust * (0.9 + 0.2 * grain), sand * 0.8);
	rough = mix(rough, 1.0, sand);
	metallic = mix(metallic, 0.0, sand);
	ALBEDO = col * (0.92 + 0.16 * grain);
	ROUGHNESS = rough;
	METALLIC = metallic;
	EMISSION = base * COLOR.a * lit;
}
