shader_type sky;
render_mode disable_fog;
#include "res://game/weather/tu_clouds.gdshaderinc"
uniform vec3 sun_direction;
uniform vec3 tu_direction;
uniform float tu_radius;
uniform float tu_spin;
uint stars_hash(ivec3 cell) {
	uvec3 p = uvec3(cell); uint h = p.x * 1597334677u ^ p.y * 3812015801u ^ p.z * 2798796415u;
	h = (h ^ (h >> 16u)) * 2246822519u; return h ^ (h >> 13u);
}
void sky() {
	vec3 ray = normalize(EYEDIR);
	float star = float(stars_hash(ivec3(floor(ray * 950.0))) & 65535u) / 65535.0;
	vec3 color = vec3(0.00025, 0.0004, 0.0008) + vec3(pow(smoothstep(0.9993, 1.0, star), 4.0) * 0.16);
	float c = dot(ray, tu_direction);
	if (c > cos(tu_radius)) {
		float dist = 1.0 / sin(tu_radius); float b = c * dist;
		vec3 n = normalize(ray * (b - sqrt(max(b*b - dist*dist + 1.0, 0.0))) - tu_direction * dist);
		vec3 pole = vec3(0,0,1); vec3 toward = normalize(-tu_direction - pole * dot(-tu_direction, pole));
		float lat = asin(clamp(dot(n, pole), -1.0, 1.0));
		float lon = atan(dot(n, cross(pole, toward)), dot(n, toward));
		color = tu_clouds(lat, lon - tu_spin, 0.0, 0.008) * (max(dot(n, sun_direction), 0.0) * 1.3 + 0.003);
	}
	COLOR = color;
}
