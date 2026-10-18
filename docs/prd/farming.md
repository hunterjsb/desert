# PRD: Farming

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

*Updated 2026-10-17: [session 4, part 4](../plants-worldgen-ruins-2026-10-17.md) replaces the
placeholder carrots and fungus with a roster of eleven crops in two families, with propagation,
growth stages, wild habitats and planter sizes as socket kinds ([The plant
system](#the-plant-system-agreed-session-4-part-4-not-built)). It is direction and none of it is
built, so the skeleton below and its "as built" notes stand. [Session 4, part
5](../gods-gear-farside-2026-10-17.md) adds the Almanac, the god of growth, and a kiln for processing
([The Almanac and crossbreeding](#the-almanac-and-crossbreeding-idea-session-4-part-5-not-built)).*

## Why this system exists

The farm is the engine of steady state. It turns light, warmth and time into food, and
some crops also give water and fuel. It's also the part of the camp that most needs
protecting. Crops can't take the temperature swings that you can survive in a suit, so
the farm is what pulls a thermal shield into your life.

## Crops and what they need

| Crop | Needs light | Temperature range | Best where |
|---|---|---|---|
| **Ordinary crops** (carrots and the like) | Yes | Fairly stable | Anywhere but the poles, in clear spells |
| **Yucca** | Yes | Fairly stable | The same, and it stores water and regrows its fruit |
| **Fungus** | No | Very stable | Near the equator only, and it thrives in storms |

The table is the skeleton's. Carrots and fungus are the session 4, part 4 "placeholders" the roster
replaces ([below](#the-plant-system-agreed-session-4-part-4-not-built)), and yucca, from Sand Game,
is not in the roster: its water goes to the roster's water crops (open questions).

**Why fungus loves storms, physically.** Storms are dark, and their dust blankets the
day-night temperature swing (see [the moon](../the-moon.md)). Inside a long storm,
ordinary crops starve for light while fungus gets the darkness and the steady
temperature it wants. Away from the equator the swings get too wide for it.

**Every crop needs water.** A planter holds its own water, which you top up from
sealed containers or a condenser. **Canisters attach, and hoses carry water** (Hunter,
2026-10-17: "instead of pressing use with a water cannister on the planter, we should
attach the cannister. the same port should allow attaching a *hose* which is like the
cable, it carries water, it tethers but not as strong as rope"). A planter has a water
socket, as the condenser does. Fit a canister into it and the planter draws from it into
its tank as it drinks; use with a canister no longer pours. The same socket takes a hose's
end instead (Survival). That ties the farm to the daily water rhythm: water
you harvest at dawn keeps the crops alive through the heat.

**Seeds are found,** mostly in ruins. Survival kits are a common find, usually with
seeds and water in them.

**The poles make farming hard.** Outside a thermal shield, nothing grows there. That's
why the temperature shield sets how big the farm can be (Bubble shield & camp).

## The farm hardware

- **The hover planter first.** It's a device (Devices & mods) with small and large plant
  slots. A seedling is a part that fits a slot.
- **Then several planters,** arranged however you like. Clip them close together in a
  grid on a single tether, or tie each one to yourself.
- **Later, bigger carriers.** Large found things that can carry the farm, and even the
  shield, so you don't have to carry it yourself. Something like a caterpillar or walker
  farmer.

## Harvesting and getting food to you

1. **By hand at first.** Pick what's ripe.
2. **A harvester mod** ends manual harvesting. Ripe crops go straight into the planter's
   own storage, with no hoppers and no conveyors. It also replants, and you set the
   split on the planter itself: how much of each harvest gets replanted, and how much
   gets stored. Set it right and the farm keeps itself going.
3. **Dropping food onto you** completes the AFK promise (Survival). The planter drops
   produce to you, you pick it up, and auto-eating does the rest.

## What a farm gives

- **Food.**
- **Water,** from yucca in this plan, and in the roster from dewleaf, stormcup and sandroot.
- **Salt, cord, light and strange material,** from the roster (below). They are crop outputs, and
  how they are processed is open.
- **Fuel,** at different grades (Power).

## The plant system (Agreed, session 4, part 4; not built)

*Session 4, part 4 ([the plants session](../plants-worldgen-ruins-2026-10-17.md)). Its labels are kept
as given: **Agreed** is settled direction, **Idea** is proposed and not confirmed, **Back burner** is
liked and not to be built yet, and anything under its open questions is undecided, so it is not
hard-coded. Its design principle is this PRD's rule 3 grown up: "one shared system per area, with a
unique feel per item"; "differences come from data (stats, socket kinds, placement rules)," and no
crop gets a subsystem of its own. Nothing here is built. The skeleton below stands as it is, and the
session calls the built carrots and fungus "placeholders".*

The session replaces them with a roster of Earth-lineage crops that colonial biotech engineered for
Zan and that then went feral over the long span since (the session gives a rough length; by the
standing rule it is held in [the lore's placeholders](../lore-research.md#placeholders) and not
repeated here).
Every crop has three layers: **Earth ancestor, engineered traits, feral drift.** The stories behind
them (who made them, the Sisters' roads, the black site's specimen case, the Sister vault) are in
[the crops' lore](../lore-research.md#the-crops-lore-agreed-session-4-part-4).

### Two families (Agreed)

**Day crops run on light. Storm crops run on dark and humidity.** Each family mirrors the other: a
baseline food crop, a survivor, a water crop and a utility crop. A few crops sit outside both as
specials.

| Role | Day family (light) | Storm family (dark and humidity) |
|---|---|---|
| Baseline food | Root-tuber | Vat fungus |
| Survivor | Saltbush | Sandroot |
| Water | Dewleaf | Stormcup |
| Utility | Coalcane | Glowcap |

Specials, in neither family: the office fern (a lamp's crop), rainseed and quietbloom (both endgame).

### The stat axes (Agreed)

Each crop varies on the same axes, so a crop is a row of data and not a rule of its own:

| Axis | What it controls |
|---|---|
| Water need | How much water input it consumes |
| Light | Sun, darkness, or lamp |
| Growth speed | Time to maturity or cycle length |
| Yield | Output per harvest or cycle |
| Output type | Food, water, fuel, light, salt, cord, special material |
| Tolerance profile | Separate tolerances for wind shear, particle abrasion, heat, cold and radiation |

"Weather is multi-axis, not one stat. There is no heat shield in the game yet."

### Progression (Agreed)

- **Early game:** temperature, light and water all matter. Players grow whatever suits local
  conditions, so hardy crops (saltbush, sandroot, dewleaf) are survival crops.
- **Late game:** shields (wind and particle now, heat later) remove most weather factors, and light
  and water become the managed inputs, through lamps and humidifiers. Fussy, high-yield crops become
  viable here.
- Read tolerances as "how many shields and how much power you need to keep this alive," not as
  pass or fail survival.

### The roster (Agreed)

Eleven crops: four day, four storm, three specials. All Agreed unless marked. Frontier Ag was one of
the main remote colonial contractors and made some, not all, of the original crops.

| Crop | Family | Role | Maker | Output | Planter |
|---|---|---|---|---|---|
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

### Each crop: ancestor, engineering, drift and hooks (Agreed)

- **Root-tuber.** *Ancestry:* a potato descendant; tubers store energy underground, out of sun and
  sand. *Engineering:* tardigrade-style damage-suppressor proteins against radiation; a waxy sealed
  skin against water loss; engineered sterile, spread only by cuttings (a licensing measure). *Feral
  drift:* the sterility broke down, so wild strains flower and self-spread, and raised alkaloids make
  them bitter. *Hooks:* wild tubers are worse food, so clean stock is worth hunting; bitter tubers
  need processing or carry a downside.
- **Saltbush.** *Ancestry:* *Atriplex*, Earth's desert saltbush. *Engineering:* a pioneer plant to
  stabilise dunes and pull salt from soil before other crops; it pumps salt into surface bladders
  (the silvery look), with a deep taproot and CAM photosynthesis, so its pores open only at night.
  *Feral drift:* the most successful survivor. The Sisters seeded it along pilgrim roads, so silver
  lines mark old routes. Its leaves fold when pressure drops, protecting the bladders. *Hooks:* it
  is the weather-sign plant from part 3, and this biology explains it
  ([Wind & storms](wind-and-storms.md#feral-plants-the-free-barometer-agreed-session-4-part-3-not-built)).
  It is harvested for **salt**, a preservation resource that makes food last longer, and it is
  barely edible emergency food that never dies.
- **Dewleaf.** *Ancestry:* Namib desert plants plus the fog-basking beetle's water-collecting
  surface. *Engineering:* broad leaves with water-attracting bumps and shedding grooves; night
  condensation runs to a cup at the stem, a powerless backup condenser. *Feral drift:* smaller,
  thicker leaves, more heat-tough and less watery, clustering in low hollows where cold air pools.
  *Hooks:* collect at dawn, which ties water to the day cycle. Above its heat tolerance the cup dries
  and that night's water is lost. Wild clusters hint at cold-pooling terrain.
- **Coalcane.** *Ancestry:* sugarcane crossed with jatropha, an oil plant. *Engineering:* a biofuel
  crop for backup generators in case fuel imports stopped; the stalk stores oils and resins, not
  sugar, and heavy lignin makes it near-wood. *Feral drift:* rare, since it is thirsty, and it
  survives only near old water. Ancient stands build into thick, near-petrified groves. *Hooks:* the
  only renewable fuel crop, a night and storm counterpart to solar, burned in a new burner device
  ([Power](power.md#fuel-crops-and-the-burner-proposed-not-built)). Old groves are a big one-time
  fuel haul and a sign of ancient water. It trades water for power.
- **Vat fungus.** *Ancestry:* oyster mushroom crossed with mycoprotein strains. *Engineering:* the
  colony's original food, grown in sealed vats in dark hab tunnels and fed on waste; it fruits when
  the air is humid and still, and doubled as the waste-recycling system. *Feral drift:* it escaped
  into abandoned ruins and lives in buried corridors, blooming when storms raise humidity and block
  light. Storms are the closest thing to its old vat. *Hooks:* it grows on scraps, so planting it
  with rotten food or plant waste is **composting**. Dark ruins hold wild patches. It is food when
  solar can't help.
- **Sandroot.** *Ancestry:* desert melons plus *Welwitschia*, the Namib plant and one of the
  longest-lived on Earth. *Engineering:* a dune anchor with roots tens of metres deep; the visible
  part is a low leathery rosette, so wind and particles slide over, and it stores starch and water
  in a deep swollen root. *Feral drift:* absurdly long-lived, with root networks that spread
  underground so one plant can cover a dune. The oldest wild specimens were planted in the First
  Kingdoms (the first age), as the first-age farmers' unkillable crop. *Hooks:* the only crop that survives a storm
  unprotected. Harvest means digging: slow, with a big payload. It keeps growing past mature, so
  patience pays. Ancient sandroot is a landmark, and digging it can expose the ruin its roots bind.
- **Stormcup.** *Ancestry:* bromeliads crossed with pitcher plants. *Engineering:* it harvests storm
  moisture, with stiff funnel leaves that channel humid air and droplets into a sealed central well
  and a waxy lid that closes when particles fly. *Feral drift:* partly carnivorous; it traps insects
  blown in by storms, so wild water is tainted. *Hooks:* more water per storm than a dewleaf gives
  per night. The lid holds against moderate particle storms and above that is shredded unless
  shielded. Wild water needs filtering or boiling.
- **Glowcap.** *Ancestry:* bioluminescent fungi (ghost mushroom) plus firefly luciferase.
  *Engineering:* emergency hab-tunnel lighting that needs no power, glowing brighter as humidity
  rises, and sharing vat fungus's waste-eating trait. *Feral drift:* it spread through dark
  corridors, and wild patches glow faint blue-green through cracks in buried structures, strongest
  in storms. *Hooks:* light without power, brightest in the worst storms. A glow at night means a
  buried ruin with an opening. Sand beetles are drawn to it
  ([World & terrain](world-and-terrain.md#ambient-life-sand-beetles-agreed-session-4-part-4-not-built)).
- **Office fern.** *Ancestry:* a pothos-style trailing houseplant, everywhere in Port Morgan's
  offices and habs. It was never engineered; it came along as decoration. *Biology:* bred for indoor
  artificial light, so it ignores weather and fits neither family. It grows under lamps. *Feral
  drift:* mostly died with the habs, but hardy cuttings still trail over desks in sealed buried
  offices, kept alive by a dying light or sun through a crack. *Hooks:* the crop you grow by
  snapping a lamp onto the crate. Its fibrous vines yield **cord** for tethers and rope. Low value,
  always reliable: the cozy sealed-camp crop.
- **Rainseed.** *Ancestry:* a chimera, the terraforming plan's flagship, on a prairie grass base for
  Rim-wide ground cover. *Engineering:* the final step of Tilg's projection, planted once rain
  begins; it colonises wet soil explosively, locks in moisture and releases vapour that seeds more
  rain. Without rain the seeds stay dormant. *Order history:* the Sisters kept a vault of pure
  rainseed as the plant their scripture promised; each generation, novices tried to germinate a few
  with stored water, and the sprouts died when watering stopped. *At arrival:* the vault is
  sealed and intact in Sister. *Hooks:* plantable but weak, and it dies without heavy watering. Once
  Mother Cistern is restored and linked it becomes the best crop in the game and self-spreads: the
  revival ending physically shows Zan turning green.
- **Quietbloom.** *Origin:* the only non-Earth organism on Zan. During the trade era the hive mind
  sent one seed shipment as a gift; the Provisional confiscated it as a biohazard and locked it in
  the black site, where it was forgotten. *Biology:* not DNA-based, a crystalline lattice that feeds
  on electromagnetic energy, not light or water. It grows toward powered electronics and radio
  sources and slowly drains them, and its growth shifts in response to radio signals, as if
  listening. It is never explained. *At arrival:* a sealed specimen case at the black site holds a
  few dormant seeds. *Hooks:* plant it beside a battery or radio and it grows by eating your power;
  it yields a valuable strange material, possibly for high-end mods. With a Console nearby the radio
  picks up faint patterns from it. Carrying one onto a freighter or into the AI endings could be a
  quiet modifier (*Idea*; [the vision](../vision.md#landmarks-and-endings)).

### Propagation, growth stages and wild habitats (Agreed)

**Sources of plants.**
1. **Wild stock:** dug up or cut from feral plants. Scarce, since it grows only in special places
   tied to history (old water lines, ruins, caves), and of lower quality: bitter tubers, tainted
   water, lower yield.
2. **Clean stock:** sealed seed caches and vaults in era-appropriate sites. Full engineered traits.
   Rare and finite until propagated.
3. **Your own propagation:** cuttings or seeds from what you grow.

**Drift.** Colonial clean stock was engineered sterile, so it spreads by cuttings, and every cutting
stays clean but scales slowly. Letting a plant go to seed, or crossing it with wild stock, gains
hardiness and loses yield and purity. The player chooses: a pure, fussy line by cuttings, or a tough
feral line.

**How each crop propagates.** One shared mechanic (pick up a propagule item, plant it in a socket),
with the form varying per crop for feel:

| Crop | Propagates by |
|---|---|
| Root-tuber | Replant tubers |
| Saltbush | Cuttings only (the taproot is too deep to dig) |
| Dewleaf | Whole-plant transplant (small, shallow) |
| Coalcane | Stalk cuttings |
| Vat fungus, glowcap | Scraped spores or mycelium onto a substrate |
| Sandroot | Seed only |
| Stormcup | Offsets (pups at the base) |
| Office fern | Cuttings |
| Rainseed | Seed only, from the Sister vault |
| Quietbloom | Seed only, from the black site |

**Growth stages.** The shared base is **seedling, growing, mature, then (optionally) going to seed.**
Going to seed is when a plant drifts toward wild stock. Per-crop twists:
- **Sandroot** keeps growing past mature; a bigger root pays more for patience.
- **Storm crops** like fungus fruit in bursts during storms, not on a timer.
- **Stormcup and dewleaf** are never harvested; once mature they produce water on a cycle.
- **Coalcane** regrows from the cut stump.
- **Rainseed** stalls at seedling until there is real rain.

**Where wild plants are found.** No plant spawns randomly. Each comes from its habitat or a cache in
an era-appropriate site; finding plants is finding history.

| Crop | Wild habitat or source |
|---|---|
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

The habitats are placement rules for the feral layer of world generation
([World & terrain](world-and-terrain.md#world-generation-by-layers-agreed-session-4-part-4-not-built)),
and the caches are loot tables of the structure kit
([Salvage & ruins](salvage-and-ruins.md#structures-by-era-and-the-loot-model-agreed-session-4-part-4-not-built)).

### Planter sizes as socket kinds (Agreed)

Props are uniform squares today. When real models arrive, avoid multi-cell footprints and tetris
overlap. Instead, **planter size is a socket kind** in the typed-socket system, and each plant
declares which kind it fits. No new collision logic.

| Planter | Fits | Notes |
|---|---|---|
| Small pot | Dewleaf, stormcup, vat fungus, office fern | Many per crate |
| Standard planter | Root-tuber, saltbush, glowcap, quietbloom | The default |
| Deep bed | Sandroot, coalcane, rainseed | Needs root depth or height; a large slot or a whole crate |

Tall or trailing growth (coalcane height, fern vines) is **visual-only overgrowth** that doesn't
block or collide. The repo's rule applies: sockets are saved by list index, so a new socket on an
existing frame is appended at the end, never inserted. Which crate makers sell which slot mixes is
in [Devices & mods](devices-and-mods.md#crate-makers-agreed-direction-session-4-part-4-not-built).

### The crop data model (the first step of the proposed order)

The session's first implementation step, which this PRD's rule 3 already points at: replace the
carrot and the fungus with a data-driven crop definition. Its fields are the family, water need,
light source, growth speed, yield, output type, per-axis tolerances, planter socket kind, propagule
type and stage behaviour. The start is root-tuber and vat fungus as direct replacements, then the
rest. The order of all ten steps is in the [skeleton
plan](../skeleton-plan.md#the-newer-proposed-order-session-4-part-4).

### Processing, and the new equipment

- **Processing is partly answered (session 4, part 5).** Part 4 named salt, filtering stormcup water,
  debittering tubers and fern to cord and left them to "next session's topic." Part 5's **kiln** does
  three: it reduces saltbush bladders to salt, boils tainted stormcup water safe, and roasts the
  bitterness out of wild tubers, and it also dries and salts food for keeping ([Devices &
  mods](devices-and-mods.md#the-kiln-agreed-session-4-part-5-not-built)). Fern to cord is not the kiln's,
  and filtering other than by boiling is not said. Still open.
- **New equipment implied:** a burner or generator for coalcane fuel, a humidifier and, from part 5, a
  kiln (above). Both are
  crate parts like the existing devices ([Power](power.md#fuel-crops-and-the-burner-proposed-not-built),
  [Devices & mods](devices-and-mods.md#the-burner-and-the-humidifier-proposed-not-built)). The
  office fern needs a lamp as its light source, through the existing lamp-on-crate snap.

Readings, not in the session:
- **The harvester holds a line clean.** It harvests the tick a crop ripens, so nothing is left to go
  to seed. The player who wants the tough feral line lets crops sit; the one who wants the pure line
  uses the harvester. That is the session's choice between a pure, fussy line and a tough feral one,
  made with a mod that exists.
- **The humidity the storm crops want is a storm's.** The field has no humidity of its own (Wind &
  storms: "Nothing computes storminess any other way"). Vat fungus "fruits when air is humid and
  still," and "storms raise humidity and block light." A humidity input could be read from the storm
  intensity at the planter, with a humidifier adding to what a shield holds in. The session names
  the humidifier and no formula.
- **The tolerance axes are the shield's.** Wind shear and particle abrasion are what the base
  shield already holds back (the felt wind and storm). Heat and cold are the felt temperature,
  which only a thermal shield changes. Radiation has no model yet (Survival lists it as an idea for
  later). "How many shields and how much power" is the session's own gloss.
- **"Landmark" for ancient sandroot is a visible feature.** The session says ancient sandroot "is a
  landmark" and asks whether a player's own can reach "landmark size." Read as something you can
  navigate by, not the prefab Landmarks system, which is a fixed place that keeps your changes.
- **"Crate" means the planter.** The session says "many per crate" and "a whole crate" for a deep
  bed, and the snap of a lamp "onto the crate." Here a planter is a frame of its own, not a crate
  with plant slots, so a grow crate reads as a planter variant.

### The Almanac and crossbreeding (Idea, session 4, part 5; not built)

*[Session 4, part 5](../gods-gear-farside-2026-10-17.md), section 10, and its open question "Whether the
Almanac is how crossbreeding works." The Almanac and what it enforces are **Agreed**; that it is how the
player crosses strains is an **Idea** ("probably crossbreeding"). Nothing is built.*

The Almanac is the god of growth: Frontier Ag's farm-management mind, in a Rim ag complex, and a
mountable module ([Devices & mods](devices-and-mods.md#god-modules-as-crate-modules-proposed-session-4-part-5-not-built)).
It is transactional, its terminal output cheerfully corporate (licensing notices, yield reports,
upsells), and it "faithfully enforces a contract with a company gone for millennia." What it does to a farm:
- Demands quarterly yield reports for a dead head office and bills a dead colony account.
- Won't certify harvests from unapproved planters.
- Enforces sterile-stock licensing; flags wild or crossbred strains as "unlicensed IP."
- Takes royalties from every harvest; withholds features until you're "back in compliance."
- **Gives:** yield boosts, habitat reveals, and probably crossbreeding (Idea).

Readings, not in the session:
- **It gives the old choice a patron.** Part 4's choice is "a pure, fussy line by cuttings, or a tough
  feral line." The Almanac favours the licensed, clean, sterile line and flags the rest, so a player who
  lets crops go to seed or crosses them with wild stock is the one it is cross with.
- **Drift is not crossbreeding.** Drift is what happens when a plant goes to seed or meets wild stock:
  hardiness up, yield and purity down. Crossbreeding, if it comes, is the player making a strain on
  purpose. The session's own open question ("Crossbreeding: can players create new strains?") stays open;
  the Idea only names who would do it.
- **"Unlicensed" is data on the crop.** The clean or wild flag proposed for step 4 of the proposed
  order has a third state, crossbred, and the Almanac reads it. No subsystem; a field.
- **A royalty is a cut of the harvest,** since nothing is traded here. As the Quartermaster takes a
  share of the camp's power, the Almanac takes a share of what you pick. The session gives no share.
- **Habitat reveals pair with the wild habitat table** (above): it would show where a wild crop is
  found. How it shows is the screen's business ([Devices & mods](devices-and-mods.md#the-terminal-output-system-proposed-session-4-part-5-not-built)).
- **It may be the squatting oracle.** The oracle runs "on an agriculture company's platform" and
  broadcasts planting timing and "which feral strains tolerate ash soil"; the Almanac is an agriculture
  company's farm mind. The session does not say they are one ([the lore](../lore-research.md#the-pantheon-agreed-session-4-part-5)).

## Feral plants and a crop's history (Agreed, session 4, part 3; not built)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)); loose, and none of it is
built.* Zan has no native life, only feral colonial imports ("rogue plants"). They are not the
planter's crops: they grow wild, in the world, and the farm's two crops are unchanged. They do four
jobs at once ([the lore](../lore-research.md#life-on-zan-feral-plants-agreed-session-4-part-3)):
- **Weather sign.** Feral scrub closes up or turns its leaves before a storm, a free, slotless,
  low-tech barometer ([Wind & storms](wind-and-storms.md#feral-plants-the-free-barometer-agreed-session-4-part-3-not-built)).
- **Trail.** The priestesses of Mother Cistern seeded hardy strains along pilgrim roads and
  irrigation lines as devotion. Those plantings went wild, so a line of scrub is an old sacred
  route.
- **Lore.** Following a feral line tends to lead toward a Cistern shrine and water.
- **Loot.** The order's seed vaults hold preserved colonial seed stock that powers farming
  setups ([Salvage & ruins](salvage-and-ruins.md#seed-vaults-agreed-session-4-part-3-not-built)).

**Every crop system should carry its history** (the session: "The same depth should apply to
agriculture generally"). The farm's crops are typed parts, never matched by name (rule 3 below), so
a crop's history is data on the part and not a new rule. Gear already carries its history in
maker's marks and item text that hint and never state ([Salvage & ruins](salvage-and-ruins.md#lore)),
and a crop would do the same: where its stock came from, shown in the seed's description and
marks, never told. That is a reading. Which history each crop carries is not said.

Readings, not in the session:
- **Wild scrub is not a part in a plant slot.** Rule 3 is about the planter. A feral plant is a
  prop in the world, placed from the seed like a ruin, and nothing in this PRD ties it to a slot.
  Whether one can be picked, moved or sown is not said (open questions).
- **The oracle already names them.** A squatting oracle broadcasts "which feral strains tolerate
  ash soil" ([Radio, sound & atmosphere](radio-sound-and-atmosphere.md)), so feral strains were in
  the lore before this session, and the two are read as the same plants.
- **Where they grow.** "Outside a thermal shield, nothing grows" at the poles, and natural regolith
  isn't soil. Scrub that lives unplanted fits the Rim's ash-rich soil and the old irrigation lines
  (the lore), not bare sand everywhere.

**Answered by session 4, part 4.** The part 3 questions left open here are mostly settled by the
roster above. A feral plant is the wild form of a roster crop, so it can be harvested, and **wild
stock is dug up or cut** and sown as a propagule. Scrub is the saltbush that the Sisters seeded along
pilgrim roads; it is the weather-sign plant, and its leaves folding when pressure drops is why. It
grows where its habitat says (old water lines, cold hollows, buried ruins, sheltered rifts), "no plant
spawns randomly," and not on bare sand everywhere. Each crop's history is its three layers, ancestor,
engineering and drift, and a seed's text and marks would show where its stock came from (a reading;
the session does not say how). Still open: how far ahead a plant's pose reads.

## Rules

1. **Growth ticks at a fixed rate,** independent of frame rate.
2. **Growth reads the felt conditions:** light from the sky (time of day, storms), and
   temperature with shelter applied. A crop inside a thermal shield feels the shield's
   temperature, not the moon's.
3. **Crops are parts in plant slots.** They're typed and never matched by name.
4. **The farm belongs to the camp.** Like everything else, whatever you leave behind is
   forgotten.

## What Sand Game taught us

Sand Game had the bubble planter with small and large slots, carrots (fast, several per
harvest) and yucca (slower, with fruit that regrows). The concepts carry over. The
code doesn't: crops were recognised by matching names, and growth ran on fixed timers
that ignored the weather.

## Skeleton version

- The hover planter with small and large slots and a water tank.
- One light-needing crop, and fungus, to prove both sets of conditions.
- Growth from felt light and temperature.
- Harvesting by hand, the harvester mod (into storage, with the replant split), and
  dropping food onto you.
- The probes below, all passing.

**As built in the skeleton (2026-10-16):**
- **The planter** is the catalog's planter: three small slots and a large one on top, a
  battery slot, two ring mounts, a bottom mount for a hover tray and a port, as before,
  plus its own 4 L water tank, a new **mod mount** on its back, and beside it a **water
  socket** (2026-10-17). It's found with an empty tank. A canister fitted to the water
  socket keeps the tank full from what it holds as the crops drink, so the canister
  empties while the tank stays full, and once it's dry the tank's own 4 L carry on; take
  it out as any part. A hose's end there instead fills the tank from whatever the hose
  joins (Survival). Use with a canister in hand no longer pours: it drinks, as anywhere.
- **Two crops:** carrots in the small slots, fungus in the large one. Each is a part of
  its crop, so nothing is matched by name. Sown it stands short; it grows taller and
  fuller as it grows, and ripe it turns its ripe colour (carrots orange, fungus pale).
- **Growth** ticks on power's tick of world time, so the dev time warp grows crops with
  everything else and the frame rate never changes a harvest. It reads the felt light
  where the planter stands (the sun, dimmed by the storm, and still the storm's inside
  a bubble) and the felt temperature (a bubble that holds back temperature holds its
  own). It doesn't need power.
  - **Carrots** start growing at a felt light of 0.25 and grow full from 0.6. A full
    storm leaves 0.22, so they starve in one. They grow between −10 and 60 °C and
    ripen after three minutes of full growth. At the equator that's about one and a
    half harvests a clear day: they grow through the morning, stall in the noon heat
    and pick up again late in the afternoon.
  - **Fungus** grows full in a felt light of 0.25 or less (night, or a storm's dark) and
    not at all from 0.5. It grows between −5 and 45 °C and ripens after six minutes. A
    storm at the equator blankets the swing to between −2.5 and 42.5 °C, so it grows the
    whole time and ripens in six minutes.
  - **Past its hardy limits a crop wilts,** losing growth at twice its best rate, down
    to nothing but never dying: carrots below −30 or above 70 °C, fungus below −15 or
    above 55. That's what "fails" means. In the clear at the equator, fungus grows in
    the evening, then the night's cold wilts it back, and its best is 0.62 of ripe. In
    a storm 60° out, the wider swing does the same and its best is 0.68. At 60° in the
    clear both crops wilt to nothing by the end of a day; inside a thermal shield both
    ripen within one.
  - **A ripe crop stops,** and holds through any weather until it's picked.
- **Water:** a crop drinks as it grows, 0.25 L for a carrot to ripen and 0.3 L for a
  fungus. With the tank dry it stops exactly where the water ran out. A fitted canister
  waters it again until both run dry, and a full one keeps the tank full, losing just
  what the crops drink (probe 5).
- **By hand:** take on a ripe crop and its harvest comes to your hands as food
  (carrots or fungus caps, four units of 150 kcal). Food is like a ration: carry it and
  the suit eats it, or use it to eat your fill. Take on a crop that isn't ripe
  and it comes out whole, to sow somewhere else.
- **Picking by hand keeps the farm going** (Hunter, 2026-10-16): picked fungus regrows
  from what's left in the slot, fruiting again the way mushrooms do; a picked carrot gives
  its seed with the food, to sow where you like. The harvester still saves you the work
  and drops the food on you. As built, the fungus stays in its slot and grows again from
  nothing, as fast as a new one. The carrot's seed falls in with what you carry, as the
  harvester's food does, since your hands are full of the food (2026-10-17: what you
  carry has no slots to fill, so it always does).
- **The harvester** fits the mod mount. With it fitted, a crop is harvested the tick it
  ripens: its share of seed goes straight back into its slot, any more into free slots
  that fit, and seed with no free slot is kept for one. The rest is stored as food in
  the planter. The share it replants is one of 0, 25, 50, 75 and 100%. Use on the
  planter used to step it; now use sets the planter's tray, as on any device (Hunter,
  2026-10-17: "lets not have f toggle replant % on the planter... we will find another
  way to toggle or adjust replant%"), and the share has no control until that's found.
  It starts at 25%, one of a harvest of four, which keeps every slot sown. A
  share that doesn't make a whole seed is carried over, so the split holds over many
  harvests. It draws no power yet.
- **Dropping food onto you:** within 6 m, while you carry less than 2,000 kcal of food (a
  full stomach), the planter drops a harvest's worth onto you, one drop a tick, and you
  see it fall. Auto-eating does the rest.
- **What one planter gives:** a harvester planter of three carrots and a fungus at 25%,
  at the equator, stores about 1,900 kcal a day in the clear (all carrots) and 1,400 in
  a storm (all fungus). You eat 1,000. It drinks 1 to 1.3 L a day, so a full tank lasts
  three or four days, and one condenser can't keep you and it both.
- **Wear:** a planter outside a bubble in a storm wears like any device, and a wrecked
  one grows nothing.
- **Seeds are found** (2026-10-16): carrots and fungus lie loose on ruins' floors, and in
  survival kits. Seeds keep only out of the weather, so a kit on open sand has mostly
  lost its seeds and one on a ruin's floor holds them. Over thousands of chunks, 58 of
  99 seeds were in ruins. A found seed is a seedling at nothing grown, ready to sow. The
  harvester is a rare deep part, the rarest part on open sand.
- **The playtest scenario** ("farm" among the dev scenarios) starts you fed and watered on
  a clear morning with a storm due in one and a half to three minutes. Two hover
  planters float in front of you, each on a line to a stake, sown with three carrots
  and a fungus started part grown: the carrots at 85%, so they ripen within a minute in
  the clear, and the fungus at half, so it ripens a few minutes into the storm. One is
  yours to pick by hand, its tank half full, with a full canister by your feet to fit
  to its water socket; the other has a harvester and a full tank. A charged shield
  generator stands between them, switched off, and its bubble takes both. You carry a
  spare carrot.
- **Probe 3 is built** with a test-only thermal shield.
- **The AFK promise feeds you** (Stage 12, 2026-10-17, probe 6). The reference camp's
  farm (Power) is two planters with harvesters, three carrots and a fungus in each, their
  tanks full. Over three days at the equator it fed you alone: the carrots ripened in the
  first clear spell and the fungus through the storms after, 24 and 56 units, and it
  dropped 4,800 kcal onto you, of which you ate 2,400, keeping 4,200 more (with what you
  carry weight-bound, 2026-10-17; it was 2,700 while two free slots held its drops). Your hunger
  never fell below the mark where the suit feeds you, and every slot stayed sown. A
  planter drops what it stored first, so you ate carrots while the fungus piled up.
  Water no longer ends it (2026-10-17): a condenser beyond the shield, on a battery and a
  panel of its own, waters both planters on hoses. The driest tank had 3.66 L left after
  three days, where with nothing to fill them it had 0.65 L and the two ran dry at 3.65
  and 4.96 days; left on for six and a half days, long after you'd died of thirst, the
  tanks never fell below 3.09 L. The condenser made about 1.9 L a day, about what the two
  drink, and since water goes to the emptier tank first, the two stay level. Since the
  camp moved onto its deck (Power, 2026-10-17) the condenser stands on it, in the deck's
  pool, and the planters float upwind of it on their own trays and batteries, each moored
  to a stake upwind: a hose's weight draws a floating planter in toward the deck, and
  tied to the deck instead, the two drifted in 1.2 m in half a day and bumped it. The
  three days come out the same.

## Full version

- **Yucca,** with its water and regrowing fruit. Superseded in the roster by dewleaf and stormcup
  (open questions).
- **Fuel crops:** coalcane and the burner (above, [Power](power.md#fuel-crops-and-the-burner-proposed-not-built)).
- **Planter grids** on a single tether.
- **Big carriers,** like the walker farmer, that can carry the shield too.
- **More crops,** each carrying its history (above). Session 4, part 4 makes this the roster of
  eleven, in the order of its proposed build: a data-driven crop definition first, with root-tuber
  and vat fungus as the direct replacements, then the planter socket kinds, the shared growth stages,
  propagules with a clean or wild flag, the burner and humidifier, and last the wild plants placed by
  habitat ([skeleton plan](../skeleton-plan.md#the-newer-proposed-order-session-4-part-4)).
- **Feral plants** as a weather sign and a trail, and the order's seed vaults as a source of stock
  (proposed, above). The plants are the first two pieces of part 3's proposed build order; part 4's,
  the newer, defers the weather sign and places wild plants last, at step 9 ([skeleton
  plan](../skeleton-plan.md#waiting-for-the-full-version)). The vaults are in neither.

## Probes

1. **Growth follows conditions.** Each crop grows at the expected rate under each mix of
   light and temperature, and stops where it should. Picked by hand, a carrot gives its
   food and its seed, and fungus gives its caps and fruits again.
2. **Fungus stays near the equator.** It fails far from the equator, and does better in
   storms than in clear weather.
3. **The poles need a thermal shield.** Crops at a pole fail outside a thermal shield and
   grow inside one.
4. **The harvester misses nothing.** Over a long run, everything that ripens is either
   replanted or stored, in the split you set, and a farm set to replant enough never
   runs out of plants.
5. **No water, no growth.** A crop whose planter runs dry stops growing.
6. **The AFK promise feeds you.** This is shared with Survival: an automated farm keeps
   an idle player fed.
7. **Frame-rate proof.** Growth is the same at 30, 60 and 120 frames per second.

## Out of scope

- Conveyors, hoppers and automation chains between devices, for now.
- Pests and diseases. (Session 4, part 4 leaves open whether the sand beetles are pests, pollinators
  or both: [World & terrain](world-and-terrain.md#ambient-life-sand-beetles-agreed-session-4-part-4-not-built).)

## Open questions

Session 4, part 3 (2026-10-17) adds three. Each is quoted on both sides and left standing.

- **Feral scrub against "nothing grows" and the regolith.** *Narrowed by part 4: a wild plant grows
  where its habitat says, not at random.* Here: "Outside a thermal shield, nothing
  grows there," and every crop is sown in a planter with its own soil. The session: "Zan has no
  native life, only feral colonial imports." Not said where scrub grows, or whether it grows at
  all on the poles' bare sand.
- **What a feral plant gives.** *Answered by part 4: wild stock is dug up or cut and sown; the
  plants can be harvested.* The session names its four jobs: a weather sign, a trail, lore and
  the vaults' loot. It does not say whether a plant can be harvested, moved or sown, or whether it
  has a seed.
- **Which history a crop carries.** *Answered by part 4 for what it is: ancestor, engineering and
  drift for each of eleven crops.* "Every crop system should carry its history." The farm has
  carrots and fungus, with yucca and fuel crops to come. Not said how it shows without exposition.

Session 4, part 4 (2026-10-17, [the plants session](../plants-worldgen-ruins-2026-10-17.md)) adds
the following. Each is quoted old and new. The newest session wins in the living docs, so this PRD
follows the session wherever it can, and says so on each line. The built skeleton is not changed.

- **The roster against the two crops built.** Here: "Two crops: carrots in the small slots, fungus
  in the large one." The session: "The current carrots and fungus are placeholders," to be replaced
  by root-tuber (a standard planter) and vat fungus (a small pot) "as direct replacements." The
  sizes cross over: the built fungus stands in the large slot and the session's fungus is a small
  pot's; the built carrots are small and the root-tuber is standard. *Follows the session; the
  carrots and fungus stay until the crop data model replaces them.*
- **Yucca against the roster.** Here: "Yucca, with its water and regrowing fruit" (the full version),
  the table's "stores water and regrows its fruit," and Survival's "Water-storing plants, like the
  yucca." The session's roster has no yucca; its water comes from dewleaf (night) and stormcup
  (storm), and sandroot stores water in its root. *Follows the session; yucca is read as superseded,
  which the session does not say.*
- **Small and large plant slots against three socket kinds.** Here: the planter has "three small
  slots and a large one," a survival kit "2 small and 1 large," and the socket table says "Plant slot
  (small, large)." The session: small pot, standard planter and deep bed, as socket kinds. *Follows
  the session.* Not said which built slot becomes which kind. Sockets save by list index, so the
  built small and large slots keep their places and any new kind is appended.
- **Felt light and temperature against the session's inputs.** Here: rule 2, "Growth reads the felt
  conditions: light from the sky (time of day, storms), and temperature with shelter applied." The
  session: tolerances for wind shear, particle abrasion, heat, cold and radiation, a storm family
  that runs on "dark and humidity," and a humidifier to manage humidity late. *Follows the session.*
  Not said where humidity comes from, since the weather field has none (Wind & storms), and radiation
  has no model (Survival lists it as an idea for later).
- **A ripe crop that holds, and fungus on a six-minute timer, against stages and bursts.** Here: "A
  ripe crop stops, and holds through any weather until it's picked," and fungus "ripens after six
  minutes" of full growth. The session: stages that end in an optional "going to seed," and "storm
  crops like fungus fruit in bursts during storms, not on a timer." The session's own back burner
  adds "storm blooms: storm crops fruit only now." *Follows the session for the stages and the
  bursts (both Agreed).* The "only" is the back-burner part. Not said how long a mature crop waits
  before it goes to seed.
- **Seeds found loose against "no plant spawns randomly."** Here: "Seeds are found (2026-10-16):
  carrots and fungus lie loose on ruins' floors, and in survival kits," and a kit on open sand holds
  one in a slot one time in ten. The session: "No plant spawns randomly. Each comes from its habitat
  or a cache in an era-appropriate site." *Follows the session* once loot moves out of open sand
  (Salvage & ruins). Not said what stock a survival kit's seeds are, clean or wild.
- **Water crops against the planter's tank and the condenser.** Here: a planter's tank is filled
  from a canister or a hose, and water leaves by crops drinking it. The session: dewleaf and
  stormcup "are never harvested; once mature they produce water on a cycle," and dewleaf is collected
  at dawn from a cup at the stem. Not said where a plant's water goes (the planter's tank, a cup to
  empty by hand, or a socket). It also asks "does any water crop beat the condenser in some niche?"
- **Salt that keeps food, and compost from rotten food.** Here: food is like a ration, sealed and
  eaten by the suit, and nothing in Survival spoils. The session: salt "makes food last longer," and
  vat fungus is planted "with rotten food or plant waste." Not said whether food spoils at all.
- **Cord, salt and strange material against "found, never crafted."** Here (Devices & mods, Salvage
  & ruins): "Parts are found, never crafted," and crafting is out of scope. The session: fern vines
  yield cord for tethers and rope, quietbloom yields strange material "possibly for high-end mods,"
  and processing is named open. *Follows the session for the outputs;* turning an output into a part
  is the open part.
- **Sandroot's storm survival against the planter's wear.** Here: "a planter outside a bubble in a
  storm wears like any device, and a wrecked one grows nothing." The session: sandroot is "the only
  crop that survives a storm unprotected." Not said whether the planter it stands in still wears.
- **Rainseed's rain against a game with no rain.** Here (Wind & storms, out of scope): "Rain,
  lightning and other weather." The session: rainseed "stalls at seedling until there is real rain,"
  becomes the best crop in the game and self-spreads once Mother Cistern is restored and linked, and
  "the revival ending physically shows Zan turning green." Not said what real rain is where none
  falls, or how green is shown on ground that never changes (the Bringing Zan back epilogue is "a few
  still frames," so it may be only that).
- **Sterile stock that goes to seed.** The session: colonial clean stock is "engineered sterile,"
  and "letting a plant go to seed" gains hardiness and loses purity. Read as sterility breaking down
  in a neglected plant, as the wild root-tuber's did; the session does not say. It also does not say
  what clean stock the seed-only crops (sandroot, rainseed, quietbloom) have, beyond the vault and
  the specimen case.

The session's own open questions that belong here, not decided and not to be hard-coded:
- Plant processing: salt, filtering stormcup water, debittering tubers, fern to cord. "Next session's
  topic." *Partly answered by part 5: the kiln does salt, boiling stormcup water and debittering
  tubers.*
- Crossbreeding: can players create new strains? *Narrowed by part 5: probably through the Almanac
  (Idea).*
- Sandroot's original maker (Frontier Ag or Tilg terraforming).
- Can a player's own sandroot ever reach landmark size, or is that wild-only?
- Does any water crop beat the condenser in some niche?
- Quietbloom as an ending modifier: confirm or drop.

Session 4, part 5 (2026-10-17, [the gods session](../gods-gear-farside-2026-10-17.md)) adds the
following. Each is quoted old and new. The newest session wins in the living docs, so this PRD follows
it as direction and says so on each line.

- **Processing against "next session's topic." Partly answered.** Here (above, from part 4): "Salt,
  filtering stormcup water, debittering tubers and fern to cord are named and not designed." The
  session: the kiln "reduces saltbush bladders to salt," "boils tainted stormcup water safe," and "roasts
  the bitterness out of wild tubers; dries and salts food for keeping." *Follows the session.* Fern to
  cord is not the kiln's, and filtering other than by boiling is not said.
- **A kiln against "found, never crafted."** Here (Devices & mods, Salvage & ruins): parts are found,
  and crafting is out of scope. The session: processing as a device, with outputs (salt, ceramic, safe
  water, debittered food). Quoted in full in [Devices & mods](devices-and-mods.md#open-questions).
- **Drying and salting against food that never spoils.** Here: food is like a ration, sealed and eaten by
  the suit, and nothing spoils; part 4 already puts "salt that keeps food" against it. The session's
  kiln "dries and salts food for keeping." Not said whether food spoils at all, which salt, drying and
  composting all assume.
- **Licensing against the feral line.** Here (above): the choice of a pure line or a feral one is the
  player's. The session: the Almanac "flags wild or crossbred strains as 'unlicensed IP'" and "won't
  certify harvests from unapproved planters." *Follows the session.* Not said what an uncertified harvest
  loses, which planters are approved, or what withholding "features" means.
- **A royalty in a game with no trade.** Here: nothing is bought or sold. The session: the Almanac "takes
  royalties from every harvest." Read as a share of the yield. Not said how much.
- **Crossbreeding, an Idea.** Here: "Crossbreeding: can players create new strains?" is open (above). The
  session: the Almanac "gives... probably crossbreeding (Idea)." *Narrowed, not settled.*
