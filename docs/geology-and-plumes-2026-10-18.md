<!-- Hunter's brief, 2026-10-18, as given: a proposal for the implementing agent to decide from. Decisions taken go into world-system.md and the PRDs. -->

# Zan: Geology, Volcanic Plumes, and History Integration
## Agent-Facing Design Brief

**Purpose:** Explore and, if justified, implement a geological foundation for Zan's volcanic and volatile plumes. The primary focus is the plumes themselves: their physical origins, behavior, visual presentation, and potential connections to procedural history and gameplay.

**This document is a proposal, not a binding specification.** The implementation agent has fuller codebase context and should make the final technical and design decisions. Challenge assumptions, simplify where appropriate, and preserve existing behavior unless a change is justified and tested.

---

## 1. Executive Direction

Consider introducing a deterministic geology phase before the existing History generation phase. It would describe a small number of large-scale geological features and expose information that History can use when constructing settlements, infrastructure, routes, and ruins.

The primary goal is to create **convincing, physically motivated volcanic plumes** that make the moon feel like a coherent place with a geological past and a still-active interior.

This could connect:

- Residual internal heat and localized volcanic activity.
- Vent locations, fissures, and ancient deposits.
- The moon's non-breathable atmosphere and ongoing outgassing.
- Colonial vent stations, pipelines, refineries, and other industrial infrastructure.
- The existing observatory/volcano landmark and rift-wall black site.
- Environmental events that make the landscape feel dynamic and historically layered.

The smallest useful implementation may not require a new geology subsystem. The agent should inspect the current architecture and decide whether geological data should precede History immediately or whether the first plume can be prototyped against existing landmarks.

### An important terminology distinction

There are two different phenomena commonly called plumes:

1. **Eruptive plume:** Gas, vapor, ash, or fine dust released from a surface vent and transported into the atmosphere. This is the visible cloud and the primary focus of this proposal.
2. **Mantle plume:** An upwelling of unusually hot mantle material deep inside a planetary body. This could explain a volcanic province, but it is not itself a visible atmospheric cloud.

These phenomena can be related, but they should not be treated as interchangeable. Zan may need only residual volcanism along old fractures; a mantle-plume explanation should be added only if it helps establish a consistent geological history.

Also distinguish a volcanic plume from the existing wind-driven sand and dust storms. A storm is a weather phenomenon; a vent plume has a localized source. Wind can transport and disperse the material released by that source.

---

## 2. Existing Code Context to Verify

The following observations were collected during an initial repository review. Verify them against the current branch before making changes.

- `game/world/terrain_shape.gd` creates `History.new(run_seed, tuning)` and subsequently creates `Sites.new(history, self, tuning)`. This may be a natural integration point for geology.
- `game/history/history.gd` contains the deterministic, seed-generated history of the moon, including landmarks, settlements, routes, and historical eras.
- Existing landmark concepts include:
  - **Halloran and Aitch:** Refinery terraces.
  - **The black site:** A blast door in a rift wall.
  - **Port Morgan:** Pylons and pad lights over a plateau.
  - **The observatory:** A tower over a volcano, including a `vent_cap` component.
- History includes infrastructure concepts such as `vent_station`, `pump_station`, `farm_dome`, and `pipeline_segment`.
- `game/weather/atmosphere.gd` presents local, wind-driven weather using GPU particle systems for ground-level streamers, airborne grit, and larger puffs. It also accounts for weather visibility, lighting, shelter, wind, and audio.

These systems provide useful starting points, but the appropriate architecture should come from inspecting the current implementation.

A useful conceptual separation is:

- **Geology:** What exists beneath and on the surface, and where.
- **History:** How people discovered, used, occupied, modified, and abandoned those places.
- **Runtime simulation:** What a vent is doing now.
- **Presentation:** How its plume appears and sounds to the player.

These do not necessarily need to be four separate classes. The separation is conceptual; the agent should choose the actual structure.

---

## 3. Geological Premise

Zan is a barren, dust-covered moon orbiting a gas giant. Its surface is hostile, and its atmosphere is not breathable without protection. The moon was more volcanically active in the past and was settled roughly ten thousand years ago, partly because volcanic activity provided a useful source of power.

The moon eventually lost much of its former activity, but some geological processes may persist.

A restrained model would be:

- Earlier in its history, Zan experienced more widespread volcanic activity.
- That activity created old volcanic provinces, fractures, altered terrain, and deposits.
- Most vents are now dormant or weak.
- A small number remain intermittently active because of residual heat, localized magma, volatile reservoirs, or gas trapped beneath relatively impermeable rock.
- Some vents produce mostly gas; others release dust, ash, or mixtures of material.
- Ancient infrastructure records the moon's more active period, while occasional modern releases reveal that the geology is not entirely dead.

The intention is not to turn Zan into a constantly erupting volcanic world. A mostly quiet landscape punctuated by a few unmistakable events may be more compelling.

### Atmospheric uncertainty

The exact atmospheric composition, surface pressure, gravity, and rate of outgassing have not been established as fixed parameters in this discussion.

A hostile atmosphere containing nitrogen, carbon dioxide, or other volcanic gases is conceivable, but the agent should not hard-code a particular mixture merely because it sounds plausible.

Volcanic outgassing does not automatically produce a breathable, oxygen-rich atmosphere. Much of the oxygen in volcanic material is chemically bound in gases and minerals.

A few active vents also cannot automatically maintain a substantial global atmosphere. That depends on the moon's volatile inventory, atmospheric escape, temperature, gravity, and other factors.

For the first visual prototype, it may be sufficient to establish that a vent can release visible material into the existing atmosphere without claiming that those releases explain the atmosphere's entire mass.

---

## 4. What Should a Plume Look and Behave Like?

The central visual challenge is making a plume read as a geological event rather than another sandstorm.

A useful plume has three identifiable parts:

1. **Source:** A vent, fissure, crater, or damaged volcanic structure on the surface.
2. **Column or cloud:** Material rises from the source, potentially forming a narrow column near the ground and a broader cloud higher up.
3. **Transport and dispersal:** Wind bends the plume, spreads fine material, and carries it away from the source.

The exact shape depends on the source and atmospheric conditions. A plume does not need to resemble an Earth volcano's towering ash column. A low-gravity, low-pressure, or otherwise unfamiliar atmosphere could produce different behavior.

The visual should communicate that the material originates from a specific point.

### Possible activity states

These are options, not mandatory states in a finite-state machine.

**Dormant**

- An old vent scar, fractured ground, altered rock, or collapsed structure.
- No continuous atmospheric effect.
- Persistent geological evidence remains visible.

**Seeping**

- A faint haze, wispy gas, or occasional release.
- The source is identifiable at close range but may be subtle at a distance.
- Activity may be nearly continuous while remaining visually restrained.

**Active**

- A recognizable source and a sustained column or plume.
- Wind bends and stretches the cloud.
- Fine particles travel farther than coarse material.
- A local deposit or altered surface may indicate repeated activity.

**Episodic burst**

- A temporary increase in material release.
- A denser or taller cloud that gradually disperses.
- Potentially fresh fallout near the source.
- The event ends without requiring the vent to become permanently inactive.

**Ancient deposit**

- A persistent surface mark left by previous activity.
- Layered or fan-shaped deposits could indicate repeated releases.
- The atmospheric plume itself has dissipated.

The first implementation should choose only the states required by the prototype. A convincing dormant vent with one well-executed episodic event may be more useful than a complicated activity system with several visually indistinguishable states.

### A critical visual consideration: pure gas may be invisible

A transparent gas release will not necessarily look like a cloud. Visible material could be provided by:

- Fine mineral dust or ash.
- Condensed vapor, if local temperature and pressure permit it.
- Refractive distortion.
- Lighting and contrast against the sky.
- A specialized instrument or sensor display, if that fits the gameplay.

Do not assume every plume should be a bright white or dark gray cloud. Its appearance should follow from the chosen material and lighting model.

---

## 5. Plume Physics: A Practical Abstraction

The game does not need a computational fluid dynamics solver. It does need internally consistent behavior.

A useful conceptual model separates source, transport, and deposition.

### Source behavior

The vent determines how much material is released and when.

Potential properties include:

- Location on the moon.
- Relative activity or source strength.
- Material category.
- Whether activity is continuous, intermittent, or dormant.
- Event duration and recurrence.
- Whether the vent represents a gas seep, dusty fumarole, or more energetic release.

Start with the minimum information needed to drive the chosen visual effect. Do not create a general-purpose volcanic simulation unless gameplay actually requires one.

### Transport behavior

Once released, material is influenced by several factors:

- **Wind:** Bends and advects the plume. It should use the existing weather or wind source where practical.
- **Gravity:** Influences the trajectory of material and the ability of an eruption to loft particles.
- **Atmospheric density:** Influences drag and how material disperses.
- **Particle size:** Coarse particles settle closer to the source; fine particles can travel farther.
- **Source energy and temperature:** Affect initial rise and plume development.
- **Material properties:** Gas, vapor, and solid particles need not behave identically.

These variables are coupled. Low gravity alone does not guarantee that material rises to great heights or that an atmosphere escapes rapidly.

For a first version, a wind-aligned procedural cloud with a few tunable parameters may be enough. The goal is coherent motion and convincing scale, not physical precision for its own sake.

### Deposition

The atmospheric cloud and the surface deposit should be treated as different things.

A cloud may disappear in minutes or hours of simulated time, while the deposit remains for years or centuries in the fictional history.

Even if dynamic terrain deposition is too expensive or unnecessary, persistent surface markings can make a vent feel old and consequential.

---

## 6. Why Geology Might Precede History

The current History system already represents landmarks, settlements, routes, and eras. Geology could provide the physical context that makes those historical decisions feel inevitable rather than arbitrary.

A possible causal chain is:

**Geology → resources and hazards → settlement and industry → infrastructure → abandonment and reuse → present-day ruins**

Examples to investigate against the existing code:

- Vent stations may have been built near productive sources, but not necessarily directly on the most dangerous vent.
- Pipelines could connect extraction sites to refineries or settlements.
- Refineries might occupy accessible industrial corridors rather than the vent itself.
- The observatory volcano could be a major geological landmark, potentially part of a larger volcanic province.
- The rift-wall black site could occupy a genuine geological fracture rather than a purely narrative feature.
- Farm domes could favor sites with reliable infrastructure and tolerable geological risk.
- Ancient deposits could help explain mineralized terrain or the location of abandoned facilities.

The first pass should not necessarily move existing landmarks. A safer approach is to generate geology that explains or validates current placements, then let future procedural placement use geological queries where that improves results.

The agent should inspect how stable landmark positions are across seeds and whether existing tests rely on their current placement.

---

## 7. A Minimal Geological Foundation

If a new geology layer is warranted, consider beginning with only a few large-scale features.

### Volcanic province

A region with elevated vent potential, old deposits, and a shared geological history.

It need not have a sharp circular boundary. A smooth influence field may be more useful than a binary region label.

### Rift or fracture zone

A continuous geological feature that could provide a plausible pathway for outgassing and help explain the existing rift-wall landmark.

The key requirement is continuity: a rift should read as one geological feature rather than a collection of unrelated points.

### Impact basin

An old, large-scale feature that may influence terrain, deposits, or later settlement. It should only be included if it offers a useful connection to the existing world or future gameplay.

### Vent sources

A small collection of individual sources associated with the broader geology.

Each source should have a stable identity and location, plus only the activity parameters necessary for the prototype.

The remainder of the moon can be represented as ordinary background crust. More feature types can be added when a concrete need emerges.

### Spherical geometry

Inspect the existing sphere and moon-cell implementations before deciding how geological features are represented.

Relevant files may include:

- `game/history/moon_cells.gd`
- `game/history/path_network.gd`
- `game/history/eras.gd`
- `game/world/terrain_shape.gd`

Existing code reportedly uses `Vector3` directions on a sphere and derives radius from `tuning.moon_circumference / TAU`. Verify that convention rather than introducing a competing coordinate system.

If the geology layer uses spherical features, great-circle distance or angular distance may be appropriate. The implementation should follow existing project conventions.

### Determinism

Geological features should be deterministic for a given world seed.

Adding geology should not accidentally reshuffle unrelated historical details because a shared random-number generator consumed values in a different order.

Consider isolated random streams or deterministic seed derivation if consistent with the codebase.

Useful tests include:

- Same seed produces the same geological features.
- Different seeds can produce different arrangements.
- Locations are valid on the sphere.
- Rift features remain continuous.
- Geological queries vary smoothly except at intentional boundaries.
- Existing landmarks remain stable unless an intentional change is made.

---

## 8. Runtime Architecture and Weather Integration

The existing weather presentation in `game/weather/atmosphere.gd` is a useful reference, but it does not establish that volcanic plumes belong inside that class.

Inspect the complete data flow for wind, weather visibility, shelter, particle updates, and audio before choosing an integration strategy.

Three possible approaches:

**Option A: Separate plume presentation system**

A dedicated system reads vent and weather state and renders plume effects. This provides a clear separation between sandstorms and geological events.

**Option B: Extend the existing presentation layer**

If the current architecture already centralizes local atmospheric effects, a carefully bounded extension may reduce duplicated logic.

**Option C: Distant and local representations**

Use an inexpensive distant plume representation, with more detailed particles only near the player. This may provide the best balance between visibility and performance.

The agent should select the approach that fits the existing camera, terrain scale, rendering architecture, and profiling results.

### Performance considerations

- Avoid a new full-screen raymarcher by default.
- Avoid spawning a large GPU particle system for every potential vent.
- Bound particle counts, effect radii, and update costs.
- Consider culling or simplifying distant sources.
- Reuse or pool effects if the project architecture supports it.
- Ensure pause/resume behavior is consistent.
- Profile before increasing visual complexity.
- Verify how existing effects interact with shelter, lighting, weather, and camera movement.

Most importantly, **world state must not depend on whether the player can currently see a plume**. If activity influences History or gameplay, its authoritative state should be separate from its rendering lifecycle.

---

## 9. How Plumes Could Affect Gameplay

These ideas are possibilities, not a list of features to implement immediately.

### Navigation

A distant plume could become a visible landmark. Players may use it to orient themselves or recognize a geological province.

### Environmental interpretation

The player might discover that a vent is active through visible emissions, altered ground, instrument readings, or clues in old infrastructure.

### Local hazards

A release might temporarily reduce visibility or create a hazardous region. Such effects should be implemented only if they fit the existing survival mechanics.

### Weather interaction

Strong winds could stretch and disperse a plume. A dust storm could obscure it. Weather might occasionally make a plume more difficult to observe rather than automatically making it more energetic.

### Industrial traces

Old pipes, sealed vent stations, mineral deposits, and damaged equipment could tell the story of past extraction.

### Dynamic aftermath

A recent event could leave a fresh deposit or change the appearance of a small area. This could be an inexpensive way to make activity feel consequential without dynamically reshaping the entire terrain.

### History and discovery

Plumes could help explain why settlements appeared where they did, why facilities were abandoned, or why certain regions are considered dangerous.

For the first milestone, a strong visual feature and a clear geological origin may be enough. Gameplay consequences should follow from prototype needs rather than being assumed in advance.

---

## 10. Scientific Guardrails

The following considerations should inform design decisions, but not every factor needs to be simulated.

**Atmospheric mass budget**

A few vents can produce local emissions or contribute to a thin atmosphere. They do not automatically sustain a substantial global atmosphere. Any strong claim about long-term atmospheric replenishment requires a consistent set of physical assumptions.

**Atmospheric retention**

Retention depends on more than gravity. Gas composition, temperature, upper-atmosphere heating, and the moon's environment also matter.

**Visible material**

Purely transparent gas may not be visible. The visual needs dust, condensate, refractive distortion, suitable lighting, or a sensor-based presentation.

**Volcanic activity**

A mostly old moon with a small number of intermittent sources is compatible with a barren landscape. There is no need for constant global volcanism.

**Storms versus plumes**

Wind-driven storms and localized volcanic releases have different causes. Their visuals may interact, but the underlying systems should remain conceptually distinct.

**Agriculture versus breathable air**

Engineered agriculture does not imply that the outside atmosphere is safe. Crops in controlled environments and rare escaped plants can coexist with a hostile exterior.

**Unsettled physical parameters**

Do not turn brainstorm values into canonical constants without review. Moon dimensions, gravity, atmospheric composition, vent rates, and the precise relationship between the moon and gas giant remain provisional.

If the implementation needs quantitative realism, establish a consistent baseline first:

- Moon radius and surface gravity.
- Surface temperature range.
- Atmospheric pressure and composition.
- Likely emitted gases and particulate material.
- Whether the plume is primarily gas, dust, or a mixture.
- Approximate source strength and event duration.

Only then estimate plume height, dispersion, and the long-term contribution of outgassing.

---

## 11. Suggested Implementation Sequence

This is a suggested workflow, not a required architecture.

### Phase 0: Inspect and decide

1. Read `game/world/terrain_shape.gd`, `game/history/history.gd`, `game/history/moon_cells.gd`, `game/history/path_network.gd`, `game/history/eras.gd`, `game/world/sites.gd`, and the relevant weather code.
2. Inspect current tests, tuning conventions, seeded randomness, spherical positioning, and rendering lifecycle.
3. Decide whether a new geology abstraction is needed immediately.
4. Decide whether the first deliverable is a visible plume prototype, a deterministic source model, or both.
5. Record unresolved physical and design assumptions.

### Phase 1: Establish the source

1. Implement the smallest useful deterministic vent representation.
2. Use an existing volcano or vent landmark if that reduces integration risk.
3. Choose a source behavior and material that can produce a readable plume.
4. Keep geology independent of particle nodes and camera visibility.
5. Add focused tests or probes for determinism and valid positioning.

A separate geology layer should be added at this stage only if it makes the implementation clearer or enables an immediate, justified use case.

### Phase 2: Build one convincing plume

1. Create a clear visual source and a recognizable rising or dispersing plume.
2. Drive wind response from the existing weather system where practical.
3. Ensure the plume reads differently from a sandstorm.
4. Start with presentation before adding hazards, sound complexity, or other gameplay effects.
5. Test under clear conditions, high wind, dust storms, and pause/resume.
6. Profile the effect at its intended viewing distance.

### Phase 3: Connect geology to History

1. Determine whether geology can explain existing vent stations, the observatory volcano, the rift/black site, and industrial routes.
2. Preserve existing landmark placement unless a deliberate change is justified.
3. Let flexible procedural placement query geological resources and hazards where beneficial.
4. Test seed stability across both geology and History.

### Phase 4: Expand only when useful

Potential follow-up work includes local deposition, episodic event scheduling, environmental readings, radio clues, storm interaction, industrial traces, and gameplay hazards.

These are optional extensions, not phase-one requirements.

---

## 12. Acceptance Criteria

A reasonable first milestone should demonstrate:

- At least one vent has a coherent, identifiable source.
- Its plume has a clear visual identity distinct from the existing dust-storm system.
- Wind affects plume shape or transport in a way that is consistent with the existing weather data.
- The visual effect has bounded rendering cost.
- Pausing and weather changes do not cause obvious lifecycle errors.
- Geological source data, if introduced, is deterministic for a given seed.
- Existing History and landmarks remain stable unless an intentional change is made.
- Tests or probes cover the new behavior.
- The implementation documents its chosen physical abstraction and its known limitations.

A larger geology layer should not be considered mandatory for this milestone unless the agent finds a concrete architectural reason to introduce it.

---

## 13. Decisions for the Implementation Agent

Please make these decisions from the actual codebase rather than treating the document's suggestions as settled requirements.

1. Does the project need a `Geology` subsystem now, or can the first plume use existing landmark data?
2. What exactly is the plume emitting: dust, ash, vapor, gas with visible particulates, or a stylized combination?
3. Should the source be continuously seeping, intermittently active, or capable of episodic bursts?
4. Is the observatory volcano part of a larger volcanic province, and how does it relate to the colonial vent stations?
5. Should the rift and volcanic province be generated independently, constrained by existing landmarks, or derived from them?
6. What is the smallest rendering approach that fits the current camera scale and performance budget?
7. Should plumes initially be visual and atmospheric only, or should they affect visibility, hazards, navigation, or History?
8. Which physical assumptions must be settled now, and which can remain qualitative?
9. What tests are appropriate for deterministic generation, visual behavior, and integration with the current weather system?
10. What should explicitly be left out of the first implementation?

## Repository References

- Terrain generation: https://github.com/HunterJSB/desert/blob/master/game/world/terrain_shape.gd
- History generation: https://github.com/HunterJSB/desert/blob/master/game/history/history.gd
- Weather presentation: https://github.com/HunterJSB/desert/blob/master/game/weather/atmosphere.gd
- World sites: https://github.com/HunterJSB/desert/blob/master/game/world/sites.gd

---

## Bottom Line

Give Zan's plumes a convincing geological source and a consistent relationship to wind, the atmosphere, and the moon's history. Start with one compelling plume, not a sprawling simulation. Add a geology layer before History if the actual architecture benefits from it, and let that layer explain settlements and ruins incrementally.

**The goal is a physically coherent world and a compelling prototype—not adherence to this document's proposed architecture. The implementation agent should make the final call.**