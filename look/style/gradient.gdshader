shader_type spatial;
// Look-test C: the ruin in one flat colour, darker at the foot and lighter at
// the top, each wall's facing a shade apart: big planes need a painted
// gradient to read as built once texture is gone.

uniform vec3 color : source_color = vec3(0.74, 0.64, 0.52);

varying vec3 lp;
varying vec3 ln;

void vertex() {
	lp = VERTEX;
	ln = NORMAL;
}

void fragment() {
	float rise = mix(0.78, 1.04, smoothstep(-0.2, 3.2, lp.y));
	float facing = abs(ln.x) > 0.5 ? 0.94 : 1.0;
	ALBEDO = color * rise * facing;
	ROUGHNESS = 1.0;
}
