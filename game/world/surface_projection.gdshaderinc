// Main-view tangent anchor X/Z and presentation radius, metres. Zero radius opts out.
uniform vec3 surface_frame = vec3(0.0);

vec3 surface_project(vec3 point) {
	vec2 off = point.xz - surface_frame.xy;
	float drop = surface_frame.z > 0.0 ? dot(off, off) / (2.0 * surface_frame.z) : 0.0;
	return point - vec3(0.0, drop, 0.0);
}

vec3 surface_unproject(vec3 point) {
	vec2 off = point.xz - surface_frame.xy;
	float drop = surface_frame.z > 0.0 ? dot(off, off) / (2.0 * surface_frame.z) : 0.0;
	return point + vec3(0.0, drop, 0.0);
}

vec3 surface_normal(vec3 normal, vec3 point) {
	if (surface_frame.z <= 0.0) return normal;
	vec2 slope = (point.xz - surface_frame.xy) / surface_frame.z;
	return normalize(vec3(normal.x + slope.x * normal.y, normal.y, normal.z + slope.y * normal.y));
}
