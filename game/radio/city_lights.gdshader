shader_type spatial;
// The living city's lights (CityLights): lamps on its decks, each a soft
// point turned to your eye, never smaller than lamp_px so they read kilometres
// off, warm or a shield's pale blue by its colour; and the glow its decks
// throw up behind them, wide and faint, that its silhouettes stand dark
// against. The haze dims them, a storm between hides them (veil), and they
// come and go together (shown) with the night, the range and their dousing.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled,
	skip_vertex_transform;

uniform float lamp_px = 2.5;
uniform float brightness = 3.0;
uniform float shown = 0.0;
uniform float veil = 1.0;
uniform vec3 haze = vec3(400.0, 9000.0, 0.7);

varying vec4 tone;
varying float glow;

float pixel_at(vec3 at, mat4 projection, vec2 viewport, vec3 eye) {
	return 2.0 * length(eye - at) / (abs(projection[1][1]) * viewport.y);
}

void vertex() {
	vec3 at = MODEL_MATRIX[3].xyz;
	float d = length(CAMERA_POSITION_WORLD - at);
	// Its own size, from the instance's scale; a lamp no smaller than lamp_px.
	float own = length(MODEL_MATRIX[0].xyz);
	glow = INSTANCE_CUSTOM.x;
	float px = pixel_at(at, PROJECTION_MATRIX, VIEWPORT_SIZE, CAMERA_POSITION_WORLD);
	float size = glow > 0.5 ? own : max(own, px * lamp_px);
	tone = COLOR;
	tone.rgb *= shown * veil * (1.0 - clamp((d - haze.x) / (haze.y - haze.x), 0.0, 1.0) * haze.z);
	// A point of light carries far at night, fading slowly with distance.
	tone.rgb *= glow > 0.5 ? 1.0 : 1.0 / (1.0 + d / 2000.0);
	vec3 c = (VIEW_MATRIX * vec4(at, 1.0)).xyz;
	VERTEX = c + vec3(VERTEX.xy * size, 0.0);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = dot(q, q);
	float fall = glow > 0.5 ? exp(-r * 2.5) * (1.0 - smoothstep(0.7, 1.0, r)) : exp(-r * 6.0);
	ALBEDO = tone.rgb * brightness * fall;
}
