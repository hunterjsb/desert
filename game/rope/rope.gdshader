// A rope drawn as a tube along a Catmull-Rom curve through its strand's
// points, in world coordinates. The mesh only carries how far along the points
// each ring sits (UV.y, in points) and which side each vertex is (UV.x).
shader_type spatial;
render_mode world_vertex_coords;

const int MAX_POINTS = 11;

uniform vec3 points[MAX_POINTS];
// How far the sand rises above each link's straight line, at its middle.
uniform float bulge[MAX_POINTS - 1];
uniform int count = 2;
uniform float radius = 0.02;
uniform float segment = 0.5;
uniform vec3 color : source_color = vec3(0.42, 0.31, 0.2);

varying float along;

void vertex() {
	int i = clamp(int(floor(UV.y)), 0, count - 2);
	float t = clamp(UV.y - float(i), 0.0, 1.0);
	vec3 p0 = points[max(i - 1, 0)];
	vec3 p1 = points[i];
	vec3 p2 = points[i + 1];
	vec3 p3 = points[min(i + 2, count - 1)];
	vec3 a = 2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3;
	vec3 b = -p0 + 3.0 * p1 - 3.0 * p2 + p3;
	vec3 p = 0.5 * (2.0 * p1 + (p2 - p0) * t + a * t * t + b * t * t * t);
	// Never below the straight line between two points, or the sand rising
	// over it: a curve through points lying on the sand would dip into it.
	p.y = max(p.y, mix(p1.y, p2.y, t) + bulge[i] * 4.0 * t * (1.0 - t));
	vec3 d = 0.5 * ((p2 - p0) + 2.0 * a * t + 3.0 * b * t * t);
	d = length(d) > 1e-5 ? normalize(d) : vec3(0.0, 0.0, 1.0);
	vec3 side = cross(d, vec3(0.0, 1.0, 0.0));
	side = length(side) > 1e-3 ? normalize(side) : vec3(1.0, 0.0, 0.0);
	vec3 up = cross(side, d);
	float angle = UV.x * TAU;
	vec3 n = side * cos(angle) + up * sin(angle);
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
