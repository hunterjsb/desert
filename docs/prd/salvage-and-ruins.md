# PRD: Salvage & ruins

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

Parts are found, never crafted, so **salvage is the whole economy**. Every upgrade,
every new device and every better battery comes out of the sand. Salvage is also how
the moon tells its story: in what you find, in the order you find it, and in the hints
that someone else might still be out there.

**In the world.** The moon never made anything high-tech. It was an assembly-and-operations
economy at the far end of a manufacturing chain, so after the cut it could fit and repair
parts but never fabricate them. Stamps come at two levels: the assembler's mark on a whole
device, and each component's own maker inside it. Why a find is rare depends on why it's on the
moon: ordinary goods are common, goods only the hub ran on were only ever made in small
numbers, and contraband, such as a deserter's military kit, is rare because someone carried it
in. See [the lore research](../lore-research.md).

## What you find

- **Parts:** batteries, hooks, hover trays, panels, instruments. These are the things
  that fit sockets (Devices & mods).
- **Whole devices,** often with parts missing. You can haul one around (tray or rope)
  until you find what it needs, or strip it and fit its parts to your own devices.
- **Fuel:** rare consumables, and fissile material if you're very lucky (Power).
- **Seeds,** mostly in ruins (Farming).
- **Survival kits:** a common find, usually holding seeds and water.
- **Lore:** fragments of what happened here.
- **Maker's marks:** almost everything found carries the mark of whoever made it, such as a
  government seal, a regulator's stamp, a shipyard logo, a contractor's tag, a comms
  casing or an improvised skimmer-crew patch. Commodity parts such as batteries carry none,
  so a mark means something where it appears. The player reconstructs the supply chain
  from salvage alone, with no exposition. The entities are in
  [the lore session](../lore-session-2026-10-14.md), and the makers beneath them in
  [part 2](../lore-session-2026-10-14-part-2.md).
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

**Built** (2026-10-15), waiting at the gate.

- **Finds** are laid out when a chunk's ground becomes solid, from the run's seed, the
  chunk's coordinates and how hard the weather has been there, and go when it stops
  being solid. While the chunk stays loaded it remembers what you took, so its finds
  come back as they were less that; once the chunk is forgotten, so is that. Open sand
  holds 1.5 finds a chunk on average, at most 4. Each find draws from its own stream of
  the seed, where it lies first, so the weather changes what a find is but never where it
  lies.
- **Partly buried.** A buried part stands on end and a device stands upright, both
  leaning with the sand and up to 15° more their own way: a quarter to a half of its
  height under the sand in the surface layer, 40 to 65% in the deep, and always at least
  35% of it and 10 cm showing. A quarter of the parts on open sand lie loose on top
  instead, and everything on a ruin's floor lies loose: loose finds are set down 3 cm up,
  settle, and then hold where they settled.
- **A find is part of its chunk** until it's yours: frozen where it lies, dark, and left
  out of power, wear and the wind. Whatever you take, take from, fit to, use or take hold
  of becomes yours, an ordinary thing in the world, and runs at once if its battery can:
  a found shield generator switches on with the first use. Taking hold of a buried
  device pulls it up out of the sand onto it.
- **What's found** is the catalog's own parts and devices. The surface layer holds
  batteries, hooks, lamps and empty canisters (where water comes from is Survival's
  question), and crate frames, chargers, planters and stakes. The deep layer holds big
  batteries, batteries, hover trays, solar panels and hooks, and crate frames, wind
  turbines, condensers and shield generators. A device comes with some of its sockets
  filled from its own layer, a third of them at the surface and three in five deep.
  Deep things were kept from the weather longer: batteries 30 to 100% charged against
  up to 40% at the surface, devices 70 to 100% sound against 35 to 75%. The look-at line
  says which layer a find came from.
- **How hard the weather has been** at a place is read over the last two hours, every
  10 minutes of world time: the mean of how deep into a storm it was or how far the wind
  blew past the prevailing wind's strongest, 16 m/s (toward 30 m/s, as hard as a storm's
  heart), whichever was harder. Fixed ticks of world time mean a chunk loaded any time
  within one reads the same. Over thousands of chunks it runs from 0.06 to 0.92, half
  of them over 0.55, and the deep layer's share runs with it from none to 60%: 19% of
  finds where storms touched half the hours or less, 53% where one sat the whole two
  hours. Changed on the way: storm or wind past 6 m/s barely varied, since storms cover
  70% of the time and the prevailing wind always counted, so the deep layer came out
  half of everything.
- **The ruin** is a thick-walled building 18 × 12 m: a 10 × 10 m hall open to the sky,
  two 6 × 5 m roofed rooms behind it, a door front and back and three inside (1.4 m wide,
  2.3 m high), walls 3 m. It's 18 boxes and slabs in its chunk's own collision body,
  built and gone with the sand's. At most one stands in each square of 5 × 5 chunks,
  wholly inside one chunk, where the dunes over its ground rise no more than 1.5 m and
  are nowhere steeper than 20°: about 2.3 a km², one every 650 m or so. It turns only
  in quarter turns, so its walls stand on the lattice. A run never starts on a ruin's
  ground.
- **Its footprint in `height_at`:** inside, the sand lies 3 cm under the floor; outside,
  it drifts 0.7 m up the walls, gone 4 m out, and lies level with the floor in front of
  each outer door; 12 m out the dunes have their own shape back. The outer walls are a
  metre thick and stand on whole metres, so the sand's rise from floor to drift happens
  inside a wall. The steepest ground round any ruin is 21.6°, under the 28° that slides
  you. **Cost:** one table lookup per call. `height_at` takes 3.4 µs at a lattice point
  (2.9 before) and 8.9 µs between points (8.2). A chunk build asks once, so it costs the
  same as before, and the far ring reads the dunes alone. Each candidate's ground is
  surveyed once a run, about 1 ms on a worker.
- **Stripping** needed nothing new: take a part out of a found device and fit it to
  yours, as with any device. A part in a socket buried in the sand can't be seen until
  you take hold of the device.
- **Streaming:** laying out a find is split into pieces of at most about half a
  millisecond (a device's frame, each part it was found with, then into the world), and
  a chunk's finds are freed one at a time. The worst streaming frame is 1.0 to 1.1 ms
  headless (world probe 7) and 1.3 to 1.4 ms in a real window (`look/stream`, 1.55 ms in
  the same run with salvage off). Found on the way: asking a shape for its bounds
  through its debug mesh made the main thread wait for the render thread, about 6 ms,
  the first time for each shape; a box's bounds come from its size now. Charge lights and
  socket tells share their looks.
- **The scenario menu's "go looking"** stands you 12 m out from the front door of the
  ruin nearest the run's start, facing it, at a clear and calm moment (no storm for ten
  minutes, wind under 6 m/s), with a bare crate frame of your own beside you. The
  ruin's hall always holds a device with at least two parts to strip. The dev overlay's
  salvage column shows the finds in memory, and how hard the weather has been where you
  stand with the deep layer's share there.
- **Probes** 1 to 7 pass, each checked against a deliberately broken build. Probes of
  other systems run without ruins and finds, as ground probes run in still air; salvage's
  own, the scenario probe and the hitch probe run with them. On the 20 km walk at most 66
  finds are in memory at once.

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
outright what happened here. In the world, spelling carries age: X-spelled names
(XN-118-7, Xanathivin) are old and official, and the Z-spelled Zan is late and colloquial
([the lore research](../lore-research.md#names-the-ug-catalog-and-the-moon)).

## Open questions

None right now.
