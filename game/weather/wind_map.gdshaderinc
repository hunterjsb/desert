// The wind map (WindMap) round the player: per 2 m texel the field's wind on
// the ground (rg, m/s, world x and z), the lee's share (b) and how hard the
// wind moves sand there (a). Engine x and z to uv by the window's lower corner
// (xy) and its extent (z); w is 1 once it's fed. Any shader may sample it:
// textureLod, as vertex() and particles have no derivatives.

uniform sampler2D wind_map : filter_linear, repeat_disable, hint_default_black;
uniform vec4 wind_window = vec4(0.0, 0.0, 256.0, 0.0);
// A look-test's view of it on the sand: 0 none, 1 the wind's arrows, 2 the
// lee as vertex() read it, 3 the sand it moves.
uniform int wind_view = 0;

vec2 wind_uv(vec2 xz) {
	return (xz - wind_window.xy) / wind_window.z;
}

vec4 wind_sample(vec2 xz) {
	return textureLod(wind_map, wind_uv(xz), 0.0);
}

vec4 wind_view_vertex(vec2 xz) {
	return wind_view == 2 ? wind_sample(xz) : vec4(0.0);
}

// The view over the sand's colour; at_vertex is wind_view_vertex's, carried.
vec3 wind_view_colour(vec3 colour, vec2 xz, vec4 at_vertex) {
	if (wind_view == 0) {
		return colour;
	}
	vec2 uv = wind_uv(xz);
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return colour * 0.12;
	}
	vec3 under = colour * 0.3;
	if (wind_view == 2) {
		return mix(under, vec3(0.02, 0.15, 0.9), at_vertex.b);
	}
	if (wind_view == 3) {
		return mix(under, vec3(0.9, 0.12, 0.01), wind_sample(xz).a);
	}
	// An arrow a 16 m cell, along the wind at its middle, longer the harder it
	// blows (full at 25 m/s), over a tint from slow blue to fast yellow.
	const float CELL = 16.0;
	vec2 rel = xz - wind_window.xy;
	vec2 middle = (floor(rel / CELL) + 0.5) * CELL;
	vec2 wind = textureLod(wind_map, middle / wind_window.z, 0.0).rg;
	float speed = length(wind);
	vec2 way = speed > 1.0e-3 ? wind / speed : vec2(1.0, 0.0);
	float along = dot(rel - middle, way);
	float aside = abs(dot(rel - middle, vec2(-way.y, way.x)));
	float reach = CELL * 0.45 * clamp(speed / 25.0, 0.3, 1.0);
	bool shaft = aside < 0.7 && along > -reach && along < reach * 0.3;
	bool head = along >= reach * 0.3 && along < reach && aside < (reach - along) * 0.9;
	vec3 tint = mix(vec3(0.03, 0.08, 0.5), vec3(0.9, 0.6, 0.02), clamp(speed / 25.0, 0.0, 1.0));
	return shaft || head ? vec3(1.0) : mix(under, tint, 0.6);
}
