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
   forgets everything in it. The one planned exception is a landmark
   ([Landmarks](#landmarks), not built).
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

**The sky follows your point on the moon** (2026-10-17, [the Tu
spec](../tu-and-day-2026-10-17.md)). Local time follows longitude, so walking east brings
sunset sooner. Tu hangs fixed over the near side at a height and bearing set by where you
are, about a degree for every 420 m toward or away from the point under it, so it's a
landmark: on the far side it's never seen, and the stars, whose pole stands at your latitude,
take over. How it all looks is in [the moon](../the-moon.md#day-length).

The dunes don't need to wrap, because they're stateless and shifting anyway. What
wraps is everything fixed: the coordinates, the underlying topography and climate by
latitude. Those are sampled from your true point on the moon, so they're seamless all
the way round and over the poles.

Loot regenerating behind you isn't an exploit. In an endless desert, the land ahead is
always as rich as the land behind.

### Landmarks

*Agreed, session 4, part 2 ([lore session](../lore-session-2026-10-17-part-2.md)); loose, and
not built.* Landmarks are one general system: a small class of prefab sites at fixed coordinates
on the planet grid, the same in every run, that persist the player's changes. They're the only
fixed things on a shifting moon, and **the one exception to unloading out-of-range content.** The
StarCom antenna, the black site, the Bastion and the Ledger are the candidates, and they can
unlock endings and, for the prisoner, spawns ([the vision](../vision.md#landmarks-and-endings),
[Salvage & ruins](salvage-and-ruins.md#landmarks)).

It bends two things here and leaves the rest alone:
- **Rule 4, "Chunks hold no state,"** and the vision's "stateless." A landmark's changes are kept
  whatever the distance, so they can't live in a chunk. As a reading, they would live with the
  camp and the player, in the world and the save (Profile & saves), as a record keyed by the
  landmark.
- **The seed.** The terrain comes from the run's seed, and a landmark is "the same in every
  run." Its ground has to be pinned to the landmark whatever the seed says: a footprint in
  `height_at` like a ruin's, but at fixed coordinates. How, and whether the moon's lap holds all
  of them, is open.

Rules 1 to 3, 5 and 6 are untouched: the ground is still one function, and a landmark is placed
into it, never dug or moved.

## Tracks

You leave tracks (Hunter, 2026-10-16: "otherwise impossible to navigate in the storm,
especially at night"): footprints, the hoverboard's wake, the groove of something dragged
on a line, the dent where a crate sat. They're a surface layer the sand is drawn with,
dents and darker, trodden sand, never a change to the ground's shape or collision, so
rules 1 and 2 hold and the physics never knows. They read in a storm and at night, which
is what they're for, and the wind fills them: slowly in the calm, faster in a storm, but
never so fast you can't follow your own trail back. Only the ground near you keeps them;
like everything else, tracks far off are forgotten. Things resting on the sand sit in
their own imprint, the half-buried look without burying anything.

**Built** (2026-10-16). A window of ground 1 km square, 512 m each way from you, holds
them at a quarter-metre a texel, so the last 500 m of a straight walk back are always
in it. It follows you 16 m at a time and is wrapped round on itself, so moving never
redraws it, and it's kept in world metres, so origin shifts never touch it. Marks are
pressed in on the CPU, which headless runs do too, into 16 m tiles that exist only
while they hold one; the GPU gets only the tiles that change. Each texel holds the
reading of a **fill clock** at which its mark will be filled, so the wind's filling
costs nothing per texel: the clock runs, and the sand's shader takes it away. Nothing
is saved; a coarse copy of the held tiles would be cheap (about 16 KB a tile, a 500 m
trail touching 30 to 60) if a resumed run should keep its trail.

- **What presses them.** Your steps, on alternate feet a stride apart as the footsteps
  sound, a landing both feet, and a slide a groove. The board's hover a faint groove a
  quarter the depth of a step, deeper pressed into a dip and none in the air. Anything
  loose on the sand: resting, a full imprint, pressed again every 3 s so the wind never
  fills it under it; dragged, a groove the width of what touches, swept so a fast drag
  leaves no gaps. A dropped board leaves its shape.
- **How they look.** Trodden sand loses up to a third of its light and its ripples, a
  mark's walls tilt the light as a 6 cm dent would, the loose lip round it is lighter,
  and a mark sees less of the sky, which is all the light there is at night. The near
  ground's lattice is a metre apart, too coarse for a print, so the drawn sand instead
  stands 3 cm higher round marks: whatever rests in one sits in it, its foot hidden.
  Nothing glows.
- **Filling.** A full-depth mark fills in 90 minutes of calm and 20 of a full storm,
  shallow edges first, at the rate of the storm where you stand. A step still reads
  with a tenth of its depth left; the board's groove is gone in about 5 minutes of
  storm or 22 of calm. A walk of 500 m back through a storm, then three minutes more
  of it, leaves the oldest steps 61% of their depth (probe 10). Tuning's Tracks group
  holds the window and both rates.
- **How they read**, as lightness (CIE L*) over each mark against the sand beside it,
  fresh and after eight minutes of storm, from `look/tracks` at the fixed exposure: in
  clear day the sand is 76 and steps 9 darker fresh, 3 aged; in a storm by day the sand
  is 20 and steps 6 darker, 5 aged. At night under Tu's light, Tu half lit near
  midnight (measured again 2026-10-17), the sand is 2 and steps about 1 darker, too
  faint to tell fresh from aged. The eye ([art direction](../art-direction.md#eye-adaptation))
  opens on it, and then the sand is 5 and steps 2 darker (`look/tracks --eye`). **In a
  storm at night there's no light at all** (the sand is 0, and 0.4 with the eye): no
  ground reads, so neither do tracks, except in a lamp's or a shield's light. A lamp like a
  device's at your side lights about 5 m, where steps are half the sand's light. The
  suit's headlamp (Survival) is the light you carry that makes storm nights navigable.
- **Cost**, measured with the game running beside it: pressing takes at most 0.2 ms of
  a tick walking, 0.3 riding and 0.4 to 1.0 dragging a crate, and uploading at most
  0.6 ms of a frame. Drawing them costs an RTX 3070 about 0.2 ms a frame at
  1920x1080 (0.07 to 0.35 over three runs, alternating them on and off), and the map
  64 MB of its memory. Streaming stayed within its line in `look/stream` (1.54 ms
  against 2.0; under the same load master's own run went over it, at 3.6).

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
- `teleport(body, to)`: the one way to put a body somewhere at once, as a respawn, a
  resumed save and an origin shift do. Left to the physics, a kinematic body (you, a
  board you ride, a device seated on another) is carried there within one tick at
  whatever speed that takes, and throws whatever touched it where it was.

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
9. **Moving you shoves nothing.** A box standing against you stays put when a respawn
   puts you ten metres away.
10. **Tracks are only drawn.** Walking leaves a print within 0.6 m of every metre walked
    and none 3 m aside, a resting crate sits in a full imprint, a storm fills marks
    faster than calm, a 500 m walk back through a storm still reads after three
    minutes more of it, and `height_at` and the collision under the path are exactly
    as they were.

Every probe gets checked against a deliberately broken build first, to prove it can
fail.

## Out of scope

- Saving terrain, and terrain persistence of any kind.
- Digging, or changing the ground's shape or collision. When storms "uncover" finds,
  that's done by placing things, not by reshaping loaded sand (rule 2). Tracks are drawn
  on the surface and never touch the shape (Tracks).
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
  1.21 ms in a real window at 144 Hz (`look/stream`). The board reads loaded ground,
  about a dozen reads a step at 240 steps a second, 0.15 ms a tick.*
- **How a fixed landmark sits on a seeded world.** Landmarks are "the same in every run,"
  while the vision has "RNG driving both the terrain and the finds." The terrain under a
  landmark would have to ignore the seed (Landmarks above). Whether "persist the player's
  changes" means within a run or across runs is not said.

Chunk size and the exact view distance are tuning decisions. The skeleton measures
them; they aren't design questions.
