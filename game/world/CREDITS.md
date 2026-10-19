# World: sources and licences

- **Tracks** (`tracks.gd`, the track map in `sand.gdshader`): the idea of drawing marks
  into a top-down texture that the ground's shader reads to darken and dent the sand
  comes from Adrián's (dip000) "CarTracksOnSnowOrSand" in
  [my-godotshaders](https://github.com/dip000/my-godotshaders), MIT License, Copyright
  (c) 2023 Adrián. No code was copied: that one draws particles into a SubViewport
  every frame; this one presses marks into tiles from code, wraps them round a window
  that follows you, and fills them by a clock instead of fading them per texel.
- **Noise on the GPU** (`noise_glsl.gd`): a GLSL port of the smooth simplex (OpenSimplex2S)
  and FBm of [FastNoiseLite](https://github.com/Auburn/FastNoiseLite) 1.1, as Godot ships it,
  gradient tables included. MIT License, Copyright (c) 2023 Jordan Peck and contributors.
