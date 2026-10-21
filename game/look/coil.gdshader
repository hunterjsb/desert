shader_type spatial;
// A tube pays out along a fixed winding path; its diameter never follows fill.
instance uniform float coil_amount = 1.0;
uniform float turns;
uniform float inner_radius;
uniform float outer_radius;
uniform float gauge;
uniform float layer_height;
uniform float lead_fraction;
uniform vec3 anchor;
uniform float fibre_turns;
uniform float fibre_contrast;
uniform float dust_amount;
uniform float roughness;
uniform vec2 whipping;
uniform vec3 rope_color : source_color;
uniform vec3 whipping_color : source_color;
uniform vec3 dust_color : source_color;
varying float path_t;
varying vec3 world_normal;

vec3 point_on_coil(float t) {
	vec3 first = vec3(inner_radius, 0.0, gauge);
	if (t < lead_fraction) {
		return mix(anchor, first, t / lead_fraction);
	}
	float u = (t - lead_fraction) / (1.0 - lead_fraction);
	float angle = u * turns * TAU;
	float radius = mix(inner_radius, outer_radius, sin(u * PI));
	float height = gauge + layer_height * smoothstep(0.4, 0.6, u);
	return vec3(cos(angle) * radius, sin(angle) * radius * 0.98, height);
}

void vertex() {
	path_t = UV.x * coil_amount;
	vec3 tangent = normalize(point_on_coil(path_t + 0.0001) - point_on_coil(path_t - 0.0001));
	vec3 across = normalize(cross(tangent, vec3(0.0, 0.0, 1.0)));
	if (dot(across, across) < 0.1) {
		across = normalize(cross(tangent, vec3(0.0, 1.0, 0.0)));
	}
	vec3 up = normalize(cross(tangent, across));
	vec3 radial = across * cos(UV.y) + up * sin(UV.y);
	bool cap = UV.y < 0.0;
	VERTEX = point_on_coil(path_t) + (cap ? vec3(0.0) : radial * gauge);
	NORMAL = cap ? tangent * (UV.x < 0.5 ? -1.0 : 1.0) : radial;
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	vec3 base = mix(whipping_color, rope_color, smoothstep(lead_fraction * whipping.x, lead_fraction * whipping.y, path_t));
	// Broad twisted strands catch light quietly, without a glittering fibre hash.
	float fibre = 0.5 + 0.5 * cos(UV.y * 3.0 + path_t * turns * TAU * fibre_turns);
	base *= 1.0 - fibre_contrast + fibre_contrast * fibre;
	float sand = smoothstep(0.55, 0.95, normalize(world_normal).y) * dust_amount;
	ALBEDO = mix(base, dust_color, sand);
	ROUGHNESS = roughness;
}
