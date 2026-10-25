// Look-test (look/sides), A: Tu's light in the near side's air. The dust throws
// Tu-shine forward, so the night sky glows round Tu and low under it, as it
// does round the sun by day; and a sky lit that brightly hides every star
// fainter than itself, as a bright moon does. The far side, dark, keeps them all.

// Tu-shine in the air, in the sky's own units (a clear day's glow is 1), and
// the faintest star that shows through what it lights.
uniform vec3 tu_air_light = vec3(0.0);
uniform float star_limit = 0.0;

vec3 tu_air(vec3 d) {
	float from_tu = acos(clamp(dot(d, tu_dir), -1.0, 1.0));
	// The dust's forward lobe: a tight aureole and a broad one.
	float lobe = 0.6 * exp(-from_tu / 0.12) + 0.4 * exp(-from_tu / 0.7);
	// Low down there's more air to light.
	float low = 1.0 + 2.0 * exp(-max(d.y, 0.0) * 8.0);
	return tu_air_light * lobe * low * smoothstep(-0.03, 0.0, d.y + sin(horizon_dip));
}
