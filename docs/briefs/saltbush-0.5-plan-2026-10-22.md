# 0.5 Saltbush: the camp lives off the land

*Proposal for Hunter, 2026-10-22. Pre-planning only: no build approval, release commitment,
PRD amendment or vision change. Hunter requested “let's pre-plan 0.5 saltbush”.*

**Proposed outcome:** salvage establishes the camp; growing, processing and repairing let
it endure. Food, water, fuel and maintenance become deliberate renewable budgets rather
than a stockpile countdown. Colonial equipment remains valuable and finite; survival
need not mean manufacturing a replacement civilization.

The [version policy](../version-policy.md) requires a “new named, coherent playable outcome”
with scope and acceptance agreed before release. The [roadmap](../alpha-roadmap.md#release-sequence)
currently calls this “Salvage and farming make the camp progressively self-sufficient.”
Everything selected or recommended below is **proposed**. Quoted PRD direction is existing
agreement, not approval to include every feature in 0.5. Baseline inspected: `9b06631a`.

## Audit corrections before choosing scope

- The agreed roster is **eleven**, not eight: eight day/storm crops plus office fern,
  rainseed and quietbloom. Four are playable: root-tuber, saltbush, vat fungus, coalcane.
- The deep planter, coalcane bundle and burner are built. Reuse them; no second fuel item.
- Wild saltbush already folds before storms. Historical “not built” headings are stale.
- Era stats and repair-material names exist; repair interactions and material items do not.
- The Almanac broadcasts useful crop advice already; its portable farm powers do not exist.
- Near/far-side geography exists, but temperature has no persistent far-side cold-trap term.
- Storm-wear work is being integrated separately. Recheck its landed contract before planning
  repair; do not use this baseline's older whole-device durability as the new specification.

## 1. Repair: a camp that can mend what weather damages

**Agreed direction.** [Devices, Frames by era](../prd/devices-and-mods.md#frames-by-era-agreed-session-4-part-5-not-built):
“All eras interoperate”; eras trade “efficiency vs repairability”. Second-age repairs use
“Grown and gathered: cord, ceramic, saltbush wood”; colonial gear uses “Finite colonial parts only”.
First Kingdoms use metal; skimmer scrap is an existing default, not a newly settled recipe.

**Built:** `game/history/eras.gd` supplies performance, toughness and `mends` data; lineage
survives salvage and saves. Existing wear can wreck a device. New visible storm damage is
SANDGAME's integration dependency, not something this proposal declares landed.
**Needed:** an inspectable damage state, a physical repair action, obtainable material items,
quantities, repair limits and a decision about wrecks. No generic “ordinary salvage” currently
exists as a repair currency. Naming material strings in era data does not supply it.
**Smallest complete path, proposed:** find damaged second-age camp equipment, acquire its
chosen grown/fired repair material, apply it physically, consume that material and restore
measured function. Save/reload both the repaired state and remaining stock. Then demonstrate
one finite colonial repair so efficiency versus repairability is an actual choice.
**Dependencies:** landed storm-wear state; material acquisition and kiln; lossless item/supply
accounting. Set whether `mends` lists alternatives or a combined recipe. Keep era compatibility;
never turn an ordinary repair into an era upgrade or replenish finite parts through unloading.

## 2. Crops: complementary food, water, fuel and useful outputs

**Agreed direction.** [Farming, Two families](../prd/farming.md#two-families-agreed):
“Day crops run on light. Storm crops run on dark and humidity.” [Propagation](../prd/farming.md#propagation-growth-stages-and-wild-habitats-agreed):
“every cutting stays clean but scales slowly”; going to seed gains hardiness and loses purity.

**Built:** `Plant`, `Planter`, `Farm` and `Feral` share crop data, growth, water use, storm
fruiting, harvesting, replant shares, clean/wild flags and history-based wild placement.
Root-tuber/vat fungus feed the player; saltbush yields salt/emergency food; coalcane fuels
an actual burner. Small/standard slots and the deep bed exist. Wild cuttings can be planted.
**Needed:** dewleaf, stormcup, sandroot and glowcap; cyclic plant water collection, tainted
water handling, digging/overmature roots, useful glow; going-to-seed and actual drift.
Current growth clamps at mature: a wild flag and reduced yield are not an evolution system.
Habitat rows for absent catalog crops place nothing; stormcup needs its own placement rule.
**Smallest complete path, proposed:** dewleaf from a real habitat/cache → suitable planter →
night collection → actual drinking or irrigation, with water inputs/outputs measured. Add
stormcup with treatment, sandroot with digging, and glowcap with readable useful light;
exercise propagation through each shared path before calling the eight-crop roster complete.
**Dependencies:** common output/container handling, water ledger, planter access, saved crop
state and bounded feral streaming. Agree a voluntary going-to-seed action or timing, which
crops can drift, and why clean sterile stock can do so; do not silently invent genetics.
**Scope trap:** office fern is the agreed cord crop but is outside the eight. A renewable
cord recipe needs fern + lamp support + processing, or a deliberately narrower repair recipe.
Rainseed/quietbloom bring revival/endgame dependencies and are proposed exclusions from 0.5.

## 3. Processing: one harvest, competing uses

**Agreed direction.** [Power, The kiln and its fuel](../prd/power.md#the-kiln-and-its-fuel-agreed-session-4-part-5-not-built):
“The kiln is a new processing device that burns coalcane.” [Devices, The kiln](../prd/devices-and-mods.md#the-kiln-agreed-session-4-part-5-not-built):
“It is what makes second-age repair possible”; “fires salt-glazed ceramic and sand-glass”.
The colonial electric variant instead runs on power; forge and clay variants burn fuel.

**Built:** burner fuel sockets, timed consumption, saved partial burns and deck power offer
patterns to reuse, not a kiln implementation. Saltbush currently gives salt directly.
No kiln, ceramic recipe, saltbush-wood item or wood-harvesting action exists in this baseline.
**Needed:** feedstock sources, fuel/time quantities, physical input/output handling, portable
processing state, repair outputs and a saltbush wood yield that does not destroy its identity.
Wood is a grown/gathered repair input; no agreed rule says the kiln manufactures wood.
**Smallest complete path, proposed:** obtain a kiln → collect the chosen raw feedstock → fire
ceramic with a real coalcane bundle → repair one weathered part. Fuel spent firing cannot
also power the camp. Bootstrap with a found kiln; separately decide how a clay kiln can be
built without requiring its own fired output first. Next close stormcup's safe-water path.
**Dependencies:** repair recipe selection; renewable cane/water budgets; source and save rules
for raw materials. Fern-to-cord remains undesigned. Drying/salting and composting presume a
food-spoilage/waste model that does not exist; exclude them unless explicitly selected.
Three kiln variants are agreed direction, but one complete variant can prove the release loop.

## 4. Wild saltbush: learn the weather before buying an instrument

**Agreed direction.** [Wind and storms, Feral plants](../prd/wind-and-storms.md#feral-plants-the-free-barometer-agreed-session-4-part-3-not-built):
“a free, slotless, low-tech barometer for players without weather consoles”.
**Built:** `Plant.forecast`, `Feral` and shared storm sampling fold saltbush ahead of local
storms; pilgrim roads carry silver lines. Farming probes 10 and 13 cover planted/wild folding.
**Needed:** ordinary-player evidence that people notice the change, interpret it and reach
shelter; not another weather system. Discovery can still fail if no reachable bush is seen.
**Smallest complete path, proposed:** a new player finds a road-side stand, sees its leaves
close, shelters before the local storm, then returns for a cutting. Observe without a text
lesson or a mandatory quest marker. Tune exposure/readability only if the playtest fails.
**Dependencies:** honest local forecast lead, visible poses in real lighting, safe ruin access,
and current burial/history placement. Do not promise that every spawn has a bush beside it.

## 5. Water across the moon: a reason to prepare, travel and return

**Agreed direction.** [Survival, Water](../prd/survival.md#water): “Frost and dew, harvested in the cold hours.”
Condensers work “better toward the far side”; water “cold-traps as frost and ground ice”.
**Built:** sealed supplies, hose networks, tanks and a powered condenser using felt temperature.
`Condenser.yield_lph` already improves in cold air. Spherical position/local solar time feed
weather, but `Weather.temperature_under` has no permanent near/far thermal or ice distribution.
Hygrometer storm humidity is not currently a matching condenser-production bonus.
**Needed:** harvestable frost/ice, depletion and melt/storage rules, regional thermal/water
balance and safe travel costs. No concrete condenser-upgrade specification was found in these
PRDs: treat upgrades as a candidate requiring Hunter's choice, not a settled tier ladder.
**Smallest complete path, proposed:** one readable cold-hour deposit gives a measured amount
of stored water through a physical collection/melt action; it depletes and survives reload.
Then prove a far-side water expedition pays after travel, heating and storage costs. If this
is outside 0.5, existing condensers plus selected water crops can support the local camp gate.
**Dependencies:** world/thermal design, terrain/history identity and water conservation;
protect existing survival and crops when changing climate. Cold alone must not imply an
unlimited new source. A richer source should not lure an unprepared new player across the moon.

## 6. The Almanac: the crop choice gets a demanding patron

**Agreed direction.** [Farming, The Almanac](../prd/farming.md#the-almanac-and-crossbreeding-idea-session-4-part-5-not-built):
“faithfully enforces a contract with a company gone for millennia”; gives “yield boosts,
habitat reveals, and probably crossbreeding (Idea)”. It takes royalties and flags wild stock.
**Built:** `Gods.ag_complex` chooses a Rim home; `Transmissions._almanac` broadcasts crop advice
from actual conditions/catalog tolerances. This is neither a playable module nor a royalty.
**Needed:** reachable encounter/physical module, saved state, inspectable benefit and cost,
approved-planter/licensing rules and an intelligible refusal. Crossbreeding is still an idea.
**Smallest complete path, proposed:** reach the ag complex, carry/mount the Almanac, grow a
licensed crop and observe one measured yield benefit and explicit royalty; reveal one useful
habitat through the existing map. A wild harvest prompts a short refusal, not a lore dump.
**Dependencies:** common god-module/save contract, crop provenance and harvest accounting,
Console-map integration, one reachable site. Keep survival viable without its permission.
Recommended stretch: useful existing broadcasts support the core milestone without requiring
a complete portable-god framework. No new Walker dependency; coordinate overlaps with Gonk.

## Proposed release boundary and order

**Spaceport:** keep its selected salvage kite, travel/recovery/camp anchoring and navigation
outcome; suit/wrist and origin details remain separate choices in the roadmap. Its name does
not promise orbital travel, Starcom repair or a functioning launch site. Do not hold those
accepted exploration goals hostage to a kiln or the entire crop roster.
**Saltbush core recommendation:** repair + one kiln/material loop + complementary water crops
and propagation; keep the four working crops and burner as foundations. Include the fern if
cord is required for the chosen renewable recipe. Barometer readability is an acceptance check.
**Scope choices:** full eight main crops/drift as a gate or staged expansion; far-side water,
extra kiln variants and portable Almanac as optional additions. All remain proposals.
**Exclude by default:** rainseed/revival, quietbloom/endings, crossbreeding, general crafting,
conveyors, new food spoilage and a complete god-dispatch network. Starcom repair stays deferred.

Build order, only after scope approval: (1) settle materials/repair outcome against landed
wear; (2) close grown fuel → kiln → repair, with reachable bootstrap gear; (3) close plant
water → storage/treatment → farm/player; (4) propagation/drift and remaining selected crops;
(5) selected geography/Almanac additions. Share physical sockets, water/power ledgers and saves.
No workstream should ship only a recipe name whose inputs cannot be obtained in normal play.

## Proposed acceptance: establish, then sustain, then recover

**N = 10 complete local days after setup**, across three fixed ordinary world seeds, with
at least two naturally occurring storms in each observation window. This is a proposed
screen for a renewable budget, not proof of ten-year survival. Hunter must accept N and scope.
Start each run from a fresh profile and normal Surveyor arrival, without dev grants, unlocked
advantages, forced weather or hand-built camp fixtures. Record setup time and every source.
Normal salvage/starting stores may bootstrap hardware and propagules; define a visible start
of the sustain window after the first successful harvest and repair. Record reserve quantities.

During that window, food comes from grown harvests, water from the selected replenishing
sources, and power from sun/wind/grown fuel. Use only self-produced renewable repair stock
for the demonstrated maintenance loop; no new rations, full cells, sealed-water loot or
replacement devices hide a deficit. Finite colonial repair gets its own separate check.
Do not require an entirely grown camp: the equipment and initial seeds were salvaged.

Pass requires player and crops survive clear/night/storm; fuel, food and water accounting
covers actual consumption without progressively draining starting stores; sufficient repair
stock can be replenished between the demonstrated damage events. Expose an ordinary working
part to real weather, then restore measured function by consuming the right material.
If ordinary storms cause no measurable damage within N days, revise the check explicitly;
never inject durability loss and call it a demonstrated maintenance economy.
Save/resume mid-growth, mid-firing and mid-repair; leave/return to Home and cross a streaming
boundary without duplicating outputs, resetting damage or reviving exhausted deposits.

Use focused accounting/failure probes and one connected long-run check, plus unassisted human
play and real GPU captures of growth, damage, repair and processing. A dry bed, empty hopper,
wrong repair input or interrupted firing must have a legible recoverable failure. Broader CI,
platform checks and performance budgets remain release gates; no full suite for this brief.

## Hunter's scope decisions

1. Is 0.5's promise the renewable camp loop above, and does the ten-day acceptance fit?
2. Must all eight main crops and going-to-seed/drift ship, or can the complete loop lead?
   Include office fern for renewable cord, or choose a narrower material recipe?
3. Which physical repair action, material combination and restoration limit should we use?
   Can wrecks recover? How is saltbush wood gathered, and what feeds the first kiln?
4. One kiln variant and ceramic/safe-water paths first, or all three variants/more recipes?
5. Is far-side frost/ice required, or are local water crops/condensers enough for 0.5?
   What concrete condenser upgrade, if any, belongs here?
6. Is a portable Almanac a gate, a stretch, or later? Crossbreeding stays unapproved.
