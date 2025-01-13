shader_type canvas_item;
render_mode unshaded;

// If you’re worried about performance, you might keep MAX_PALETTE_COLORS moderate
// or convert this to a separate data structure or texture-based lookup.
#define MAX_PALETTE_COLORS 32

uniform bool enabled = true;

// Steps for toon-style channel quantization (optional).
uniform int toon_steps : hint_range(1, 16) = 4;

// We'll store up to 32 palette colors, or any number you like.
uniform int palette_size : hint_range(1, MAX_PALETTE_COLORS) = 8;
uniform vec4 palette_colors[MAX_PALETTE_COLORS] : source_color;

// "Soft converge" parameters
uniform float soft_threshold : hint_range(0.0, 1.0) = 0.2;
// If the color is outside `soft_threshold`, we blend at "nudge_factor"
// between the original color and the nearest palette color.
uniform float nudge_factor : hint_range(0.0, 1.0) = 0.5;

// 1) Basic channel stepping
float quantize_channel(float c, int steps) {
    // e.g. if steps=4, step=1/3
    float step_size = 1.0 / float(steps - 1);
    // Round to the nearest step
    return floor(c / step_size + 0.5) * step_size;
}

// 2) Find the nearest color in our palette
//    returns (closest_color, distance_to_it)
struct NearestResult {
    vec3 color;
    float dist;
};

NearestResult pick_nearest_palette_color(vec3 color) {
    float min_dist = 1e20;
    vec3 best_match = palette_colors[0].rgb;

    for (int i = 0; i < MAX_PALETTE_COLORS; i++) {
        if (i >= palette_size) {
            break; // Don’t use palette entries above 'palette_size'
        }
        float dist = distance(color, palette_colors[i].rgb);
        if (dist < min_dist) {
            min_dist = dist;
            best_match = palette_colors[i].rgb;
        }
    }
    NearestResult result;
    result.color = best_match;
    result.dist = min_dist;
    return result;
}

void fragment() {
    // Grab the raw color from the current sprite/texture
    vec4 raw_color = texture(TEXTURE, UV);

    if (!enabled) {
        // Pass through original color if disabled
        COLOR = raw_color;
        // return;
    }

    // 1) (Optional) Step each channel to discrete “toon” levels
    float r = quantize_channel(raw_color.r, toon_steps);
    float g = quantize_channel(raw_color.g, toon_steps);
    float b = quantize_channel(raw_color.b, toon_steps);
    vec3 stepped_color = vec3(r, g, b);

    // 2) Find the nearest palette color
    NearestResult nr = pick_nearest_palette_color(stepped_color);
    vec3 nearest = nr.color;
    float dist   = nr.dist;

    // 3) “Soft” convergence:
    //    - If color is within `soft_threshold` distance, snap fully.
    //    - Otherwise, partially nudge towards nearest palette color
    //      by `nudge_factor`.
    // You can tweak this logic to taste, e.g. linear fade, smoothstep, etc.
    vec3 final_rgb;
    if (dist <= soft_threshold) {
        // Full snap
        final_rgb = nearest;
    } else {
        // Partial blend
        final_rgb = mix(stepped_color, nearest, nudge_factor);
    }

    // Write out the final color
    COLOR = vec4(final_rgb, raw_color.a);
}
