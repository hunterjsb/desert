// A rope drawn as a tube through its strand's points, in world coordinates.
// The mesh only carries which ring and which side each vertex is.
shader_type spatial;
render_mode world_vertex_coords;

const int MAX_POINTS = 13;

uniform vec3 points[MAX_POINTS];
uniform int count = 2;
uniform float radius = 0.02;
uniform float segment = 0.5;
uniform vec3 color : source_color = vec3(0.56, 0.45, 0.31);

varying float along;

void vertex() {
	int i = clamp(int(UV.y + 0.5), 0, count - 1);
	vec3 p = points[i];
	vec3 t = points[min(i + 1, count - 1)] - points[max(i - 1, 0)];
	t = length(t) > 1e-5 ? normalize(t) : vec3(0.0, 0.0, 1.0);
	vec3 side = cross(t, vec3(0.0, 1.0, 0.0));
	side = length(side) > 1e-3 ? normalize(side) : vec3(1.0, 0.0, 0.0);
	vec3 up = cross(side, t);
	float a = UV.x * TAU;
	vec3 n = side * cos(a) + up * sin(a);
	VERTEX = p + n * radius;
	NORMAL = n;
	along = UV.y * segment;
}

void fragment() {
	// Three twisted strands, laid about every 9 cm.
	float lay = fract(UV.x * 3.0 + along / 0.09);
	float strand = smoothstep(0.0, 0.3, lay) * smoothstep(1.0, 0.7, lay);
	ALBEDO = color * mix(0.6, 1.05, strand);
	ROUGHNESS = 0.95;
}
