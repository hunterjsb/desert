# PRD: World & terrain

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

The desert is the stage for everything else. It has to be endless, it has to look like
somewhere worth wandering, and above all it has to be **solid**. Sand Game died here:
things fell through the ground, floated above it, or vanished. If the ground can't be
trusted, nothing built on top of it can be either. So this system is judged on
reliability first and beauty second.

## What the player experiences

- Rolling dunes in every direction, fading into haze. There's no edge and no seam.
- Walking, sliding and hoverboarding over sand that always holds you.
- Anything you drop lands on the sand and stays there.
- A sense of distance travelled. The game always knows how far you are from where the
  run began, even though the land behind you isn't kept.

## Rules

These rules come straight from Sand Game's failure, and they don't bend.

1. **The ground is one function.** `height_at(x, z)` is the single source of truth. The
   visible mesh, the collision and the placement of every object all read it. Nothing
   computes height any other way.
2. **Loaded ground never changes.** A chunk's collision is built once, when it comes
   into range, and it's never rebuilt or reshaped while it exists. Detail levels only
   change how the ground looks, never how it collides.
3. **Nothing physical is ever outside collision.** Collision reaches further than any
   physics object is allowed to be. Anything that's about to leave that range gets
   frozen or forgotten first, so nothing can drop into the void.
4. **Chunks hold no state.** A chunk is pure output of the seed and its coordinates. The
   camp and the player belong to the world, not to any chunk. Unloading a chunk
   forgets everything in it.
5. **Loading follows coordinates, not collisions.** Which chunks exist is decided by
   the player's grid position, never by what a raycast happens to hit.

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

Loot regenerating behind you isn't an exploit. In an endless desert, the land ahead is
always as rich as the land behind.

## Skeleton version

This is the minimum that makes the whole game loop possible. Every item gets built.

- `height_at(x, z)` from seeded noise. One layer of gentle dunes, the same for the
  same seed every time.
- A square chunk grid that streams around the player by grid position. Starting
  values to tune: **64 m chunks with 1 m height samples**, collision within 2 chunks
  of the player, visible ground out to about 8 chunks.
- Collision from the same samples as the visible mesh up close, so what you see is
  exactly what you stand on.
- Haze that hides the edge of the loaded world. It's atmosphere and engineering at
  once.
- The scene shifts back toward the origin in whole-chunk steps. World coordinates are
  tracked in double precision, and a debug readout shows world position and distance
  from spawn.
- A flat sand-coloured material.
- The probes below, all passing.

## Full version

Built after the skeleton loop works end to end, in roughly this order:

- **Underlying topography.** Large, fixed shapes the dunes sit on: dune seas, hard
  flats, basins, ridges. These are the bones of the land, and they're stable across a
  run.
- **Dunes shaped by the wind.** Crests run across the prevailing wind, and steep slip
  faces sit downwind. This connects to the Wind & storms PRD.
- **Shifting dunes.** Land generated after a storm passes comes out different. This
  only affects newly generated chunks; rule 2 still holds.
- **Distance rendering.** Lower-detail rings for far chunks (with skirts so no gaps
  show), generation on worker threads, and a view distance tuned against the haze.
- **Sand that looks like sand.** Wind ripples, colour variation, a shimmer at
  distance.

## What other systems get from this one

- `height_at(x, z)`: the one height function.
- World position and distance from spawn, in double precision.
- Signals when a chunk loads, when a chunk unloads, and when the origin shifts. Salvage
  places finds when a chunk loads, seeded from the chunk's coordinates. Anything that
  caches positions listens for the origin shift.
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
7. **No hitches.** No single chunk build blocks the main thread for longer than a set
   budget.

Every probe gets checked against a deliberately broken build first, to prove it can
fail.

## Out of scope

- Saving terrain, and terrain persistence of any kind.
- Digging or deforming the ground. When storms "uncover" finds, that's done by placing
  things, not by reshaping loaded sand (rule 2).
- Caves, water and anything underground.
- Multiplayer.

## Open questions

- Does distance from spawn matter to gameplay, like harsher weather or richer finds
  further out, or is it only a number?
- What are the right chunk size and view distance? The skeleton will tell us. The
  numbers above are starting values.
- How steep can a dune get before you can't walk up it, and how smooth does the sand
  need to be for the hoverboard?
