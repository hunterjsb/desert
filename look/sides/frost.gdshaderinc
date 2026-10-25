// Look-test (look/sides), B: the far side's frost. Zan's water cold-traps on the
// cold side (docs/world/the-moon.md), so its sand rimes over in the night and
// loses it after sunrise, first where it faces the sun and last in the shade.

// How much the night has laid, 0 to 1; how far the morning has gone to taking
// it, 0 at sunrise to 1, gone even from the shade; and toward the sun, world axes.
uniform float frost = 0.0;
uniform float frost_melt = 0.0;
uniform vec3 frost_sun = vec3(0.0, 1.0, 0.0);
// Hoarfrost, linear, and the most of the sand it hides: a thin rime, not snow.
const vec3 FROST = vec3(0.7, 0.75, 0.82);
const float FROST_MOST = 0.5;
// Its crystals' facets flash as the grains' do, and more of them.
const float FROST_GLINT = 2.0;

float frost_cover(vec3 n, vec2 at, float foot, float trough) {
	if (frost <= 0.0) {
		return 0.0;
	}
	// Thinner on the sand's coarser ribbons, drawn out down the wind as they
	// are, and patchy close up; an even rime once a pixel spans the patches.
	vec2 along = vec2(dot(at, vec2(-downwind.y, downwind.x)), dot(at, downwind));
	float patch = value_noise(along / vec2(2.5, 8.0)) * 0.6 + value_noise(at / 0.7) * 0.4;
	patch = mix(patch, 0.5, smoothstep(0.05, 0.5, foot));
	float laid = smoothstep(0.25, 0.75, patch + frost - 0.6);
	// The ripples' troughs keep the cold a little longer.
	laid *= 0.85 + 0.15 * trough;
	float facing = max(dot(n, frost_sun), 0.0);
	float dose = frost_melt * (0.6 + 3.5 * facing) + (patch - 0.5) * 0.3;
	return laid * (1.0 - smoothstep(0.35, 0.9, dose)) * FROST_MOST;
}
