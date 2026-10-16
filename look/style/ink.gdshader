shader_type spatial;
// Look-test D: the ink line, an inverted hull. Drawn as a next pass, grown out
// from the piece and showing only its back faces, so a dark rim rings every
// silhouette. Boxes grow along their corners, which keeps their edges closed.

render_mode unshaded, cull_front;

uniform vec3 ink : source_color = vec3(0.13, 0.08, 0.06);
// m at 1 m away; the line keeps about the same width on screen up close.
uniform float width = 0.006;
uniform bool boxy = false;

void vertex() {
	float far = clamp(-(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z, 1.0, 40.0);
	vec3 grow = boxy ? sign(VERTEX) : NORMAL;
	VERTEX += grow * width * far;
}

void fragment() {
	ALBEDO = ink;
}
