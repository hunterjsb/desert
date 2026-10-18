# The world system

*Draft, 2026-10-17. The contract for every builder of the world system: the history pass, the
landmarks, the paths, the sites, the structures, exposure, loot, lineage, the feral layer and spawns.
It answers [World & terrain](prd/world-and-terrain.md) and [Salvage & ruins](prd/salvage-and-ruins.md)
and builds part 4 ([plants, world gen and ruins](plants-worldgen-ruins-2026-10-17.md)) and part 5
([gods, gear and the far side](gods-gear-farside-2026-10-17.md)) as one system.*

Hunter, 2026-10-17: "flesh out the ruin gen... so we can stop just having totally random loot just all
over the desert. actually lets go for the whole system, who am i kidding? half assing is what killed
last sand game. a giant isnt built of small human skeletons."

So this is one design with one set of interfaces, and every later piece plugs into it. The spine (the
history pass, the landmarks, the path network and the site index) is built and probed
([What the spine does now](#what-the-spine-does-now)). Everything else here is a package for a builder,
with the interface it plugs into ([The build plan](#the-build-plan)).

Where the lore leaves a gap that blocks the design, this doc picks a value and marks it **(default)**.
Every default is listed in [Defaults](#defaults), so Hunter can change any of them in one place, and
every number is in Tuning's History group or a table in code, never scattered.

## The shape of it

Three layers, each built on the one below:

1. **The history** is a plan of the whole moon made from the seed, on the sphere: where Tu's point is,
   the eight landmarks, every road, rail line, water line and track, every settlement, and the sites they
   left, each with its era, its kind and its burial. It is pure in the seed and never changes during a
   run. It lives on the sphere because the moon is a sphere: walk a lap and you meet the same history
   again.
2. **The sheet** lays the history near you onto the flat ground the game is built on. It works in moon
   cells about 500 m across: a cell is laid down before any chunk it touches is built, and lifted only
   once every such chunk is gone. Laid down, a site has a place in world metres like everything else.
3. **The site index** answers the questions chunks and systems ask: which sites, path pieces and
   landmarks touch this area, which site's ground is under this lattice point, what is nearest that I
   want. It holds today's ruin too, as the first kind registered.

Builders plug in above the index. **Kits** say what a site is on the ground (its carve, boxes, sockets
and look). **Loot** says what it holds. **Lineage** says what each thing it holds remembers. **Feral**
says what grows along it. **Spawns** say where a run starts in it.

## The law, and how this keeps it

The rules of [World & terrain](prd/world-and-terrain.md#rules) don't bend for history.

1. **The ground is one function.** A site that changes the ground does it through its kind's carve,
   inside `height_at`, as the ruin does today. Nothing else shapes ground.
2. **Loaded ground never changes.** A cell is laid before any chunk it touches is built, and lifted only
   after every chunk it touches is forgotten. A site's exposure is decided when its chunk is built and
   holds while it's loaded. A site can change while you're away; never while you look.
3. **Nothing physical is outside collision.** A site's boxes join the collision of the chunk its middle
   stands on, as the ruin's do, so they come and go with that chunk's sand.
4. **Chunks hold no state.** A chunk is the output of the seed, its coordinates and the sheet. The sheet
   is the world's, like the camp and the player, and the save keeps it ([Saves](#determinism-and-saves)).
5. **Chunk streaming and origin shifts.** The index works in world metres, never engine positions, so an
   origin shift touches nothing in it. Laying a cell and querying the index fit inside the streaming
   budget.
6. **The 150 km lap.** History is on the sphere, so a lap comes home to the same Port Morgan.
7. **The moon position is the truth of where you are.** `MoonPosition` dead-reckons latitude and
   longitude from your walk. The sheet lays history from that same point, so where Tu stands in your sky
   and what history is under your feet always agree near you.

### Why a sheet, and what it costs

Flat ground can't hold a sphere. Dead reckoning makes the flat world's place on the moon depend on the
way you walked: east then north ends somewhere a little different from north then east, by the area
walked round times tan(latitude) over the moon's radius, about 20 m for each square kilometre at 25°.
No fixed map of the flat world onto the moon can agree with dead reckoning everywhere. So the history is
laid near you, from where you are, and kept while it's near.

The cost is seams. Two cells laid at different moments, from points you'd walked between, can meet a
little off. On the equator, or walking along a meridian, they meet exactly. Elsewhere the offset grows
with how far east or west you walked between the two and with tan(latitude). At the Rim's latitudes
(the axis keeps them under 25°, [Landmarks](#landmarks)), the widest seam on a 3 km walk east past
Halfrise at 22° was 24 m (probe 4 measures it). Paths are invisible and sites stand tens to hundreds of
metres apart, so a seam reads as nothing. Inside one cell everything is laid together and agrees to the
centimetre.

## Scale

| | |
|---|---|
| The lap | 150 km (Tuning `moon_circumference`); radius 23.87 km |
| One degree | 417 m |
| The Rim to the point under Tu | a quarter lap, 37.5 km |
| The point under Tu to the anti-Tu point | half a lap, 75 km |
| A game day on foot | 20 min at 1.8 m/s, about 2.2 km |
| A game day on the board | 20 min at 20 m/s, 24 km |
| Spawn | 0°, 0°; Tu over 0°, 60° W (Tuning), so spawn is 25 km east of the point under Tu, 12.5 km inside the Rim |

The moon's area is about 7,160 km². The near side (under Tu and the Rim's inner half) is half of it.

## The history pass

One pass per seed, run when the world's ground is made (`TerrainShape`), on the sphere, at the scale of
the whole moon. It is pure: the seed and Tuning in, the plan out. It runs the eras in the order part 5
fixed: **colonial, collapse, skimmer era, First Kingdoms, Dark Age, second age, feral, then sand.** Each
layer reads what the layers before it left, so history stays coherent per seed. Hunter's chain of
collapses (2026-10-17, [the lore, section 19](lore-research.md#19-open-after-session-4-part-5)) is the
spine of it: "colonial collapse when the lane was cancelled when the war broke out, devolved into
skimmer offworld with black site"; "skimmer collapsed into first age kingdoms when the provisional state
fell"; "first kingdoms collapsed when power infrastructure collapsed and mass war broke out on the
moon"; "final kingdoms collapsed slowly into nomads"; "almost all nomads die out as the atmosphere and
planet changes."

### The frame

- **The point under Tu** comes from the Tu work: Tu hangs over latitude 0 at `tu_longitude_degrees`
  (`DayCycle`), so the sub-Tu point is (0°, Tu's longitude). The **anti-Tu point** is opposite it.
- **The angle from Tu**, θ, the angle between a place and the sub-Tu point seen from the moon's centre,
  says where you are under the giant: Tu stands 90° − θ above your horizon.
- **The regions** are bands of θ **(default)**: **Han**, under Tu, θ under 20°; **Mon**, θ 20° to 75°;
  **the Rim**, θ 75° to 105°, the ring band where Tu sits on the horizon; **the far side**, past 105°.
  The hot zone is Han and Mon, the ring band is the Rim and the dark zone is the far side ([the
  lore](lore-research.md#corrections-and-places-agreed-session-4-part-4)).
- **Richness** is how much was ever built there, tapering as the lore says: "rich at the Rim, thinner
  in Mon, sparse and grim in Han." **(default)** The Rim 1.0, Mon 0.5, Han 0.25, the far side 0.12,
  blended across a band's edges, and thinning toward the calm poles, from 50° of latitude to 30% at
  80° (the poles have "less loot, and nothing unique," Salvage & ruins). Every density in the pass is
  multiplied by it.
- **The axis** is the line the three great sites lie on, from the Rim in toward the point under Tu: a
  great circle from the sub-Tu point at a bearing the seed picks, east or west within 25° **(default)**,
  so the Rim end stays under 25° of latitude, where seams are small and the sky's latitude dials stay
  mild.

### The layers

1. **Colonial.** The fixed landmarks first ([Landmarks](#landmarks)), then the colonial skeleton between
   them: the main artery, the spokes from Port Morgan to the ring, the ring routes, the observatory's
   long spoke, Starcom's spur, Han's pipelines along the rift, and what runs along them (power
   corridors, water-import aqueducts, the depot's rail line). Then colonial settlements along that
   skeleton: frontier towns on the spokes, pump stations on the aqueducts, Frontier Ag farm domes near
   the Rim, vent stations on the rift. Off the network, survey beacons and relay towers on a grid.
2. **Collapse.** No sites. It marks the colonial layer abandoned: from here on, colonial sites only
   lose things and gain sand.
3. **Skimmer era.** "Mostly scars on colonial structures": camps and pads on colonial sites, more of
   them the nearer Han; black-site checkpoints on the artery round the rift; wreck fields off the
   network, clustered toward Han.
4. **First Kingdoms.** Settlements along the dead colonial lines and near water, cisterns where the
   colonial water lines ended, first-age water lines linking neighbours, and hermits and holdouts
   remote. The keepers' holdings are where the colonial machines were: the three powers sit on Port
   Morgan, Halloran and the Rim's farm towns.
5. **Dark Age.** No sites, by part 5's rule. It writes two things: the **lineage rule** every later
   loot draw uses ([Item lineage](#item-lineage)), and **signs** along the migration routes, the First
   Kingdoms' water lines the survivors followed: cairns marking water, caches, the first deliberate
   saltbush plantings. Signs are markers, not structures ([Sites](#sites)).
6. **Second age.** Towns on top of or near first-age sites, most on the Rim; Halfrise and Sister as
   anchors; a dense road network between towns; pilgrim roads with wayshrines; caravanserais at a day's
   walk on the artery; battlefields round Halfrise; crusader bunkers on colonial sites in Mon.
7. **Feral.** Hooks, not placement, in the pass: every path, water line, ruin and region can be asked
   for, so the feral package places plants by habitat ([Feral hooks](#the-feral-layer-and-spawns)).
8. **Sand.** Every site gets a burial depth matching its era ([Eras](#eras)).

### What it produces

- `History.landmarks`: the eight, with their parts ([Landmarks](#landmarks)).
- `History.network`: the path graph, its nodes and edges, each edge a spline on the sphere
  ([Paths](#paths)).
- `History.settlements`: every settlement node, with its era, kind, size and seed.
- A cell table: for each moon cell, the path edges and settlements that reach it. Sites themselves are
  made from it a cell at a time, when asked, and never stored ([Sites](#sites)).

### What it costs

The pass is a fixed-size job, since the moon is finite. Its budget is 40 ms once per run **(default)**,
measured by the budgets probe; making one cell's sites is under 1 ms. Nothing in it runs per tick.

## Landmarks

"Placed procedurally per seed, but always present, because the endings depend on them" (part 4), with
part 5's swap: no orbital launch site; the Rim depot and the far-side observatory instead. Each is placed
by a rule that keeps it true to Tu's geography. All angles are from the sub-Tu point; distances on the
150 km lap.

| Landmark | Where | Why | Parts |
|---|---|---|---|
| **Halloran and Aitch** | On the axis, 3° to 5° from the sub-Tu point (1.3–2.1 km): Tu all but overhead. A rift crosses the axis there. | "Deepest in, near the sub-Tu point. Rift valley; refinery on the terraces, H-Town on the floor." The Stoker's twin fire. | The refinery terraces (Muster on them), the Crossing at the switchback, Aitch on the rift floor 600 m across |
| **The black site** | On the artery 1.0–1.6 km from the refinery toward Port Morgan, in the rift wall | "Cut into the rift wall near Halloran inside the ring... on the main artery, not an isolated spoke." The Quartermaster's bunker | The bunker, the specimen case |
| **Port Morgan** | On the axis, 38° to 48° from the sub-Tu point (16–20 km from it, 17–22 km in from the Rim): Tu 42° to 52° up | "Partway in on its plateau. Tu high but off to one side." The colonial hub every spoke leaves | The Pads, the Bastion (the freighter and the Ledger), Kesselside, Lowtown, the Okafor bunker under the Bastion **(default: which enclave is open)** |
| **Halfrise** | On the axis at the Rim, 88.5° to 90°: Tu half-risen | "On the Rim, Tu half-risen on the horizon... at the head of the old road in to Port Morgan" | The citadel |
| **Sister** | On the Rim 1.6 to 2.6 km from Halfrise, either way along it | "A sister city near Halfrise," Mother Cistern's temple | The temple, the basin, the seed vault |
| **The Rim depot** | 0.7 to 1.2 km from Sister, on the Rim, away from Halfrise | "A suborbital port near Sister... The Cistern was built beside the depot that supplied it" | The pads, the rail yard |
| **Starcom** | In Mon, 50° to 68° from the sub-Tu point, 40° to 75° off the axis | "High altitude, on a peak or ridge above the weather"; apart from the axis and the depot | The antenna |
| **The observatory** | Exactly at the anti-Tu point | "The far-side volcano... at the anti-Tu point... far-side centre, on the equator," the one place Tu is never visible; Tilg's elevator stub on the summit | The tower stub, the vent cap under it |

So the three great sites lie on one line from the Rim toward the point under Tu, Port Morgan is "not
dead centre" (it stands well off the sub-Tu point, so the Rim's stretch nearest it matters most), and the
endgame is a journey down the axis. Pumpwell and Saloon, the frontier salvage towns on the old road
between Mon and Han, are settlements on the artery at a third and two thirds of the way from Port Morgan
to Halloran, not landmarks.

**How each is shown now.** Full interiors are out of scope. A landmark is three things in data, and the
kit package draws them:
- a **footprint**: a middle, a heading and a radius on the sphere (Port Morgan 1.6 km, the observatory's
  volcano 3 km, Halloran's rift 1.2 km, the others 150 to 400 m **(default)**), which a later landform or
  carve fills;
- **markers**: its named parts, each a point and a radius, where the endings' things will stand;
- **surface signs** for the kit to draw: Starcom's mast, the observatory's tower, Halfrise's walls, what
  you'd see first from the dunes.

Landmarks keep their changes whatever the distance (the one exception to unloading). That record lives
with the world and the save, keyed by the landmark's id, and is the endings work's to define.

## Paths

"The roads themselves are gone; the player never sees a road surface." Paths are invisible placement
rules: sites, signs and feral plants scatter along them, and "the pattern of saltbush lines, shrines and
watchtowers is what traces the road."

### The network

| Path | Era(s) | Carries | From, to |
|---|---|---|---|
| **The main artery** | colonial, First Kingdoms, second age | road; rail from the depot to Port Morgan; an aqueduct Port Morgan to the Rim; a fuel pipeline Port Morgan to Halloran; power | The Rim depot, Sister, Halfrise, Port Morgan, Pumpwell, Saloon, the black site, Halloran, the Crossing, Aitch |
| **Spokes** | colonial, then First Kingdoms along the dead lines, second age on the Rim end | road, power | Port Morgan out to the Rim, five besides the artery **(default)**, spread across the outward half |
| **Ring routes** | colonial between spoke ends near Port Morgan; second age all round | road | Round the Rim through the spokes' ends and Rim towns every 15° or so |
| **The observatory spoke** | colonial; second age pilgrims, faint | road, power ("a maintenance road with power lines") | Port Morgan out its own spoke to a Rim gate, then across the dark to the anti-Tu point |
| **Starcom's spur** | colonial | road, power | Port Morgan to Starcom |
| **Han's lines** | colonial; skimmer tracks | pipeline; tracks | Along the rift to vent stations; Halloran out to the wreck fields |
| **Water lines** | First Kingdoms | water | Between neighbouring first-age settlements and from cisterns |
| **Second-age roads** | second age | road | Between neighbouring towns: dense on the Rim, sparse in Han |
| **Minor paths and farm tracks** | the settlement's own era | track | From each settlement out to its fields and wells, short |

The colonial lines run straight: "a straight line in nature means people." Later roads wander a little,
the second age most.

### How a path is held

- **A graph on the sphere.** Nodes are points (a landmark, a settlement, a junction, a Rim gate). An
  edge joins two nodes and carries its kind, its eras, what it carries, its richness and its seed.
- **A spline.** An edge's line is its control points (the two nodes, and for the later eras a few
  points wandered off the great circle between them), smoothed by corner cutting on the sphere and kept
  as points no more than 250 m apart with their running length. That is the spline everything samples,
  and nothing else is.
- **A corridor.** Sites stand within an edge's corridor, 60 m either side **(default)**, so a road reads as
  a line of things, not a scatter.

### How a chunk asks what paths cross it

`sites.paths_in(rect)` returns every laid path piece crossing a rectangle of world metres: the edge's
id, kind, eras, what it carries, and its line through the cell as points in world metres. A chunk
asks for its own square, the feral package for a strip, the map for a view. It costs one lookup per
chunk the rectangle covers.

## Sites

A site is one structure instance: a pylon stub, a wayshrine, a wreck hull, a house ruin. Every site has:

| Field | |
|---|---|
| `id` | Stable for the seed: the same site has the same id every time it's made |
| `kind` | A kind in the registry ([The structure framework](#the-structure-framework)) |
| `era` | colonial, skimmer, first, second |
| `point` | Where it stands on the sphere |
| `bearing` | Which way it faces, from north |
| `reach` | How far its ground reaches from its middle, m |
| `depth` | How much sand lies on it, by its era ([Eras](#eras)) |
| `loot` | Its loot seed |
| `source` | What placed it: an edge, a settlement, the grid, a landmark |
| `region` | Han, Mon, the Rim or the far side |

Laid on the sheet, a site gains its place in world metres (`x`, `z`) and its flat bearing. A kind that
stands on the lattice also turns in quarter turns and surveys its floor, as the ruin does.

### Where sites come from

- **Along edges.** Each edge kind has placement rows: which kind, at what spacing along the edge, how
  far to the side, in which eras. Pylon stubs every 150 m along power, pipeline segments every 120 m on
  a pipeline, relay masts every 1.5 km on colonial roads, wayshrines every 700 m on pilgrim roads,
  watchtowers every 2.5 km on second-age roads, caravanserais a day's walk apart on the artery (2.2 km),
  dugouts along the artery in Han **(defaults)**. Each place on that spacing keeps its site as often as
  richness says, so the Rim is rich and Han sparse. Sites are placed by running length along the edge,
  so a cell gets the same sites whichever cell asked first.
- **In settlements.** A settlement is a cluster of its era's kinds within its radius: a walled village is
  house ruins, a wall and a granary; a pipe town is pipe-wall huts on a colonial pipeline; a skimmer camp
  is a pad, fuel bladders and a dugout on a colonial site.
- **Off the network.** Survey beacons and relay towers on a grid of latitude and longitude every 6°
  (2.5 km) on the near side, a relay tower at every second; skimmer wrecks that "crash anywhere,"
  likelier toward Han; First Kingdoms hermits far from any path.
- **Meaningful emptiness.** Nothing else. A cell no path or settlement reaches holds only the grid and the
  rare wreck or hermit. Some deep desert is empty on purpose: "the dangerous zone between settled areas,"
  dangerous by being far from water and roads.

### Signs

A sign is a small marker with no structure: a saltbush line's planting, a cairn, a cache, ancient
sandroot, glow in a crack. Signs "say something is buried beneath," and they're placed by the same rows
as sites, as their own kinds in the registry with no carve and no boxes. The feral package and the Dark
Age's markers are signs.

### The site index

The index is the generalised `RuinSites`. It is two sides of one thing:

- **On the sphere** (`History`), pure in the seed: the moon is cut into **moon cells** about 500 m across
  (bands of latitude, each cut into as many cells as fit round it, so cells are near square everywhere,
  about 28,600 of them). `history.sites_in_cell(cell)` makes a cell's sites from the cell table, the
  edges' rows, the settlements that reach it and the grid. It is cheap and deterministic.
- **On the ground** (`Sites`, on `TerrainShape`), laid by the sheet: every laid site in world metres,
  hashed by the chunk it touches, every laid path piece the same way, and the laid landmarks.

What chunks and systems ask:

| Call | Answers |
|---|---|
| `sites.query(rect)` | Every site whose ground touches a rectangle of world metres, today's ruins included |
| `sites.paths_in(rect)` | Every path piece crossing it |
| `sites.landmarks_in(rect)` | Every landmark whose footprint touches it |
| `sites.in_chunk(coord)` | The sites whose middle is in a chunk: those whose boxes it builds |
| `sites.covering(x, z)` | The site whose ground a lattice point is on, or none: what `height_at` asks |
| `sites.nearest(x, z, radius, wanted)` | The nearest site a test keeps |
| `history.nearest_landmark(point)` | The nearest landmark on the sphere, its distance and bearing, however far |
| `history.region_of(point)`, `history.richness(point)` | Where on the moon a point is, and how built up |

A chunk's own query costs a few lookups **(budget: 50 µs)**. The
probes check every answer against a scan of everything laid (probe 4).

### The sheet

- **Units.** The sheet lays moon cells, and landmarks as their own units because their footprints are big.
- **Laying.** Each time you cross into another chunk, on the physics tick, the world gives the sheet its
  anchor: the place the moon position was just reckoned at, in world metres, with that latitude,
  longitude and facing (which way north lies on the ground, turned round past a pole). Every unit whose
  ground comes within 1,300 m of you is laid **(default)**: each site's sphere point goes through the
  anchor's map (its distance and bearing from the anchor, as metres east and north) into world metres.
  Loaded ground reaches about 900 m, so a unit is laid long before its ground loads. Laying is spread
  over frames inside the streaming budget, a part at a time (one path's sites, one settlement's, the
  cell's own), and anything within reach of ground about to be built is laid at once, on the tick: the
  terrain builds no chunk until it is. Each unit keeps the anchor it was offered with, so where things
  land never depends on frame timing.
- **Lifting.** A unit is lifted once every part of it is more than 1,800 m away on the ground
  **(default)**, well past the last chunk that could touch it.
- **Jumps.** A dev teleport, a scenario that puts you elsewhere on the moon, or a resume, moves the moon
  position without a walk. The sheet sees the moon point disagree with the ground it walked from and
  starts again: units still under loaded ground stay as they were laid until that ground goes; no new unit
  is laid over loaded ground until it's gone. So even a jump never changes loaded ground.

### Today's ruin, the first kind

The three-room ruin is registered as the second age's **house ruin**: the look of "sand to the windows"
with a roofed pair of rooms and a hall open to the sky fits a second-age house better than any colonial
building. Its placement source for now is the grid it has always had (at most one in each 5 by 5 chunks
where the dunes are flat enough), in world metres, so **every ruin stands exactly where it did**: the
same middle, turn and floor on every seed (probe 5). The index answers for them like any other site, and
the radio's beacon now picks its ruin through the index.

**The rule that will move it**, for the kit and loot packages: when the house ruin's kit is built from
history (house ruins in second-age villages and along roads), the grid source is switched off, and a
house ruin stands only where history put one. Until then the grid's ruins are the only sites with
ground, and history's sites are a plan the map shows.

## The structure framework

A kit piece is data in the kind registry (`SiteKinds`), and one shared system builds every kind:

| Field | What it is |
|---|---|
| `era` | Its era: its look, its burial and its loot identity follow |
| `reach` | How far its ground reaches from its middle, m |
| `lattice` | Whether it stands on the lattice and turns in quarter turns (anything with walls) |
| `carve` | How it presses into `height_at`: the sand at a lattice point given what the dunes would be, as `Ruin.sand` does (floor, drift up the walls, level at the doors, back to the dunes by `reach`) |
| `boxes` | Boxes and slabs in plan metres, built for walking, never from a mesh, never scaled |
| `sockets` | Plan points where loot and props go, each with a socket kind (a floor spot, a shelf, a cache, a planter bed) |
| `paint` | Its era's look through the paint pass (`Paint`): colonial composites, First Kingdoms brass and enamel, second-age ceramic and cord |
| `depth` | Its burial by era ([Eras](#eras)), and how far it leans buried (the skimmer era's wrecks lie tilted) |
| `states` | What shows buried, partly exposed and exposed: which boxes stand above the sand and which sockets are reachable |
| `survey` | Where it may stand: the most the dunes may rise and how steep they may be over its ground |

Rules the framework keeps, from Salvage & ruins: collision is simple shapes; nothing physical is scaled
at runtime (different sizes are different kinds); sites never move; finds are placed, not dropped. A
kind's boxes join the chunk its middle stands on; its carve may reach the neighbouring chunks, through
`height_at`. The house ruin is the reference implementation: `Ruin` is a `Site` with its carve, boxes,
sockets (`Ruin.SPOTS`) and mesh.

## Eras

| Era | Kit (part 4) | Burial **(default)** | Loot identity (part 4) |
|---|---|---|---|
| Colonial | Pylon stubs, pipeline segments, hab pods, relay masts | Deepest: 2 to 6 m of sand over the roof; rarely exposed | Infrastructure: power, crates, big systems |
| Skimmer era | Wreck hulls, fuel bladders, dugouts | Shallow, 0.2 to 1 m, tilted 10° to 35°; exposed and reburied fast | Best single-item gear: from deserters and the black site |
| First Kingdoms | Pipe-wall huts, cisterns, low stone walls | Deep, 0.8 to 2 m: low foundations, barely visible | Intact working colonial tech used in new ways |
| Dark Age | No sites | None | No loot of its own: the lineage of second-age gear |
| Second age | Wayshrines, watchtowers, house ruins | Shallowest, 0 to 0.6 m: most often exposed; towers stand out of the dunes | Worn reused gear; water, seeds and salt |

The burial table orders the skimmer era above the First Kingdoms, as part 4 does for structures; the
loot strata of the vision ("history runs backwards in the ground") still hold for what lies loose, since
a standing wreck sits higher than a low foundation ([Salvage & ruins](prd/salvage-and-ruins.md#readings-not-in-the-session)).

## Exposure

A site is **buried, partly exposed or exposed**, decided purely from the storm history at its place up to
the moment its chunk is built, as finds are today (`Finds.exposure`). Nothing is decided while you look.

- **The sand taken off** is the weather's work at the site over a long window: the same reading as finds
  (how deep into a storm, how far past the prevailing wind's strongest), summed over the last 12 hours of
  world time in 30-minute ticks **(default)**, so one big storm strips a lot and calm lets the sand return.
- **The state** compares it with the site's depth: under a third of its depth stripped, buried; under its
  whole depth, partly exposed; past it, exposed. A colonial site needs a storm far harder or longer than a
  second-age one.
- **Reburial** is the same function: as calm hours replace stormy ones in the window, the sand taken off
  falls and the site goes back under. Relaxed, not a hard timer.
- **Deeper layers on a revisit.** A site's sockets have depths too. A returning storm that strips further
  reaches sockets lower in the same site, so revisiting pays; what was taken stays taken
  ([Saves](#determinism-and-saves)).
- **Fixed ticks.** It reads on fixed ticks of world time, so a chunk built any time within one reads the
  same, and the ground is the same however you came to it.

Signs follow the same function: a saltbush line shows whatever the sand does; glow in a crack only from a
site partly exposed.

## Loot

"Loot follows history: it comes from sites, and storms decide what's reachable. Stop spawning items
loose in open sand."

- **Site loot.** Tables by era and kind, drawn from the site's loot seed into its sockets. The era sets
  the loot identity (table above), the kind sets the sockets and what fits them, the region sets how
  generous (Han is "the jackpot for single items: sparse, dangerous, rewarding"). A socket's depth gates
  it by exposure.
- **Drift.** "Storms carry light debris, scraps and occasional small items." Drift is not objects carried
  across chunks: it is a stream computed from the storm and the camp's place, made into bodies only
  where something catches it (a net or tether mod), so it stays stateless. Its rate is the wind through
  the catcher, and terrain matters: "a camp in a sheltered valley below a dune crest where high winds ramp
  over" catches most, which is the lee ([Wind & storms](prd/wind-and-storms.md#the-lee-of-a-dune)): the
  wind slows there and what it carries falls out. Steady and low value.
- **Expedition.** After a big storm, sites are exposed for a while, and the good loot is in them. The
  radio's beacon, a surveyor's detection and the surface signs say where.
- **Today's loose finds.** The migration, in order: (1) finds on a ruin's floor become the house ruin's
  socket loot, unchanged in what they are; (2) the kit package's kinds get their own tables; (3) loose finds
  on open sand fall to a tenth of today's 1.5 a chunk, kept only along paths and in settlements' scatter,
  and drift takes over the gap; (4) the survival kits a first hour lives on move to the sites a start is
  near ([Spawns](#the-feral-layer-and-spawns)). Each step keeps Salvage's probes passing, rewritten to the
  new placement where they asked for loose finds.

## Item lineage

"A second-age item is a colonial or first-age item remade in the Dark Age. Item data should record
lineage: original era plus remake history."

- **Data on every item.** A short list on the part or device: its original era and maker, then each
  remake, as [era, what was done]: kept, marked, remade. A colonial find has one entry; a First Kingdoms
  find two (made, marked with a house's heraldry); a second-age find three (made, marked, remade in the
  Dark Age). It sits beside the maker and the layer a find came from.
- **Drawn, not saved, for finds.** A find's lineage comes from its loot seed and its site's era by the Dark
  Age's rule (`Eras.lineage`). Only a thing that's yours keeps it, with the thing.
- **Layered marks are driven by it**, readable without text ([art
  direction](art-direction.md#layered-marks-agreed-session-4-part-5-named-not-drawn)): the stencil, the
  heraldry cut over it, the repair on top.
- **Era stats are data.** Efficiency against repairability per era, on the frame
  ([Devices & mods](prd/devices-and-mods.md#frames-by-era-agreed-session-4-part-5-not-built)), with the
  repair material per era: finite colonial parts, metal, and cord, ceramic and saltbush wood. The skimmer
  era is "the light cheap gear from before" (Hunter, 2026-10-17). Lineage drives the look; the frame's
  era drives the stats.

## The feral layer and spawns

**Feral hooks.** "No plant spawns randomly. Each comes from its habitat or a cache in an era-appropriate
site; finding plants is finding history." The feral package asks the index and the history:

| Habitat | Asked as |
|---|---|
| Along old pilgrim roads (saltbush's silver lines) | `paths_in` with second-age roads |
| Near old colonial water lines (wild root-tuber) | `paths_in` with what carries water, colonial |
| Cold hollows near first-age cisterns (dewleaf) | Cistern sites, and low ground from `TerrainShape` |
| Dried first-age wells (coalcane groves) | First Kingdoms water sites |
| Buried colonial corridors and habs (vat fungus, glowcap, office fern) | Colonial sites partly exposed |
| First-age sites (ancient sandroot) | First Kingdoms sites, as a sign |
| Sheltered rifts and caves (stormcup) | Han's rift, from the landmark footprint |
| The Sister vault, the black site's case | Landmark parts |

Plants are signs or props placed per chunk from these, by the feral package; never in the pass.

**Spawns by kit.** "Early game for everyone: find an artery and follow it." Each origin's kit names its
start (`Kit.start`) and `Starts` finds it in the history, pure in the seed and the start: the
**Surveyor** in deep desert, no path or settlement within 600 m, the nearest artery or spoke 1 to 3 km
off, and walking in toward Tu crosses one within 3 km **(default)**, so the bearing is the one thing
always in the sky; the **Salvager** within 300 m of a skimmer wreck field's hulls; the **Homesteader** on
a second-age road within 100 m of a wayshrine. Every start is on the near side, within 12° of the
equator, where the clear's widest swing stays inside the suit's limits **(default)**, 500 m clear of
the landmarks' footprints, and never on a site's ground. The prisoner's is the black site (not built).
A start is a point on the sphere; the world sets the moon position there before it lays any history
(`World.start`), and the sheet lays history round it. A world with no origin, the menu's, a probe's or
a save's from before origins, starts where the tuning says.

*Built 2026-10-18.* On twenty seeds every start found a place keeping its rule, in at most 45 ms
once a run on a quiet machine, after the pass. What history puts round each, on those twenty (spawns
probe 1 measures the rules on eight): the Surveyor's, always in Mon 4.6 to 11 km from Port Morgan or
Starcom, has nothing within 700 m but now and then the survey grid's beacon or relay mast, and the
line it walks in to is 1.5 to 2.9 km off toward Tu, a spoke: a colonial line of pylon stubs and relay masts
with the second age's wayshrines on it. The Salvager's is 40 to 240 m from a wreck's hull and its fuel
bladders, two times in five in Han within 10 km of Halloran or the black site, otherwise in Mon, and
between 80 m and 24 km from the nearest artery. The Homesteader's is on the artery or a spoke out of
Port Morgan, or on the Rim's ring and roads by Halfrise and the depot, a wayshrine 20 to 60 m off and
most often a watchtower, a house ruin or a pylon stub within a few hundred metres. Until the
structure kits build history's sites none of this stands on the ground: the map shows it.

### What the feral layer does now

*Built 2026-10-18, on the `feral` branch (`game/farming/feral.gd`).*

- **Where they grow.** A table of habitats, a row each, is the whole rule (`Feral.HABITATS`):

  | Crop | Grows | As built |
  |---|---|---|
  | Saltbush | Both sides of every pilgrim road | A bush every 3.2 m, 2.2 to 3.2 m off the line; 60 m stretches live 95% of the time on the Rim, 85% in Mon |
  | Saltbush | Every other road the second age used (its own roads, the ring, the artery, the spokes) | One side a stretch, a bush every 4 m, 90 m stretches live 55% of the time on the Rim, 30% in Mon, 8% in Han |
  | Saltbush | The Dark Age's plantings on the First Kingdoms' water lines (`saltbush_planting` signs) | A clump of 4 to 9 within 4 m |
  | Root-tuber | Near the colonial aqueducts (paths carrying water, colonial) | A patch of 3 to 6 every 160 m, 8 to 35 m off the line, by region |
  | Root-tuber | By colonial pump stations | 3 to 7 within 14 m |
  | Vat fungus | Colonial habs, pump stations and vent stations a kit stands on the ground | 3 to 8 within 5 m, only where a kit builds the site (`planned` false) and it's partly exposed or exposed (its `state()`, Exposure's, past buried) |

  Dewleaf (by cisterns), coalcane (by cisterns), sandroot (on First Kingdoms sites), glowcap and the
  office fern (in colonial habs a kit stands) have rows already; each places nothing until its crop is
  in the catalog. Stormcup waits on a way to ask for Han's rift by its landmark parts. Every slot is
  drawn from the seed by its path and running length, or its site, never by which chunk asks, as
  history's own rows are; a row's place in the table seeds its plants, so rows are appended.
- **How lines read.** The old bushes stand 0.95 to 1.4 of the bush's own size on pilgrim roads, a
  metre and more across: a double silver line, straight over the dunes, with the second age's roads a
  broken single line. Bushes keep clear of a ruin's ground. Away from roads, water
  lines and sites there's nothing: at the start of seed 1234, 12 km from the nearest second-age road,
  no chunk loaded holds a plant.
- **What you can do.** Near you (on ground with collision) each wild plant is a real crop of its row's
  catalog id, marked wild, standing in the sand: take on it as on a planted crop. Ripe, its harvest
  comes at the wild share (half, never none of a part) with its propagule, a cutting, tuber or spores,
  and a crop that regrows stays cut back to its share; not ripe, a crop grown from cuttings gives a
  cutting and is cut back to the ground, and anything else, or one cut to the ground, comes up whole.
  What you carry away is wild stock: it grows in your planter as clean stock does and gives the wild
  share; its seed stays wild (Farming).
- **The barometer.** Saltbush folds before a storm as it does in a planter: once a second, within 400
  m of you (Tuning `feral_fold_m`), each chunk's bushes read the storm field over the chunk now and two
  minutes on, close over half a minute, and open once it's clear. Folded, a line goes narrow and dull
  green, so it reads from as far as it can be seen. Farther lines hold their pose until you come near.
- **What it costs** (measured on a pilgrim road out of Sister, 289 chunks loaded, 38 with wild plants,
  736 plants, 192 of them standing as crops). No plant is a node of its own: a chunk's plants are drawn
  as one instanced mesh a look, the bush's near look (6,400 vertices) giving way to a plain one (2,000)
  past 80 m, and the ones you can stand among are a few frozen bodies a chunk, six plants each, that
  nothing moving touches (a layer only rays see). On the main thread, in Feral's own 0.3 ms a frame
  (Tuning `feral_budget_ms`): making a chunk's plants from the laid history, 0.09 ms on average and
  0.44 ms at most; drawing it, 0.02 ms, 0.39 at most; a stand of six, 0.33 ms at most. Walking 2 km,
  no frame of it took more than 0.46 ms. On the farm's tick only crops that aren't ripe grow, 0.11 ms a
  tick on average; once a second the fold reads the field twice a chunk within 400 m, 0.45 ms. The
  bush's looks, every stage at every step of the fold, are made once a run while the world loads,
  92 ms. On the GPU (an RTX 3070 at 1080p, someone playing meanwhile), looking down a double line
  running away from you cost 0.5 to 0.75 ms a frame, and the other views nothing measurable.
- **Saves.** Plants are derived. What you took or cut is remembered per chunk while it's loaded, by
  each plant's id, and is all a save keeps of the wild (`Snapshot`: `feral`); a forgotten chunk's
  plants grow back whole, as its finds lie there again.
- **Probes** (`probes/farming/`): 11 saltbush lines a pilgrim road, 547 bushes all within 3.2 m of
  its line and 85% of every ten metres lined both sides; 12 no wild plant away from its habitat, 1,405
  of them from the open desert at the start (none there) and 2 km on over the Rim; 13 a wild saltbush
  folds before a storm; 14 a wild cutting gives the wild share in a planter and stays wild, and a save
  keeps only what you cut; 15 wild plants are the seed's and the laid history's alone, and laid from
  another point they move no more than the road's line does (3.8 m, the seam 400 m off at 20°).

## Budgets

| | Budget | Measured (probe 6) |
|---|---|---|
| The history pass | 40 ms once per run | 32 ms (the best of three seeds) |
| Making one cell's sites | 1 ms on average | 0.37 ms where paths run, 0.02 ms over the whole moon |
| Laying one unit on the sheet | no part of it past the hitch line's room (1.5 ms), begun as the 0.5 ms streaming budget ends | 0.43 ms a unit in about 6 parts at the Rim; the slowest part 0.54 ms |
| A chunk's query | 50 µs | 10 µs at the Rim |
| Memory | under 8 MB for the history and the sheet | 3.6 MB with a Rim sheet laid |
| Per tick, for anything static | zero: no site, path or landmark has a process step | none: standing still for 300 ticks, the sheet never ran |

The pass, the cells and the index are `RefCounted`, with no node and no process step. Laying runs in the
terrain's streaming step, inside its budget, and only when the ground under you changes chunk.

## Determinism and saves

- **Derived:** the history (the seed), every site, path and landmark (the seed), a site's exposure (the
  seed, its place and the weather up to its chunk's build), its loot draw and its lineage (its loot seed).
- **The sheet is saved.** Laying depends on the way you walked, so the save keeps each laid unit's anchor,
  a few numbers a unit, and a resumed run lays the same units in the same places. Units laid after the
  resume are laid as usual.
- **What's taken and opened is saved,** as today's finds are: per site, by its id, which sockets were
  taken and whether it was opened (a door forced, a cache broken), kept while the site is laid and
  dropped with it, as `Salvage` keeps a loaded chunk's memory now. A landmark's record is kept whatever the
  distance.
- **Discoveries** go to the profile as now: the first of each kind of thing, and later the first sight of
  each landmark.

## The build plan

Five packages on top of the spine, each with the interface it plugs into and the files it owns, so
builders in parallel don't collide. Each ships with probes, each checked against a broken build.

1. **Structure kits.** Owns `game/history/site_kinds.gd` (adds the fields above to the registry),
   `game/salvage/kits/` (one file per era's pieces, `Ruin` as the pattern), the carve path in
   `TerrainShape.height_at` (switching from `ruins.covering` to `sites.covering`) and the chunk build's
   boxes for laid sites (`TerrainChunk`). Plugs into `sites.in_chunk`, `sites.covering`, `Paint`. Starts
   with the second age (wayshrine, watchtower, house ruin from history), then the other eras; switches
   the grid source off when the house ruin stands from history. Builds exposure (`Exposure.state`).
   Probes: every kind sits in the sand, walks through, never changes loaded ground.
2. **Loot.** Owns `game/salvage/finds.gd` and `salvage.gd`: site loot tables by era and kind into
   sockets, exposure gating sockets, drift (a catcher's stream), the migration of loose finds, the
   per-site memory of what's taken. Plugs into `sites.query`, the kinds' sockets, `Finds.exposure`.
3. **Lineage and era stats.** Owns `Eras.lineage` and the data on parts and devices (`Catalog`), the
   layered marks (`Paint`), era frames' stats. Plugs into the loot draw's seed. Never touches placement.
4. **Feral.** Owns `game/farming/feral.gd` (new): wild plants by habitat per chunk, as signs and props.
   Plugs into `sites.paths_in`, `sites.query`, `history.region_of`, the landmark parts.
5. **Spawns by kit.** Owns `World`'s start (the spawn search) and the kits' data: a start per kit from the
   history, with the moon position set there. Plugs into `History` (paths, sites, landmarks).

The landform package (Port Morgan's plateau, Halloran's rift, Starcom's peak, the far-side volcano) is
the terrain's, after these: it reads the landmark footprints. The endings' work reads the landmark
parts.

Shared files each package may touch, and nothing else outside its own: `Tuning` (its own group),
`docs/world-system.md` (its own section) and its PRD.

## What the spine does now

*Built 2026-10-17, on the `world` branch.*

- **The history pass** (`game/history/`): `History` runs the layers above on the sphere for every seed,
  from `Sphere` (the moon's geometry), `MoonCells` (its 28,650 cells of 500 m), `Eras` (the order,
  burial, loot identity, the Dark Age's lineage rule), `SiteKinds` (the registry, today's ruin as the
  house ruin) and `PathNetwork` (the graph and its splines). It makes the eight landmarks, about 530
  paths (some 900 km of them) and about 240 settlements per seed, and a cell's sites when asked.
- **What it looks like, by the numbers** (probe 3, three seeds, away from the landmarks' own ground):
  history's own sites about 1.1 a km² on the Rim, 0.45 in Mon and 0.05 to 0.3 in Han; path about 950 m a
  km² on the Rim, 370 in Mon, 60 to 180 in Han; towns 0.059 a km² on the Rim, 0.017 in Mon, 0.005 in
  Han; and 90% of the near side's cells reached by no path or settlement at all. Round Halfrise a
  walker sees a structure every few hundred metres along the roads and open desert between them.
- **The sheet and the index** (`game/world/sites.gd`, `site.gd`): `Sites` on `TerrainShape` lays cells and
  landmarks round you from the moon position's own point, in the terrain's streaming step, and answers
  every call in the table above. The terrain builds no chunk until the history that could touch it is
  laid. Today's ruins come through it from their grid, unmoved.
- **Navigation:** the dev overlay's world column names the region and how high Tu stands
  (`zone`) and the nearest landmark with its distance and compass point (`lmk`), at every chunk you
  cross; `history.nearest_landmark` is there for the compass. The radio's beacon picks its ruin through
  `sites.nearest`.
- **To see it in game** (dev console): `goto` alone lists the landmarks with how far each is and which
  way; `goto port_morgan` (or any landmark or part: `aitch`, `muster`, `bastion`, `sister`,
  `observatory`...) stands you a little in front of it on fresh ground, facing it. `map` toggles the
  history map, `map 4000` makes it 4 km across: what's laid is bright (paths in their latest era's colour,
  water lines blue, sites by era, hollow where only planned, the grid's ruins filled, landmarks and
  their parts named), the loaded ground and the laying's reach are outlined, and past what's laid the
  whole plan shows faint, so `map 60000` shows the artery, the spokes and the great sites.
- **The save** keeps the sheet's anchors (`Snapshot`: `sheet`).
- **Probes** (`probes/history/`): 1 the pass is the seed's alone; 2 every landmark where its rule puts it,
  on thirteen worlds, Tu's height checked through `DayCycle`; 3 the network's shape and its taper; 4 the
  index against a scan, cells laid before loaded ground, laid sites never moving, seams within 30 m at
  22° north, and a jump keeping loaded ground as it was; 5 today's ruins exactly where master put them;
  6 the budgets.

## Defaults

Every value this doc picked where the lore was silent. Change any of them here and in Tuning's History
group.

- The regions: Han under 20° from the sub-Tu point, Mon to 75°, the Rim 75° to 105°, the far side
  beyond.
- Richness: the Rim 1.0, Mon 0.5, Han 0.25, the far side 0.12; thinning from 50° of latitude to 30% at 80°.
- The axis: east or west of the sub-Tu point, within 25°.
- Halloran 3° to 5° from the sub-Tu point; the black site 1.0 to 1.6 km from it up the artery; Port Morgan
  38° to 48°; Halfrise 88.5° to 90°; Sister 1.6 to 2.6 km from Halfrise; the depot 0.7 to 1.2 km from
  Sister; Starcom 50° to 68°, 40° to 75° off the axis; the observatory exactly at the anti-Tu point.
- Landmark footprints: Port Morgan 1.6 km, the volcano 3 km, the rift 1.2 km, the rest 150 to 400 m.
- Five spokes besides the artery; Rim nodes every 15° of the Rim.
- A path's corridor: 60 m either side.
- Spacing along edges: pylon stubs 150 m, pipeline segments 120 m, relay masts 1.5 km, wayshrines
  700 m, watchtowers 2.5 km, caravanserais 2.2 km (a game day's walk), at full richness.
- The survey grid: every 6° of latitude and longitude on the near side, a relay tower at every second.
- Wreck fields: one cell in fifty holds one under Tu, one in five hundred far from it; two or three more at
  the end of skimmer tracks out of Halloran, 2 to 6 km out. A hermit in one empty cell in eighty.
- Settlements along the lines: frontier towns every 4 km, First Kingdoms towns every 2.5 km, Rim towns every
  2.5 km of the ring, each kept as often as richness says; a second-age village on a First Kingdoms town
  85% of the time on the Rim, 45% in Mon, 15% in Han.
- Moon cells 500 m; a unit laid within 1,300 m and lifted past 1,800 m.
- Burial: colonial 2 to 6 m, skimmer 0.2 to 1 m tilted 10° to 35°, First Kingdoms 0.8 to 2 m, second age 0
  to 0.6 m.
- Exposure's window: 12 hours of world time in 30-minute ticks.
- Spawns: the Surveyor 1 to 3 km from an artery or spoke (first set at 2 to 4, brought in to a fair walk
  on 2026-10-18), crossed walking in toward Tu within 3 km, no path or settlement within 600 m; the
  Salvager within 300 m of a wreck field; the Homesteader on a road within 100 m of a wayshrine; every
  start within 12° of the equator and 500 m clear of a landmark's footprint.
- The Okafor bunker under the Bastion.

## Open

- **Seams at high latitude.** Near the poles cells are small and dead reckoning is unsteady. History is
  thin there by richness, but the Rim's ring route runs over both poles, and its seams would show
  there.
- **A landmark's changes across runs.** Within a run, kept whatever the distance; across runs, not said.
- **Landforms.** The plateau, the rift, Starcom's peak and the volcano wait on the terrain; until then a
  landmark stands on the ground as it is.
- **A jump in place.** A scenario that moves the moon point without moving you (the far side's) keeps the
  old place's history under the ground you stand on, and lays none of the new place's over it until you
  walk off that ground, about a kilometre. The console's goto lands on fresh ground for this reason.
- **How dense history should be.** Away from the great sites the Rim has about one structure a km²
  besides the grid's ruins, Mon half that: open desert with structures strung along the roads. The rows
  and settlements tables set it, and the kit package will tune it in play.
- **The Rim's far stretch.** The second-age empire is "centred on the stretch of Rim closest to Port
  Morgan." How built up the Rim is on the far side of the sub-Tu point is the richness default.
