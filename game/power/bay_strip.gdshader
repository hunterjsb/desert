shader_type spatial;
// A power box bay's light strip, read at a glance: lit from its foot as far as
// the battery in the bay is full, green, amber when low, red nearly gone, as
// every charge light is; a pulse running up it while the bay charges and down
// it while it supplies, faster the harder it flows, still while it rests. A
// bay held to charge only shows its dark segments a cool blue. Each strip's
// state rides on its instance (INSTANCE_CUSTOM): how full, the flow (-1 out
// to 1 in), the bay (0 supplying, 1 held, 2 dead, 3 empty) and its segments
// (0 a smooth glass, as a temple's).
render_mode unshaded, shadows_disabled, cull_back;

uniform vec3 full_color : source_color = vec3(0.3, 1.0, 0.35);
uniform vec3 low_color : source_color = vec3(1.0, 0.7, 0.15);
uniform vec3 gone_color : source_color = vec3(1.0, 0.2, 0.15);
uniform vec3 dark_color : source_color = vec3(0.025, 0.028, 0.03);
uniform vec3 held_color : source_color = vec3(0.12, 0.3, 0.75);
uniform float glow = 1.6;
uniform float pace = 0.9;

varying vec4 bay;

void vertex() {
	bay = INSTANCE_CUSTOM;
}

void fragment() {
	float along = 1.0 - UV.y;
	float fill = bay.x;
	float flow = bay.y;
	float state = bay.z;
	float segments = bay.w;
	vec3 level = fill > 0.5 ? full_color : (fill > 0.2 ? low_color : gone_color);
	float lit;
	float gap = 1.0;
	if (segments > 0.5) {
		float s = along * segments;
		float within = fract(s);
		lit = fill * segments > floor(s) + 0.001 ? 1.0 : 0.0;
		gap = smoothstep(0.06, 0.14, within) * (1.0 - smoothstep(0.86, 0.94, within));
	} else {
		// Smooth glass: lit to its level, a bright meniscus on top.
		lit = along < fill ? 1.0 : 0.0;
		lit += (1.0 - smoothstep(0.0, 0.03, abs(along - fill))) * 0.6 * step(0.001, fill);
	}
	// Its rim, a little darker, so each strip reads as a part of its own.
	float rim = smoothstep(0.0, 0.12, UV.x) * (1.0 - smoothstep(0.88, 1.0, UV.x));
	vec3 off = state > 0.5 && state < 1.5 ? held_color * 0.35 : dark_color;
	vec3 color = mix(off, level * glow, lit);
	// The pulse: up as it charges, down as it supplies.
	float speed = abs(flow);
	if (speed > 0.01 && state < 1.5) {
		float head = fract(TIME * pace * (0.4 + speed) * sign(flow));
		float d = abs(along - head);
		d = min(d, 1.0 - d);
		float pulse = 1.0 - smoothstep(0.0, 0.16, d);
		color += level * pulse * (lit > 0.5 ? 1.2 : 0.35);
	}
	if (state > 1.5) {
		color = dark_color;
	}
	ALBEDO = color * gap * mix(0.55, 1.0, rim);
}
