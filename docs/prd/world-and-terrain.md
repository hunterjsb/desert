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
   change how the ground looks, never how it collides. The one exception (2026-10-18): the
   ground of a site a storm works on follows the weather's own function, pressed afresh
   in steps of 2.5 cm, mesh and collision together, never over you or your camp
   ([Wind & storms](wind-and-storms.md#storms-with-a-payoff-agreed-2026-10-18-spec)).
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
  of them, is open. *Overtaken by session 4, part 4 (below): landmarks are placed per seed, so the
  ground is generated around them and nothing is pinned against the seed.*

Rules 1 to 3, 5 and 6 are untouched: the ground is still one function, and a landmark is placed
into it, never dug or moved.

**Sister (Agreed, session 4, part 3).** Session 4, part 3 ([lore
session](../lore-session-2026-10-17-part-3.md)) gives the first landmark a description: "a
fixed-coordinate prefab landmark: half-buried temple, dormant terminal, basin that refills slowly.
Restoration and linking can wait for the endings work." It is Mother Cistern's temple city, near
Halfrise on the Rim ([Salvage & ruins](salvage-and-ruins.md#landmarks) has the site, [the
lore](../lore-research.md#mother-cistern-and-her-order-agreed-session-4-part-3) the story).
Readings, not in the session:
- **Where it stands is a longitude question.** The Rim is a region of the sky's map, Tu half-risen
  on the horizon, and the game has only latitude. Sister's coordinates wait for the regions
  ([the vision](../vision.md#the-world)), and so do Halfrise and the other great sites.
- **Its basin is state a chunk can't hold.** How full it is, and whether Mother Cistern is dormant,
  restored or linked, belong with the landmark's record in the save, the reading above
  ([Profile & saves](profile-and-saves.md#ending-flags-proposed)).
- **It is one more fixed place on a map that has none,** so it leans on the same open question as
  the other landmarks: how a fixed landmark sits on a seeded world (open questions).

**Placement per seed (Agreed, session 4, part 4).** Part 4 settles most of how a landmark sits on a
seeded world. Its fixed landmarks (Port Morgan, the Halloran refinery and H-Town, the black site,
Starcom, the observatory, the orbital launch site (replaced by the Rim depot in part 5), Sister, Halfrise) are "placed procedurally per
seed, but always present, because the endings depend on them." The newer session wins, so a landmark
is no longer "the same in every run" at "fixed coordinates on the planet grid" (part 2): every world
has them, along the line toward Tu, and the terrain is generated around them, history first
([World generation by layers](#world-generation-by-layers-agreed-session-4-part-4-not-built)). The
exception to unloading stays: what you changed in one is kept whatever the distance.

## World generation by layers (Agreed, session 4, part 4; not built)

*Designed whole in [the world system](../world-system.md), which is the contract for building it. Its
spine is built (2026-10-17): the history pass per seed on the sphere, the eight landmarks, the path
network and the site index, laid onto the ground near you by moon cells.*

*[Session 4, part 4](../plants-worldgen-ruins-2026-10-17.md), with its labels as given: **Agreed** is
settled direction, **Idea** is proposed and not confirmed, **Back burner** is liked and not to be
built yet, and anything under its open questions is undecided and not to be hard-coded. None of it is
built. Its scope warning: "the game has no structures and no terrain generation yet. Lore here is
deliberately deeper than what should be built now." What to build first is the session's ten steps
in the [skeleton plan](../skeleton-plan.md#the-newer-proposed-order-session-4-part-4). Hard rule: no NPCs, no
dialogue, no exposition; history reaches the player through objects, terrain, instruments and
radio.*

**The takeaway: generate history first, then terrain and loot.** The session describes today as 99%
of loot "loose in sand and the rest in one copy-pasted ruin," on a world that is "fully procedural
with an underlying coordinate system but no terrain generation phase yet." The ground here is built
(Ridges, the first pass of underlying topography); what the session means is that no phase yet
decides what was where. It adds one, in layers:

### The layers (Agreed)

1. **Colonial layer.** Place the fixed colonial landmarks first, then the colonial skeleton: main
   highways, pipelines, power corridors, water-import aqueducts and hab tunnels.
2. **Skimmer layer.** Wrecks, pads and camps, mostly overlapping colonial ruins and clustering around
   Han.
3. **First Kingdoms layer (the first age).** Settlements along dead colonial lines and near water;
   first-age water lines link them. Part 5 says part 2 is canon for the age: the keepers' holdings, a
   citadel and toll towns, as well as part 4's pipe towns and cisterns ([Salvage &
   ruins](salvage-and-ruins.md#structures-by-era-and-the-loot-model-agreed-session-4-part-4-not-built)).
4. **Second-age layer.** Towns on top of or near first-age sites, with Halfrise and Sister as
   anchors and a dense road network.
5. **Feral layer.** Plants placed along the roads, water lines and ruins the layers left
   ([Farming](farming.md#propagation-growth-stages-and-wild-habitats-agreed)).
6. **Sand.** Everything is buried at a depth matching its era, and storms take over from there
   ([Salvage & ruins](salvage-and-ruins.md#structures-by-era-and-the-loot-model-agreed-session-4-part-4-not-built)).

"Each layer builds on the last, so history stays coherent per seed."

**The order, restored by part 5.** The history pass runs in the session's order: "colonial → collapse →
skimmer era → **First Kingdoms** (first age) → **Dark Age** → second age → feral." The layers above are
the ones that place sites. The Dark Age "generates no sites of its own": it is a lineage rule on loot
([Salvage & ruins](salvage-and-ruins.md#the-dark-age-as-a-lineage-rule-agreed-session-4-part-5-not-built)).
The collapse has no layer either, in part 4 or part 5; a reading is that it adds no site and changes
what the earlier layers hold, their burial and abandonment. So the order of sites is unchanged:
colonial, skimmer era, First Kingdoms, second age, feral, sand.
### Roads and water lines are placement rules (Agreed)

"The roads themselves are gone; the player never sees a road surface." Generate invisible paths
between anchors, then scatter structures and feral plants along them. The pattern of saltbush lines,
shrines and watchtowers is what traces the road.

### The colonial skeleton (Agreed)

(The session's word; it is not the game's skeleton build.)
- Port Morgan is the colonial hub, on the Tu-facing side. **Spokes** run outward to the ring; some
  routes run **around** the ring and some **in** toward the hub.
- The **main artery** runs inward from the Rim (Halfrise, Sister), through Mon (Port Morgan), down to
  Han (Halloran, the black site).
- The **observatory** sits alone in the dark zone on its own long spoke: a maintenance road with power
  lines, giving a reason to cross the dark. (Part 5: it is the elevator stub on the far-side volcano, at
  the anti-Tu point.)
- **Starcom** is high altitude, on a peak or ridge above the weather.
- Density tapers: rich at the Rim, thinner in Mon, sparse and grim in Han.

### Fixed landmarks in every world (Agreed)

"Placed procedurally per seed, but always present, because the endings depend on them": Port Morgan;
the Halloran refinery and H-Town (Aitch); the black site; Starcom; the observatory; the orbital
launch site; Sister; Halfrise. (**Part 5 replaces the orbital launch site** with the Rim depot:
[below](#the-rim-depot-the-twin-fires-and-the-elevator-stub-agreed-session-4-part-5-not-built).) The
session corrects two places on the way: the black site sits on the
main artery, not an isolated spoke, and Starcom and the orbital launch site are separate places
([the lore](../lore-research.md#corrections-and-places-agreed-session-4-part-4)).

### Keeping a huge moon interesting (Agreed)

Arteries alone leave most of the moon empty. The fixes:
- **Dense networks:** each era made many minor paths, farm tracks and local wells, not just main
  roads.
- **Off-network sites:** skimmer wrecks crash anywhere; colonial survey beacons and relay towers sit on
  a grid; First Kingdoms hermits and holdouts lived remote.
- **Drift** fills the gaps ([Salvage & ruins](salvage-and-ruins.md#two-channels-agreed)).
- **Meaningful emptiness:** some deep desert stays empty on purpose as the dangerous zone between
  settled areas.
- **Region identity:** the hot zone, the dark zone and the ring band each have their own plants,
  storms and sites.

### Readability

Arteries must be legible from the dunes: "a straight line in nature means people." Saltbush lines,
watchtower silhouettes, pylon stubs and pipeline humps run in straight lines. A basic survey mod on
the Console picks up buried metal, so colonial pipelines show as lines on screen
([Devices & mods](devices-and-mods.md#the-console-proposed-first-version-built)).

### Spawns and the early goal (Agreed)

The early game for everyone: **find an artery and follow it.** Spawn position depends on the kit:
- **Surveyor:** deep desert with detection gear; finding an artery is their early game.
- **Salvager:** near a skimmer wreck field.
- **Homesteader:** right on a road, near a wayshrine.

### Readings, not in the session

- **A layer plan is still the one function.** Rule 4 says a chunk is "pure output of the seed and its
  coordinates." Roads, anchors and sites can be so if they are a plan of the whole moon made from the
  seed, and a chunk only reads it. The moon is finite, about 150 km round, so a coarse plan is a
  fixed-size job done once a run, as each ruin candidate's ground is surveyed once a run now
  ([Salvage & ruins](salvage-and-ruins.md)). The roads are paths on the sphere, so they are sampled
  from latitude and longitude, which the terrain's fixed fields do not yet use ("still sampled from
  flat world coordinates").
- **The sand layer is the footprint trick.** A built ruin is pressed into `height_at` so the sand
  meets its floor. A structure "buried at a depth matching its era" is the same trick with the sand
  over its roof, set when the chunk is made. Nothing reshapes loaded ground (rule 2) but a storm
  working a site, live (2026-10-18).
- **Per-seed landmarks answer a standing question.** "How a fixed landmark sits on a seeded world"
  (open questions) was hard when landmarks were "the same in every run." Placed per seed along the
  axis, with the terrain generated around them, they sit on any seed. Whether a landmark's changes
  carry across runs is untouched.
- **The ring is the Rim's band, a reading.** "The ring" is new to the docs. Spokes "run outward to
  the ring," the black site is "inside the ring," and the hot zone, dark zone and ring band are
  regions with their own plants. They fit the sky's three regions: hot zone under Tu, ring band the
  Rim, dark zone the far side ([the lore](../lore-research.md#tu-the-tidal-lock-and-the-water-agreed-session-4-part-2)).
- **Scale.** The Rim to the point under Tu is a quarter of a lap, about 37 km, the same as equator
  to pole here, a walk of several hours. Caravanserais "at day-long intervals on the artery" would
  be about 1.7 km apart if a day is the game's 20 minutes on foot, so about twenty of them along the
  line, or a handful if "day" means a lore day's march. The session does not say.
- **Density is regional, and the built ruin density is not.** One ruin in each 5 by 5 chunks,
  about 650 m apart, holds everywhere today. Rich at the Rim and sparse in Han is a field over the
  moon.

## The Rim depot, the twin fires and the elevator stub (Agreed, session 4, part 5; not built)

*[Session 4, part 5](../gods-gear-farside-2026-10-17.md), section 6, labels as given (everything is
**Agreed** unless marked). None of it is built. The lore is in [the lore
research](../lore-research.md#the-rim-depot-and-the-twin-fires-agreed-session-4-part-5).* "Part 4's
'orbital launch site' landmark is **replaced** by two things: the Rim depot and the far-side elevator
stub, which is also the observatory."

- **The Rim depot** is a suborbital port near Sister, built for the terraforming effort. It is a
  landmark in the launch site's place. Interstellar freight landed at Port Morgan and hopped
  suborbitally, or went by rail and truck, out to the Rim, so later roads follow the colonial rail and
  truck line from Port Morgan to the Rim: the **main artery** has a reason. It gives the Rim real colonial
  loot (hoppers, pads, rail yards, terraforming equipment), and it explains why Mother Cistern, Sister and
  Halfrise sit where they do.
- **The twin fires.** Tidal heating peaks at the point facing Tu and the point opposite it, and
  volcanism clusters at both: Halloran's rift vents at the sub-Tu point (the Stoker's) and a great
  far-side volcano at the anti-Tu point, "far-side centre, on the equator" (the Eye's).
- **The elevator stub is the observatory.** The summit of the far-side volcano holds the finished ground
  anchor and lower tether of a space elevator, and the cultists built the observatory out of the tower
  stub: "the tallest structure on Zan, above the dust, out in the dark," with one of the moon's major
  vent caps under it.
- **Hoppers (late-game travel; deferred):** from the depot out to the observatory, up to Starcom, or
  into Port Morgan carrying parts or fuel. "Flying over Han's coverage without having dealt with the
  Quartermaster gets you shot down."

The landmark list is now Port Morgan; the Halloran refinery and H-Town (Aitch); the black site; Starcom;
the observatory; the Rim depot; Sister; and Halfrise.

Readings, not in the session:
- **The far side has a place to walk to.** The anti-Tu point is half a lap from the sub-Tu point, about
  75 km on the game's lap, and a quarter lap past the Rim, so about 37 km, the walk from the Rim to the
  point under Tu, across the dark. The observatory's "own long spoke" of part 4 (a maintenance road
  with power lines) is the tower's service line. Nothing is placed there yet.
- **A tower is a landmark you can steer by.** The tallest structure on Zan, standing out of the dust
  in a black sky, is visible from far. It meets the same missing landform as Starcom's peak: the ground
  has only basins, rises and ridges (open questions).
- **The depot is the Rim's, and the main artery now runs from it.** The artery runs inward from the
  Rim "through Mon, down to Han"; its Rim end is the depot, Sister and Halfrise together.
- **The twin fires are two regions of one rule.** Volcanic ground is heat, vents and ash; the sub-Tu
  and anti-Tu points each get it, and the ground between is the Rim's and the cold. The rift valley is
  the first, and the second has no description beyond the volcano and its tower.
  *Built 2026-10-18: the world system's [Geology](../world-system.md#geology) holds the rift's line and
  its vents, and the plumes are in [Wind & storms](wind-and-storms.md#plumes).*

## Ambient life: sand beetles (Agreed, session 4, part 4; not built)

Zan now has colonial insects as well as feral plants (Agreed). "The constraint: they must be cheap to
model."
- **Sand beetles** are colonial pollinators or decomposers that went feral: small ambient creatures
  that scuttle, with no AI beyond that.
- They tie into the plants. Dewleaf's ancestor is the fog-basking beetle, glowcap attracts them, and
  wild stormcups trap blown-in insects ([Farming](farming.md#the-plant-system-agreed-session-4-part-4-partly-built)).
- *Open:* whether beetles are pests, pollinators, or both.

Readings, not in the session:
- **They sit with "no native life."** Part 3 says "Zan has no native life, only feral colonial
  imports ('rogue plants'), plus the last nomad city and possibly a bunker holdout." Beetles are
  colonial imports, so the line holds, with insects added to the plants.
- **A scuttle needs no body.** Rule 3 is about physical things leaving collision, and a beetle is not
  one: no physics body and no collision, drawn only in loaded ground near the player, placed from the
  seed by habitat (near glowcap, in buried ruins' cracks). The vision's "No AI enemies, so no
  creature rigging" is untouched, since they are not enemies, and one rigid mesh moving needs no rig.
- **Pests and pollinators would each add a rule.** A pest breaks Farming's "Pests and diseases" out of
  scope, and a pollinator would need a crossing rule (Farming asks "can players create new strains?").
  The session decides neither.

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
  exactly what you stand on. *(2026-10-18: a chunk's collision comes in four 32 m
  heightmaps, built first in a frame, as many as the streaming budget holds. A whole
  chunk's took up to 1.25 ms headless, and under load it was what most often took a
  frame past the hitch line, stretched to 2 to 14 ms; a quarter takes about 0.15.
  Each piece runs a metre past its edges, 5 cm below the neighbour's ground there. A
  heightmap's edge is a real edge to Jolt, and a small body riding a centimetre into
  the sand hit the next one's like a step: a rope's loose end dragged across a seam at
  13 m/s came out at 3, against 10.7 mid-chunk. With the lip it comes out at 9.8, what
  the slope costs it there. Rope probe 5's loose end had been snagging on a seam, not
  the dune face it was laid for.)*
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
- **World generation by layers** (session 4, part 4; above): a plan of the moon made from the seed,
  colonial landmarks and skeleton first and the feral layer last, with sand over all of it. The
  session's order starts with the colonial skeleton and the second-age roads only
  ([skeleton plan](../skeleton-plan.md#the-newer-proposed-order-session-4-part-4)).
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
5. **No seams.** Neighbouring chunks agree exactly on their shared edge, and the
   collision inside each chunk's edges holds exactly its mesh's samples.
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
  1.28 ms headless (0.9 ms since collision comes in quarters, 2026-10-18), against
  1.16 ms walking (probe 7 here) and the 2.0 ms line, and
  1.21 ms in a real window at 144 Hz (`look/stream`). The board reads loaded ground,
  about a dozen reads a step at 240 steps a second, 0.15 ms a tick.*
- **How a fixed landmark sits on a seeded world.** *Narrowed by session 4, part 4: landmarks are
  "placed procedurally per seed, but always present" (below).* Landmarks are "the same in every run,"
  while the vision has "RNG driving both the terrain and the finds." The terrain under a
  landmark would have to ignore the seed (Landmarks above). Whether "persist the player's
  changes" means within a run or across runs is not said. Session 4, part 3's Sister adds a
  place on the Rim, and the Rim needs longitude regions the game doesn't have yet.

Chunk size and the exact view distance are tuning decisions. The skeleton measures
them; they aren't design questions.

Session 4, part 4 (2026-10-17) adds the following. Each is quoted old and new. The newest session wins
in the living docs, so this PRD follows it where it can, and says so on each line.

- **Landmarks per seed against "the same in every run."** Here (Landmarks, from part 2): "prefab sites
  at fixed coordinates on the planet grid, the same in every run." The session: "Placed procedurally
  per seed, but always present." *Follows the session.* Not said whether a landmark keeps the same
  shape in every seed, or only its role; "persist the player's changes" is still unsaid as within a
  run or across runs.
- **A plan of the whole moon against "Only what's around the player exists."** Here (the vision):
  "Only what's around the player exists," and "Stateless." The session: roads, anchors and layers
  generated as history, "coherent per seed." Read above as a plan the chunks read, finite because the
  moon is. Not said how coarse the plan is, or whether anything of it is kept in a save.
- **Landforms the ground doesn't have.** Here: underlying topography is "broad basins and rises about
  12 m high and never steeper than about 1°" and ridges up to about 40 m. The session needs a plateau
  for Port Morgan, a rift valley and wall for Halloran and the black site, and a peak "above the
  weather" for Starcom. Not said whether the topography grows these or the sites stand on the
  ground as it is.
- **The dangerous deep desert in a game with no enemies.** The session: "some deep desert stays empty
  on purpose as the dangerous zone between settled areas." The vision: "No enemies to fight." Read as
  the danger being distance from water and roads, since the pressure is "the moon itself: wind,
  storms, heat, thirst."
- **"Find an artery" for everyone against wandering, and the oyster.** The session: "Early game for
  everyone: find an artery and follow it." The vision: wander "wherever you like," and the
  Homesteader (the oyster) is "fully stationary." The session puts the Homesteader on a road, so
  the artery finds them. Not said how the Surveyor's artery is found "deep" in the desert beyond
  "detection gear."
- **Spawns by kit against the built spawn and the built kit.** Here: "A run never starts on a ruin's
  ground," and starts on flat ground near the first chunk's middle (Salvage & ruins); the Surveyor's
  kit is a crate, standard shield, tray, multi-compass, stake tether and radio (the vision), with no
  detection gear, and the Archaeologist is the start with ground-penetrating radar. The session: the
  Salvager near a skimmer wreck field, the Homesteader "near a wayshrine," the Surveyor with
  "detection gear." *Follows the session* for where each starts. Not said whether the Surveyor's
  detection gear is in the kit or a find, or whether a start beside a wayshrine breaks "never on a
  ruin's ground" (it is beside, not on) or the vision's "oysters never find ruins."
- **How much storm-driven dune movement the terrain can support.** The session's own open question.
  Here, rule 2: loaded ground never changes, and "Shifting dunes" only change newly generated chunks.
  Since 2026-10-18 a site's own ground follows a storm live (rule 2's exception).
- **The orbital launch site.** *Answered by session 4, part 5: there is none, and the Rim depot and
  the elevator-stub observatory replace it (above).* The session's own open question: location and
  structure. The ladder
  launches "from Port Morgan," and Port Morgan's colonial pads are a landmark of their own
  ([Salvage & ruins](salvage-and-ruins.md#landmarks)). Not said whether the launch site is those pads
  or a separate place.

Session 4, part 5 (2026-10-17, [the gods session](../gods-gear-farside-2026-10-17.md)) adds the
following. Each is quoted old and new. The newest session wins in the living docs, so this PRD follows
it as direction and says so on each line.

- **The orbital launch site against the Rim depot.** Here (above, from part 4): the launch site is a
  fixed landmark and "location and structure" is the session's own open question. The session: it is
  "**replaced**" by the Rim depot and the elevator stub. *Follows the session; the question is
  answered.* Not said whether the launch endings fly from the depot. The ladder says they launch "from
  Port Morgan," and the depot is suborbital.
- **A volcano and a tower on a ground of low rises.** Here: underlying topography is "broad basins and
  rises about 12 m high and never steeper than about 1°," with ridges up to about 40 m. The session: a
  "great far-side volcano" with the tallest structure on Zan on its summit. Not said whether the
  topography grows a mountain or a rise carries a tower that only looks tall; the same open question as
  the plateau, the rift and Starcom's peak.
- **A far side nobody has built.** Here: the game has latitude and no longitude regions, and a run starts
  on the near side. The session puts a landmark at the far-side centre. Not said how the regions arrive,
  or whether a run ever goes there before the sky does (the Tu spec's open question).
- **Hoppers against a game with no flight.** Here: movement is the board, the tray and the sailboat. The
  session: suborbital hoppers as late-game travel. *Deferred in the session.* Not said what a hopper is
  as a thing in the world.
- **The tidal heating at both bulges.** Here (the moon): a fading, rounding orbit with the vents going
  quiet. The session: the heat peaks at two points and the volcano at the far one is a vent cap that
  still matters at the end. Not said where the First Kingdoms' vents went, or whether they went to the far
  side ([the lore, section 19](../lore-research.md#19-open-after-session-4-part-5)).
