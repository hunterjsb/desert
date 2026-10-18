// Tu's clouds unrolled, longitude across and latitude up, their albedo as it
// is, for the look-test's sheet: the whole of Tu at once, the far side too.
shader_type canvas_item;

#include "res://game/weather/tu_clouds.gdshaderinc"

uniform float time = 0.0;
uniform float rows = 960.0;

void fragment() {
	float lon = (UV.x - 0.5) * TAU;
	float lat = (0.5 - UV.y) * PI;
	COLOR = vec4(pow(tu_clouds(lat, lon, time, PI / rows), vec3(1.0 / 2.2)), 1.0);
}
