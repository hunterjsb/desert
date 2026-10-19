# Toward 1.0 Alpha

Proposed release scope, 2026-10-19. This is a planning map, not a claim that
everything below is built or approved for implementation. The vision and each
system's PRD remain the design sources. A full Alpha means a complete playable
game loop with progression and conclusions; final art and final balance can follow.

## Version policy

- Fix releases increment the patch: **0.2.1-alpha “Sailboat”** is published.
- Named alpha sub-releases increment the minor and reset the patch. Reserve
  **0.3 “Sanddune”** for the next such release, followed by **0.4 “Spaceport”**.
- **1.0.0-alpha** marks the full Alpha gate below. It is still a pre-release.
- Each release needs accurate notes and Linux, Windows and macOS builds from the
  same verified commit. A version change alone does not publish a release.

## Existing foundation

The travelling shield, modular chassis, shared power, ropes, survival, farming,
salvage, boards, sailing, radio, saves and deeds already exist in playable form.
Generated history, era-specific structures, loot and feral plants also have
as-built accounts. They need completion and playtesting, not replacement.

Use the current accounts in [world-system](world-system.md),
[profile and saves](prd/profile-and-saves.md#starts-on-the-chassis-and-two-new-kits-agreed-2026-10-18-spec-built),
and [farming](prd/farming.md#as-built-the-feral-layer-2026-10-18).
The [skeleton plan](skeleton-plan.md) records earlier stage gates; its waiting
statuses are historical and must not be used as a current inventory.

## Release sequence

### Current inventory

This uses current as-built accounts rather than historical “not built” headings.
The remaining column identifies work and decisions; it does not approve every
proposal for Alpha. The release sequence below chooses outcomes from this inventory.

| System | Built now | Remaining work or scope choice |
| --- | --- | --- |
| [World and terrain](prd/world-and-terrain.md) | Streaming dunes, stable origins/spherical travel, generated history/paths/sites, sand and tracks. | Destination-specific landforms/interactions; decide shifting dunes and ambient creatures. Full landmark interiors remain excluded. |
| [Wind and storms](prd/wind-and-storms.md) | Weather field, visible walls/lee, forecasts/instruments, anomalies, vents/plumes/rumbles, exposure and archaeology. | Finish agreed storm-planning crop/repair dependencies. A condenser humidity-yield boost remains proposed. Forecasts, sleep, audio and saltbush's barometer already work; deferred mechanics stay deferred. |
| [Shield and camp](prd/bubble-shield-and-camp.md) | Travelling protection, load/collapse, radar auto-on and Varran personal shield. | Thermal/combo protection and nested late-game setups. Do not confuse the working personal shield with older carried-shield proposals. |
| [Movement](prd/movement.md) | Foot traversal, boards, dig/carve/tumble, skate rigs, yacht/helm/keel and board-as-keel sailing. | Finish current load/control playtests. Patrol-board superchassis is an agreed unbuilt direction; select whether mechanical haulers/carriers belong in Alpha. |
| [Rope](prd/rope-and-tethering.md) | Stakes/hooks/waist ties, load/breaking/drag, reeling/towing, physical sheet/bridle and selected-line handling. | Upgrade/anchor variety and winch automation; settle player-load behavior from playtests. Reeling itself is built. |
| [Devices](prd/devices-and-mods.md) | Sticky chassis/frame assembly, pooled mass, Console/screens/sensors, radar/sieve, mast gear, lineage/era stats. | Repair actions/materials, per-part wear and agreed filtered Map page. General god modules/state/dispatches are a separate incomplete package. |
| [Power](prd/power.md) | Solar/turbine/cells, deck/cable pools, board charging, era boxes/banks, priorities and reference camp. | Crop-fuel burner/kiln chain. Decide tracked solar/heavy generators; do not rebuild existing bank/priority/charging foundations. |
| [Survival](prd/survival.md) | Needs/harms, suit burden, food/drink, condenser/canisters/hoses, death and physical bedroll/ruin-bed sleep. | Thermal suit/travel gear and full frost/dew/open-water rhythm; crop water depends on the remaining farm roster. |
| [Farming](prd/farming.md) | Shared crop data/growth, three crops, typed sockets, feral lineage/habitats, harvest automation and saltbush weather response. | Eight agreed crops, deep-bed hardware, going-to-seed/clean-to-wild details and processors. Keep crossbreeding's Idea status separate from the agreed Almanac role. |
| [Salvage](prd/salvage-and-ruins.md) | Era kits/loot/exposure, walkable ruins, excavation/scrapping/wrecks, nomads and distant signs/glints. | Seed vaults/Sister and ending-linked interactions. Generated site shells are not yet functional ending destinations. |
| [Radio and atmosphere](prd/radio-sound-and-atmosphere.md) | Signals/broadcasts, weather voice, world audio, Walker evidence/teaching, triangulation and living-city lights. | Reputation/pilgrimage/aggro, Walker taking/copying and general god-state interactions. City discovery is not a completed city ending; proposed variants stay proposed. |
| [Profile and saves](prd/profile-and-saves.md) | Run/profile/assembly persistence, Normal/Ironman, deeds/unlocks and five origins including Varran/Archaeologist. | Selected ending axes/flags/completion/unlocks and novelty starts. Steam/cloud are separate integration choices. |
| [Menus](prd/menus-and-ui.md) | Main/system/options/origins/deeds/creative, save flows, themed bars, console access and scenario sailing booklet. | Input remapping and unassisted onboarding in normal play. Seamless camera drop-in remains deferred. |
| [Endings](vision.md#landmarks-and-endings) | Walker/city discovery and landmark/save foundations supply prerequisites; named ending axes remain absent. | Finished routes are not recorded as built. Select the required ladder, then complete destinations, dependencies, conclusions and persistent unlocks. |

### Playable milestones

| Milestone | Playable outcome | Completion evidence |
| --- | --- | --- |
| 0.2.1 patch | Current sand/Nomad work and reported playtest fixes work together. | Combined CI, real trail/rope captures, start/save checks and smoke-tested builds on three OSes. |
| 0.3 “Sanddune” minimum | A new player can travel, sail, salvage and maintain a camp without developer guidance. | Tutorial playtest; explicit line management and understood board/rig speeds; storm preparation and recovery; measured rendering budget. |
| 0.4 “Spaceport” | Next named minor release; scope remains to be selected, with unfinished Sanddune stretch work eligible. | Agree its playable outcome and acceptance checks when selecting scope. |
| Camp progression | Salvage and farming make the camp progressively self-sufficient. | Audit remaining crop roster, propagation, processing and equipment against the farming PRD; demonstrate sustainable clear/night/storm power, water and food. |
| Exploration progression | Better gear opens meaningful new journeys across latitude and history. | Audit biome/era loot and thermal gates; complete agreed instrument and navigation dependencies; prove viable trips and returns with ordinary finds. |
| Conclusions | Long runs have discoverable destinations and outcomes. | Choose and implement a coherent ending ladder and its prerequisites; save/resume each route and record completion/unlocks. |
| 1.0 Alpha candidate | Those systems form one understandable, persistent game. | Fresh-profile runs, long-run reliability, accessible controls and menus, supported-platform release gates, then Hunter's playtest acceptance. |

The remaining intermediate rows are dependency groups, not assigned version numbers or dates.
They can be split into named minor releases after their scope is agreed.

### Sanddune minimum and stretch work

**Agreed, 2026-10-19:** the Sanddune outcome above is a bare minimum, with stretch
goals that may ship in Sanddune or move to **0.4 “Spaceport”**. The name Spaceport is
reserved; its feature scope is open.

The minimum has three connected acceptance goals:

1. **Confident sailing:** players understand which line they select, tie, reel and
   release, and can predict board assistance and player loads. Settle remaining
   load and control decisions in the movement and rope PRDs before implementation.
2. **Learning through objects:** the sailing notes, streamer and other in-world
   teaching let a new player learn without developer guidance.
3. **A complete expedition:** from a fresh profile, leave camp, find salvage,
   prepare for and weather a storm, return and improve the camp without the dev
   console. Save/resume must preserve the journey.

These goals must work together. Stretch work can enrich Sanddune after the
minimum is secure; unfinished stretch goals can move to Spaceport without
blocking Sanddune.

**Proposed stretch candidates, pending scope selection:**

| Candidate | Playable benefit | Dependencies to settle |
| --- | --- | --- |
| Repair and salvage progression | A recovered part can be maintained and earns its place in the camp. | Devices PRD repair acts/materials and era tradeoffs; choose one complete path. |
| A farming and processing chain | Growing something new makes the camp more self-sufficient. | Choose crops, planter hardware and processing from the farming/devices PRDs as a usable chain. |
| Navigation and discovery | Players can plan a salvage trip and find their way through it. | Agreed Console Map page and instrument/world dependencies. |

These are candidates for prioritization, not an implementation commitment or a
requirement to finish the full crop roster in Sanddune. Each selected goal needs
its system design decisions and a concrete playtest outcome before work begins.

## Scope audit before committing the full Alpha

1. **Camp and movement:** reconcile remaining full-version work in
   [movement](prd/movement.md), [rope](prd/rope-and-tethering.md),
   [devices](prd/devices-and-mods.md), [power](prd/power.md),
   [survival](prd/survival.md) and [shield](prd/bubble-shield-and-camp.md).
   Resolve multi-line selection, reeling and safe player loads from playtests.
   Keep the vision's standard board/towing rule explicit.
2. **Ecology and economy:** mark each agreed crop, propagation rule, processor,
   planter and salvage tier built/partial/missing from
   [farming](prd/farming.md) and [salvage](prd/salvage-and-ruins.md).
   Eleven crops are agreed while three are built; complete the agreed roster,
   clean-to-wild/going-to-seed rules and missing deep-bed frame. Track the kiln,
   burner, humidifier and water-producing crops as sustainability dependencies.
   Repair actions and materials are still unbuilt despite implemented gear lineage
   and era stats ([world system](world-system.md)). Almanac crossbreeding is an
   idea; the Almanac's god, module, yield and habitat role are agreed in the
   devices PRD. Audit those separately rather than treating all Almanac work as optional.
3. **World and weather:** reconcile [world](world-system.md),
   [terrain](prd/world-and-terrain.md) and [storms](prd/wind-and-storms.md).
   Protect the single terrain truth, stable origins, deterministic history and
   bounded residency while extending exploration. Audit landmark landforms and
   only the persistent interactions/interiors required by the selected ending
   routes; full landmark interiors are explicitly outside the current world
   system's scope. Audit the full water rhythm and thermal suit/travel gates
   explicitly; generated history alone does not complete these packages.
4. **Endings:** the [vision's ladder](vision.md#the-ladder) describes several
   agreed and proposed outcomes, modifiers and prerequisites; it is not a built
   campaign. Select the required Alpha routes explicitly. Audit the observatory,
   radio/god interactions, far-side access, nomad reputation and world-clock
   dependencies before estimating them. The Walker quest and city have built
   accounts; the general god module/state/dispatch framework, Cistern restoration
   and links, and offstage axes need separate dependency audits. Proposed variants
   stay proposed. Deferred hoppers, orbital strikes and forgery are not implicit
   Alpha promises.
5. **Persistence and presentation:** complete the agreed progression in
   [profile](prd/profile-and-saves.md), [menus](prd/menus-and-ui.md),
   [radio](prd/radio-sound-and-atmosphere.md) and [art direction](art-direction.md).
   Define save compatibility per release and preserve unreadable saves safely.

## Full Alpha acceptance gate

- An unassisted new player can learn the core loop and recover from ordinary
  mistakes without the dev console.
- Hybrid, board-focused and stationary play remain viable within their intended
  tradeoffs; a sustainable camp earns the AFK promise through day/night/storm.
- Progression from common salvage into demanding regions has no missing mandatory
  item or unreachable dependency; the selected endings can actually be completed.
- Save/resume preserves camp assemblies, ropes, crops, progression and world state;
  death and Ironman behave consistently.
- Targeted regression checks, full CI and native platform build/smoke jobs pass.
  Real captures and representative long play sessions validate motion, readability,
  performance and memory behaviour that headless checks cannot establish.
- Release notes distinguish implemented scope, limitations and save compatibility.
  Hunter plays the candidate and accepts the full Alpha milestone.

Next planning step: turn the scope audit into a checked built/partial/missing table
with the required ending routes chosen. This proposal does not schedule every
loose lore idea or promise a release date.
