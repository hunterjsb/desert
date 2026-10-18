# Desert — Plants, World Gen & Ruins, 17 Oct 2026 (part 4)

Oct 17, 2026 · @Hunter Boyd

## Brief for the agent

This doc is the canon from the part 4 session: a full plant system, history-first world generation, structures by era, and the loot model. It follows *Desert — Lore & Kits Session (part 3)* and should be merged into the repo's docs folder alongside it.

- **Hard rules still apply:** no NPCs, no dialogue, no exposition. Everything reaches the player through objects, terrain, instruments, radio and ending epilogues.
- **Design principle for this doc:** one shared system per area, with a unique feel per item. Do not add bespoke subsystems for individual crops or structures; differences come from data (stats, socket kinds, placement rules).
- **Scope warning:** the game has no structures and no terrain generation yet. Lore here is deliberately deeper than what should be built now. Section 12 says what to build first.
- **Labels:** *Agreed* = settled direction. *Idea* = proposed but not confirmed. *Back burner* = liked, do not build yet. Anything in Open questions is undecided; don't hard-code it.

## Timeline terms and corrections

The era names are now: **colonial → collapse → skimmer era → first age → second age.** "Bronze Age" is retired everywhere; replace it in existing docs and code comments.

1. **Colonial era** — the transshipment hub, Port Morgan, Halloran, Starcom, the observatory.
2. **Skimmer era** — short. The war, the black site, H-Town at its peak rivalling Port Morgan, deserters.
3. **First age** — survivors living on scraps of colonial power until it fails and war breaks out.
4. **Second age** — the Cistern kingdoms (Halfrise, Sister), dying slowly of thirst.

Corrections to earlier docs:

- **Black site:** a Provisional State facility during the hive mind war, run with Halloran's security force, cut into the rift wall near Halloran inside the ring. It later becomes the Quartermaster's bunker. It sits on the main artery, not an isolated spoke.
- **Geography axis** runs toward Tu, not the sun: Halfrise on the Rim, Port Morgan partway in, Halloran deepest near the sub-Tu point.
- **Starcom** (high-altitude comms) and the **orbital launch site** are separate places.

## Plant system overview

The current carrots and fungus are placeholders. They're replaced by a roster of Earth-lineage crops that colonial biotech engineered for Zan and that then went feral over thousands of years. Every crop has three layers: Earth ancestor, engineered traits, feral drift.

**Two families (Agreed).** Day crops run on light. Storm crops run on dark and humidity. Each family mirrors the other: a baseline food crop, a survivor, a water crop and a utility crop. A few crops sit outside both families as specials.

**Stats (Agreed).** Each crop varies on:

| Axis | What it controls |
| --- | --- |
| Water need | How much water input it consumes |
| Light | Sun, darkness, or lamp |
| Growth speed | Time to maturity / cycle length |
| Yield | Output per harvest or cycle |
| Output type | Food, water, fuel, light, salt, cord, special material |
| Tolerance profile | Separate tolerances for wind shear, particle abrasion, heat, cold and radiation |

Weather is multi-axis, not one stat. There is no heat shield in the game yet.

**Progression (Agreed).**

- **Early game:** temperature, light and water all matter. Players grow whatever suits local conditions, so hardy crops (saltbush, sandroot, dewleaf) are survival crops.
- **Late game:** shields (wind/particle now, heat later) remove most weather factors. Light and water become the managed inputs, through lamps and humidifiers. Fussy, high-yield crops become viable here.
- Read tolerances as *how many shields and how much power you need to keep this alive*, not as pass/fail survival.

**New equipment implied:** burner/generator (for coalcane fuel), humidifier. Both are crate parts like the existing devices.

## Crop roster

Eleven crops: four day, four storm, three specials. All Agreed unless marked.

| Crop | Family | Role | Maker | Output | Planter |
| --- | --- | --- | --- | --- | --- |
| Root-tuber | Day | Baseline food | Frontier Ag | Food | Standard |
| Saltbush | Day | Survivor | Tilg terraforming | Salt, emergency food | Standard |
| Dewleaf | Day | Water | Frontier Ag | Water (night trickle) | Small |
| Coalcane | Day | Utility | Frontier Ag | Fuel | Deep |
| Vat fungus | Storm | Baseline food | Hab contractors | Food, compost | Small |
| Sandroot | Storm | Survivor | Unassigned | Starch, water | Deep |
| Stormcup | Storm | Water | Frontier Ag | Water (storm) | Small |
| Glowcap | Storm | Utility | Hab contractors | Light | Standard |
| Office fern | Special (lamp) | Indoor oddball | None (decoration) | Cord | Small |
| Rainseed | Special (endgame) | Revival flagship | Tilg terraforming | Best crop once restored | Deep |
| Quietbloom | Special (endgame) | Alien mystery | Hive mind | Strange mod material | Standard |

Frontier Ag was one of the main remote colonial contractors and made some, not all, of the original crops.

### Root-tuber

- **Ancestry:** potato descendant; tubers store energy underground, out of sun and sand.
- **Engineering:** tardigrade-style damage-suppressor proteins against radiation; waxy sealed skin against water loss; engineered sterile, spread only by cuttings (licensing measure).
- **Feral drift:** sterility broke down, so wild strains flower and self-spread. Raised alkaloids make them bitter.
- **Hooks:** wild tubers are worse food, so clean stock is worth hunting. Bitter tubers need processing or carry a downside.

### Saltbush

- **Ancestry:** *Atriplex*, Earth's desert saltbush.
- **Engineering:** pioneer plant to stabilise dunes and pull salt from soil before other crops. Pumps salt into surface bladders (silvery look). Deep taproot; CAM photosynthesis, so pores open only at night.
- **Feral drift:** the most successful survivor. The Sisters seeded it along pilgrim roads, so silver lines mark old routes. Leaves fold when pressure drops, protecting the bladders.
- **Hooks:** it is the weather-sign plant from part 3; this biology explains it. Harvested for **salt**, a preservation resource that makes food last longer. Barely edible emergency food that never dies.

### Dewleaf

- **Ancestry:** Namib desert plants plus the fog-basking beetle's water-collecting surface.
- **Engineering:** broad leaves with water-attracting bumps and shedding grooves. Night condensation runs to a cup at the stem. A powerless backup condenser.
- **Feral drift:** smaller, thicker leaves; more heat-tough, less water. Clusters in low hollows where cold air pools.
- **Hooks:** collect at dawn, tying water to the day cycle. Above heat tolerance the cup dries and that night's water is lost. Wild clusters hint at cold-pooling terrain.

### Coalcane

- **Ancestry:** sugarcane crossed with jatropha (an oil plant).
- **Engineering:** biofuel crop for backup generators if fuel imports stopped. Stalk stores oils and resins, not sugar; heavy lignin makes it near-wood.
- **Feral drift:** rare, since it's thirsty; survives only near old water. Ancient stands build into thick, near-petrified groves.
- **Hooks:** the only renewable fuel crop, a night/storm counterpart to solar, burned in a **new burner device**. Old groves are a big one-time fuel haul and a sign of ancient water. Trades water for power.

### Vat fungus

- **Ancestry:** oyster mushroom crossed with mycoprotein strains.
- **Engineering:** the colony's original food, grown in sealed vats in dark hab tunnels and fed on waste. Fruits when air is humid and still. Doubled as the waste-recycling system.
- **Feral drift:** escaped into abandoned ruins; lives in buried corridors and blooms when storms raise humidity and block light. Storms are the closest thing to its old vat.
- **Hooks:** grows on scraps, so planting it with rotten food or plant waste is **composting**. Dark ruins hold wild patches. Food when solar can't help.

### Sandroot

- **Ancestry:** desert melons plus *Welwitschia* (Namib plant, lives 1,000+ years).
- **Engineering:** dune anchor with roots tens of metres deep. Visible part is a low leathery rosette, so wind and particles slide over. Stores starch and water in a deep swollen root.
- **Feral drift:** absurdly long-lived; root networks spread underground so one plant can cover a dune. The oldest wild specimens were planted in the **first age**, as first-age farmers' unkillable crop.
- **Hooks:** the only crop that survives a storm unprotected. Harvest means digging: slow, big payload. Keeps growing past mature, so patience pays (see growth stages). Ancient sandroot is a landmark; digging it can expose the ruin its roots bind.

### Stormcup

- **Ancestry:** bromeliads crossed with pitcher plants.
- **Engineering:** harvests storm moisture. Stiff funnel leaves channel humid air and droplets into a sealed central well. A waxy lid closes when particles fly.
- **Feral drift:** partly carnivorous; traps insects blown in by storms, so wild water is tainted.
- **Hooks:** more water per storm than dewleaf per night. Lid holds against moderate particle storms; above that it's shredded unless shielded. Wild water needs filtering or boiling.

### Glowcap

- **Ancestry:** bioluminescent fungi (e.g. ghost mushroom) plus firefly luciferase.
- **Engineering:** emergency hab-tunnel lighting needing no power. Glows brighter as humidity rises. Shares vat fungus's waste-eating trait.
- **Feral drift:** spread through dark corridors; wild patches glow faint blue-green through cracks in buried structures, strongest in storms.
- **Hooks:** light without power, brightest in the worst storms. A glow at night means a buried ruin with an opening. Sand beetles are drawn to it.

### Office fern

- **Ancestry:** a pothos-style trailing houseplant, everywhere in Port Morgan's offices and habs. Never engineered; came along as decoration.
- **Biology:** bred for indoor artificial light, so it ignores weather and fits neither family. Grows under lamps.
- **Feral drift:** mostly died with the habs; hardy cuttings still trail over desks in sealed buried offices, kept alive by a dying light or sun through a crack.
- **Hooks:** the crop you grow by snapping a lamp onto the crate. Fibrous vines yield **cord** for tethers and rope. Low value, always reliable: the cozy sealed-camp crop.

### Rainseed

- **Ancestry:** a chimera, the terraforming plan's flagship. Base is a prairie grass, for Rim-wide ground cover.
- **Engineering:** the final step of Tilg's projection, planted once rain begins. Colonises wet soil explosively, locks in moisture and releases vapour that seeds more rain. Without rain the seeds stay dormant.
- **Order history:** the Sisters kept a vault of pure rainseed as the plant their scripture promised. Each generation novices tried to germinate a few with stored water; the sprouts died when watering stopped.
- **At arrival:** the vault is sealed and intact in Sister.
- **Hooks:** plantable but weak, dies without heavy watering. Once Mother Cistern is restored and linked, it becomes the best crop in the game and self-spreads: the revival ending physically shows Zan turning green.

### Quietbloom

- **Origin:** the only non-Earth organism on Zan. During the trade era the hive mind sent one seed shipment as a gift; the Provisional confiscated it as a biohazard and locked it in the black site, where it was forgotten.
- **Biology:** not DNA-based. A crystalline lattice that feeds on electromagnetic energy, not light or water. Grows toward powered electronics and radio sources and slowly drains them. Its growth shifts in response to radio signals, as if listening. Never explained.
- **At arrival:** a sealed specimen case at the black site holds a few dormant seeds.
- **Hooks:** plant beside a battery or radio and it grows by eating your power; yields a valuable strange material, possibly for high-end mods. With a console nearby the radio picks up faint patterns from it. Carrying one onto a freighter or into the AI endings could be a quiet modifier (*Idea*).

## Propagation, growth stages and wild habitats

### Sources of plants (Agreed)

1. **Wild stock** — dug up or cut from feral plants. Scarce: it only grows in special places tied to history (old water lines, ruins, caves). Lower quality: bitter tubers, tainted water, lower yield.
2. **Clean stock** — sealed seed caches and vaults in era-appropriate sites. Full engineered traits. Rare and finite until propagated.
3. **Your own propagation** — take cuttings or seeds from what you grow.

**Drift (Agreed):** colonial clean stock was engineered sterile, so it spreads by cuttings and every cutting stays clean but scales slowly. Letting a plant go to seed, or crossing it with wild stock, gains hardiness and loses yield and purity. The player chooses: a pure, fussy line by cuttings, or a tough feral line.

### How each crop propagates (Agreed)

One shared mechanic (pick up a propagule item, plant it in a socket); the form varies per crop for feel.

| Crop | Propagates by |
| --- | --- |
| Root-tuber | Replant tubers |
| Saltbush | Cuttings only (taproot too deep to dig) |
| Dewleaf | Whole-plant transplant (small, shallow) |
| Coalcane | Stalk cuttings |
| Vat fungus / Glowcap | Scraped spores or mycelium onto a substrate |
| Sandroot | Seed only |
| Stormcup | Offsets (pups at the base) |
| Office fern | Cuttings |
| Rainseed | Seed only, from the Sister vault |
| Quietbloom | Seed only, from the black site |

### Growth stages (Agreed)

Shared base: **seedling → growing → mature → (optional) going to seed.** Going to seed is when a plant drifts toward wild stock. Per-crop twists:

- **Sandroot** keeps growing past mature; a bigger root pays more for patience.
- **Storm crops** like fungus fruit in bursts during storms, not on a timer.
- **Stormcup and dewleaf** are never harvested; once mature they produce water on a cycle.
- **Coalcane** regrows from the cut stump.
- **Rainseed** stalls at seedling until there is real rain.

### Where wild plants are found (Agreed)

No plant spawns randomly. Each comes from its habitat or a cache in an era-appropriate site; finding plants is finding history.

| Crop | Wild habitat / source |
| --- | --- |
| Root-tuber | Clean: Frontier Ag seed caches in colonial ruins. Wild: near old colonial water lines |
| Saltbush | Silver lines along old pilgrim roads; usually the first plant found |
| Dewleaf | Cold hollows near first-age cisterns; spotted at dawn by beading water |
| Coalcane | Petrified groves at dried-up first-age wells; live stalks at the edges |
| Vat fungus | Buried colonial corridors and hab tunnels, exposed after storms |
| Glowcap | Glow in cracks of buried ruins at night |
| Sandroot | Seeds from flowering ancient specimens marking first-age sites |
| Stormcup | Sheltered rifts and caves where humidity pools |
| Office fern | Sealed colonial offices deep in ruins |
| Rainseed | Sister vault |
| Quietbloom | Black-site specimen case |

## Planter sizes and crate manufacturers

### Planter sizes as socket kinds (Agreed)

Props are uniform squares today. When real models arrive, avoid multi-cell footprints and tetris overlap. Instead, planter size is a **socket kind** in the existing typed-socket system; each plant declares which kind it fits. No new collision logic.

| Planter | Fits | Notes |
| --- | --- | --- |
| Small pot | Dewleaf, stormcup, vat fungus, office fern | Many per crate |
| Standard planter | Root-tuber, saltbush, glowcap, quietbloom | The default |
| Deep bed | Sandroot, coalcane, rainseed | Needs root depth or height; large slot or a whole crate |

Tall or trailing growth (coalcane height, fern vines) is **visual-only overgrowth** that doesn't block or collide.

Reminder from the repo: sockets are saved by list index, so new sockets on existing frames must be appended at the end, never inserted.

### Crate manufacturers (Agreed direction)

Multiple manufacturers make crates with different slot mixes. A crate's maker tells you its era and its job; the slot mix is the variety axis.

| Maker | Era | Character |
| --- | --- | --- |
| Tilg & Standard | Colonial | Standard logistics all-rounder, most common |
| Halloran Isotope | Colonial / skimmer | Industrial, rugged, heat-tolerant, few planter slots |
| Frontier Ag | Colonial | Purpose-built grow crates with deep beds and integrated misters; rare and fragile |
| First / second age (hand-built) | First, second | Crude, heavy, odd slot layouts; the Sisters' versions built for water storage |

## Sand beetles and ambient life

Zan now has colonial insects as well as feral plants (Agreed). The constraint: they must be cheap to model.

- **Sand beetles** are colonial pollinators or decomposers that went feral. Small ambient creatures that scuttle; no AI beyond that.
- They tie into the plants: dewleaf's ancestor is the fog-basking beetle, glowcap attracts them, and wild stormcups trap blown-in insects.
- *Open:* whether beetles are pests, pollinators, or both.

## World generation

The key takeaway of the session: **generate history first, then terrain and loot.** Today 99% of loot spawns loose in sand and the rest in one copy-pasted ruin. The world is fully procedural with an underlying coordinate system but no terrain generation phase yet. Add one, structured as historical layers (Agreed):

1. **Colonial layer** — place the fixed colonial landmarks, then the colonial skeleton: main highways, pipelines, power corridors, water-import aqueducts, hab tunnels.
2. **Skimmer layer** — wrecks, pads and camps, mostly overlapping colonial ruins and clustering around Han.
3. **First-age layer** — settlements along dead colonial lines and near water; first-age water lines link them.
4. **Second-age layer** — towns on top of or near first-age sites; Halfrise and Sister as anchors; a dense road network.
5. **Feral layer** — plants placed along the roads, water lines and ruins the layers left.
6. **Sand** — everything buried at a depth matching its era; storms take over from there.

Each layer builds on the last, so history stays coherent per seed.

### Roads and water lines are placement rules

The roads themselves are gone; the player never sees a road surface. Generate invisible paths between anchors, then scatter structures and feral plants along them. The pattern of saltbush lines, shrines and watchtowers is what traces the road.

### The skeleton (Agreed)

- Port Morgan is the colonial hub, on the Tu-facing side. **Spokes** run outward to the ring; some routes run **around** the ring and some **in** toward the hub.
- The **main artery** runs inward from the Rim (Halfrise, Sister), through Mon (Port Morgan), down to Han (Halloran, the black site).
- The **observatory** sits alone in the dark zone on its own long spoke: a maintenance road with power lines, giving a reason to cross the dark.
- **Starcom** is high altitude, on a peak or ridge above the weather.
- Density tapers: rich at the Rim, thinner in Mon, sparse and grim in Han.

### Fixed landmarks in every world (Agreed)

Placed procedurally per seed, but always present, because the endings depend on them:

Port Morgan · Halloran refinery and H-Town (Aitch) · the black site · Starcom · the observatory · the orbital launch site · Sister · Halfrise.

### Keeping a huge moon interesting

Arteries alone leave most of the moon empty. Fixes (Agreed):

- **Dense networks:** each era made many minor paths, farm tracks and local wells, not just main roads.
- **Off-network sites:** skimmer wrecks crash anywhere; colonial survey beacons and relay towers sit on a grid; first-age hermits and holdouts lived remote.
- **Drift** fills the gaps (see loot).
- **Meaningful emptiness:** some deep desert stays empty on purpose as the dangerous zone between settled areas.
- **Region identity:** hot zone, dark zone, and the ring band each have their own plants, storms and sites.

### Readability

Arteries must be legible from the dunes: a straight line in nature means people. Saltbush lines, watchtower silhouettes, pylon stubs and pipeline humps run in straight lines. A basic survey mod on the console picks up buried metal, so colonial pipelines show as lines on screen.

### Spawns and the early goal (Agreed)

Early game for everyone: **find an artery and follow it.** Spawn position depends on kit:

- **Surveyor:** deep desert with detection gear; finding an artery is their early game.
- **Salvager:** near a skimmer wreck field.
- **Homesteader:** right on a road, near a wayshrine.

## Structures by era

Two tiers: hand-designed **landmarks** (few, fixed per world) and a small **repeatable kit** per era that scatters across the world at zone-appropriate density. The kit is what to build first. Eras overlap: later sites sit on and reuse earlier ones.

### The repeatable kit (Agreed direction)

Three or four small, cheap pieces per era:

| Era | Kit pieces | Burial depth |
| --- | --- | --- |
| Colonial | Pylon stubs, pipeline segments, hab pods, relay masts | Deepest; rarely exposed |
| Skimmer | Wreck hulls, fuel bladders, dugouts | Shallow, at an angle; exposed and reburied fast |
| First age | Pipe-wall huts, cisterns, low stone walls | Deep; barely visible |
| Second age | Wayshrines, watchtowers, house ruins | Shallowest; most often exposed |

Each piece has three exposure states: **buried, partly exposed, exposed.** Storms shift them. A reburied piece can come back later with fresh loot.

### Colonial (oldest)

The best infrastructure loot. Landmarks: Port Morgan (spaceport pads, warehouses, Harbourmaster offices, Tilg terminals), the Halloran refinery terraces, Starcom (high-altitude comms), the observatory, the orbital launch site.

Generated pieces: vent power stations along the rift; buried hab blocks and tunnel networks (vat fungus, glowcap, office fern); Frontier Ag farm domes and seed stores; water-import aqueducts, pump stations and tanks; survey beacons and relay towers on a grid; frontier towns on the plains.

Encounter: big, deep, mostly buried. A storm strips a dune and exposes a roof or tower top. Same structure, different way in each time. Dig or find a breach; the best loot is deepest.

### Skimmer era

Short era, little of its own architecture: mostly **scars on colonial structures.** Wreck hulls, improvised landing pads with fuel bladders, fortified deserter dugouts with weapons caches, black-site checkpoints and patrol posts around the rift, squatter habs patched with scrap.

Encounter: half-buried at an angle; wind exposes and reburies them fast. Loot it now.

### First age

Survivors on failing colonial power, then war. Pipe towns built into colonial pipelines; generator shrines around the last working generators (possibly the first sacred sites); cut-and-cover halls roofed with hull plates; cisterns where colonial water lines ended (before the Sisters); low walls and old sandroot field plots; buried war earthworks.

Encounter: low stone foundations, found by surface signs (saltbush lines, ancient sandroot). Digging reveals a floor plan. More likely than second-age sites to hold working colonial tech.

### Second age (most common)

Kingdoms slowly dying of thirst, so most structures revolve around water.

- **Wayshrines** — small Cistern shrines on pilgrim roads; basins, offerings, a few seeds.
- **Stepwells** — stairs down to dry bottoms; dewleaf, maybe stormcup in the shade.
- **Ration gates** — fortified checkpoints where the Sisters controlled water; lockboxes, tokens.
- **Caravanserais** — walled rest stops at day-long intervals on the artery.
- **Watchtowers** — tall, the most visible landmarks; late-war weapons caches.
- **Granaries** — sealed stores, preserved seed or salt.
- **Walled villages** — the bulk of sites; in Mon, built into colonial ruins.
- **Battlefields** — late wars, around Halfrise.

Zones: the Rim is densest (sacked Halfrise; intact, empty Sister; shrines, ration gates, stepwells between). Mon has villages in colonial ruins, granaries and salvage yards. Han has Muster, the Crossing and Aitch, and little else.

Encounter: tall and fairly intact; towers stand out of the dunes.

## Loot model

Loot follows history: it comes from sites, and storms decide what's reachable. Stop spawning items loose in open sand.

### Two channels (Agreed)

- **Drift** — storms carry light debris, scraps and occasional small items across the map. Caught as it blows past, perhaps with a net or tether mod. Steady, low value, rewards a good camp. **Terrain matters:** a camp in a sheltered valley below a dune crest where high winds ramp over should be one of the best passive farms.
- **Expedition** — big storms reshape dunes and expose ruins. Afterward, go explore before sites rebury. This is where the good loot is, and it pulls you away from camp.

The storm loop: shelter and catch drift while it rages, then go into its wake to hunt what it uncovered. Weak players avoid storms, strong players hunt them, and everyone gets caught.

### Exposure window (Agreed)

Relaxed, not a hard timer. Sites rebury gradually. A returning storm can expose a **deeper layer** of the same ruin, so revisiting pays.

### Loot identity by era (Agreed)

| Era | Best for |
| --- | --- |
| Colonial | Infrastructure: power, crates, big systems |
| Skimmer | **Best single-item gear:** military weapons, armour, mods from deserters and the black site |
| First age | Intact working colonial tech used in new ways |
| Second age | Worn reused gear; water, seeds and salt |

H-Town at its peak and the black site make **Han** the jackpot for single items: sparse, dangerous, rewarding.

### Surface signs

Saltbush lines, glow in cracks, coalcane groves and ancient sandroot all say something is buried beneath.

## Storms as planning sessions

A storm can last 20–40 minutes, a whole play session. It becomes the reflective half of the loop; calm is the active half (Agreed):

- **Read the storm** — console and plants show where it's heading and what it may uncover.
- **Plan routes** — map, known roads, spotted signs; pick the post-storm target and the long-term goal.
- **Tend camp** — water crops fill, fungus blooms, glowcap lights up; harvest and process.
- **Listen** — radio carries better in some storms.
- **Craft and repair** — fix storm damage, rearrange mods.

### Storm-only mechanics (Back burner)

Liked, don't build yet:

- **Wind power surge** — turbines spike; charge batteries hard.
- **Static harvest** — particle storms build charge; a lightning rod or collector captures a big spike, risking fried electronics. Ties to quietbloom.
- **Deep exposure** — mid-storm sand movement briefly opens the deepest ruin layers.
- **Storm blooms** — storm crops fruit only now.
- **Radio windows** — some conditions carry distant transmissions.
- **Glass forming** — lightning in heat storms fuses sand into glass, a crafting material collected in the wake.

## Implementation order

Roughly in the order things can land. Follow existing conventions; no one-off exceptions in core systems.

1. **Crop data model.** Replace carrot/fungus with a data-driven crop definition: family, water need, light source, growth speed, yield, output type, per-axis tolerances, planter socket kind, propagule type, stage behaviour. Start with root-tuber and vat fungus as direct replacements, then add the rest.
2. **Planter socket kinds.** Add small / standard / deep planter sockets to the typed-socket system. Append new sockets to existing frames; never insert.
3. **Shared growth stages.** Seedling → growing → mature → to-seed, with per-crop flags: keeps growing (sandroot), storm-burst fruiting, cyclic water output (dewleaf, stormcup), regrow from stump (coalcane), stall-until-rain (rainseed).
4. **Propagules and clean vs wild.** One pickup-and-plant mechanic with per-crop propagule items; a clean/wild flag that affects yield and output quality; going to seed flips clean toward wild.
5. **New devices.** Burner (consumes coalcane, produces power) and humidifier. Lamp-as-light-source for the office fern via the existing lamp-on-crate snap.
6. **Terrain/history generation phase.** Fixed landmarks placed per seed, then colonial skeleton, then later layers, as invisible paths. Start with the colonial skeleton and second-age roads only.
7. **Repeatable structure kit.** Begin with second age (most common): wayshrine, watchtower, house ruin. Each with buried / partly exposed / exposed states and an era loot table. Then add other eras' kits.
8. **Loot relocation.** Move loot out of open sand into structure loot tables; keep a low-value drift channel carried by storm wind.
9. **Wild plant placement.** Feral layer places wild crops by habitat rules (roads, water lines, ruins, hollows, rifts).
10. **Spawn by kit.** Surveyor deep desert, salvager near wrecks, homesteader on a road.

Deferred: feral plants as weather sign (needs the queryable storm curve from the sleep work), storm-only mechanics, landmark interiors, heat shields.

## Open questions

- [ ] Plant processing: salt, filtering stormcup water, debittering tubers, fern to cord. Next session's topic.
- [ ] Sand beetles: pests, pollinators, or both
- [ ] Crossbreeding: can players create new strains?
- [ ] Sandroot's original maker (Frontier Ag or Tilg terraforming)
- [ ] Can a player's own sandroot ever reach landmark size, or is that wild-only?
- [ ] Does any water crop beat the condenser in some niche?
- [ ] Quietbloom as an ending modifier: confirm or drop
- [ ] Orbital launch site: location and structure
- [ ] How much storm-driven dune movement the terrain can actually support
- [ ] Second-age structures: how much of the list makes the first pass
