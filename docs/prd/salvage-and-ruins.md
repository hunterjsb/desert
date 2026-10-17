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
- **Seeds,** mostly in ruins (Farming), and in the Cistern order's seed vaults (proposed; see
  Seed vaults, below).
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
2. **First Kingdoms to Second Age:** forged goods and cult works from the three ages after the
   collapse (the First Kingdoms, the Dark Age and the Second Age), which share this layer.
3. **Skimmer era:** skimmer-era salvage, in the middle.
4. **Colonial:** the original colonists' technology, which session 3 calls corporate tech.
   It's the oldest, the rarest and the best. You'll almost never find it in shallow erosion;
   it practically requires deep erosion. The best of it is **StarCom**, overbuilt for these
   exact conditions, but it turns up only as rare fragments (shards, relays and hardened
   modules), never a whole one.

**Renamed (Agreed, Hunter, 2026-10-16, after session 3).** The list used to read Surface, the
second empire, the first empire and Colonial. "The second empire," the layer above the ash band,
became **Bronze Age** and held both feudal eras. "The first empire," which the PRD called the
smuggler era below the ash band, is now **Skimmer era**; whether the two names cover the same
years is open (ambiguity D in [the lore
research](../lore-research.md#14-open-after-session-3)). **Surface** and **Colonial** keep
their names, and Colonial is the corporate tech. Nothing else about the layers changed, and
the skeleton's two layers are untouched.

**Renamed again (Agreed, session 4, part 2, 2026-10-17).** The layer called Bronze Age is now
**First Kingdoms to Second Age**, because the session retires the term and puts three ages in
place of the two feudal eras. It is one layer spanning all three, as the two shared one before.
Whether the three should stack as three layers instead is open (the lore research, [section
16](../lore-research.md#16-open-after-session-4-part-2)).

**The ash band** is the paroxysm, and a readable depth cue in storm-cut dunes. It no longer
has to divide the First Kingdoms to Second Age layer from the Skimmer era one, and where it sits
among the layers is an open item (Agreed, Hunter, 2026-10-16, after session 3), so the full
version's ash band waits on the answer.

**In the world (Agreed, session 3).** Corporate tech lies deepest and rarest, skimmer-era
salvage in the middle, and the forged goods of the First Kingdoms to the Second Age near the
surface. Dry, low-oxygen sand preserves ruins, and migrating dunes and storms expose and rebury
them, which is why harsher weather uncovers deeper loot. Burial needs little time: dunes and
eruptions bury ruins within centuries (session 4, part 2). The four layers above are these three
strata with a surface layer on top. How finds from the three ages differ inside their one layer
is not said, so this PRD doesn't try.

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

## Gear and ruins by era

*Hunter, 2026-10-17 ([notes](../session-notes-2026-10-17.md)); loose, and none of it built. The
current ruin is a placeholder, and large structures are out of scope for now.*

**What the eras left (Agreed, session 4).** The colonisation era lasted `{COLONIAL_ERA_SPAN}`
([placeholders](../lore-research.md#placeholders)), and hover trays and true space-age tech
were only shipped in then. So the best loot is **intact, sealed colonial facilities**, with
space-age power generation and late-game base gear. Most scattered ruins were stripped by the
societies after the collapse (the notes' wording predates the rename), so they hold **worn,
reused space-age items with carvings**: the First Kingdoms' heraldry and guild stamps, the
Second Age's religious symbols. Some carry useful mods, such as tuning for low-power setups,
which is the First Kingdoms' reworked, low-power gear (session 4, part 2: "every repair
cannibalises something else"). They're generally lower tier. The layer list above says "forged
goods and cult works" for the First Kingdoms to Second Age layer; this adds what they stripped
and reused. Which is commoner is not said.

**Era gear has trade-offs, not a ladder.** The notes' example is the crate:

| Era | Crate |
|---|---|
| **Colonial** | Best power efficiency per kilogram |
| **Skimmer era** | Light, cheap and fragile, because Zan wasn't a desert yet and gear wasn't built for storms |
| **First Kingdoms** | Practical to drag without a hover tray, still mountable, somewhat worse power efficiency per kilogram |

The notes name this row for the societies after the collapse. Session 4, part 2 ties reworked,
low-power gear to the First Kingdoms, so the row is theirs. What a Dark Age or Second Age crate
is like is not said. [Devices & mods](devices-and-mods.md#frames-by-era) has the frames' side of
it. The shield's shape is the first to change by era
([art direction](../art-direction.md#shape-by-era)).

**Ruins by era, kept simple.**
- **First Kingdoms to Second Age:** pillars and wall stubs from an outpost or complex, holding
  that era's gear. The base case. The notes don't say which of the three ages built it, so it
  spans them. The Second Age adds the crusader bunkers (below).
- **Skimmer era:** wreck props, such as a crashed hull or hangar frame. They sit with the
  skimmer ruins above (cradles, tethers, catch stations, crew wreckage), and the notes pick the
  simple version.
- **Colonial:** buried bunkers. You camp outside and go down for loot. To get big items out,
  keep both a sand-choked cargo ramp you can drag crates up and a dead freight lift you power
  from your own camp (the favourite). The lift is the kind of power check the notes say the
  hybrid play drags its camp to (a reading of two separate lines).

**The collector (idea).** A net like those in the game Raft, catching wind-blown loot. What
blows is open. It would suit the oyster, who never finds ruins (a reading; the notes don't link
them).

## Crusader bunkers on older sites

*Agreed, session 4, part 2 ([lore session](../lore-session-2026-10-17-part-2.md)); loose, and
none of it is built.* The Second Age empire can't reliably hold Port Morgan, so holding it is a
Templar-style holy war, kept by a military order with water convoys and fortified outposts dug
into colonial ruins ([the lore](../lore-research.md#the-dark-age-and-the-second-age-agreed-session-4-part-2)).
**The gameplay, the session's own: crusader bunkers sit on top of much older sites.**

Readings, not in the session:
- A bunker is a ruin type of its own, a Second Age building (religious symbols) standing over a
  colonial site, so one place stacks two eras: "history runs backwards" in a single walk-through.
- It is above ground in the sense this PRD means, built on top. The session also says "dug
  into," which would be a descent (open questions).

## Seed vaults (Agreed, session 4, part 3; not built)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)); loose, and none of it is
built.* Mother Cistern's priestesses seeded hardy strains along pilgrim roads and irrigation lines
as devotion, and those plantings went wild ([the
lore](../lore-research.md#life-on-zan-feral-plants-agreed-session-4-part-3)). **The loot half, the
session's own: the order's seed vaults hold preserved colonial seed stock that powers farming
setups.** A line of feral scrub "tends to lead toward a Cistern shrine and water," so the plants
point the way too.

Readings, not in the session:
- A vault is a find site of its own: a Second Age building (the order's religious symbols) holding
  colonial stock, so like a crusader bunker it stacks two eras. The colonial layer already holds
  "sealed seed stores, where the oldest seed is the best seed" ([the
  lore](../lore-research.md#8-the-ground-strata-the-oldest-tech-and-names)), and the vaults are
  where the order kept that stock.
- "Seeds keep only out of the weather" ([Farming](farming.md)): a sealed vault is where they do.
  Its seeds are the same kind of find as a ruin floor's, only more of them and better kept, a
  seedling at nothing grown, ready to sow.
- What "powers farming setups" means is not said. The game has two crops, carrots and fungus, and
  no stock is better than another yet, so "better" has no number anywhere.
- Where vaults stand is not said beyond the shrines the feral lines lead to. "Vault" also sounds
  like a descent, against "nothing underground" (open questions).

## Landmarks

*Agreed, session 4, part 2; loose, and none of it is built.* Landmarks are one general system,
not one-offs: a small class of prefab sites at fixed coordinates on the planet grid, the same in
every run, that persist the player's changes. They're the only fixed things on a shifting moon,
the exception to unloading out-of-range content ([World & terrain](world-and-terrain.md#landmarks)
has the rule). They can unlock endings and, for the prisoner, spawns. Candidates: the StarCom
antenna, the black site, the Bastion and the Ledger ([the endings](../vision.md#landmarks-and-endings)).

What it means for this PRD, as readings:
- A landmark is a ruin that is not seeded: a fixed, hand-built place, so the rule that puts at
  most one ruin in each square of chunks doesn't place it.
- "Persist the player's changes" means what you took from it stays taken and what you repaired
  stays repaired. The run save already keeps which finds near you were taken; a landmark's
  record would be the same kind, kept whatever the distance (Profile & saves).
- A landmark can be big, a fortress round a mainframe or a bunker cut into a rift wall, where the
  notes put large structures out of scope for now. They are later work.

**Sister (Agreed, session 4, part 3).** The first landmark with a description: "a fixed-coordinate
prefab landmark: half-buried temple, dormant terminal, basin that refills slowly. Restoration and
linking can wait for the endings work." It is Mother Cistern's temple city near Halfrise ([the
lore](../lore-research.md#mother-cistern-and-her-order-agreed-session-4-part-3)). At the player's
arrival the temple is abandoned, half buried and intact, and Mother Cistern is dormant but still
drips a trickle into a basin, "a reliable small water source until restored." Readings, not in
the session:
- It is an unseeded ruin like the rest, and "half buried and intact" is the base case at a larger
  scale: sand to its windows, with the roof standing. Large structures are later work.
- The basin is a small piece of state, how full it is, kept as the landmark's record. "Refills
  slowly" gives it a rate. The landmark rule keeps changes you made, not time that passed, so
  whether it refills while you are away is not said.
- Restoring and linking Mother Cistern are the Cistern axis ([Profile &
  saves](profile-and-saves.md#ending-flags-proposed)) and wait for the endings work.
- The Bastion is built round the freighter left behind, with the Ledger as its mind (Agreed,
  endings session), so the Bastion and the Ledger, two candidates above, may be one place.
- The endings need more fixed places: the sealed hangar deep in Aitch, the observatory on the far
  side, the far-side ice and an orbital station. Whether each is a landmark is not said, and the
  station is off the planet grid.

## People: only hinted

There are no NPCs. The moon is empty, or *almost* empty, and we only ever hint at it:

- A hatch standing open in the distance, just out of reach.
- A ruin where something has been used recently and left behind.
- Maybe a voice on the radio.

The game never answers the question.

**An idea from the endings session, not agreed:** the Okafor line, an underground bunker with a
holdout. Session 4, part 3 says Zan has the last nomad city "and possibly a bunker holdout." A
holdout would be a person, against the rule above, in a bunker underground, against this PRD's
"nothing underground." The session says to develop it or drop it.

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

**Built** (2026-10-15), passed the gate 2026-10-16.

- **Finds** are laid out when a chunk's ground becomes solid, from the run's seed, the
  chunk's coordinates and how hard the weather has been there, and go when it stops
  being solid. While the chunk stays loaded it remembers what you took, so its finds
  come back as they were less that; once the chunk is forgotten, so is that. Open sand
  holds 1.5 finds a chunk on average, at most 4. Each find draws from its own stream of
  the seed, where it lies first, so the weather changes what a find is but never where it
  lies.
- **Partly buried.** A buried part stands on end and a device stands upright (a
  hoverboard stands on end, nose down, as a board stuck in snow does, and a chassis
  piece on its edge, a sheet the dunes half took), all
  leaning with the sand and up to 15° more their own way: a quarter to a half of its
  height under the sand in the surface layer, 40 to 65% in the deep, and always at least
  35% of it and 10 cm showing. A quarter of the parts on open sand lie loose on top
  instead, as do parts too short to bury and still show 10 cm (hooks and plugs), and
  everything on a ruin's floor lies loose: loose finds are set down 3 cm up, settle, and
  then hold where they settled.
- **A find is part of its chunk** until it's yours: frozen where it lies, dark, and left
  out of power, wear and the wind. Whatever you take, take from, fit to, use or take hold
  of becomes yours, an ordinary thing in the world, and runs at once if its battery can:
  a found shield generator switches on with the first use. Taking hold of a buried
  device pulls it up out of the sand onto it.
- **Yours, it's loose.** Anything not buried can be taken hold of, pushed or towed from
  the moment it's yours, however it became yours. A find still buried stays as the sand
  holds it until you take hold of it: a line tied to it holds fast, as on a stake. Found
  in Hunter's playtest (2026-10-16): a find you'd taken from or tied a line to stayed
  frozen, so a stripped device on a ruin's floor could never be taken hold of, and a line
  tied to one held you as an anchor would. Nothing found is too heavy to drag by hand:
  the heaviest, a crate with every socket filled, is 51 kg, 250 N of your 400 N on a
  ruin's floor or the sand.
- **What's found** is the catalog's own parts and devices. The surface layer holds
  batteries, hooks, lamps, empty canisters, rope coils, cable plugs, hoses and compasses
  (2026-10-17, compasses one in twenty-one of the surface layer's parts), and crate
  frames, chargers, planters, stakes, survival kits, radios (Stage 11, two in thirteen of
  the surface layer's devices) and chassis pieces (2026-10-17, one in thirteen). The deep
  layer holds big batteries,
  batteries, hover trays, solar panels, hooks, strong cable plugs and harvesters, and
  crate frames, wind turbines, condensers, shield generators and, rarer, hoverboards
  (Stage 10, one in ten of the deep layer's devices; a ruin's hall never holds one,
  since it promises parts to strip) and chassis pieces (one in ten). A ruin's floor holds all
  its layer's finds and more: seeds (carrots and fungus), sealed rations and survival
  kits. A device comes with some of its sockets filled from its own layer, a third of
  them at the surface and three in five deep. Over 3,000 chunks on two seeds, rope coils
  and plugs are each about one find in fourteen, strong plugs one in thirty-five, survival
  kits one in thirty-three (a seventh of them on ruins' floors), and the harvester, at one in
  sixty, is the rarest part on open sand (2026-10-16, before radios). With radios,
  hoses, chassis pieces and compasses (2026-10-17), of 4,675 finds radios are one in 27
  and compasses one in 47.
- **Rope and wire** lie as one body until they're yours. A coil, taken, gives you a
  line's first end to lay, the rest on your belt. A plug standing in the sand is a
  cable's first end: take it and its 6 m cable and second plug come up with it, a strong
  cable's from the deep layer. Carried, yours roll back up the same way (Survival).
- **The first deep shield is an upgrade.** A found shield generator is the base shield:
  a 7 m bubble of still air against the 4 m, half-windy light shield every run starts
  with (Survival), and a found solar panel makes 60 W against the light panel's 30.
- **A survival kit** is a small sealed case you can carry, 3 kg, with a water socket, a
  food socket and three plant slots. It's found with each filled three times in four, and
  its canister and ration sealed and full: what you live on at first. Seeds keep only out
  of the weather, so a kit on open sand holds a seed in a slot only one time in ten. Over
  the same chunks, 58 of 99 seeds were in ruins. Rations are found sealed wherever they
  lie; a loose canister is found empty, since open water boils off.
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
- **The "go looking" scenario** stands you 12 m out from the front door of the
  ruin nearest the run's start, facing it, at a clear and calm moment (no storm for ten
  minutes, wind under 6 m/s), with a bare crate frame of your own beside you. The
  ruin's hall always holds a device with at least two parts to strip. The dev overlay's
  salvage column shows the finds in memory, and how hard the weather has been where you
  stand with the deep layer's share there.
- **Probe 5** also checks every kind turns up, rope and wire are common, seeds are mostly
  in ruins and the harvester is the rarest part; **probe 2** lays by hand any kind its
  walk didn't meet; **probe 6** strips a survival kit and unrolls a found coil, plug and
  strong plug through the hands.
- **Probe 8** walks the heaviest find, stripped of a part, out of the ruin's front door
  in your hands, and tows a found crate out of a roofed room and the back door on a line
  tied at your waist, dragged first into line with the door.
- **Probes** 1 to 8 pass, each checked against a deliberately broken build. Probes of
  other systems run without ruins and finds, as ground probes run in still air; salvage's
  own, the scenario probe and the hitch probe run with them. On the 20 km walk at most 66
  finds are in memory at once.

## Full version

- **All four layers,** from recent traces down to colonial: Surface, First Kingdoms to Second
  Age, Skimmer era and Colonial, with the ash band's place still open.
- **Things surfacing during a storm.** Sand pours off something new right beside you.
  It's placed, not dug.
- **Many ruin types,** part-buried, with interiors (all above ground), placed by terrain
  and carrying their makers' marks. Session 4 starts them as one per era (Gear and ruins by
  era), and its colonial bunker clashes with "all above ground" (open questions). Session 4,
  part 2 adds the crusader bunkers on older sites and the landmarks (both above).
- **Lore through item descriptions** that hint and never state.
- **Radio frequencies.**
- **Beds in some ruins** (proposed, 2026-10-17; [Survival](survival.md#sleep-proposed)).
- **Seed vaults and Sister** (session 4, part 3; both above, neither built).
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
8. **Out the door.** A found device, once yours, can be taken hold of and walked out of
   a ruin's doors, and towed out of them on a line.

## Out of scope

- Digging, and anything underground.
- NPCs, trading and crafting.

## Lore

Lore starts in **item descriptions**. They hint and never state. The game never says
outright what happened here. In the world, spelling carries age: X-spelled names
(XN-118-7, Xanathivin) are old and official, and the Z-spelled Zan is late and colloquial
([the lore research](../lore-research.md#names-the-ug-catalog-and-the-moon)). Session 3 adds
that the forms between them, skimmer-era slang and the variants of the ages after the collapse,
date a ruin too, and that the giant's name, Tu, wears down the same way from a designation
number ([the names](../lore-research.md#hierarchy-and-the-name-decay-agreed-session-3)).
Session 4, part 2 adds worn names and slang to use in carvings and radio chatter: Zan, Tu, Han,
Mon, Aitch, Monward, Hanmen, Zanborn and the tu- prefix
([the names](../lore-research.md#slang-and-name-erosion-agreed-session-4-part-2)).

## Open questions

Session 4's clashes with what's above are quoted and left standing. Nothing here is decided.

- Where the ash band sits among the four layers. It used to divide the second and first
  empire layers, and no longer has to ([the lore
  research](../lore-research.md#14-open-after-session-3), ambiguity D).
- **Buried bunkers against "nothing underground".** Here: "Everything is above ground:
  there's no digging and nothing underground," and out of scope, "Digging, and anything
  underground" (World & terrain agrees: "Caves, water and anything underground"). The notes:
  "Colonial: buried bunkers. You camp outside and go down for loot." Not said: whether the
  bunker is a real descent below the ground, or a building the sand has buried to its roof.
  One way it could fit, not decided: the ruin's footprint cut into `height_at` as a sunk court
  the sand drifts into, with roofed rooms of boxes over it, as the built ruin's rooms are, so
  the ground stays one function and nothing is a cave.
- **Trade-offs against "better".** Here: "The deeper the layer, the older the find, and the
  better its technology"; the vision: "Everything built after them is cruder"; art direction:
  "this is where 'older is better' reads best"; and the deep shield "is an upgrade." The
  notes: "Era gear has trade-offs, not a ladder." Colonial wins on power efficiency, but the
  skimmer-era crate is lighter and cheaper and the First Kingdoms one drags without a tray. Both
  can hold if tier orders how good a find is while a frame's traits trade (the notes call
  the ruins of the ages after the collapse "generally lower tier"). Not said whether that is the
  reading.
- **The built ruin against the base case.** The built ruin is a roofed building with a hall,
  and the radio's beacon and the "go looking" scenario point at its hall ("The ruin's hall
  always holds a device with at least two parts to strip"). The notes: the current ruin "is a
  placeholder," and the base case is "pillars and wall stubs," which have no hall. Not said:
  where a find sits at a stub, and whether the walk-in building becomes the colonial bunker's
  entrance or goes.
- **What counts as a big item.** Here: "Nothing found is too heavy to drag by hand: the
  heaviest, a crate with every socket filled, is 51 kg." The notes: "To get big items out, keep
  both a sand-choked cargo ramp... and a dead freight lift." Nothing found today needs either.
  The big finds they serve, late-game base gear, don't exist yet.
- **The collector against frozen finds.** Here: a find "is part of its chunk until it's yours:
  frozen where it lies, dark, and left out of power, wear and the wind," and "finds are placed,
  not dropped"; the vision: "Only what's around the player exists," and stateless. The notes:
  "a net... that catches wind-blown loot. What blows is open." Not said: what blows, where it
  comes from, and whether the net works only while its chunk is loaded.
- **One layer or three.** The layer list has one for the First Kingdoms, the Dark Age and the
  Second Age. Session 4, part 2 names three ages and says dunes and eruptions bury ruins within
  centuries, so the oldest could lie deepest. Not said whether they stack.
- **Crusader bunkers: "dug into" or "on top of."** Here: "Everything is above ground: there's no
  digging and nothing underground." The session: the order holds "fortified outposts dug into
  colonial ruins," and "crusader bunkers sit on top of much older sites." The bunkers section
  follows "on top of," which fits. Not said which the session means for the outposts.
- **Landmarks against "Ruins never move" and "Chunks hold no state."** A landmark is fixed and
  keeps your changes (World & terrain, Landmarks). Whether it is a ruin with a different
  placement rule or a system of its own is not said.

Session 4, part 3 (2026-10-17) adds three. Each is quoted on both sides and left standing.

- **Seed vaults against "nothing underground."** Here: "Everything is above ground: there's no
  digging and nothing underground." The session: "the order's seed vaults hold preserved colonial
  seed stock." Not said whether a vault is a descent or a sealed building above the sand, as with
  the buried bunker above. Not said where they stand, or what makes their stock better than a
  seed found on a ruin's floor.
- **A fixed basin against "finds are placed" and stateless ground.** Here: finds are laid when a
  chunk loads, from the seed and the weather, and a chunk holds no state. The session: Sister's
  "basin that refills slowly." Not said whether it refills while you are away, or what a player
  who camps beside it for days gets (every other source in Survival is carried, towed or used
  up).
- **A holdout against "no NPCs."** Here: "There are no NPCs." The endings session's Okafor line,
  "an underground bunker with a holdout," and part 3's "possibly a bunker holdout." Not said what
  the player would see of a holdout, and the session puts it among the ideas to develop or drop.

The sleep session (2026-10-17) adds two. Each is quoted on both sides and left standing.

- **Beds in ruins.** The session: "Some ruins have beds." Here: the built ruin is a thick-walled
  building, a hall open to the sky and two roofed rooms; ruins are static, "never physics
  objects"; and finds are typed parts and devices. A bed is none of those: it is furnishing, a
  fixed thing you use. Not said: which ruin type or era has beds, whether a bed can be taken (as
  a bedroll), and where it sits. A roofed room keeps no weather out as built, since only a bubble
  or a dune's lee shelters you, so a ruin bed helps in a storm only under a shield. And oysters
  "never find ruins" (the vision's playstyles), so they never see one.
- **Loot while you sleep.** Here: "Things surfacing during a storm" is a full-version line, and
  finds are laid out when a chunk's ground becomes solid; a loaded chunk only "remembers what you
  took." The session: "Storm-loot mechanics will help once they're in." Not said whether a storm
  slept through lays things bare as it passes, or only one you're awake for, and how an unseen
  span would place them. The sleep's arithmetic would have to say what surfaced.
