# PRD: Salvage & ruins

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

Parts are found, never crafted, so **salvage is the whole economy**. Every upgrade,
every new device and every better battery comes out of the sand. Salvage is also how
the moon tells its story: in what you find, in the order you find it, and in the hints
that someone else might still be out there.

## What you find

- **Parts:** batteries, hooks, hover trays, panels, instruments. These are the things
  that fit sockets (Devices & mods).
- **Whole devices,** often with parts missing. You can haul one around (tray or rope)
  until you find what it needs, or strip it and fit its parts to your own devices.
- **Fuel:** rare consumables, and fissile material if you're very lucky (Power).
- **Seeds,** mostly in ruins (Farming).
- **Survival kits:** a common find, usually holding seeds and water.
- **Lore:** fragments of what happened here.
- **Maker's marks:** everything found carries the mark of whoever made it, such as a
  government seal, a regulator's stamp, a shipyard logo, a contractor's tag, a comms
  casing or an improvised skimmer-crew patch. The player reconstructs the supply chain
  from salvage alone, with no exposition. The entities are in
  [the lore session](../lore-session-2026-10-14.md).
- **Radio frequencies** to tune into (Radio, sound & atmosphere).
- **Water:** still open. How you get it and how you make it is a hard question that
  belongs to Survival.

## How finds show up

- **Half-buried in the sand.** Things stick out of the dunes, part-hidden. Burying is
  done by *placing* things partly below the surface, never by reshaping the ground
  (World & terrain, rule 2).
- **Ruins you can walk into.** These are structures sitting in the dunes, with sand
  drifted against their walls. Everything is above ground: there's no digging and
  nothing underground.
- **Ruin types follow the terrain.** Skimmer cradles, tethers and catch stations stand on
  high ground, refineries cluster near volcanic vents, tank farms sit buried in basins,
  and port cradles and beacons stand on the heights. Gardens, water-cracking and power
  gather around the town sites. Improvised skimmer-crew wreckage is a separate, scrappier
  texture from the institutional ruins. Placing them needs the underlying topography
  (World & terrain), so it belongs to the full version.
- **Storms uncover things.** The harder the weather that exposed a place, the deeper
  the layer it reached.

## History runs backwards in the ground

The deeper the layer, the older the find, and the better its technology:

1. **Surface:** recent traces, and rare hints of holdouts.
2. **The second empire.**
3. **The first empire.**
4. **Colonial:** the original colonists' technology. It's the oldest, the rarest and
   the best. You'll almost never find it in shallow erosion; it practically requires
   deep erosion. The best of it is **StarCom**, overbuilt for these exact conditions, but
   it turns up only as rare fragments (shards, relays and hardened modules), never a whole
   one.

**The ash band** sits between the second and first empire layers. It's the paroxysm, the
page break of the whole history, and a readable depth cue in storm-cut dunes. The second
empire is the Bronze Age above it, and the first is the smuggler era below.

**The weather decides how deep the sand is stripped.** Stronger storms and fiercer
winds expose deeper layers. Venture into the storm, or travel into the wind, and you
find older, better things. Both difficulty dials pay out in salvage.

**Latitude gives two play styles.** The stormy equator is choppy and rich in salvage.
The calm poles have less loot, and nothing unique, but much more stability. That's where
you build big, with large solar farms and a thermal shield inside a wind shield, and
outpace the storms reliably.

Technically, a chunk's finds are placed when it loads, from the run's seed, the chunk's
coordinates and how hard the weather there has been. Like everything else, they're
stateless (World & terrain). Loot regenerating behind you isn't an exploit, because the
land ahead is always as rich.

## People: only hinted

There are no NPCs. The moon is empty, or *almost* empty, and we only ever hint at it:

- A hatch standing open in the distance, just out of reach.
- A ruin where something has been used recently and left behind.
- Maybe a voice on the radio.

The game never answers the question.

## What Sand Game taught us

Walk-in ruins had collision trouble, for the same reasons the terrain did:

- **Ruins were placed at a fixed height** (8–14 m above the chunk's origin), ignoring
  the dunes entirely, so they floated or sank.
- **Collision came straight from the imported model,** which gives thin, one-sided
  surfaces.
- **Each ruin was scaled up at random by 2–3.5×,** collision included.
- **Loot spawned at the ruin's own center,** inside the walls, frozen until you came
  near.

## Rules

1. **Ruins are part of the ground's one function.** A ruin's footprint is built into
   `height_at`, so the sand meets its floor and drifts up its walls exactly. Its
   position comes from the same seed and coordinates as the terrain around it.
2. **Ruin collision is simple shapes** (boxes and slabs), built for walking: floors,
   walls and doorways. Never collision taken from a detailed mesh.
3. **Nothing physical is ever scaled at runtime.** Different sizes are different pieces.
4. **Ruins never move.** They're static, never physics objects.
5. **Finds are placed, not dropped.** Every find sits at its intended depth: on the
   sand, partly buried, or on a ruin's floor. Loose finds settle from a few centimetres,
   never from metres.
6. **Finds are typed parts and devices** (Devices & mods), so anything salvaged works
   with your sockets the moment you pick it up.

## Skeleton version

- Finds placed when a chunk loads, from the seed and the chunk's coordinates: loose
  parts and whole devices, partly buried.
- Two layers: a common surface layer and a better deep layer, with exposure driven by
  the storm field.
- One walk-in ruin type made of simple shapes, with its footprint built into
  `height_at`.
- Stripping parts out of found devices.
- The probes below, all passing.

## Full version

- **All four layers,** from recent traces down to colonial, with the ash band between the
  second and first empire.
- **Things surfacing during a storm.** Sand pours off something new right beside you.
  It's placed, not dug.
- **Many ruin types,** part-buried, with interiors (all above ground), placed by terrain
  and carrying their makers' marks.
- **Lore through item descriptions** that hint and never state.
- **Radio frequencies.**
- **The hints of people.**

## Probes

1. **Deterministic.** The same seed, chunk and weather always give the same finds.
2. **Finds sit where they should.** Every find rests at its intended depth, never
   floating and never buried out of reach. Loose finds settle without falling through.
3. **Ruins sit in the sand.** Every ruin floor meets the sand within tolerance.
4. **The walk-through.** A probe walks every doorway and floor of every ruin type. The
   player never snags, never gets stuck, and never falls through.
5. **Harder weather, better finds.** Across many chunks, the average find tier rises
   with storm and wind exposure.
6. **Strip and fit.** Every part in a found device can be taken out and fitted to one of
   yours.
7. **Nothing leaks.** On the 20 km walk, the number of finds in memory stays bounded.

## Out of scope

- Digging, and anything underground.
- NPCs, trading and crafting.

## Lore

Lore starts in **item descriptions**. They hint and never state. The game never says
outright what happened here.

## Open questions

None right now.
