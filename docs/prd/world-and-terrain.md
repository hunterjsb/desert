# PRD: World & terrain

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

The desert is the stage for everything else. It has to be endless, it has to look like
somewhere worth wandering, and above all it has to be **solid**. Sand Game died here:
things fell through the ground, floated above it, or vanished. If the ground can't be
trusted, nothing built on top of it can be either. So this system is judged on
reliability first and beauty second.

## What the player experiences

- On a clear day, a **big, lonely, epic view**: dunes out to a horizon blurred by heat
  shimmer and the flatness of the land. Clear skies are rare and earned. They come from
  diligence, and some luck, in staying clear of the storms.
- In a storm, you can barely see past your own shield. That's where it gets cozy.
- There's no edge and no seam in either case.
- Walking, sliding and hoverboarding over sand that always holds you.
- Anything you drop lands on the sand and stays there. On a slip face it slides to the
  foot first, as it would on real sand.
- A sense of distance travelled. The game always knows how far you are from where the
  run began, even though the land behind you isn't kept.

## Rules

These rules come straight from Sand Game's failure, and they don't bend.

1. **The ground is one function.** `height_at(x, z)` is the single source of truth. The
   visible mesh, the collision and the placement of every object all read it. Nothing
   computes height any other way. Between its 1 m lattice points the ground is the
   lattice's triangles, split the way the mesh and collision split each square, so all
   three agree exactly, even on a sharp crest. On loaded ground the world reads the
   chunk's own samples instead of computing them again: the same numbers, cheaper.
2. **Loaded ground never changes.** A chunk's collision is built once, when it comes
   into range, and it's never rebuilt or reshaped while it exists. Detail levels only
   change how the ground looks, never how it collides.
3. **Nothing physical is ever outside collision.** Collision reaches further than any
   physics object is allowed to be. Anything that's about to leave that range gets
   frozen or forgotten first, so nothing can drop into the void. What's on you, in your
   hands, at your waist or under you on a board, goes where you go instead (Stage 10:
   streaming far behind once let the world forget a board you were riding).
4. **Chunks hold no state.** A chunk is pure output of the seed and its coordinates. The
   camp and the player belong to the world, not to any chunk. Unloading a chunk
   forgets everything in it.
5. **Loading follows coordinates, not collisions.** Which chunks exist is decided by
   the player's grid position, never by what a raycast happens to hit.
6. **The sand is a hard floor** (added 2026-10-14, after a battery fell through the
   map in the Stage 4 playtest). Jolt's heightmap is a skin with no inside, so a thin
   part pressed more than halfway into it, say under a crate that lost power and
   dropped on it, went out the bottom. Now no corner of a loose body may sink more
   than Jolt's few-centimetre slop below `height_at`. Anything whose middle still ends
   up below the sand is put back on top and **counted**. Every world probe fails if
   that count isn't zero, and it shows on the dev overlay.

## Stateless, but located

The desert is stateless (decided in the vision). Terrain is generated from the run's
seed and the chunk's coordinates, so nothing is saved. If you walk away and come back,
you get land regenerated from the seed. Once dune-shifting arrives (see the full
version), it's new land.

World coordinates are tracked anyway. The engine's floats lose precision the further
you get from the origin, and from roughly 10 km out that shows up as jitter and physics
wobble. So the
engine keeps the player near the origin and shifts the whole scene back in whole-chunk
steps. Meanwhile the true world position is tracked separately in double precision.
That gives us **distance from spawn** for free, plus the hook for an underlying
topography later.

### A moon, not a plane

The desert is a moon, and the coordinates behave like it. The ground near you is flat
(we don't render the curve), but your position is tracked as **latitude and longitude**,
updated from how you move. Everything a sphere does follows from that. Walk far enough
east and you come back to where you started. Circling the moon is shorter near the
poles. Walk over a pole and you come down the other side, with north becoming south.

**The moon is about 150 km round** (a radius of about 24 km). That's around 30 hours
on foot, and about 37 km from the equator to a pole. Circling it is an epic a long run
can achieve. A real sphere this small would put the horizon about 300 m away. We render
the ground flat precisely so the big views stay possible.

The dunes don't need to wrap, because they're stateless and shifting anyway. What
wraps is everything fixed: the coordinates, the underlying topography and climate by
latitude. Those are sampled from your true point on the moon, so they're seamless all
the way round and over the poles.

Loot regenerating behind you isn't an exploit. In an endless desert, the land ahead is
always as rich as the land behind.

## Skeleton version

This is the minimum that makes the whole game loop possible. Every item gets built.

- `height_at(x, z)` from seeded noise. One layer of gentle dunes, the same for the
  same seed every time. *(Replaced by the full version's Ridges, 2026-10-15.)*
- A square chunk grid that streams around the player by grid position. Starting
  values to tune: **64 m chunks with 1 m height samples**, collision within 2 chunks
  of the player, visible ground out to about 8 chunks.
- Collision from the same samples as the visible mesh up close, so what you see is
  exactly what you stand on.
- A **crude far ring**: low-detail ground, visual only, reaching a few kilometres
  out. It proves early that the far view is cheap and stays separate from collision
  (rule 2), because the big views depend on it.
- Distance haze that hides the edge of the loaded world: thin in clear weather, thick
  enough in a storm that you can barely see past the shield.
- The scene shifts back toward the origin in whole-chunk steps. The player's latitude
  and longitude are tracked from movement in double precision. A debug readout shows
  them, along with distance from spawn measured around the moon.
- A flat sand-coloured material. *(Replaced by the sand shader, 2026-10-15; see the full
  version.)*
- The probes below, all passing.

## Full version

Built after the skeleton loop works end to end, in roughly this order:

- **Underlying topography.** Large, fixed shapes the dunes sit on: dune seas, hard
  flats, basins, ridges. These are the bones of the land, and they're stable across a
  run. *(A first pass came with Ridges: land of broad basins and rises about 12 m high and
  never steeper than about 1°, and a sand-supply field a few kilometres across that makes
  dune seas where it's high and bare flats where it's low. Sand gathers in the basins.
  Both are still sampled from flat world coordinates, not yet from the moon.)*
- **Real dune shapes** (decided). Windward slopes are gentle (about 5–15°), and slip
  faces sit downwind at the steepest angle loose sand holds (about 33°). Travelling with
  the wind, you walk up gentle slopes and slide down steep faces. Travelling into it, you
  climb slip faces, which puts the difficulty dial into the ground itself. Dunes face the
  long-term prevailing wind of their region, not the day's wind, so they stay stable and
  seams stay exact. **Pulled forward** (Hunter, 2026-10-15): he wants the dunes bigger and
  steeper in places, as long as they look good. A dune look-test (`look/dunes`) runs
  ahead, as the storm wall's did: candidate shapes in the real world, judged by eye,
  before any becomes the default. **Hunter picked Ridges** (2026-10-15, from the
  look-test's sheets): long ridges across the long-term wind, up to about 40 m where sand
  is plentiful, shrinking into flat corridors where it's short, crests that wander, dip
  and fork, gentle windward ramps and slip faces near 32°.

  **Built** (2026-10-15), and the game's ground. Ridges stand about 260 m apart across
  the run's mean wind, the same mean the weather blows round. Each has a windward ramp of
  up to 14° where sand is plentiful, a crest rounded over a metre or two, and a slip face
  at 31.5°. A bare flat comes before the next ramp: wide where sand is short, a sliver in
  a dune sea. Crest lines wander about 70 m over 600 m, rise and dip along their length,
  and fork where a second set of crests grows in patches. Everything is built from ramps
  measured in true metres and joined so nothing gets steeper, so no ground passes 33°.
  Measured over 5.8 km² at the collision's 1 m: 10% of the ground is over 15°, 7% over
  28° (enough to slide you), the steepest is 32.5°, and half of it is flat enough to
  camp on (a shield-sized square under 5°). The skeleton's noise had nothing over 14°
  and only 15% of it was camp-flat. A run starts on flat ground near the first chunk's
  middle, never on a slip face. The numbers live in Tuning's Terrain group, and
  `look/dunes` shoots and measures them.
- **Latitude and the poles** (decided). Toward the poles, storms weaken and the
  temperature swings get wider (see the vision). This system supplies latitude; Wind &
  storms and Survival read it. Fixed fields get sampled from the true point on the
  moon, and each new chunk copies its shared edges from loaded neighbours so seams stay
  exact.
- **Shifting dunes.** Land generated after a storm passes comes out different. This
  only affects newly generated chunks; rule 2 still holds.
- **Distance rendering.** This is core, not polish, because the clear-day view is a
  reward. Lower-detail rings out to the horizon (with skirts so no gaps show),
  generation on worker threads, and heat shimmer softening the far edge. In a storm,
  the far rings can be dropped entirely. *(Mid-distance chunks went from 4 m to 2 m
  samples with Ridges: at 4 m, sharp crests staircase past 100 m.)*
- **Sand that looks like sand.** Wind ripples, colour variation, a shimmer at
  distance. *(A first pass, built 2026-10-15 and on by default: ripples across the wind
  on gentler slopes, fading out before they flicker; slip faces a shade deeper, warmer
  and smoother; a thin highlight on crests; broad patches of colour. Tuning's
  `sand_shader` switches back to the flat colour. Hunter kept it on, 2026-10-15.)*
- **Light on the ground.** The sun, plus a warm fill from the dusty sky at three
  quarters of it, which lights every slope alike. The sand sends back about a third of
  the light, as real desert sand does: when it was paler, sunlit ground ran into the
  tonemap's white and every dune washed out to one pale colour. At the equator the noon
  sun stands overhead and lights every face alike, so slip faces' deeper colour is what
  shows the dunes then. Tuning's Light group holds the sand's colour, the sky's fill
  and the exposure; look/dunes prints how well the ground reads in each view.

## What other systems get from this one

- `height_at(x, z)`: the one height function.
- Position on the moon (latitude, longitude) and distance from spawn, in double
  precision.
- Signals when a chunk's ground becomes solid, when it stops being solid, when a chunk
  is forgotten, and when the origin shifts. Salvage lays out finds when a chunk's ground
  becomes solid, seeded from the chunk's coordinates. Anything that caches positions
  listens for the origin shift.
- A guarantee: inside the collision range, the ground is solid and doesn't move.

## Probes (how we know it works)

All of these run without a window, use a fixed seed, and assert:

1. **Function equals collision.** At 1,000 random points in loaded chunks, a downward
   raycast hits within 1 cm of `height_at`.
2. **Nothing falls through.** Physics boxes dropped at random points all come to rest
   on the sand, within a small tolerance of `height_at`.
3. **The long walk.** Move the player 20 km, both in a straight line and on a random
   wander, with objects following. Nothing ever ends up below the ground, the number
   of loaded chunks stays bounded, and memory stays flat.
4. **Origin shift is invisible.** A resting stack of boxes and a jointed pair survive
   an origin shift without moving relative to the ground or to each other.
5. **No seams.** Neighbouring chunks agree exactly on their shared edge.
6. **Deterministic.** The same seed and coordinates always give the same heights.
7. **No hitches.** No frame spends longer than a set line of main-thread time on
   streaming, from the first chunk on. Headless runs can't see the shader compile or
   the GPU's side of an upload, so `look/stream` holds a real window to the line, by
   hand. Headless, one frame over is allowed: a busy machine can pause the main
   thread, while streaming that overruns does it at every chunk.
8. **A sphere underfoot.** Dead reckoning behaves like the moon: a lap of the equator
   comes home, a lap at 60° is half as long, and walking over a pole comes down the
   other side.

Every probe gets checked against a deliberately broken build first, to prove it can
fail.

## Out of scope

- Saving terrain, and terrain persistence of any kind.
- Digging or deforming the ground. When storms "uncover" finds, that's done by placing
  things, not by reshaping loaded sand (rule 2).
- Caves, water and anything underground.
- Multiplayer.

## Open questions

- **Does difficulty also scale with distance from spawn?** Latitude already scales it
  (see above).
- **Is the ground cheap enough for the hoverboard?** Ridges' `height_at` takes about
  3 µs at a lattice point and 8 µs between points, against 0.3 µs for the skeleton's
  noise; the ruins' check adds half a microsecond more (Salvage & ruins). Reads on loaded ground come from the chunk's samples, at about 1 µs. The main
  thread doesn't feel it, since chunks are built on workers. But flying at dev speed,
  the ground round you is still being built in almost half the frames, against a fifth
  with the old noise. The hoverboard's top speed will need it cheaper: a native port of
  the shape, or fewer noise calls. *Measured at Stage 10: cheap enough for now. Flat out
  on the board, 20 m/s, at sixty frames a second, the ground was solid at least 120 m
  ahead the whole way (Movement probe 7), and the worst streaming frame was 1.17 to
  1.28 ms headless, against 1.16 ms walking (probe 7 here) and the 2.0 ms line, and
  1.21 ms in a real window at 144 Hz (`look/stream`). The board reads loaded ground, about a dozen reads a step at 240 steps a second, 0.15 ms
  a tick.*

Chunk size and the exact view distance are tuning decisions. The skeleton measures
them; they aren't design questions.
