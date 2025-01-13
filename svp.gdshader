shader_type canvas_item;
render_mode unshaded;

#define MAX_PALETTE_COLORS 16

uniform bool enabled = true;

// Toon steps for channel quantization (optional).
uniform int toon_steps : hint_range(1, 16) = 4;

// Up to 16 palette colors.
uniform int palette_size : hint_range(1, MAX_PALETTE_COLORS) = 4;
uniform vec4 palette_colors[MAX_PALETTE_COLORS] : source_color;

// We'll do a smooth blend over this distance range.
uniform float soft_threshold : hint_range(0.0, 1.0) = 0.2;

// 1) Basic channel stepping (optional).
float quantize_channel(float c, int steps) {
    float step_size = 1.0 / float(steps - 1);
    return floor(c / step_size + 0.5) * step_size;
}

// 2) Find nearest color in our palette, returning both color + distance.
struct NearestResult {
    vec3 color;
    float dist;
};

NearestResult pick_nearest_palette_color(vec3 color) {
    float min_dist   = 1e20;
    vec3  best_match = palette_colors[0].rgb;

    for (int i = 0; i < MAX_PALETTE_COLORS; i++) {
        if (i >= palette_size) {
            break;
        }
        float dist = distance(color, palette_colors[i].rgb);
        if (dist < min_dist) {
            min_dist   = dist;
            best_match = palette_colors[i].rgb;
        }
    }
    NearestResult nr;
    nr.color = best_match;
    nr.dist  = min_dist;
    return nr;
}

void fragment() {
    vec4 raw_color = texture(TEXTURE, UV);

    if (!enabled) {
        COLOR = raw_color;
         // return;
    }

    // 1) Optional “toon” stepping of each channel.
    float r = quantize_channel(raw_color.r, toon_steps);
    float g = quantize_channel(raw_color.g, toon_steps);
    float b = quantize_channel(raw_color.b, toon_steps);
    vec3 stepped_color = vec3(r, g, b);

    // 2) Find nearest palette color and distance.
    NearestResult nr = pick_nearest_palette_color(stepped_color);
    float dist       = nr.dist;      // 0.0 = identical, up to ~1.7 max if totally different
    vec3 nearest_rgb = nr.color;

    // 3) Compute a continuous blend factor from 0..1 based on distance to nearest color.
    //    - If dist=0, factor=0 => we snap fully to the palette color.
    //    - If dist >= soft_threshold, factor=1 => we leave it at “stepped_color”.
    //    - In between, a smooth transition.
    float t = clamp(dist / soft_threshold, 0.0, 1.0);

    // Option A: a simple linear blend
    //   final = mix(nearest_color, stepped_color, t);
    // Option B: a smoother blend using smoothstep
    //   float t_smooth = smoothstep(0.0, 1.0, t);
    //   final = mix(nearest_color, stepped_color, t_smooth);

    // Let’s do the linear approach:
    vec3 final_rgb = mix(nearest_rgb, stepped_color, t);

    // Output with alpha from the original texture
    COLOR = vec4(final_rgb, raw_color.a);
}
