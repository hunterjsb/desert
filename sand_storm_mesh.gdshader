shader_type spatial;
render_mode cull_disabled;

// === UNIFORMS === //

// Colors and highlight
uniform vec4 sand_color : source_color = vec4(0.8, 0.7, 0.5, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.9, 0.6, 1.0);
uniform float burn : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float emission_strength : hint_range(0.0, 5.0, 0.1) = 1.0;

// Noise scale for swirling dust in fragment
uniform float noise_scale : hint_range(0.0, 10.0, 0.1) = 2.0;
uniform float swirl_speed : hint_range(0.0, 5.0) = 1.0;

// === VERTEX WARPING === //
// Warp around Y + slight vertical warping
uniform float swirl_amount : hint_range(0.0, 3.0) = 1.0;
uniform float swirl_frequency : hint_range(0.1, 5.0) = 1.0;
uniform float radius_noise_strength : hint_range(0.0, 2.0) = 0.5;
uniform float vertical_warp_strength : hint_range(0.0, 1.0) = 0.2;
uniform float twist_noise_strength : hint_range(0.0, 2.0) = 0.3;
// twist_noise_strength controls a random “twist” of the angle itself

// === FADING === //
uniform float fresnel_power : hint_range(0.0, 5.0) = 2.0;
uniform float distance_fade_start = 50.0; 
uniform float distance_fade_end   = 150.0;

// (Optional) Extra top/bottom fade
uniform float vertical_fade_height = 0.0; 
// If > 0, fade out near top and bottom of the sphere

// --------------------------------------------------------------------
// NOISE HELPERS
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise2d(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f); 
    return mix(a, b, u.x)
         + (c - a) * u.y * (1.0 - u.x)
         + (d - b) * u.x * u.y;
}

// Fragment swirl
vec2 swirl_uv(vec2 uv) {
    vec2 center_uv = uv - 0.5;
    float r = length(center_uv);
    float angle = atan(center_uv.y, center_uv.x);

    angle += swirl_amount * sin(TIME * swirl_speed + r * 5.0);

    return vec2(cos(angle), sin(angle)) * r + 0.5;
}

// --------------------------------------------------------------------
// VERTEX: Multi-axis warp
//   - We swirl around Y using radius+angle
//   - We add vertical distortion
//   - We also add a random “twist” factor in the angle
void vertex() {
    // Convert (x,z) to polar coords
    float radius = length(vec2(VERTEX.x, VERTEX.z));
    float angle  = atan(VERTEX.z, VERTEX.x);

    // Sample noise for radius warping
    // Use vertex.y + time to vary the radius
    float n_radius = noise2d(vec2(VERTEX.y * swirl_frequency, TIME * 0.2));
    float radius_offset = (n_radius - 0.5) * radius_noise_strength;
    radius = max(0.0, radius + radius_offset);

    // Random twist factor for the angle
    // Another noise call with different coords
    float n_twist = noise2d(vec2(VERTEX.y + TIME * 0.15, angle * swirl_frequency));
    float twist_angle = (n_twist - 0.5) * twist_noise_strength;
    // swirl the base angle with swirl_amount + twist
    angle += swirl_amount * sin(TIME * swirl_speed + VERTEX.y * 0.25) + twist_angle;

    // Reconstruct X,Z
    VERTEX.x = radius * cos(angle);
    VERTEX.z = radius * sin(angle);

    // Vertical warp
    // e.g. noise on (x+z+time)
    float n_vert = noise2d(vec2(VERTEX.x + VERTEX.z, TIME * 0.1));
    float vertical_offset = (n_vert - 0.5) * vertical_warp_strength;
    VERTEX.y += vertical_offset;
}

// --------------------------------------------------------------------
// FRAGMENT
void fragment() {
    // 1) Swirl the UV
    vec2 uv_swirl = swirl_uv(UV);
    float noise_value = noise2d(uv_swirl * noise_scale + TIME * 0.3);

    // 2) Base color
    vec4 final_color = sand_color;

    // 3) Highlight if noise < burn
    if (noise_value < burn) {
        float diff = clamp(burn - noise_value, 0.0, 1.0);
        vec4 hcol = mix(sand_color, highlight_color, diff);
        final_color.rgb *= hcol.rgb;

        float grad_intensity = (
            abs(hcol.r - hcol.g) +
            abs(hcol.r - hcol.b) +
            abs(hcol.g - hcol.b)
        ) / 3.0;

        EMISSION = hcol.rgb * grad_intensity * emission_strength * diff;
    } else {
        EMISSION = vec3(0.0);
    }

    // 4) Fresnel fade
    //    Edges vanish, center remains
    float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float fresnel = pow(ndotv, fresnel_power);
    final_color.a *= fresnel;

    // 5) Distance fade
    float dist = length(VIEW);
    float dist_fade = 1.0;
    if (dist > distance_fade_start) {
        dist_fade = 1.0 - clamp(
            (dist - distance_fade_start) / max(0.001, (distance_fade_end - distance_fade_start)),
            0.0, 1.0
        );
    }
    final_color.a *= dist_fade;

    // 6) Optional: vertical fade near top/bottom (makes it super ephemeral)
    //    If vertical_fade_height > 0, we fade out near y = ±vertical_fade_height
    //    We need WORLD_POSITION or something similar.
    if (vertical_fade_height > 0.0) {
        float y_world = NODE_POSITION_WORLD.y; 
        // We'll assume the sphere center is near y=0, radius ~some_value
        // fade factor => 0 near ±vertical_fade_height
        // Let’s say the entire fade region is from [-vertical_fade_height..vertical_fade_height]
        float fade_top = clamp((vertical_fade_height - y_world) / (vertical_fade_height), 0.0, 1.0);
        float fade_bot = clamp((vertical_fade_height + y_world) / (vertical_fade_height), 0.0, 1.0);
        float fade_vertical = fade_top * fade_bot; 
        // If y is near +vertical_fade_height or -vertical_fade_height => fade out
        final_color.a *= fade_vertical;
    }

    // 7) Output
    ALBEDO = final_color.rgb;
    ALPHA  = final_color.a;
    ROUGHNESS = 0.8;
    METALLIC  = 0.0;
}