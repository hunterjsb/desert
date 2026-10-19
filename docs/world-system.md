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
2. **Loaded ground never changes, but where a storm works a site.** A cell is laid before any chunk it
   touches is built, and lifted only after every chunk it touches is forgotten, so nothing laid moves
   under loaded ground. A site's exposure is the weather's at every moment; on loaded ground it follows
   that a frame at a time, its ground pressed afresh from the chunk's own dunes in steps too fine to see,
   mesh and collision together, and never over you or your camp. A chunk that unloads is the desert
   eating what it held: come back and it's as the weather has it then.
3. **Nothing physical is outside collision.** A site's boxes are a body of the chunk its middle stands
   on, moved as it rises or sinks, so they come and go with that chunk's sand.
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

1. **Colonial.** The fixed landmarks first ([Landmarks](#landmarks)), then the ground they stand on
   ([Geology](#geology)), then the colonial skeleton between them: the main artery, the spokes from Port Morgan to the ring, the ring routes, the observatory's
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
- `History.geology`: the rift, its vents and the volcano's capped summit ([Geology](#geology)).
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
| **Port Morgan** | On the axis, 38° to 48° from the sub-Tu point (16–20 km from it, 17–22 km in from the Rim): Tu 42° to 52° up | "Partway in on its plateau. Tu high but off to one side." The colonial hub every spoke leaves | The Pads, the Bastion (the freighter and the Ledger), Crakeside, Lowtown, the Haberjack bunker under the Bastion **(default: which enclave is open)** |
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

## Geology

*Built 2026-10-18, on the `plumes` branch, from Hunter's brief ([geology and
plumes](geology-and-plumes-2026-10-18.md)): "Give Zan's plumes a convincing geological source and a
consistent relationship to wind, the atmosphere, and the moon's history. Start with one compelling
plume, not a sprawling simulation." The plumes' look was settled in a third round, when the smoke didn't
sit right with him: "its mostly emitting gas at this point so its just massive sand plumes that are epic
from a distance but really just blend into the storm and or the haze when up close cuz theyres so big"
([Wind & storms](prd/wind-and-storms.md#plumes)).*

The ground the landmarks stand on, made once a run (`Geology`, on `History`) after the landmarks and
before the colonial layer, which reads it. It holds only what something reads.

- **Where the heat is.** The lore's twin fires: tidal heating peaks at the two bulges, so volcanism
  clusters at the point under Tu and the point opposite ([the moon](the-moon.md#where-the-heat-concentrates-agreed-session-4-part-5)).
  The landmarks already stand on both, so the two provinces are where they are, not drawn: Han's rift
  round Halloran, and the far side's volcano under the observatory. No heat field is kept; nothing
  reads one yet.
- **The rift.** One line, its floor's middle: the great circle through Aitch along Halloran's heading
  (the heading history already drew for the rift), running 8 to 11 km either way **(default)**, held as
  points no more than 250 m apart. Its floor is 600 m across (Aitch's) and its walls climb to 1.6 km
  from its middle **(default)**, so the black site, 1.0 to 1.6 km out from the refinery, is in its far
  wall and the refinery on its near terraces. The rift is constrained by the landmarks, not drawn
  against them: nothing in the landmark table moves. It has no landform yet ([Open](#open)).
- **The vents.** Each is `{id, name, state, p, bearing, along, seed}`, `bearing` the rift's there and
  `along` its metres from Aitch:
  - two **tapped** vents, one each way 1.5 to 3 km along the floor **(default, the vent stations' old
    rule)**: the vents live when the colony came, which its vent stations tapped and Han's lines piped
    to the refinery. Quiet since the fall.
  - two **live** vents, one each way 5 to 7.5 km along **(default)**, at least 2 km past the farther
    pipe and still in Han, under Tu nearly overhead: where the rift's two ends are still opening. Part
    2's fall: "The vents didn't die, they moved, and nobody had the rigs to follow the heat." The heat
    moved on along the rift as it propagated, and this is where it still comes up. (The second was added
    in round two, 2026-10-18, so a run sees bursts more often.)
  - the volcano's **capped** summit vent, the observatory's vent cap: Tilg's anchor seals it. No plume.
  - the volcano's live **flank** vent, 1.2 to 2.4 km from its summit **(default)**: capped at the top, its
    heat came out on its side. The far side's own plume.
- **Gas pockets.** Round the rift, gas trapped under the old flows breaks out now and then:
  `geology.pockets(t0, t1)` gives those whose plumes show in a span, each a point 1.5 to 13 km from the
  point under Tu, a start, a size and how long it blows. One slot of 500 s in two holds one; it blows 20
  to 50 s at 1.7 to 6.7 times the rift's seep and fades by e every 12 s, a dust column a kilometre or
  two high **(defaults)**. Harmless, as everything is: a spectacle and a boom.
- **What a vent is doing** is a pure function of the time, as the weather is:
  `geology.venting(vent, t)` gives how hard, as a share of its seep, and the share of ash in what it
  carries. What comes out is mostly gas, which lifts the sand and dust round the mouth; that's what
  shows. A live vent breathes by a fifth over periods of 170 and 410 s, and bursts: a blast of gas
  clearing its throat that swells its column of dust. Each slot of 1,200 s (a game day) holds one 70% of
  the time, rising over 10 s, holding 90 s and fading by e every 220 s, at 25 to 170 times the seep
  (whose own lift is the steady column's, 1.5 to 3 km), a column standing 6 to 10 km in a breeze; ash is
  a fifth of what it carries seeping and 85% at a burst's peak, a faint trace in the dust **(defaults)**. `next_burst(vent, t)` says when the next begins and `last_burst(vent,
  t)` when the last did, and how big. A pocket's venting is its blowout's. Quiet and capped vents give
  nothing. Nothing in the world reads the plumes: what they show is `venting`'s.
- **Magnetized crust.** `geology.magnetized(p)`, 0 to 1: lava that cooled in the old field stays
  magnetized, so the rift's dykes (across its walls, fading 2 km past its ends) and the volcano's flows
  (its 3 km footprint, gone by 6 km) read 1 and ordinary ground 0 **(default)**. A few products a call:
  what the compass will read its local deviation from.
- **Its mouth on the ground.** A live vent's mouth is a kit piece of the ground's own era
  (`Eras.GEOLOGY`, `GeologyKit`, built as `VentMouth`): a fissure along the rift, its 12 m pit 1.2 m
  under the dunes' mean, a spatter rampart round it 2.4 m high, sulphur crusting its throat, and an
  apron of its own ash out to 56 m that the dunes rise or fall from no steeper than 18°, banking at the
  sand's own slope over its last 14 m **(defaults)**. It stands where geology put it, sliding up to
  24 m along the rift to where its apron holds the dunes best, so it stands on every seed (24 of 24
  tried, a third of them slid); nothing round it is steeper than its 24° throat. It's the same in every exposure state (a live vent keeps itself clear),
  laid by the sheet like any site (a cell part of its own), and never gives way to a structure: the
  ground's own comes first. Its ash fan on the sand is the sand's look
  ([Wind & storms](prd/wind-and-storms.md#plumes)).
- **Determinism.** Geology draws only from its own streams (the seed, "geology", what it's for), and
  runs after the landmarks, which never read it. The colonial layer's vent stations now stand on its
  tapped vents and their pipelines run to them, in the same order and number as before, so nothing else
  in history moves: on seeds 1234, 7 and 42, of 13,015 lines of landmarks, paths, settlements and path
  cells' sites, the 113 that changed are Han's lines (the two vent stations, their pipelines, the pylon
  stubs and pipe along them, a skimmer camp scarring a station and a First Kingdoms town on a pipeline).
  Every landmark is where it was.

### The brief's questions, answered

1. **A geology layer now?** Yes, a small one, because something reads it at once: the colonial
   layer's vent stations stand on its tapped vents, the plume and the vent's mouth on its live one, and
   the compass on its magnetized crust. It's the rift, its vents and the capped summit; no heat field,
   no impact basin, nothing else until something needs it.
2. **What does the plume emit?** Mostly gas, which doesn't show (carbon dioxide, sulphur gases and
   water vapour are the science brief's guesses, not fixed), sweeping up and lifting the sand and dust
   round the mouth, which does: a vast column of the storms' own dust, with a faint trace of ash at a
   burst's core. Round two's ash, steam and sulphate haze were dropped in round three, when the smoke
   read wrong.
3. **Seeping, intermittent or bursting?** It seeps all the time, breathing, and bursts now and then.
   The tapped vents are quiet and the summit capped. Round two made the bursts tower (columns of 6 to
   10 km, booming) and added the rift's second live vent, the volcano's flank vent and gas pockets;
   round three made the seep's own column 1.5 to 3 km and the bursts a little more often.
4. **Is the observatory volcano part of a province?** Yes: the far side's, one of the two tidal-heating
   provinces, its summit vent capped by the elevator's anchor. The colonial vent stations are the other
   province's, Han's, on the rift. Both are the same heat, from the same tides.
5. **The rift and the province: independent, constrained, or derived?** Constrained by the landmarks.
   The provinces are the bulges, which the landmarks already mark; the rift is the line Halloran's
   heading already drew, through Aitch, with the black site in its wall; only its length and the vents
   along it are geology's own draws.
6. **The smallest rendering?** The storm walls' own: a dust volume marched round a line of points
   computed on the main thread, up to three plumes in one compute pass at half the screen's size and
   brought up by depth, with the walls' billows, light and haze, and near you the haze and grit you stand in rather than anything drawn; the
   sand's look for the old ash; no particle simulation ([Wind & storms](prd/wind-and-storms.md#plumes)).
7. **Visual only, or more?** Visual and atmospheric, with history's vent stations moved onto the
   vents, the magnetized crust for the compass, and booms and a roar ([Radio, sound &
   atmosphere](prd/radio-sound-and-atmosphere.md#distant-phenomena-agreed-2026-10-18-spec)). No hazard
   and no visibility cut.
8. **Which physical assumptions now?** Settled now: the plume's rise and bend follow Briggs's
   buoyant-plume laws in the field's wind and an air stability that's steadier by night; gravity enters
   both the buoyancy and the stability, so how high a plume levels doesn't change with it, only how
   hard it climbs at first; the sand it lifts falls out over minutes, the fines staying up. Qualitative:
   the gases' mixture, the vent's real heat output (its buoyancy is a look value, `plume_buoyancy`), and
   the outgassing's share of the air, which a single vent doesn't sustain: the air still leaks.
9. **Which tests?** Geology's purity and shape on twelve worlds (geology 1), venting and pockets as the
   time's alone (geology 2), the plume following the field's drift, bending in its wind, hidden by
   storms and towering over them (wind & storms 15), its life through a run (16), a burst heard after
   it's seen (17), and a run seeing a plume from far now and then (18). The kits' probes take the mouth
   like any piece.
10. **Left out:** the rift's and the volcano's landforms; dormant scars at the tapped vents (the vent
   stations' kit will stand on them); deposits that grow with bursts; hazards and readings.

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

*Done 2026-10-18: the house ruin stands from history and the grid source is gone ([What the structure
kits do now](#what-the-structure-kits-do-now)).*

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
| Colonial | Pylon stubs, pipeline segments, hab pods, relay masts | Deepest: 2 to 6 m of sand over the roof; rarely exposed | Infrastructure: power, chassis, big systems |
| Skimmer era | Wreck hulls, fuel bladders, dugouts | Shallow, 0.2 to 1 m, tilted 10° to 35°; exposed and reburied fast | Best single-item gear: from deserters and the black site |
| First Kingdoms | Pipe-wall huts, cisterns, low stone walls | Deep, 0.8 to 2 m: low foundations, barely visible | Intact working colonial tech used in new ways |
| Dark Age | No sites | None | No loot of its own: the lineage of second-age gear |
| Second age | Wayshrines, watchtowers, house ruins | Shallowest, 0 to 0.6 m: most often exposed; towers stand out of the dunes | Worn reused gear; water, seeds and salt |

The burial table orders the skimmer era above the First Kingdoms, as part 4 does for structures; the
loot strata of the vision ("history runs backwards in the ground") still hold for what lies loose, since
a standing wreck sits higher than a low foundation ([Salvage & ruins](prd/salvage-and-ruins.md#readings-not-in-the-session)).

## Exposure

A site is **buried, partly exposed or exposed**, and between, decided purely from the weather at its
place up to that moment (`Exposure`), so its state at any moment is known without anyone having
watched it: a save, sleep, a far stand-in and the loaded site all agree.

- **The settled sand** is the weather's work at the site over a long window: the same reading as finds
  (how deep into a storm, how far past the prevailing wind's strongest), summed over the last 12 hours of
  world time in 30-minute ticks **(default)**, so one big storm strips a lot and calm lets the sand return.
- **The storm's own work** (the 2026-10-18 spec, [Wind & storms](prd/wind-and-storms.md#storms-with-a-payoff-agreed-2026-10-18-spec)):
  while a storm works on a site its big dunes move, a minute at a time, laying it bare where they're
  moving off it and burying it again where they're moving on, and what they moved comes back within
  minutes once the storm lets go. A ruin seen mid-storm may be gone by morning.
- **The state** compares the two together with the site's depth: under a third of its depth stripped,
  buried; under its whole depth, partly exposed; past it, exposed. A **level** runs between them, 0 buried
  through 1 (the partly exposed look) to 2 dug out, so a site comes out of the sand smoothly.
- **Reburial** is the same function: as calm hours replace stormy ones the sand comes back. Relaxed, not
  a hard timer.
- **Deeper layers mid-storm and on a revisit.** A site's sockets have depths too. A storm that strips
  further reaches sockets lower in the same site, mid-storm most of all; what was taken stays taken
  ([Saves](#determinism-and-saves)).
- **Read between ticks.** Both parts are read between their fixed ticks, a tick behind, so the sand on a
  site never jumps and it's only ever the weather that has been.
- **Loaded, it follows the weather** a frame at a time (the law, rule 2) and never comes back over you or
  your camp. **The desert ate it:** once its ground unloads nothing holds it; come back and it's as the
  weather has it then.

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
- **Mid-storm** (the 2026-10-18 spec). A site a storm lays bare offers its deeper tier, its era's best,
  while it's open, for the active player who goes out into the dust; a glint through the dust and a clang
  on the wind say where, and later the Console's sensors. Once the sand comes back it's gone again. Its
  lesser things blow downwind meanwhile, into the drift a camp's lines catch, so a stationary camp
  downwind still gets some.
- **Today's loose finds.** The migration, in order: (1) finds on a ruin's floor become the house ruin's
  socket loot, unchanged in what they are; (2) the kit package's kinds get their own tables; (3) loose finds
  on open sand fall to a tenth of today's 1.5 a chunk, kept only along paths and in settlements' scatter,
  and drift takes over the gap; (4) the survival kits a first hour lives on move to the sites a start is
  near ([Spawns](#the-feral-layer-and-spawns)). Each step keeps Salvage's probes passing, rewritten to the
  new placement where they asked for loose finds.

*Built 2026-10-18: [What loot does now](#what-loot-does-now).*

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

*Built 2026-10-18: [What lineage does now](#what-lineage-does-now), with the loot package's interface.*

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
**Surveyor** in deep desert, no path or settlement within 600 m, the nearest artery or spoke 0.6 to 3 km
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

*In sight, 2026-10-18 (`sightlines`).* Every start also has something to walk to in sight from where its
run's ground begins (`Starts.in_sight`): a structure history put there that stands where the sheet
would lay it, its top clear over the ground as drawn by 3 px at 1080 rows however deep the sand lies on
it; the Salvager's a hull of its field, the Homesteader's its wayshrine, the Surveyor's one drawn past the
built ground, 600 to 1000 m off. A start knows where its ground begins before there's a world (`Starts.ground`,
on the dunes alone, as `World.flat_near` finds it): the usual flat patch, and for the Surveyor the
nearest bare flats, where the horizon is far; its search sets it out behind a relay mast of its line so
the mast stands on a spot of that ground it shows from, along a way the mast's glints shine back at you
some time on the run's first day (looked for first in its first nine minutes): drawn true to its size,
a mast that far off is a sharp eye's find, and its glint is what catches the eye. What's in sight is
drawn by the skyline ([Salvage & ruins](prd/salvage-and-ruins.md#whats-built-2026-10-18-the-sightlines-branch)).

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
| A storm working loaded sites | only the sites on loaded ground near you each frame, the rest a few chunks a frame, never all sites | 6 µs a frame for each site moving near you ([What storms do to sites now](#what-storms-do-to-sites-now)) |
| A big dune's ruin you pass | nothing at a chunk's load, a seed only; looked at on a worker only once you've slowed, built only once bared | 0.03 ms a frame riding past at 20 m/s, nothing found or built (kits probe 8) |

The pass, the cells and the index are `RefCounted`, with no node and no process step. Laying runs in the
terrain's streaming step, inside its budget, and only when the ground under you changes chunk.

## Determinism and saves

- **Derived:** the history (the seed), every site, path and landmark (the seed), a site's exposure (the
  seed, its place and the weather up to the moment), its loot draw and its lineage (its loot seed).
- **The sheet is saved.** Laying depends on the way you walked, so the save keeps each laid unit's anchor,
  a few numbers a unit, and a resumed run lays the same units in the same places. Units laid after the
  resume are laid as usual.
- **What's taken and opened is saved,** as today's finds are: per site, by its id, which sockets were
  taken and whether it was opened (a door forced, a cache broken), kept while the site is laid and
  dropped with it, as `Salvage` keeps a loaded chunk's memory now. A landmark's record is kept whatever the
  distance.
- **The sand held off a site over you or your camp is saved** (2026-10-18): a site's exposure is the
  weather's, but where a storm let go while something of yours stood on it, the sand it held off is
  kept by the site's id, so a resume never buries you.
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

## What the structure kits do now

*Built 2026-10-18, on the `kits` branch: package 1.*

- **The framework** (`game/salvage/kits/`). `StructureKit` holds every kit piece as data, from one file
  per era (`colonial.gd`, `skimmer.gd`, `first_kingdoms.gd`, `second_age.gd`): its footprint, its rooms
  (where the sand lies just under a floor once dug out, with a drift ramp down into a pit), its openings
  (where the drift falls away level), its boxes in plan metres with the coat each takes, its sockets,
  how far each exposure state sinks it and fills its rooms, its survey, how much of its site's lean it
  takes, a tour through its openings, and its look in Paint's worn pieces. A `Structure` is a `Site`
  built from a piece; `Ruin` is the house ruin's, its old names kept. `SiteKinds` answers a kind's reach
  from its piece. The doc's `Kit` was already the survival kit's name, so the framework is
  `StructureKit` and its socket `SiteSocket` (`Socket` is the devices').
- **Sockets**, the loot package's interface: each is a plan point on what it rests on, a kind (`floor`,
  `shelf`, `cache`, `bed`) and how much deeper than the rest of the site it lies, as a share of its
  burial a storm must strip past it. `Structure.socket_at(i)` gives its place; `reached(i)` whether it
  can be reached now: clear of the sand, no higher than a hand reaches from it, and stripped deep enough.
  `dug(p)` and `rest(p)` say whether a floor spot is dug out and where something set there rests.
- **Where a structure stands.** History's site is surveyed as the sheet lays it, on a worker (a unit's
  structures as one task, ahead of chunk builds; the unit is laid once they're surveyed, and the terrain
  builds nothing they could touch until then): the dunes over its ground on a grid of up to 4 m, rising
  no more than its survey's rise and nowhere steeper than its slope. Where they won't take it, it looks
  along its line, up to 10 to 24 m either way (across the way it faces, or along it for what runs with a
  line: pylons, pipe, wrecks), as a road's builders would; on the lattice by whole metres. Where none
  does, the dunes took it and it's a plan on the map. Two structures' grounds never overlap: the smaller
  gives way, whether or not the bigger stands, so which stands is the seed's alone; it's decided when
  its ground is first built, when everything that could overlap it is laid. Measured round thirty
  settlements and the roads through them on three seeds: 55% of house ruins stand, 60 to 70% of
  wayshrines and watchtowers, half the dugouts, about 40% of pipe-wall huts, low walls, pylon stubs and
  relay masts, 30% of hab pods, cisterns and fuel bladders, 23% of pipeline segments. What the dunes take
  is what lies under the dune seas, which is where it would be.
- **Exposure** (`Exposure`, Tuning's History group). The settled sand taken off a site is the weather's
  work over the last 12 hours in 30-minute ticks, read as finds read it (`Exposure.reading`, which
  `Finds.exposure` now shares): each tick a storm's heart strips 0.5 m and the wind lays 0.2 m back, and
  the older a tick the more has drifted back since, so one big storm strips a lot and calm lets the sand
  return, never a hard timer **(defaults)**. Against its depth: under a third stripped, buried; under all
  of it, partly exposed; past it, exposed. Measured over 600 places and moments with the wind: the second
  age is exposed 80% of the time and buried 11%; the skimmer era exposed 66%; the First Kingdoms mostly
  partly exposed (52%, buried 26%); colonial sites buried 73% and partly exposed 26%, and dug out only in
  the hardest storms at their shallowest. *Since 2026-10-18 a storm's own work adds to it, and a loaded
  site follows both ([What storms do to sites now](#what-storms-do-to-sites-now)).*
- **How the states read.** A state sinks the piece into the sand and fills its rooms to the sand line;
  dug out, its rooms go down to their floors. Buried, only a top shows: a hab pod's roof and hatch, a
  watchtower's platform level with the sand (walk onto it through the parapet's gap and its weapons
  cache is in reach), a pylon's crossarm, a relay mast's upper half, a wreck's fin, the coping of a
  cistern, the top course of a low wall, a hump of sand over a pipeline, the jar on a house's corner and
  its wall tops. Partly exposed shows the tops of the walls, doors dark slots under their lintels.
  Exposed is dug out: sand drifted up the walls, level at the openings, floors swept. What a state leaves
  out of a piece's boxes lies wholly under the sand, so the carve and the boxes always agree.
- **Loaded ground never changed** (until 2026-10-18). A structure's exposure was read when the first
  chunk touching its ground was launched and held while any chunk touching it was loaded, so a site
  changed only while you were away. *It now follows the weather while loaded ([What storms do to sites
  now](#what-storms-do-to-sites-now)); `sites.hold` and `sites.release` still say which chunks hold it.*
- **History-driven.** Every piece stands where history's rows and settlements put it: pylon stubs every
  150 m on a power line, pipe every 120 m on a pipeline, wayshrines every 700 m on second-age roads,
  watchtowers and house ruins along them, relay masts on colonial roads and the survey grid, pipe-wall
  huts and low walls on the First Kingdoms' lines, skimmer camps and wreck fields, villages and Rim towns
  of house ruins. The grid source is gone (`RuinSites` deleted): a house ruin stands only where history
  put one. The chunk build's boxes and the carve read `sites.in_chunk` and `sites.covering`.
- **The old grid's users, moved.** The radio's beacon picks a house ruin history put there, the first
  standing in its chunk (`sites.ruin_in`, which the chunk's finds are laid out in too), through
  `sites.nearest`, whose test now takes the site. The hall's device is a later visitor's: it lies on
  whatever sand is in the hall, so the beacon's choice stays the seed's alone; the floor's other finds
  are laid only where the floor is dug out, and loose finds keep off every structure's ground
  (`Finds.plan`'s `on_site`). The `ruin` scenario finds history's house ruin nearest the run's start
  however far round the moon, and stands you on fresh ground before its door at a moment it's dug out.
  The `radio` scenario, there to follow a beacon, stands you on fresh ground beside the nearest town
  where one is heard. Probes and look-tests that need ruins start the run beside a town where they
  stand (`StructureKit.starts_among`); a run's own start is deep desert.
- **The sheet, two fixes.** A unit waiting in the queue now takes the distance it's at as you walk
  toward it, not the one it was offered at, while keeping the anchor it was offered from; and
  everything that ground about to be built, or kept a chunk past the view, could touch is laid at once.
  Before, both were covered only while laying kept ahead, which structures' surveys no longer let it.
- **Laid by hand** (`sites.by_hand`, `sites.add`): a structure of any kind at a world place, for probes
  and look-tests; laying it over loaded ground builds that ground again, a dev action like a jump, and
  it's never saved.
- **Cost.** Building every piece's looks while the world loads, 270 ms (a house's colours are recoloured
  copies, a leaning piece one look for every state). A structure's survey takes at most 0.5 ms on a
  worker (the house ruin; the rest under 0.25 ms); laying a town's sheet all at once, 11 ms; laying a
  unit on the main thread, 0.48 ms in about 7 parts, the slowest 0.6 (the spine's 0.43). On the chunk
  workers, a near chunk with structures costs 3% more to build than one without, 6% the first time over
  a structure, which then keeps its carve for each lattice point in its state; a mid chunk the same.
  Holding a chunk's structures as it's launched, 6 µs on the main thread. The ground's one function on a
  structure's ground, 12.9 µs against 12.0 on open sand. Static things cost nothing per tick: no
  structure has a process step; its look and its boxes are part of its chunk.
- **Probes** (`probes/kits/`): 1 every kind sits in the sand in every state; 2 you can walk through every
  kind's doors and openings, up a pit's drift as slowly as up any slope (it replaces salvage's probe 4,
  which walked only the ruin); 3 a loaded site follows the storm, smoothly, and never buries you; 4
  exposure is pure, and a storm works a site; 5 the grid is gone and the beacon still finds a site (it
  replaces the spine's probe 5, which held the grid's ruins in place). Each fails on a deliberately
  broken build: rooms dug out in every state; doorways half a metre wide; no hold over you, no ground
  pressed afresh, or a look that doesn't follow; the storm's sand never coming back, or read only on
  its ticks; the beacon only in the grid's ruins.
- **To see them** (unseen, on a GPU): `look/kits/shoot.sh <dir>` stands every piece by era in each
  state on fresh ground, shoots each and the artery out of Halfrise with its sites, and builds
  `~/Desktop/structures.png`.
- **Hand-offs.** World's start searches for flat ground with `sites.covering` before the sheet is first
  laid, so it can't see history's structures yet: the spawns package's to order. The performance pass's
  `held_height_at` and `highest_in` on master ask `ruins.covering` and `RuinSites.MARGIN`: on this branch
  they become `sites.covering` and `sites.narrowest()`, the narrowest any structure's ground is.
- **Wrecks** (2026-10-18, the `wrecks` branch): five kit pieces with a scrapping plan, in one file of
  their own (`WreckKit`): the skimmer hull (the wreck fields' hull, now at half its site's lean), the
  tithe hauler (wreck fields and the black site's checkpoints), the freight pod (by frontier towns,
  1 to 3 m deep, a kind's own burial over its era's: `SiteKinds.burial`), the lifeboat (a row off the
  roads into Port Morgan, within 16 km of it: a row may say how `near` a landmark it lies) and the
  Knights' hopper (a row along the artery, and by crusader bunkers). New kinds are appended to their
  settlements' members and to the rows, so every older site keeps its stream. Their plates, packed
  holds, held modules and hazards are [Salvage & ruins'](prd/salvage-and-ruins.md#wrecks-and-scrapping-hunter-2026-10-18-built).
- **Planned only, still:** survey beacons, pump stations, farm domes, vent stations, checkpoints,
  generator shrines, caravanserais, stepwells, ration gates, granaries, earthworks, bunkers and the signs:
  history's plan, for the map and the packages to come.

## What lineage does now

*Built 2026-10-18, on the `lineage` branch: package 3.*

- **A lineage is a short list on the thing** (its `lineage`, saved with it), each entry [era, what was
  done, how], from its making on:
  - [colonial, made, who]: who made it, as its stamp says (`Catalog.MAKERS`): Tilg on chassis pieces
    and frames, the contractor RMC on the condenser, the Console and the fitted shield, the shield's
    maker on the light shield, the wind maker on the turbine; commodity parts name none.
  - [First Kingdoms, marked, house]: a Port Morgan house kept it and marked it: Haberjack, Pellicott, Crake
    or Vonatelli.
  - [Dark Age, remade, work]: what held it together, one of five sets of cord, ceramic, a saltbush-wood
    splint and a plate off something else **(default)**.
  - [second age, blessed, gifts]: one of four sets of the sign of Tu, a charm, a tassel and a water vial,
    or the Cistern's blue glaze with a charm **(default)**.
- **The rule** (`Eras.lineage(era, kind, seed)`, the seed's alone). A colonial or skimmer-era find is only
  made: the skimmer era's imports are the one thing made after the colony. A First Kingdoms find is
  colonial, marked by a house. A second-age find is colonial, remade in the Dark Age, keeping a house's
  marks under the repair half the time (part 5's "a colonial or first-age item", so the contract's three
  entries are two to four), and blessed after 40% of the time, 90% at a wayshrine and 60% at a stepwell,
  where half are the Cistern's; elsewhere 5% of blessings are hers **(defaults)**. A Dark Age cache's find
  is remade and never yet blessed. Over 6,000 draws at every second-age kind of site, every one was an
  older thing remade in the Dark Age, 49% kept a house's marks and 35% were blessed (probe 2).
- **Its era** is its last hands': a Dark Age remake is second-age gear. That era sets its numbers, and its
  first hands' set the row its own stamp is from. A thing with no lineage is what it was before: the
  company's issue when it was never found (the run's kit: colonial numbers, the "new" row, LOT 3127 on
  its chassis), and its layer's look when a save from before lineage found it.

### The interface for loot

`Catalog.found_in(body, era, kind, seed) -> Array` draws a find's lineage, gives it to the body and
returns it.
- `body`: the find as `Catalog.part`, `Catalog.device`, `Catalog.stake` or `Finds.bare` make it, before
  it's in the world (a shield reads its draw as it starts), and after `Finds.mark` if it keeps a layer:
  the lineage's look wins over the layer's.
- `era`, `kind`: its site's (`site.era`, `site.kind`); a Dark Age sign passes `Eras.DARK`, and `kind` may be
  `&""`.
- `seed`: the thing's own draw from the site's loot seed (its socket, its index), so each thing in a site
  has its own lineage. The same seed gives the same lineage, numbers and look, so a find made again as its
  chunk loads needs nothing saved.
- Each part fitted in a found device, or stuck on a found chassis, takes its own call and seed: a chassis's
  battery can be another era's than the chassis. Nothing anywhere asks what era a thing is: anything sticks
  on any era's chassis, and pieces of any eras join.
- A crop, food or salt takes none, and it returns an empty list.
- What's taken keeps its lineage through the save (`Snapshot`: a thing's `lineage`).
- `Eras.lineage(era, kind, seed)` is the draw alone; `Catalog.inherit(body, lineage)` gives a known one.

### Era stats

Part 5's one axis, efficiency against repairability, as factors on what a thing already has numbers for
(`Eras.GEAR`), against colonial make. "Keeps" scales a battery's capacity, a panel's or a light panel's
watts, a turbine's and a tray's lift; "draws" a tray's watts a kilogram, a shield's draw in the clear and
in a storm, an instrument's or a Console's draw and a lamp's; "tough" how slowly the weather wears a
frame; the skimmer era's is lighter (Hunter: "light, cheap and fragile"). **(defaults, all but the
order)**

| Era | Keeps | Draws | Tough | Weight | Repaired with (not built) |
|---|---|---|---|---|---|
| Colonial, and the company's issue | 1.00 | 1.00 | 1.0 | 1.0 | finite colonial parts |
| First Kingdoms | 0.92 | 1.05 | 1.5 | 1.0 | metal |
| Skimmer era | 0.85 | 1.10 | 0.5 | 0.7 | scrap **(default: nothing says)** |
| Second age | 0.75 | 1.25 | 0.9 | 1.0 | cord, ceramic, saltbush wood |

So a battery holds 100, 92, 85 and 75 Wh by era, a big battery 300, 276, 255 and 225; a panel makes 60,
55, 51 and 45 W, a turbine 200, 184, 170 and 150; a tray floats 80, 74, 68 and 60 kg at 2.0, 2.1, 2.2
and 2.5 W a kilogram; the base shield holds a storm back on 200, 210, 220 and 250 W. A mixed deck's trays
draw by each one's share of the lift. Probe 3 checks each.

**Repair is needed and not built.** Nothing mends yet; each era's material is data
(`Eras.GEAR`'s `mends`). It wants: a repair act on a worn thing; the materials as catalog parts (colonial
spares, which only salvage gives and run out; metal; fern cord, the kiln's salt-glazed ceramic, saltbush
wood); what a mend gives back of a thing's soundness, by era; and whether a mend is a lineage entry of
your own, a new lashing or cap on its look.

### The marks

Readable without text, through the paint pass, stacked in lineage order (art direction, "Layered
marks"):
- **Its maker's stamp** is the look's own, from its first hands' row: the colonial row (TILG XN 0217,
  RMC), the new row for the company's issue.
- **A First Kingdoms house's** is an enamel band in the house's colour round the top edges of a frame,
  round a round housing or round a part's end, and an enamel plaque with the house's crest cut through to
  bright metal, riveted in brass: Haberjack's key, Pellicott's cauldron, Crake's arch, Vonatelli's tower; deep
  red, ochre, teal, and ochre with red for Vonatelli **(default)**.
- **The Dark Age's repair** is cord lashed round two corner posts or round a part's body or a round
  housing, a round ceramic cap on a square corner, a saltbush-wood splint lashed along an edge, and a
  plate off something else in its paint, riveted on crooked; on what was consigned, the code daubed back
  on it from memory, "ZN".
- **The second age's devotion** is the sign of Tu (half-risen, banded) daubed on a limewashed patch, a
  charm on cord, a dyed tassel at a corner, a sand-glass water vial tied on; Cistern-touched, a blue-glazed
  cap and a blue charm.

Where they go is worked out once a thing, from its own look (`Paint.Shell`): its box, or the round body in
it (`Catalog.ROUND`), its faces cast against with rays so a plaque sits on a device's recessed panel, not
in the air before it, and four spots clear of its sockets, its charge light, its mast and its stamps, a
part's face out of its socket first. Each entry's marks are drawn alone on those, so they cache by entry
and stack in any lineage; the lineage's look is its own merged with them (`Paint.merged`), one mesh and
one draw, cached while anything wears it. Too small to read (a stake, a hook, the ends of lines, a coil,
the dish, the screen, a compass: `Catalog.BARE`), a thing keeps its numbers and shows its era only in its
paint's age.

### Cost and probes

- **Cost**, on the main thread of a quiet machine: every thing's shell while the world loads, 20 ms for
  the 24 that take marks (the Console's slowest, 2.8 ms); the first time each of a thing's lineage entries
  is drawn, once a run, 0.3 ms (0.6 ms for nine in ten, 2.3 ms at most, the first of a size of piece:
  every piece is a prototype placed natively after); a lineage's look merged from entries already drawn,
  0.2 ms for a crate frame (since removed with the slots) and less for anything smaller. A marked look adds a few hundred triangles to a
  thing and no draw.
- **Probes** (`probes/lineage/`): 1 a lineage is its seed's alone, for every era and kind of site; 2 the
  Dark Age's rule, every second-age find an older thing remade; 3 era stats scale the numbers as the table
  says, a colonial battery holding the most and a second-age one the least; 4 a found device, its parts
  and a shield keep their lineages, numbers and looks across a save and resume, and things without one
  stay so; 5 every era's battery, tray, hook, panel and light shield go on every era's chassis and
  chassis pieces join across eras (both reworked off the crate with the chassis, 2026-10-18). Each fails on a deliberately broken build: a lineage drawn from no seed; a second age made,
  not remade; numbers left unscaled; a save that drops a thing's lineage; a fit refused across eras.
- **To see them** (unseen, on a GPU): `look/lineage/shoot.sh <dir>` stands a device and a battery in each era
  and lineage before the camp and builds `~/Desktop/lineage.png`. Not shot yet: the GPU needs a reboot.

### What's fragile

- **Seen only flat.** The marks were checked on a CPU render of their meshes, not on the GPU: no wear
  shader, light, dust or scale. The sheet above is the test.
- **A house's teal on the colonial teal.** Crake's band reads weakly on a teal chassis; its plaque does.
- **Hanging is a part's guess.** What hangs from a part hangs as if its socket faced sideways; on a top
  mount it stands out.
- **Marks follow the look.** They settle on a thing's look by ray; change a look in Dress and its marks
  move with it, and a look with nowhere flat enough takes fewer.
- **Saved numbers win.** A save keeps a part's numbers as they were, but a frame's are made again from its
  lineage, so changing `Eras.GEAR` changes a resumed frame and not a resumed battery.
- **Given before it starts.** A shield takes its draw when it enters the world: a lineage given after
  changes its stats but not its draw until it's made again.
- **The atlas grew a row.** Every reader of `marks.png` now reads four rows (the worn and ruin shaders);
  a new one must too.
- **The skimmer era** has no look of its own: its stamps' colonial row and a worn paint, and "scrap" for
  its repair is a default.

## What loot does now

*Built 2026-10-18, on the `loot` branch: package 2.*

- **Site loot** (`SiteLoot`, `game/salvage/site_loot.gd`). Every kit piece's sockets are filled from its
  era's table, a row for each kind of socket (floor, shelf, cache, bed) and a best that every socket lying
  deeper than the rest of its site holds; a kind may put its own row in place of its era's, which is how
  the kind says what fits. Each socket draws from its own stream of the site's loot seed, so a site holds
  the same things whoever comes, whenever, laid from wherever on the ground. What each era's sites hold:
  - **Colonial,** infrastructure: chassis pieces and frames, a condenser or turbine, big batteries,
    trays, panels and strong cable on its floors; batteries, lamps, plugs and instruments on its shelves;
    clean root-tuber and vat fungus in its beds; at its best Consoles, shield generators, turbines,
    condensers, big batteries, trays and panels, radar, screens and harvesters. A hab pod's shelf holds
    vat fungus and rations, a relay mast's cabinet its instruments and power, a pipeline's hatch hose,
    water and a condenser. A little over half its sockets still hold something, sound and charged.
  - **Skimmer era,** the single items: survival kits, radios, now and then a hoverboard, batteries and
    rations on its floors; at its best military shield generators, hoverboards, radar, harvesters and the
    wind and particle instruments. A wreck still holds nine things in ten it carried, a dugout eight;
    found light and fragile, half to nine tenths sound. A wreck hull's best is its own (2026-10-18):
    the land yacht's helm seat and keel, 3 in 13 each, with shields, boards, radar, a harvester and a
    big battery ([Movement](prd/movement.md#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built)).
  - **First Kingdoms,** working colonial machines kept running: condensers, turbines, frames, planters
    and chassis pieces, three sockets in four filled, instruments on the shelves, water kept sealed; a cistern's
    floor water and hose, its bed and a field plot's seed and saltbush. Near sound.
  - **Second age,** worn reused gear, water, seeds and salt: a house ruin's floor holds what its floor
    always did (parts, devices, seeds, rations and survival kits), its hall a later visitor's device with
    parts to strip on whatever sand is there; shelves hold water, salt, seeds and cord; a wayshrine's
    basin and niche its offerings (water vials, salt, a few seeds) and its plinth a pilgrim's survival
    kit; a watchtower's platform the late wars' cache (shield generators, radios, survival kits, cord). Its
    best is the deep layer's of old. Worn, water kept sealed.
  - **The region** says how generous **(defaults)**: the Rim keeps all of it, Mon nine tenths with one
    floor or cache in twelve holding its era's best, Han three quarters with a third holding the best
    (the jackpot for single items), the far side three fifths.
- **What's within reach.** A find rests on the highest of its site's boxes under its socket no higher
  than the socket, moved clear of any it would stand in and off the way through the piece (its tour), or
  on the sand over that, frozen there: placed, never dropped. Buried, only what lies on top of the sand
  shows. Otherwise a find with sand over it shows half buried where at least a third of it and 10 cm
  stand out; deeper, it lies in the sand that fills the site, surfacing as the storms strip it: partly
  exposed, as many of a site's as the sand taken off has gone from a third of its depth toward all of it,
  each socket at its own share **(default)**; dug out, all of it. Nothing shows higher over the sand than a
  hand reaches, and what lies deeper than the rest of a site only once a storm has stripped past it. Of what
  twelve of each kind held (loot probe 2), buried 19 of 305 showed (a house's hall and a watchtower's
  platform, level with the sand), partly exposed 118, dug out 298 (all but the watchtower's platform, out
  of reach), every deep socket hidden short of a storm past it and shown past it.
- **The expedition.** A storm that has come and gone means a revisit finds a site deeper, and mid-storm
  deeper still ([What storms do to sites now](#what-storms-do-to-sites-now)): round twelve towns on two
  seeds (salvage probe 5), at each site's most stripped moment of six through three days and its storm's
  height, 646 finds lay within reach against 554 at its least, the mean tier rising from 1.11 to 1.16
  (with states read whole and no storm's own work, 621 against 466, 1.08 to 1.14: the First Kingdoms'
  four times as many, the second age's a quarter more, as they lie shallowest, mostly dug out already,
  the colonial nothing short of the hardest storms). The good things are deep: an era's best lies in the
  sockets a storm must strip past, and elsewhere only in Han's floors and caches (a third of them) and
  Mon's (one in twelve).
- **Memory.** What's taken from a site is remembered by its id while it's laid, and dropped with it
  once the sheet lifts it, so a site walked 2 km away from comes back whole; the save keeps it
  (`Snapshot`: `sites`, a site's id and its sockets taken), and a save from before resumes with none.
  Open sand's loose finds keep their chunk's memory as before. Whether a site was opened waits on an act
  that opens one; none does yet.
- **Drift** (`Drift`, `game/salvage/drift.gd`). The catcher is a line strung between two stakes driven in
  the sand, at least 1.5 m: what the kits' stakes and coils already make, laid by the actions that lay
  any line; a mooring line to a floating device doesn't count. Every 20 s of world time each catch line
  on solid ground draws from its own stream of the seed (its stakes' places and the tick) whether it
  caught something, at a rate of things an hour of 1 a metre of line straight across the wind, times how
  hard it blows there (the reading exposure uses, none in the clear), times 0.25 for what snags on a line
  in the open plus 1.0 times the ground's lee for what falls out where the wind slows **(defaults)**. What
  it catches (saltbush leaves, salt, a wild saltbush cutting, a hook, now and then a compass, a lamp or a
  battery with a little charge) lies on the sand 0.3 to 0.9 m downwind of the line, held there, yours,
  a surface find, until you take it up; a line's pile holds 8 before more blows past. Over three days of
  seed 1234's weather an 8 m line across the run's wind would catch 357 things at the foot of a tall slip
  face and 76 on open sand (loot probe 5): in a 30-minute storm, three or four in a good lee and one in
  the open. The dev overlay's salvage column shows what a 10 m line would catch an hour where you stand.
- **Loose finds** (migration step 3). Open sand holds 0.15 finds a chunk on the way, a tenth of the 1.5
  it held, and none elsewhere: on the way is within a laid path's 60 m corridor, or 60 m of a
  settlement's site, built or only planned **(default)**, where what travellers dropped lies. They are
  what they always were, deeper the harder the weather. At seed 1234's start, deep desert, the 769 chunks
  within a kilometre hold 2 (loot probe 4); round a town 166 chunks on the way hold about one in ten.
- **The first hour** (step 4, loot probe 6, six seeds; measured before the chassis rework, when crates and
  chargers lay where chassis pieces, frames and light panels lie now). The Surveyor walks in toward Tu 1 to 1.3 km to
  the line it starts off and finds what lies loose along it (a condenser, a radio, a crate, a canister of
  water) or a watchtower's; the Salvager finds the wreck field's hulls 70 to 240 m off, a hoverboard or a
  survival kit half buried in one, or what lies among the wrecks 90 to 350 m off (a charger, a planter, a
  chassis piece), and once in six, where the dunes took every hull, a wayshrine's 430 m off; the
  Homesteader finds the wayshrine 26 to 52 m off holding water, seeds or a saltbush cutting, and once in
  six, where its offerings were gone, a chassis piece lying on the road 360 m along. Something worth finding (water, food, a survival kit or a
  device) lies within a fair walk, 3 km, of every start.
- **What moved.** The house ruin's floor finds are its socket loot; `Finds.plan` lays open sand's alone,
  asking `on_way`. The radio's beacon points at a house ruin's hall, now its socket 0, its choice drawn
  from the ruin's loot seed and passing over one whose hall you've taken (`Salvage.taken(site id,
  socket)`); every standing house ruin holds its own. A site's find is a find of the chunk its
  structure's middle stands on, `[coord, socket, site id]`. The `radio` scenario's beacon test takes the
  site; the `lee` scenario strings a catch line across the wind in front of you.
- **Lineage.** Every site find is given the hands it passed through by the lineage package's call,
  `Catalog.found_in(body, era, kind, seed)`, as it's made, before it's in the world and after its layer's
  mark: its site's era and kind, and its own seed (from the site's loot seed and its socket); each part
  it's found with takes its own call, seeded by its place among them. So a find made again as its chunk
  loads is the same thing, and nothing is saved until it's yours. On this branch `found_in` is a stand-in
  drawing by the Dark Age's rule until the branches meet. Open sand's loose finds and drift take none and
  keep their layer's look.
- **Cost.** Every socket's resting spots for what it may hold, by kind and state, are worked out once
  while the world loads, 64 ms. Each socket's loot is a piece of the streaming budget of its own; in the
  world a house ruin's nine came to 0.4 to 0.7 ms all told, and the slowest frame laying out finds took
  0.70 ms in a town and at a ruin dug out (1.0 to 1.1 ms headless before, by the PRD). Drift is drawn
  every 20 s of world time for each catch line, nothing between; the overlay's reading is a few reads
  of the field a tick.
- **Probes** (`probes/loot/`): 1 site loot is pure per seed and site, laid from anywhere, and made again
  is given the same hands; 2 the sand decides what's within reach, and your hands take what lies on a dug-out floor; 4
  open sand holds no random finds; 5 drift is caught at a camp in a storm and grows in a lee; 6 each
  origin's first hour finds something within reach; 7 what a storm bares blows downwind (2026-10-18). Saves probe 2 is the taken loot staying taken across
  a save and a resume, and an older save resuming. Rewritten to the new placement: salvage probes 1, 2, 5
  (now the expedition), 7 and 8, saves probe 5, the scenarios probe, the kits' probe 5, movement probe 7. Each of the
  six fails on a deliberately broken build: the draw seeded by where a site lies; buried sites showing
  what's under their sand; a save that forgets the sites; loose finds laid off the way; drift blind to
  the lee; no site laying its loot and no loose finds.
- **To see it** (unseen, on a GPU): `look/kits/shoot.sh <dir>` stands every kit piece in each state, now
  with what it holds within reach laid in it; the `lee` scenario stands you at a slip face's foot with a
  catch line strung and a storm minutes off.

## What storms do to sites now

*Built 2026-10-18, on the `exposure` branch: the first two bullets of [Storms with a payoff](prd/wind-and-storms.md#storms-with-a-payoff-agreed-2026-10-18-spec).*

- **A storm works the site it sits on** (`Exposure.surge`). Besides the settled sand, a storm's heart moves
  sand a minute at a time where its big dunes move (`WeatherField.dune_shift_at`: patches 400 m across,
  changing over 15 minutes, leaning toward moving off): off a site where they're moving off it, onto it
  where they're moving on, at most 0.8 m a minute, the last 25 minutes counting, and what it moved comes
  back over about 5 minutes once the storm lets go **(defaults)**. So it lays a site bare over its
  course and can bury it again mid-storm. In a storm's heart it has more than a metre off a site 45% of
  the time; after a storm's height its sand is back to a tenth in a median 13 minutes (3 to 54 over a
  thousand storms), under a game day: a ruin seen mid-storm may be gone by morning. Measured over twelve
  places and three days on seed 1234: in a storm's heart a site's deepest sockets (half its depth again)
  open, against its settled sand alone, 94% of the time against 80% at 0.3 m deep, 83% against 56% at
  0.6 m, 38% against 1% at 1.4 m, 6% against none at 2.5 m, and never at 4 m.
- **Pure, so nothing needs to watch it.** `Exposure.taken` is the settled sand plus the storm's, each
  read between its ticks a tick behind, so the sand on a site never jumps (at play speed, 0.13 mm in a
  frame at most through a storm that takes 3.2 m off) and it's only ever the weather that has been. A
  site kept readings by tick (`Exposure.Memo`) reads exactly as one read afresh. A save, sleep, a far
  stand-in and a loaded site all read the same function; the far ring's stand-ins are drawn at the level
  the skyline's job read, once a minute.
- **A level between the states** (`Exposure.level`): 0 until a third of a site's depth is off, then
  steadily out to 2 once all of it is, through 1, the partly exposed look. Between, a piece sinks as far
  as its states' sinks say (`Piece.sink_at`), the sand drifts as high and fills its rooms as high
  (`drift_at`, `fill_at`); its look and boxes are those of the least buried state whose sand line lies no
  lower (`Piece.shown_state`), so all they leave out is under the sand, and its look's sand stain moves
  with the sand (`foot_shift`).
- **A loaded site follows the storm, smoothly.** While its ground is loaded (`sites.hold`) a structure
  follows the weather a frame at a time (`Structure.follow`): its look and its boxes, a body of their own,
  rise out of the sand or sink back together. Its ground follows in steps (`Structure.ground`), each moving
  no sand more than 2.5 cm (`StructureKit.STEP_M`; the house ruin has 21, a cistern's pit 101): a chunk
  keeps its dunes where structures press into it, and when a step changes, each chunk it touches is
  pressed afresh on a worker from them (`ChunkBuild.pressed`), mesh and collision swapped in together. A
  mid chunk is pressed only once it's 8 steps behind. Structures within two chunks of you follow every
  frame; the rest a few chunks a frame in turn.
- **What it holds follows it.** A loaded site is read again (`Salvage.follow`) each time 2 cm more sand is
  off it or back, or it has risen or sunk 3 cm, a socket a piece of the streaming budget, from what it holds
  drawn once: a find still within reach eases to where it lies now over about a quarter of a second, one
  gone out of reach sinks into the sand and is gone, one come within reach is laid coming up out of it.
  What you've taken stays taken. Finds rest on the boxes that stand of a site at its level.
- **Never over you or your camp.** While you or one of your camp's devices stands on a site's ground, the
  sand never comes back over it; once you're off it comes back no faster than 5 cm a second
  (`site_rebury_m_s`). A house's rooms keep their sand level as it sinks, so its floor goes down under
  you rather than the sand up over you; the hold is for pits and drift, and for the rule. **A save
  keeps it:** the sand held off a site over you or your camp is saved (`sites.held`), and resumed, the
  site comes back as held whoever stands there yet, until the resume is done; a pit you saved in comes
  back dug out round you (saves probe 23).
- **The desert ate it.** When the last chunk holding a site's ground is forgotten (`sites.release`),
  nothing holds it; come back and it's built as the weather has it then.
- **The best loot shows mid-storm.** A site's deepest sockets, where its era's best lies, are reached only
  once the sand off it passes them (half their depth again for most), so mid-storm the storm's work opens
  them for the active player who goes out, and the sand coming back closes them. Read at each site's
  storm's height as well as six moments through three days, round twelve towns on two seeds (salvage
  probe 5), 646 finds lay within reach at each site's most stripped moment against 554 at its least, the
  mean tier rising from 1.11 to 1.16; partly exposed, a site shows what stands proud of the sand on the
  way out, so the least already show more than when states were read whole (466).
- **Its lesser things blow downwind** (`Drift.from_sites`). A site a storm has laid bare, out of the sand
  past its settled sand, sheds the light things of its floors, shelves, caches and beds (parts of 4 kg at
  most: `Drift.carried_from`) into the drift stream, as many as 120 an hour in a storm's heart once the
  storm has it a level further out, carried off along the wind as long as the wind takes, spreading from
  4 m wide by 15 cm a metre and thinning as what it carries falls out, most of it within 150 m
  **(defaults)**, the sites asked of the index by area. A catch line catches it as it catches the open
  drift, the lee and all, its own lesser things falling just past the line in the site's era's look.
  Through the storm a house ruin out in the open is dug out by (loot probe 7), an 8 m line 30 m downwind
  catches about three things of the house's (3.0 expected, 0.21 at 200 m, none upwind or past 450 m, and
  aside only as the wind swings through the storm, 0.04), five times as many in a full lee: a stationary
  camp downwind gets some.
- **A glint through the dust** (Skyline). Inside a storm everything far off takes the storm's veil
  (`Plume.seen_through`, the far saltbush round's) and is hidden, glints and all, but what the storm has
  newly laid bare near you, the metal or glass its settled sand would still cover, glints through the
  dust, veiled by nothing else: out to 90 m, fading from 45 m, at 0.7 of the open sky's glare, and
  since the dust glows all round it shines whichever way it faces you, strongest face on, coming and
  going as the dust thickens and thins **(defaults)**. Looked over five times a second, by area
  (`sites.newly_exposed`).
- **A clang on the wind.** What a storm has newly laid bare within 140 m bangs on the wind now and then: a
  chance every 4 s of world time by how far it's laid bare, heard from the site after the sound's trip
  there, duller the further (`clang.ogg`, from Sand Game's metal clank, its ring kept).
- **The hook for the Console's sensors.** `sites.newly_exposed(x, z, radius)` lists the sites near a place a
  storm has newly laid bare, nearest first, with how much further out of the sand it has them: the ground
  radar marks them bared on a Console's survey page (2026-10-19, below).
- **Cost** (17 sites by hand coming out of the sand round you as a storm rises, headless; `terrain/site` on
  the dev overlay, and `terrain/dust` the glints through the dust): following them, 0.10 ms a frame on average and 0.43 at most, about 6 µs a moving
  site, and nothing for sites the weather isn't moving; 12 presses a minute at play speed, each 4 ms on a
  worker and swapped in within 0.64 ms on the main thread (the heightmap's rebuild), 101 a minute at ten
  times speed; loot read again, 0.27 ms in a frame at most; the terrain's slowest frame 0.95 ms, under the
  2 ms hitch line. A site reads the weather once a minute and its settled sand once a half hour; between,
  two lerps. Its ground at its last two steps is kept, 13 KB a step for a house; a chunk with structures keeps its
  dunes, 18 KB near and 5 KB mid. `sites.newly_exposed` within 140 m takes 56 µs. A drift tick for a
  line with 18 sites near is 0.27 ms, 16 µs with none, so the drift a clock jump draws (540 ticks at most)
  can cost a few tens of milliseconds once where sites stand thick.
- **Where it lies among the dunes** (2026-10-19, `Exposure.dune_at`): -1 to 1 from the bare dunes along
  the run's long-term wind, which they face, read where the site is surveyed and kept with it. Toward 1:
  the ground climbing downwind through it (a windward face, from a rise of 0.02 to 0.15 a metre), or
  standing 2 to 10 m over the ground 50 m either way along the wind (a crest), off a slip face. Toward -1:
  a slip face (the ground falling 0.2 to 0.45 a metre downwind), or a crest upwind within 128 m sheltering
  it, as the lee's own reading would (Lee's heights and tall). The term times `site_dune_strip` (1) more
  stripping and more of the storm's work off it; less than none times `site_dune_bury` (1) more sand back
  and more of the storm's work onto it **(defaults)**. Every reader of a site's weather takes its term:
  its memo is its own. Kits probe 6.
- **A seeded ruin in each big dune's lee** (2026-10-19, `DuneRuins`, the sites' `dunes`). Cells along the
  run's wind a dune spacing long (260 m) and 300 m across it **(default)**; through a seeded line across
  each, every 2 m, the highest crest whose top lies in the cell, standing at least 14 m over the trough past
  its slip face, is a big dune; its ruin lies on the flat past the foot of its slip face, tried every 5 m
  down it and 60 m along the crest either way until the ground takes it (its kind's own survey) where the
  dune term is -0.3 or less. Its kind, bearing, depth (5.5 to 6.5 m) and loot are its seed's; its id
  stays clear of history's; `source` says `dune`. Finding one costs a worker 0.5 to 28 ms (2.6 on average
  round the start), most of it surveys.
- **A seed until it's needed.** Nothing at a chunk's load: a dune's ruin isn't in the index until it's
  built. Each frame (`Sites.step_dunes`, from the world's tick) your pace is read from where you are; slower
  than 4.5 m/s for 2 s you've slowed, and then a worker at low priority takes up to three seeds within 300 m
  that want a look, nearest first, a turn at most every 0.2 s, finds where each lies if it hasn't, and reads
  how far out of the sand it is, again every 15 s of world time **(defaults)**. A ground radar's place is
  looked over the same way whatever your pace. One read with something of it showing, within 150 m while
  you're slow, joins the index (`Sites.join`): a unit of its own, never saved with the sheet, over no other
  structure's ground (where one stands the dunes took it). The loaded chunks under it hold it from then and
  are pressed afresh with it on a worker (`Terrain.join`), sampling their dunes again where they kept none;
  the one its middle stands on draws it and makes it solid once that's in, and its finds are laid
  (`Salvage.adopt`). A chunk still building when it joins is pressed once it's built. From then it's a site
  like any other, held, followed and released with its ground, until the sheet lifts it; lifted, it's a
  seed again and what was dug off it is forgotten with it. **A save keeps** the seeds dug or built (`dunes`:
  each one's cell, the sand dug off it, whether it was built and how much a sieve sifted), and resumed, one
  built is built again as soon as the sheet is laid.
- **Digging** (2026-10-19, `Sites.dig_at`, `Structure.dig`): sand off a site by hand, m, kept on it
  (`dug_m`) apart from the weather's (`pure_taken`), and added to it only up to dug out (`with_dug`), so the
  deepest sockets still need a storm to strip past them, and what's dug never reads as a storm's baring
  (`bared` leaves it out). A seed not built yet takes it on itself until it builds. History's sites keep
  theirs in the index's memory while they're laid (`dug`: each one's id, m dug and m³ sifted, in the save).
- **Light things fall in a crest's lee** (2026-10-19, `Drift.lee_ground`, `Drift.fallen`). Each tick of
  drift, round you and each deck of yours on solid ground, the 6 m squares within 24 m whose lee at the
  tick's wind is half or more each draw from their own stream of the seed (the square and the tick) at
  `drift_lee_fall` things an hour on a hundred square metres of full lee in a storm's heart, times how hard
  it blows there **(defaults)**; what falls, what the wind carries, lies on the sand in the square, as drift
  does. Fewer than a pile's worth (8) lie round you first; a clock that jumps draws its last 90 ticks of
  them at most. Loot probe 8.
- **Cost, dune archaeology.** A ride's frame pays 0.03 ms for the seeds, nothing found or built (kits probe
  8, 20 m/s 40 m off a bared one). Built as history's are, as you pass, the same ride along the crests
  hitched the terrain's frame to 4.5 ms, laying their finds 4.2 ms (a found Console among them), against
  0.95 ms lazily. A build, once you've slowed: the index's join and the chunks' hold well under a
  millisecond on the main thread, each chunk pressed on a worker in a few ms and swapped in within 0.2 ms,
  and its finds a socket at a time in the streaming budget. Lee falls: a tick reads the wind and the lee at
  about 60 squares, every 20 s, only while the weather blows; a clock that jumps, 90 ticks at most.
- **Wrecks follow it too.** A wreck's scrapping (`Wreckage`) stands at its floor as its chunk draws it,
  so its plates, hazards and packed holds rise and sink with its hull, and its modules are read again
  as any finds are; what's cut and cleared is its memory, apart from the weather's function, so a
  storm never undoes it. A cut plate rides the wreck it lies on, and one on the sand is buried with
  the wreck as it sinks deeper than when it fell, never lifted off its sand as it rises (wrecks probe 7;
  [Salvage & ruins](prd/salvage-and-ruins.md#wrecks-and-scrapping-hunter-2026-10-18-built)).
- **Probes:** kits 3 (a loaded site follows the storm, smoothly, and never buries you), kits 4 (exposure is
  pure, and a storm works a site), loot 7 (what a storm bares blows downwind), sightlines 4 (a glint
  through the dust only near), saves 23 (a save never buries you); and for dune archaeology kits 6 (the dune
  term strips a windward face more than its lee), kits 7 (a big dune's ruin bares only past an intense
  storm), kits 8 (a buried site costs nothing until bared and slowed by), loot 8 (light loot falls in a
  crest's lee), saves 32 (the dune deeds through play). Kits 1 and loot 2 read a site's weather through
  the site, its dune term and all. Each fails on a deliberately broken build: no hold over you, no ground
  pressed afresh, a look that doesn't follow; the storm's sand never coming back, or read only on its
  ticks; drift shed upwind as well; glints through the dust at any range, or every bare glint; a
  resume that forgets the held sand.
- **To see it** (unseen, on a GPU): `look/exposure/shoot.sh <dir>` stands a hab pod where a storm lays it
  bare by day and shoots it from off its ground in the clear before the storm, rising half out of the
  sand in it, at its height and in the clear after, and from out in the dust its bared windows glinting
  through, and builds `~/Desktop/exposure.png`. `look/archaeology/shoot.sh <dir>` shoots a big dune's ruin
  bared after a big storm, the archaeology setup on a deck beside it and its survey page, and what a
  storm let fall in a crest's lee round you, and builds `~/Desktop/dunes.png`.

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
- Exposure's window: 12 hours of world time in 30-minute ticks; a storm's heart strips 0.5 m a tick, the
  wind lays 0.2 m back every tick, and a tick's work counts less the older it is, down to nothing 12 hours
  back.
- A storm's own work on a site: 0.8 m a minute in its heart where its dunes move off it, as much onto it
  where they move on, back over about 5 minutes, its last 25 counting; the dunes' patches 400 m across,
  changing over 15 minutes, leaning a quarter toward moving off and swinging 1.3. Sand never back over you
  or your camp; once you're off, back at 5 cm a second at most. Site drift 120 things an hour in a heart,
  laid a level bare, carried 150 m, 4 m wide and 15 cm wider a metre. A glint through the dust to 90 m at
  0.7 of the glare; a clang heard to 140 m.
- Where a structure may stand: the most the dunes over its ground may rise and how steep they may be,
  and how far it may look along its line for ground that takes it, per kit piece (the era files).
- Spawns: the Surveyor 0.6 to 3 km from an artery or spoke (first set at 2 to 4, brought in to a fair
  walk, then to the deep desert's edge for a mast 600 to 1000 m off on its horizon, on 2026-10-18),
  crossed walking in toward Tu within 3 km, no path or settlement within 600 m; the
  Salvager within 300 m of a wreck field; the Homesteader on a road within 100 m of a wayshrine; every
  start within 12° of the equator and 500 m clear of a landmark's footprint; and something in sight by
  3 px buried, the Surveyor's from bare flats (sand at most 0.15).
- The Haberjack bunker under the Bastion.
- Lineage: a second-age find keeps a house's marks half the time and is blessed 40% of the time, 90% at a
  wayshrine and 60% at a stepwell, half of those the Cistern's, 5% elsewhere; five sets of Dark Age repair
  and four of blessings.
- Era stats: keeps 1.00, 0.92, 0.85, 0.75 (colonial, First Kingdoms, skimmer, second age); draws 1.00,
  1.05, 1.10, 1.25; tough 1.0, 1.5, 0.5, 0.9; the skimmer era's weight 0.7; the skimmer era mended with
  scrap.
- The houses' colours: Haberjack deep red, Pellicott ochre, Crake teal, Vonatelli ochre with a red plaque.

- Loot ([What loot does now](#what-loot-does-now)): each era's tables and each kind's rows; the regions'
  generosity (the Rim all, Mon 0.9, Han 0.75 with a third of floors and caches its era's best, the far side
  0.6); a partly exposed site's buried loot surfacing as the sand taken off goes from a third of its depth
  to all; loose finds 0.15 a chunk within 60 m of a path or a settlement's site; drift 1 a metre an hour in
  a storm's heart, 0.25 snagging in the open and 1.0 more in a full lee, drawn every 20 s, 8 to a line.

- Geology ([Geology](#geology)): the rift 8 to 11 km either way from Aitch, its floor 600 m across and
  its walls to 1.6 km; the tapped vents 1.5 to 3 km along it, the live ones 5 to 7.5 km either way; the
  volcano's flank vent 1.2 to 2.4 km from its summit; a live vent's breath a fifth over 170 and 410 s,
  a burst in a 1,200 s slot 70% of the time, rising 10 s, holding 90 s, fading by e every 220 s, 25 to
  170 times the seep, ash a fifth seeping and 85% at a peak; gas pockets 1.5 to 13 km from the point
  under Tu, one in two 500 s slots, blowing 20 to 50 s at 1.7 to 6.7 times the seep; the magnetized crust
  across the rift's walls, 2 km past its ends and over the volcano's footprint to 6 km; the mouth's
  pit, rampart and 56 m apron, sliding up to 24 m along the rift.

## Open

- **The rift's and the volcano's landforms.** Geology holds the rift's line, floor and walls for the
  landform package to carve; until then the vents' mouths stand on the dunes as they are, the flank
  vent's on the dunes where the volcano will be.
- **The tapped vents' ground.** The vent stations stand on cold vents; their kit, when it's built,
  carries the old vent's scar.
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
- **Session 5's places** ([the lore](lore-research.md#mitchell-the-dead-god-agreed-session-5)). The Counting House
  in Crakeside and Halfrise's stone cradles are not parts of any landmark yet. The Counting House is the
  likeliest new part of Port Morgan; the cradles wait on their kit. Wow's resting place is unplaced (Hunter,
  2026-10-18: not under the black site), so it is no part of any landmark.
- **The Rim's far stretch.** The second-age empire is "centred on the stretch of Rim closest to Port
  Morgan." How built up the Rim is on the far side of the sub-Tu point is the richness default.
