<!-- Research brought by Hunter, 2026-10-18: a roadmap for sand and wind rendering, its claims marked [V] verified, [S] synthesis, [E] estimate. The roadmap is agreed in direction; each step is decided as it is built (art-direction.md). -->

# One wind texture drives Desert's sand

Desert needs one GPU resource before anything else: a player-centred, compute-baked wind/shelter/transport texture. The current analytic `wind_at`, the Lee lattice and the storm logic are each consulted separately on the CPU, and that is why streamers appear only near storm fronts, why trails heal on one global clock, and why ripples ignore the wind. Once a single RGBA16F texture carries wind velocity, lee shelter and a thresholded "transport potential", the particle systems, the sand shader and the track heal pass all read it and stay consistent. On top of that foundation, the research supports four concrete moves.

1. **Real trail depth without tessellation.** Godot 4 has no tessellation in its shading language. Use a dense, displaced near-player clipmap patch (about 0.125 m spacing over about 64 m) fed by a GPU track texture through `Texture2DRD`, with per-pixel normals and an analytic berm profile.
2. **Journey-class shading.** Write a custom `light()` with Fujii Oren-Nayar backscatter diffuse, max-combined rim and "ocean" Blinn-Phong sheen, and a Wang & Bowles-style log-stepped procedural glitter. Together these cost a few dozen ALU operations per light.
3. **Wind- and lee-dependent healing.** Turn the single global fill clock into a per-region clock that advances at a rate proportional to (wind excess)³ × (1 − shelter). This keeps the existing fill-clock track data almost unchanged. A Werner/Desertscapes-style flux pass for drifts is the later upgrade.
4. **Physics-based particle gating.** Gate streamers on wind exceeding the saltation threshold, not on storm proximity, and spawn crest plumes from brink points found in compute.

Desert's wind- and lee-dependent healing would go beyond anything found documented for a shipped game. The researchers found no such source, so most of the integration design below is synthesis.

**How to read the claims.** **[V]** means the claim is verified by a cited primary or official source. **[S]** means it is the researchers' or this report's own design synthesis. **[E]** means it is an unmeasured cost or parameter estimate. Unmarked numbers inside cited sentences come from the cited source.

## Godot 4 forces dense geometry plus GPU stamping, not tessellation

### Shipped games densify geometry where trails exist

Games that ship deformable snow or sand agree on the architecture:

- a GPU heightfield in a sliding window around the player
- writes to that field by stamping capsules or shapes
- dense geometry, displaced from the field, only where deformation exists

**God of War Ragnarök is the closest analogue to Desert** **[V]** ([80.lv](https://80.lv/articles/santa-monica-s-senior-programmer-on-how-god-of-war-ragnar-k-s-snow-system-was-made/)):

- It replaced screen-space parallax mapping with tessellated displacement because of parallax's artifacts.
- It carves with the characters' own capsules against a hard floor, recomputed every frame on the GPU.
- Particles read the displacement field.
- The same tech produces deep sand in Alfheim, mostly through data changes.
- The new system performs "the same and often faster" than the old parallax one.

Rise of the Tomb Raider likewise used compute plus hardware tessellation, "agnostic of the original snow mesh" **[V]** ([SIGGRAPH 2015](https://history.siggraph.org/wp-content/uploads/2022/10/2015-Talks-Michels_Labs-R_D-Rendering-Techniques-in-Rise-of-the-Tomb-Raider.pdf)).

Two details are often repeated but could not be checked: Arkham Origins' orthographic depth render from below the snow, and Rise of the Tomb Raider's berm curve. The slides and the GPU Pro 7 chapter were blocked or paywalled, so treat both as unverified.

### Godot has no tessellation, so use a dense displaced clipmap

Godot cannot follow that path directly:

- Dynamic tessellation (proposal #5995) is open and unimplemented, and a maintainer considers tessellation to have "lost traction" **[V]** ([godot-proposals #5995](https://github.com/godotengine/godot-proposals/issues/5995)).
- The RenderingDevice tessellation stage enums exist but need C++ renderer changes **[V]** ([Godot Forum](https://forum.godotengine.org/t/any-information-about-rendering-device-in-particular-tessellation/139935)).

That leaves a dense displaced mesh. Terrain3D already proves a vertex-shader-displaced clipmap that re-centres on the camera **[V]** ([Terrain3D docs](https://terrain3d.readthedocs.io/en/latest/docs/system_architecture.html)).

The SNOWFLOW WebGPU demo is a complete reference for deformable snow that ports almost line for line **[V]** ([snowflow wiki](https://github.com/Noniv/snowflow_demo/wiki)):

- an 8-ring nested clipmap with 8.5 cm inner spacing, about 333k triangles in one draw call
- vertices that store only (grid index, ring level), with all placement, CDLOD morphing and displacement done in the vertex shader
- the same displacement code run in the shadow cascades, so trails self-shadow
- **a 3.22 ms total GPU frame at 1440p on an RTX 5070 Ti** with every system enabled

### Recommended layout for Desert

Desert's specific problem is vertex density, not displacement range: a 1 m lattice cannot show a 0.25 m footprint however far its vertices move. The recommended layout **[S]**:

- **Keep the 1 m chunks for distance.**
- **Add a player-centred patch.** For example 64×64 m at 0.125 m spacing (about 524k triangles), or nested rings at 0.125/0.25/0.5/1 m. Snap it to texel multiples so it doesn't swim.
- **Hide the chunk mesh inside the patch radius,** either by sinking its vertices or by discarding pixels by radius, to prevent z-fighting.
- **Lift the 3 cm cap to about ±0.3 m,** and widen `custom_aabb` or `extra_cull_margin` so culling stays correct.

The cost of the patch is inferred from SNOWFLOW; no Godot benchmark exists **[E]**.

### Use POM only inside prints, and compute normals per pixel

Parallax occlusion mapping is a supplement, not a replacement. Godot's built-in deep parallax is documented as "much more expensive on the GPU" and artifacts at oblique angles **[V]** ([BaseMaterial3D docs](https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/BaseMaterial3D.xml)). It also assumes material UVs, not a world-space track texture.

- A custom 8–16 step POM loop that samples the track texture in world XZ within about 10 m adds toe and heel detail finer than the 0.125 m vertex spacing **[S]**.
- **Compute normals per pixel in `fragment()`** from central differences of the track texture, not per vertex, so dents stay crisp regardless of mesh density **[S]**.
- Vertex-stage sampling must use explicit-LOD fetches (`textureLod`), because derivatives don't exist in the vertex stage **[V]** ([Riccardi](https://andreariccardi.artstation.com/blog/category/1)).

### Move stamping to RenderingDevice compute

Use compute, not a SubViewport. The official Compute Texture demo is the template **[V]** ([source](https://raw.githubusercontent.com/godotengine/godot-demo-projects/master/compute/texture/water_plane/water_plane.gd), [Asset Library](https://godotengine.org/asset-library/asset/2764)):

- an R32F storage texture with sampling, storage and can-copy-to usage bits
- setup and dispatch run through `RenderingServer.call_on_render_thread`
- 8×8 workgroups
- three textures rotated by swapping RIDs into a `Texture2DRD`, rather than copied
- the main RenderingDevice, so compute runs before rendering in the same frame

SubViewport accumulation is fragile. `render_target_clear_mode` is documented as "intended for 2D usage" **[V]** ([SubViewport docs](https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/SubViewport.xml)), and a 4.4 forum attempt at under-ground depth stamping failed both to accumulate and on uneven terrain **[V]** ([Godot Forum](https://forum.godotengine.org/t/interactive-snow-shader-issues/119668)).

SNOWFLOW's toroidal buffer handles window motion for free **[V]** ([snowflow wiki](https://github.com/Noniv/snowflow_demo/wiki)). It addresses the texture with `fract(worldXZ/size)` and zeroes newly exposed texels in the same pass. Desert's wrapped 4096² texture already has this shape.

At R16F the full 4096² texture is 32 MB **[S]**. A full-texture pass every frame would be wasteful, so dispatch compute only over the 64-texel dirty tiles the CPU already tracks **[S]**.

### Berms: an analytic profile first, a mass channel later

Real-looking trails need displaced mass at the rim as well as depth.

**The cheap version** **[S]** is a stamp profile with a negative core and a positive smoothstep ring. Size the ring height so its volume roughly balances the core: B ≈ D·r0/(2w), where D is core depth, r0 is core radius and w is ring width. Skew the profile forward along the direction of motion. Where stamps overlap, follow the published overlap rule: "add negative displacement values and limit the positive ones to the maximum height of the highest crater" **[V]** ([SBGames paper](https://sol.sbc.org.br/index.php/sbgames/article/download/32332/32129)).

**The richer version** follows SNOWFLOW **[V]** ([snowflow wiki](https://github.com/Noniv/snowflow_demo/wiki)). It tracks a separate displaced-mass channel, which is "what distinguishes a trail with raised berms from a flat footprint". Loose berms slump about 3× faster than packed trench floors, and wind infill comes from upwind.

### Keep collision on the base terrain

Physics should stay visual-only:

- God of War has particles read the carve but documents no CPU collision against it **[V]** ([80.lv](https://80.lv/articles/santa-monica-s-senior-programmer-on-how-god-of-war-ragnar-k-s-snow-system-was-made/)).
- Godot warns that downloading large textures "can have a prohibitive cost for real-time even when using the asynchronous method" **[V]** ([RenderingDevice docs](https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/RenderingDevice.xml)).

Drive both the GPU visual field and any CPU gameplay record (foot IK, vehicle drag, saves) from the same CPU stamp list. That keeps the two consistent with no readback **[S]**.

## A custom light() gets Journey's look for a few dozen ALU ops

Journey remains the only well-documented sand-shading reference. The researchers found no public shader write-ups for Dune: Awakening, Sable, Assassin's Creed or Uncharted 3.

### Journey's layers

Alan Zucconi's reconstruction (not Journey's actual code) splits the look into layers **[V]** ([Zucconi Parts 1–6](https://www.alanzucconi.com/2019/10/08/journey-sand-shader-1/)):

- **Diffuse contrast:** scale N.y by 0.3, then `saturate(4·N·L)` lerped from a shadow colour to the sand colour. This gives a hard terminator that exaggerates dune shape ([Part 2](https://www.alanzucconi.com/2019/10/08/journey-sand-shader-2/)).
- **Grain normal:** a random-normal texture blended in with nlerp and renormalised ([Part 3](https://www.alanzucconi.com/2019/10/08/journey-sand-shader-3/)).
- **Specular:** Fresnel rim and Blinn-Phong "ocean" specular, combined with **max(), not a sum**, so overlaps don't get too shiny ([Part 4](https://www.alanzucconi.com/2019/10/08/journey-sand-shader-4/)).
- **Glitter:** reflect the light off a random normal and threshold the result. Glitter is added on top and can exceed 1, which triggers HDR bloom ([Part 5](https://www.alanzucconi.com/2019/10/08/journey-sand-shader-5/)).
- **Ripples:** normal maps blended by a sharpened steepness term, `pow(saturate(N·up), k)` ([Part 6](https://www.alanzucconi.com/2019/10/08/journey-sand-shader-6/)).

The talk also lists "sharpened mipmaps", "anisotropic masking" and a "detail heightmap" **[V]** ([Polycount summary](https://polycount.com/discussion/comment/1913443)). No public text explains them, so the likely readings below are guesses **[S]**:

- **Sharpened mipmaps:** lower mips contrast-boosted so sparkle survives at distance.
- **Anisotropic masking:** glitter faded at grazing angles.

Journey wanted Oren-Nayar but dropped it for cost on PS3 **[V]** ([Part 2](https://www.alanzucconi.com/2019/10/08/journey-sand-shader-2/)).

### Desert can afford real backscatter diffuse

Desert currently runs ROUGHNESS=1 with Godot's default Burley diffuse. Burley is not retroreflective, so low-sun dunes lack the powdery backscatter glow real sand shows when the sun is behind the viewer.

Fujii's Oren-Nayar (FON) fixes this **[V]** ([EON paper](https://arxiv.org/html/2410.18026v3)):

- formula: `f = (ρ/π)(A + B·s/t)`
  - `s = L·V − (N·L)(N·V)`
  - `1/t = 1/max(N·L, N·V)` when s > 0, otherwise 1
  - `A = 1/(1 + (0.5 − 2/(3π))·r)` and `B = r·A`, with roughness r in [0, 1]
- cost: **6.3 ns versus 1.4 ns for Lambert** (single CPU thread)
- the energy-preserving EON variant costs 20.8 ns and has public GLSL

Full Hapke regolith models exist, but no validated real-time simplification does **[V]** ([CU Boulder NESS](https://www.colorado.edu/ness/sites/default/files/attached-files/efficient_photometric_models_of_the_lunar_regolith_for_virtual_reality_simulation.pdf)).

### Godot's light() is the right hook

Godot's `light()` runs "for every light in every pixel" and writes `DIFFUSE_LIGHT` and `SPECULAR_LIGHT`. Note that `LIGHT_COLOR` includes a factor of π **[V]** ([spatial shader reference](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/shaders/shader_reference/spatial_shader.rst)).

Desert is lit mostly by the sun, and the gas giant could be a second, dim directional light. `light()` would therefore run once or twice per pixel. FON diffuse, optionally multiplied by Journey's contrast terminator, plus `max(ocean, rim)` sheen plus glitter totals **about 40–60 ALU operations** **[E]**.

Because the terms live in `light()`, `ATTENUATION × LIGHT_COLOR` handles shadows, eclipses and night automatically **[S]**.

### Glitter: Wang & Bowles is the sweet spot

Glitter is where aliasing decides quality. There are three tiers.

**Wang & Bowles (EGSR 2016)** is the production sweet spot **[V]** ([PDF](https://diglib.eg.org/bitstream/handle/10.2312/sre20161209/049-054.pdf)):

- a jittered 3D grid of seed points with a round inverted squared-distance kernel
- depth stability from a **stepped logarithmic grid scale** with no mip chain, whose pops are masked by the sparkling itself
- view-vector domain repetition so distant sparkles still twinkle as the camera moves
- an elliptical kernel at grazing angles to cut flicker
- shipped in an AAA title; **about 0.0047 ms full-screen on a GTX 980**

**Deliot & Belcour (HPG 2023)** is the upgrade path **[V]** ([arXiv 2306.05051](https://arxiv.org/abs/2306.05051)):

- footprint-aware binomial counting of flakes, temporally stable
- 1.15–1.54 ms at 1080p on an RTX 2080
- its "gated Gaussian" approximation needs only two random numbers and no loops
- no public code repository

**Godot recipe** **[S]**:

1. Hash `floor(WORLD_POS·density)` to a random microfacet normal and a jittered seed point.
2. Choose the cell scale in discrete steps from `log2(fwidth(world_pos))`.
3. Fade the result by footprint/cell-size so sub-pixel sparkles fade out instead of crawling.
4. Gate it with `reflect(-L, g)·V`.
5. Emit it inside `light()` with values above 1, so Godot's glow does the bloom.

Godot's roughness limiter and TAA do not anti-alias custom additive terms **[V]** ([3D AA docs](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/3d/3d_antialiasing.rst)), so the footprint fade must be built into the shader.

Derivatives are normally available only in the fragment stage. Compute the hash and the fade in `fragment()` and pass them to `light()` through varyings. Whether `fwidth` compiles inside `light()`, and how fragment-to-light varyings behave, are both **unverified**.

### Keep distant dunes reading as sand

Keep Desert's fwidth-faded ripples, and add three things **[S]**:

- **A second, larger "sand wave" band** that persists further out, mirroring Journey's three heightmaps ([Polycount](https://polycount.com/discussion/comment/1913443)).
- **Specular widening as ripples fade:** convert the lost ripple normal variance into a wider sheen lobe (lower `ocean_pow`). This is a Toksvig-style trick, so distant dunes keep a soft sheen instead of going flat.
- **Track coupling:** make track darkening also kill glitter and lower sheen, since disturbed sand is darker and rougher.

For texture tiling, Quilez's third technique costs only 2 fetches plus a low-frequency index **[V]** ([iquilezles.org](https://iquilezles.org/articles/texturerepetition/)).

## Aeolian physics says streamers belong to every windy afternoon

### Saltation starts at ordinary wind speeds

The physics literature contradicts the current storm-only gating:

- Loose sand starts moving at a wind stress of about **0.05 N/m², a friction velocity u\* ≈ 0.2 m/s** **[V]** ([Kok et al. 2012](https://arxiv.org/pdf/1201.4353)).
- Using the log law with z₀ around 0.1 mm, that is roughly **5–6 m/s at 10 m height** **[S]**. That is an ordinary breezy afternoon, not a storm.
- Saltation also has a daily cycle: transport peaks in the afternoon, dies after sunset, and largely stops above about 40% relative humidity **[V]** ([arXiv 1812.03612](https://arxiv.org/pdf/1812.03612)).

This gives the atmosphere system a principled gate: `smoothstep(~5, ~8 m/s)` on local wind, times (1 − shelter), times a day-cycle factor **[S]**.

### What the particle shapes should be

The geometry of real saltation tells the particle systems what to draw:

- **Hops are tiny.** Mean hop height is under a centimetre and hop length is about 6–10 cm, both "relatively insensitive" to wind speed **[V]** ([Pähtz et al. 2021](https://ar5iv.arxiv.org/html/2108.06048)).
- **Streamers are narrow and flickery.** Much transport travels in streamers about **0.2 m wide** **[V]** ([Kok et al.](https://arxiv.org/pdf/1201.4353)), varying on **about 0.1 s timescales** and spanning 0.1–10 m **[V]** ([Baas, EGU 2005](https://www.meetings.copernicus.org/www.cosis.net/abstracts/EGU05/03616/EGU05-J-03616.pdf)).

Visually that implies **[S]**:

- a dense streamer layer at 0–0.3 m, made of thin velocity-aligned streaks
- a separate readable haze of suspended fines at 0.3–2 m
- spawn density modulated by anisotropic noise stretched along the wind (about 0.2–1 m across, 3–10 m along) and advected at wind speed, which produces flickering "sand snakes"

### Dune lees and crest plumes

The flow behind a dune is well characterised:

- Flow separates at the brink and reattaches about **6 dune heights (6H) downwind**, with maximum back-flow at about 55% of that distance. The slip face sits at the 34° angle of repose **[V]** ([Araújo et al.](https://arxiv.org/pdf/1307.6978)).
- Shear stress and sand flux peak slightly upwind of the crest: about 3.2 m and 1.2 m upwind respectively on a 2 m dune **[V]** ([Claudin et al.](https://arxiv.org/pdf/1205.4411)).

So crest plumes should **[S]**:

- spawn just upwind of brinks where transport potential exceeds the threshold
- leave the brink horizontally at wind speed
- fall out within a few H into the lee, with a faint reverse swirl in the inner half of the separation bubble

No source quantifies how plumes look (length, height, onset speed), so their tuning will be art-directed.

### Ghost of Tsushima's wind model fits wind_at almost exactly

Ghost of Tsushima's wind is "Vector + Noise + Vorticles" **[V]** ([Game Developer](https://gamedeveloper.com/design/using-vorticles-to-simulate-wind-in-i-ghost-of-tsushima-i-)):

- **Vector:** one global wind vector of constant direction.
- **Noise:** magnitude modulated by time-varying Perlin noise, which "produces visible gusts over grass fields". Particles add curl noise so they swirl more.
- **Vorticles:** a brute-force-summed list of up to hundreds of invisible wind particles that can act as vortices, linear gusts or outward blasts.
- **Terrain:** particles sample the heightmap several times ahead of themselves and add upward velocity early, so they ride over steep terrain.

This maps almost one-to-one onto `wind_at`, with storm outflow acting as a blast vorticle **[S]**.

**Do not claim GoT uses a baked wind texture around the player.** No accessible source confirms one, or its resolution or update method.

God of War (GDC 2019) did run a grid-based wind fluid simulation with motors and receivers, but public summaries give no numbers **[V]** ([80.lv](https://80.lv/articles/santa-monica-studio-showed-how-interactive-wind-and-vegetation-were-made-for-god-of-war)).

### Godot particle tools: which to use and which to avoid

Godot's particle stack supports the needed design, with documented pitfalls:

- **Attractor vector field (`GPUParticlesAttractorVectorField3D`):** names sandstorms as a use case and suggests about 64³ resolution **[V]** ([docs](https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_gpuparticlesattractorvectorfield3d.rst)). It is a better fit for local 3D swirls than for terrain-hugging sand.
- **Heightfield collider (`GPUParticlesCollisionHeightField3D`):** its always-update mode has "a significant performance cost", and follow-camera "will force the heightmap to update whenever the camera moves" **[V]** ([docs](https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_gpuparticlescollisionheightfield3d.rst)). Prefer heightmap lookahead in a custom `process()` shader.
- **Particle budget:** cost scales with `amount`, and lowering `amount_ratio` gives "no performance benefit" **[V]** ([GPUParticles3D docs](https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_gpuparticles3d.rst)). Use a separate, right-sized emitter per effect.
- **Directed emission points:** `EMISSION_SHAPE_DIRECTED_POINTS` takes positions and velocities from point textures **[V]** ([ParticleProcessMaterial docs](https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_particleprocessmaterial.rst)). This suits crest plumes fed by a compute-generated brink-point texture.

Untested: binding a `Texture2DRD` as a uniform on a particle `ShaderMaterial`. It is expected to work, but nobody has confirmed it.

## Wind-integrated fill clocks heal trails without a full simulation

### Werner's lee rule is the trail-healing rule

Werner's 1995 cellular automaton is the parent of every graphics dune model **[V]** ([Werner 1995](https://planetarygeoscience.uchicago.edu/doc/Werner_1995.pdf)):

- slabs hop a fixed distance downwind
- deposition is more likely on sand than on bare ground
- a **15° lee shadow zone** where nothing erodes and everything deposits
- avalanching at 30°

That shadow rule is exactly Desert's design goal: trails vanish on exposed crests and survive in hollows.

### Desertscapes CUDA timings rule out a full-field sim

The 2024 real-time CUDA port of Desertscapes defines shelter in a GPU-friendly way: march up to 10 cells upwind, take the maximum terrain angle, and treat **below 10° as unsheltered and above 15° as fully sheltered**, ramping linearly between **[V]** ([SciTePress 2024](https://scitepress.org/publishedPapers/2024/123156/pdf/index.html)).

Its timings set hard limits on an RTX 4080:

| Grid size | Time per step |
|---|---|
| 512² | about 0.5 ms |
| 1024² | about 1 ms |
| 4096² | **48–82 ms** |

**Avalanching takes 35–85% of step time** **[V]** ([same](https://scitepress.org/publishedPapers/2024/123156/pdf/index.html)).

A full dune simulation on Desert's 4096² track texture every frame is therefore not viable. Two things reduce the cost for trails:

- **Few avalanche passes.** A trail layer needs a handful of avalanche iterations, not 50, and only on dirty tiles.
- **Low update rate.** Fill times are measured in minutes, so the layer can update at 1–10 Hz or be time-sliced across frames.

Steady-state cost then lands around **0.1–0.2 ms/frame** **[E]**.

Godot compute has no portable float atomics. Use gather formulations, such as virtual pipes or semi-Lagrangian advection, or fixed-point integer heights **[S]**.

### Smallest change: a per-region fill clock

The smallest change that achieves wind- and lee-dependent healing keeps Desert's fill-clock representation and replaces the one global clock with a low-resolution **local clock texture** **[S]** (this report's synthesis):

- **The clock:** an R32F texture over the same wrapped 1 km window. 256² cells at 4 m matches the Lee lattice. Each tick, compute adds `dt·(max(u−u_th,0)/u_ref)³·(1−shelter)` to every cell, where u is local wind speed, u_th the transport threshold and u_ref a reference wind. The u³ dependence follows the saturated-flux law u\*(u\*²−u\*t²) **[V]** ([Kok et al.](https://arxiv.org/pdf/1201.4353)).
- **The track texel:** still stores the clock reading at stamp time, now sampled from the local clock at its own location.
- **Visible depth:** `f(clock_local(x) − stored)`.

Several properties follow:

- **Healing for free in the shader.** Because the clock only ever increases, depth falls out of a subtraction, with no relax pass, much like the current global scheme.
- **Lee and calm behave correctly.** Trails in full lee never heal, and calm days freeze them.
- **Existing tuning carries over.** The current 90-minute calm and 20-minute storm fill times calibrate u_ref. Under the cubic law, 20 minutes needs about **(90/20)^(1/3) ≈ 1.65× the calm wind excess** **[S]**.

Precision needs watching. R32F avoids drift over long sessions, or the clock can be periodically re-based **[S]**.

### Flux upgrade for drifts and ghost trails

The flux version adds drifts and "ghost trails". It is a compute pipeline over a signed deformation layer d, capped at about ±0.5 m over the immobile analytic dunes **[S]**:

1. **Micro-shadow:** a 2–4 texel upwind march using the 10–15° ramp.
2. **Lift:** ∝ u³·(1−shelter), stronger on convex rims.
3. **Transport:** semi-Lagrangian advection of a flux buffer.
4. **Deposition:** favoured in concavities and lee.
5. **Creep:** a Laplacian term, after Nishimori-Ouchi **[V]** ([CS348B summary](https://graphics.stanford.edu/courses/cs348b-competition/cs348b-03/sanddunes)).
6. **Avalanching:** a few iterations at about 33°.

The rim angle explains why this behaves well **[S]**. A footprint rim 3–4 cm higher than its floor 25 cm away sits at about 8°, so it is partially sheltered. Steep wheel ruts are fully sheltered. In partial lee the troughs fill but the rims survive.

Marking crates and ruins as "sticky" cells grows lee drift tails, mirroring Desertscapes' sticky-cell rule **[V]** ([SciTePress](https://scitepress.org/publishedPapers/2024/123156/pdf/index.html)). Loot can hop as heavy slabs that stop in shelter **[S]**.

No empirical rate data exists for footprint infill in dry sand, so rates will be tuned by eye.

### Ripples migrate in the shader

Ripples cannot be simulated at 0.25 m texels: real wavelengths are 5–30 cm. They should be a shader layer driven by measured scaling laws:

- Wavelength and phase speed both scale linearly with (u\*/u\*th − 1), with aspect ratio around 0.04 **[V]** ([Andreotti et al. 2006](https://www.phys.ens.fr/~foldingslidingstretchinglab/papers/A24_PhysRevLett_96_028001.pdf)).
- In the field, migration speed grows from linear to cubic with wind. Ripples respond with lags of about **2.3 min for speed, 5.6 min for height and 8.3 min for wavelength** **[V]** ([Nield et al.](https://eprints.soton.ac.uk/506673/1/Nield_etal_ripples_revision_JGR.pdf)).

Implementation **[S]**:

- **Accumulate phase in a low-resolution "ripple phase" channel** (phase += c(u)·dt), rather than computing t·c. Changes in wind speed then don't make ripples jump.
- **Smooth orientation and wavelength** with time constants of several game-minutes, crossfading two orientations through a direction change.
- **Fade ripples:** in deep lee, on slopes above about 30°, and where trails are fresh. Restore them as the heal fraction rises.

## Conclusion

The literature changes the problem Desert is solving. The storm-gated, globally-clocked behaviour is not a rendering limitation. It comes from treating wind as an event rather than as a field. Physics puts the saltation threshold at ordinary afternoon wind speeds and makes transport cubic in wind excess. Werner's lee rule makes trail survival a function of local shelter. Once wind, shelter and transport potential live in one texture, streamers, plumes, ripple migration, trail healing and drifts all become consumers of the same signal, and stay mutually consistent for free.

On geometry and shading, the lesson is to stop asking Godot for features it lacks. Dense displaced geometry is what God of War shipped; tessellation was only its densifier. In Godot that densifier is a clipmap patch. Journey's "trillions of grains" was a shading trick, and it is cheaper today than on PS3.

The main risks are integration details nobody has tested in Godot:

- sampling a `Texture2DRD` in `vertex()` and in particle shaders
- fragment-to-`light()` varyings and `fwidth` behaviour
- the real cost of a 500k-triangle displaced patch

Prototype each of these before committing to the full roadmap.

## Prioritised implementation roadmap

| # | Change | Files | Basis | Est. cost |
|---|---|---|---|---|
| **P0** | **Wind/shelter texture.** Port `wind_at` to GLSL. Each frame, a compute pass bakes a player-centred, texel-snapped RGBA16F texture (for example 128² over 256 m at 2 m per texel): RG = wind velocity on the ground plane, B = shelter, A = transport potential (threshold × (1−shelter) × gust × day cycle). Expose it via `Texture2DRD` on the main RenderingDevice using the Compute Texture demo pattern. Keep `wind_at` on the CPU for audio and gameplay. Optionally add a coarse 64² texture over 1 km for distant gust bands. | `weather_field.gd` (bake owner), new `wind_bake.glsl` | Pattern **[V]**; layout **[S]** | <0.1 ms **[E]** |
| **P0** | **GPU shelter.** Replace the 4 m lattice and 2° heading lookups with a compute upwind march (up to 10 taps, 10°→15° ramp) written into channel B, so shelter follows wind direction continuously. Keep `lee.gd` as the CPU query API for loot and AI, or have it sample a coarse copy. | `lee.gd`, `wind_bake.glsl` | Ramp **[V]**; integration **[S]** | Included above **[E]** |
| **P1** | **Sand `light()`.** FON diffuse (optionally times Journey's terminator), `max(ocean, rim)` sheen, and Wang & Bowles-style log-stepped hashed glitter with a footprint fade (computed in `fragment()`, passed by varyings), output above 1 for glow. Fade glitter and sheen with storm density and on tracks. Add a sand-wave band, and widen sheen as ripples fade. | `sand.gdshader` | Components **[V]**; recipe **[S]** | ~40–60 ALU per light **[E]** |
| **P1** | **Threshold-gated streamers.** Convert the three systems to custom particle `process()` shaders that sample the wind texture. In `start()`, reject spawns where A < rand. Use heightmap lookahead for lift over crests, a 0–0.3 m saltation band, thin streaks or short `RibbonTrailMesh` trails, and anisotropic advected noise for snakes. Size `amount` to the real peak. Run distant haze at `fixed_fps` 30 with interpolation. | `atmosphere.gd` | Threshold and particle docs **[V]**; design **[S]** | 20k–50k particles **[E]** |
| **P2** | **Per-region fill clock.** Add an R32F 256² wrapped clock texture advanced by compute at `(u_excess/u_ref)³·(1−shelter)`. Store the local clock reading at stamp time. In the shader, depth = f(local − stored). Recalibrate u_ref from the 90/20-minute fill times. | `tracks.gd`, `sand.gdshader`, `weather_field.gd` | **[S]**, based on [V] flux law and Werner's lee rule | Negligible **[E]** |
| **P3** | **GPU track texture.** Move the 4096² texture to the RenderingDevice (R16F or RG16F, 32/64 MB). Upload a small per-frame stamp buffer. A compute pass over dirty 64² tiles only writes the analytic core-plus-berm profile, using min-depth/max-berm overlap. Clear newly exposed rows on window scroll. Compute per-pixel normals by central differences. | `tracks.gd`, `sand.gdshader`, new `track_stamp.glsl` | Pattern **[V]**; profile **[S]** | µs-scale **[E]** |
| **P4** | **Near-field displacement patch.** A static nested-ring mesh (0.125→1 m, about 64 m inner radius), placed, morphed and displaced in `vertex()` with `textureLod` from base height plus track texture, using the same code in shadow passes. Sink the chunk mesh inside the radius. Lift the 3 cm cap to about ±0.3 m and fix the AABB. Optionally add an 8–16 step world-space POM inside 10 m. | new `near_patch.gd`, `sand.gdshader` (shared include) | SNOWFLOW/Terrain3D **[V]**; Godot cost unknown | Profile it; SNOWFLOW ~3.2 ms total frame **[V]** |
| **P5** | **Crest plumes.** A compute pass finds brink points (high upwind slope, sharp drop downwind, A above threshold) and writes them to a point texture plus a count. A dedicated emitter (directed points or a custom `start()`) launches particles horizontally at wind speed, with lift decaying into gravity once shelter > 0.5. Particles fall out within about 6H, with a faint reverse swirl. | `atmosphere.gd`, `wind_bake.glsl` | Separation physics **[V]**; emitter **[S]** | 5k–20k particles **[E]** |
| **P6** | **Ripple migration.** Add a low-resolution phase accumulator (phase += c(u)·dt), with λ and A scaled by (u/u_th − 1), and 2–8 minute lag smoothing with orientation crossfade. Mask ripples by shelter, slope and trail heal fraction. | `sand.gdshader`, `weather_field.gd` | Scaling laws **[V]**; shader mapping **[S]** | Negligible **[E]** |
| **P7** | **Flux infill and drifts.** Upgrade the track layer to a signed deformation layer with a flux buffer: micro-shadow, lift, semi-Lagrangian transport, deposition, creep, and 1–4 virtual-pipe avalanche passes on dirty tiles. Run at 1–10 Hz or time-sliced. Add a sticky mask for crates and ruins to grow drift tails. | `tracks.gd`, new `aeolian_step.glsl` | Model **[V]**; layer split **[S]** | ~0.1–0.2 ms/frame steady **[E]** |
| **P8** | **Loot drift and ruins.** On the CPU, loot hops as heavy slabs with p_lift ∝ u³(1−shelter) and stops in shelter. Bury or expose ruins by advancing the analytic dune phase during storms, not via the local layer. | `lee.gd`, `weather_field.gd` | **[S]** | Trivial **[E]** |

P0 and P1 are independent and can ship in parallel. P1 is the cheapest large visual win. P2 removes the global clock without touching the track data layout. P3 and P4 together deliver real trail depth, and only P4 carries meaningful GPU risk.
