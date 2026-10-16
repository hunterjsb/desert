shader_type spatial;
// Look-test B: painted metal worn by this moon. Paint chips at edges and
// corners down to bare metal, and the old chips are red rust; faces turned to
// the prevailing wind are scoured pale and matte; sand settles on whatever
// faces up and in the low band at the foot. No UVs: everything is read from
// the mesh's own frame, so primitives wear without unwrapping.

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
// The piece's half extents in its own frame, so edges are found without UVs;
// round_xz measures x and z as a cylinder's radius.
instance uniform vec3 half_size = vec3(0.5);
instance uniform float round_xz = 0.0;

varying vec3 obj_pos;
varying vec3 obj_n;
varying vec3 world_n;

void vertex() {
	obj_pos = VERTEX;
	obj_n = NORMAL;
	world_n = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

float tri(vec3 p, vec3 n, float s) {
	vec3 w = abs(n) + 0.001;
	w /= w.x + w.y + w.z;
	return texture(noise, p.yz * s).r * w.x + texture(noise, p.xz * s).r * w.y + texture(noise, p.xy * s).r * w.z;
}

void fragment() {
	vec3 d = max(half_size - abs(obj_pos), vec3(0.0));
	if (round_xz > 0.5) {
		float r = half_size.x - length(obj_pos.xz);
		d = vec3(max(r, 0.0), d.y, 1e3);
	}
	// The nearest edge is where the two nearest faces meet: the middle distance.
	float lo = min(d.x, min(d.y, d.z));
	float hi = max(d.x, max(d.y, d.z));
	float edge_d = d.x + d.y + d.z - lo - hi;
	float corner = 1.0 - smoothstep(0.0, chip_width * 2.5, hi);
	float coarse = tri(obj_pos, obj_n, 2.3);
	float fine = tri(obj_pos, obj_n, 9.0);
	float grain = tri(obj_pos, obj_n, 31.0);
	vec3 wn = normalize(world_n);
	float windward = clamp(dot(wn, -normalize(wind_dir)), 0.0, 1.0);
	float edge = 1.0 - smoothstep(0.0, chip_width * (0.4 + 1.2 * coarse), edge_d);
	float worn = (edge * (0.55 + 0.9 * fine) + corner * 0.4 + windward * 0.35 * fine) * wear;
	float chip = smoothstep(0.5, 0.56, worn);
	float old = smoothstep(0.62, 0.8, worn + 0.25 * grain) * smoothstep(0.35, 0.65, coarse);
	// Scoured: pale, flat and fine-pitted where the sand strikes.
	float scour = windward * wear * (0.55 + 0.45 * grain);
	vec3 coat = mix(paint, mix(paint, vec3(dot(paint, vec3(0.33))), 0.5) * 1.18, scour * 0.8);
	vec3 metal = mix(bare, rust, old);
	vec3 col = mix(coat, metal, chip);
	float rough = mix(mix(paint_rough, 0.92, scour), mix(0.38, 0.9, old), chip);
	float metallic = mix(paint_metal, mix(0.85, 0.0, old), chip);
	// Sand on what faces up, and in the low band at the foot.
	float up = smoothstep(0.55, 0.95, wn.y);
	float foot = 1.0 - smoothstep(0.0, 0.07, obj_pos.y + half_size.y);
	float sand = clamp((up * (0.25 + 0.4 * smoothstep(0.5, 0.75, coarse + 0.3 * grain)) + foot * (0.4 + 0.4 * fine)) * dust_amount, 0.0, 1.0);
	col = mix(col, dust * (0.9 + 0.2 * grain), sand * 0.8);
	rough = mix(rough, 1.0, sand);
	metallic = mix(metallic, 0.0, sand);
	ALBEDO = col * (0.92 + 0.16 * grain);
	ROUGHNESS = rough;
	METALLIC = metallic;
}
