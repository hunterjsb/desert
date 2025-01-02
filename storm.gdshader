shader_type spatial;

uniform sampler2D storm_texture;
uniform sampler2D edge_mask_texture; // A noise or cloud texture for irregular edges
uniform float scroll_speed = 0.01;
uniform float alpha_strength = 0.5;
uniform float fade_radius = 0.3;
uniform float edge_fade = 0.4;

// Adjust this to match sky color more closely at edges.
// If your sky is light, maybe something pale (1.0, 1.0, 0.9).
uniform vec3 edge_tint = vec3(1.0, 1.0, 1.0);

void fragment() {
    vec2 uv = UV;
    // Scroll the main texture
    uv.x -= TIME * scroll_speed;
    uv = fract(uv);

    vec4 tex_color = texture(storm_texture, uv);

    // Distance from center for radial fade
    float dist_from_center = distance(uv, vec2(0.5, 0.5));

    // Base radial fade
    float radial_fade = 1.0 - smoothstep(fade_radius, fade_radius + edge_fade, dist_from_center);

    // Sample an edge mask texture to break up the uniformity
    // We'll use another set of UVs for variation (e.g., scaled or rotated)
    vec2 mask_uv = UV * 3.0; // Scale UV for mask
    vec4 mask_color = texture(edge_mask_texture, mask_uv);
    float mask_value = mask_color.r; // Use red channel as mask

    // Combine radial fade with noise-based mask to get a more irregular fade
    // Multiply them so the mask further reduces the alpha at the edges
    float combined_fade = radial_fade * mask_value;

    // Edge tinting: As we fade out, we can blend ALBEDO with edge_tint to reduce contrast
    // The more it fades, the closer to edge_tint it gets
    vec3 final_color = mix(edge_tint, tex_color.rgb, combined_fade);

    ALBEDO = final_color;
    ALPHA = combined_fade * alpha_strength * tex_color.a;
}
