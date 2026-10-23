# Saltbush: material for the post-Spaceport revisit

*Prepared 2026-10-22 for SANDGAME to hold until the 0.4 tag. Not a presentation,
selected scope, acceptance gate or build instruction. Sources below own decisions;
all release combinations and dependencies here are proposals.*

Hunter: “so this raises what is the p&a? we will revisit it after the spaceport release.”
The [roadmap](../alpha-roadmap.md#saltbush-promise-and-acceptance-deferred-2026-10-22)
keeps 0.5 open. “It is not. Farming is not promised.” The ten-day sustain gate was
rejected; neither the Saltbush name nor existing crop code reinstates it.

## Material on the table

- **Mother Cistern and agriculture.** [Farming](../prd/farming.md#agricultural-depth-before-variety-and-portable-gods-selected-2026-10-22), Hunter:
  “no, ag depth and the ag complex is needed first. the mother should probably come first tbh.”
  Mother-before-Almanac is tentative, not an approved Mother quest or 0.5 assignment.
  “loop first, variety later. variety can be introduced as-needed for bigger systems for now.  we also deferred repairs.”
  The complex and advice broadcasts exist; portable Almanac remains later.
- **Four kilns and coalcane.** [Devices](../prd/devices-and-mods.md#four-kiln-forms-selected-2026-10-22), Hunter:
  “a col. electric kiln that fits on a chassis, a skimmer era modified version of the col kiln to draw less power but slower output, a mounted, large first era kiln made from a repurposed colonial item such as a mech repair cauldron or he3 reactor, a middle size clay feudal kiln in a feudal forge. we can have the second two burn coalcane.”
  Found in uncovered ruins; only colonial/skimmer hosts travel. The four forms are
  selected direction, not built. “coalcane is a go” ([Farming](../prd/farming.md#coalcane-chain-agreed-2026-10-22))
  already yielded the grow → harvest → burner chain; kilns need a useful input/output.
- **Repairs/raw materials.** [Devices](../prd/devices-and-mods.md#repairs-and-era-mobility-selected-2026-10-22):
  “sorry once again defered. we dont really have raw materials in this game.”
  Reopening them requires an explicit decision, not an assumed dependency of kilns.
- **Near/far side beyond appearance.** [World](../prd/world-and-terrain.md#near-and-far-side-readability-selected-2026-10-22):
  “We shouldnt require far side expositions for water/ice yet but should at least start to visually differentiate between the two side somehow”.
  The held look-test is a visual foundation, not approval of cold traps, ice collection
  or changed climate. Any further gameplay difference needs its own outcome.
- **Suit and pack.** [Menus](../prd/menus-and-ui.md#combined-inventory-direction-and-first-module-selected-2026-10-22):
  “start with headlamp. tarkove-style visual layour of your gear in tab.” Timing: “after”.
  On the [first slice](suit-first-slice-2026-10-22.md): “1. yes 2. optional 3. yes 4. yes”.
  Approved order: headlamp/gear layout → set-down pack → broader harness/carry view;
  optional ship fitting, protected starter lamp and compatibility grants. Pack feel:
  “C. needs to feel really good and snappy and white is open you can see the objects physically.”
  “white” is read as “while”; exact mechanics and release allocation remain open.
- **Later hardcore layer.** [Survival](../prd/survival.md#rest-food-and-drink-support-exploration-selected-2026-10-22):
  “deep starvation if left at low levels for 2+ weeks and acute thirst after a few days, along with macronutrient systems as buff/debuff modifiers.”
  These are later ideas, not selected timers; Spaceport's deliberate stamina buffs
  must not quietly become another early race against hunger.

## Three possible promises — none preferred or selected

| Candidate promise | Release it would make; exclusions | Depends on what Spaceport leaves behind |
| --- | --- | --- |
| **“Your equipment becomes something you wear and unpack.”** | Headlamp first slice plus a snappy physical pack; broader harness follows in the approved order. No required farming, kiln, Mother quest or hardcore layer. | Ship/pod persistence, existing holding and weight carry, stable rest-buff HUD. Needs actual pack interaction/recovery design and compatibility tests. |
| **“Old waterworks give you a new reason to travel.”** | A bounded Mother Cistern encounter, with an explicitly chosen water benefit. Portable Almanac, full crop roster, mandatory far-side ice travel and hardcore needs stay out. | Navigable expeditions, real sites, water containers/hoses and camp power. Needs an audit of Mother-specific behavior and a chosen discovery → interaction → useful result; no ending or portable god implied. |
| **“A ruin's furnace turns a find into something useful.”** | One complete kiln processing loop using the selected era forms; choose which forms ship. Repairs, raw-material gathering and farming remain out unless separately reopened. | Coalcane fuel, real power, ruins and cargo mobility. Needs obtainable inputs and an output worth the trip; cannot promise a ceramic repair loop while repairs remain deferred. |

## Questions to ask after release

1. Which one playable outcome should define 0.5, or what different outcome is missing?
2. For that outcome, what must a fresh player actually do, obtain and retain after
   save/resume to pass? Choose test worlds, journey/duration and failure conditions
   then; do not reuse the rejected ten-day gate.
3. Which boundary is essential: pack now or headlamp only; Mother's precise benefit;
   or kiln recipe and required forms? What can wait without breaking that outcome?
4. Should repairs/materials, deeper agriculture, near/far gameplay differences or
   hardcore needs remain deferred? Reopen only a named dependency with its own design.
