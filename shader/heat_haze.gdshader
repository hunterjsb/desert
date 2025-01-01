/*
    Simple Heat Haze / Wavy Distortion for Godot 4
    ------------------------------------------------
    - No depth usage
    - Single sine-based wave
    - Minimal uniforms for quick experimentation

    MIT License
*/

shader_type spatial;
render_mode unshaded;

//----------------------------------------
// SCREEN TEXTURE
//----------------------------------------
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

//----------------------------------------
// UNIFORMS
//----------------------------------------
// Amplitude of the wave distortion (in UV space).
uniform float wave_amplitude = 0.5;

// Frequency of the wave (how many “ripples” appear).
uniform float wave_frequency = 4.0;

// Speed at which the wave moves over time.
uniform float wave_speed = 1.0;

//----------------------------------------
// FRAGMENT
//----------------------------------------
void fragment()
{
    // Basic sine-based distortion
    // We vary UV based on the screen’s y coordinate and time.
    float wave_x = sin(SCREEN_UV.y * wave_frequency + TIME * wave_speed) * wave_amplitude;

    // If you want some vertical distortion as well, you can do another sine using x:
    // float wave_y = sin(SCREEN_UV.x * wave_frequency * 0.5 + TIME * wave_speed * 0.8) * wave_amplitude * 0.5;
    // For an extremely simple approach, let's leave it at wave_x only.

    vec2 distorted_uv = SCREEN_UV + vec2(wave_x, 0.0);

    // Sample the screen texture at this new UV
    vec3 color = texture(SCREEN_TEXTURE, distorted_uv).rgb;

    // Output
    ALBEDO = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    ALPHA  = 1.0;
    DEPTH  = 0.0;  // Post-process style
}