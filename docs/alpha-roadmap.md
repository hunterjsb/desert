# Toward 1.0 Alpha

Release direction and status, updated 2026-10-20. This is a planning map, not a claim that
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

Use the current accounts in [world-system](world/world-system.md),
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
| [Power](prd/power.md) | Solar/turbine/cells, deck/cable pools, board charging, era boxes/banks, priorities, reference camp and a finite stationary Stoker maintenance burn. | Crop-fuel burner/kiln chain; the Halloran burn is not a portable generator or sustainable fuel loop. Decide tracked solar/heavy generators; do not rebuild existing bank/priority/charging foundations. |
| [Survival](prd/survival.md) | Needs/harms, suit burden, food/drink, condenser/canisters/hoses, death and physical bedroll/ruin-bed sleep. | Thermal suit/travel gear and full frost/dew/open-water rhythm; crop water depends on the remaining farm roster. |
| [Farming](prd/farming.md) | Shared crop data/growth, three crops, typed sockets, feral lineage/habitats, harvest automation and saltbush weather response. | Eight agreed crops, deep-bed hardware, going-to-seed/clean-to-wild details and processors. Keep crossbreeding's Idea status separate from the agreed Almanac role. |
| [Salvage](prd/salvage-and-ruins.md) | Era kits/loot/exposure, walkable ruins, excavation/scrapping/wrecks, nomads, distant signs/glints and Halloran’s bounded First Fire encounter. | Seed vaults/Sister and further ending-linked interactions. Most landmark shells remain without functional encounters; First Fire is not a completed ending. |
| [Radio and atmosphere](prd/radio-sound-and-atmosphere.md) | Signals/broadcasts, bundled weather/god/beacon speech, frequency marks, thirteen satellites, world audio, Walker evidence/teaching, triangulation and living-city lights. | Reputation/pilgrimage/aggro, Walker taking/copying and general god-state interactions. City discovery is not a completed city ending; proposed variants stay proposed. |
| [Profile and saves](prd/profile-and-saves.md) | Run/profile/assembly persistence, Normal/Ironman, deeds/unlocks and five origins including Varran/Archaeologist. | Selected ending axes/flags/completion/unlocks and novelty starts. Steam/cloud are separate integration choices. |
| [Menus](prd/menus-and-ui.md) | Main/system/options/origins/deeds/creative, save flows, themed bars, console access and four-page visual sailing notes. | Input remapping and unassisted onboarding in normal play. Seamless camera drop-in remains deferred. |
| [Endings](vision.md#landmarks-and-endings) | Walker/city discovery, Halloran’s first furnace encounter and landmark/save foundations supply prerequisites; named ending axes remain absent. | Finished routes are not recorded as built. Select the required ladder, then complete destinations, dependencies, conclusions and persistent unlocks. |

### Playable milestones

| Milestone | Playable outcome | Completion evidence |
| --- | --- | --- |
| 0.2.1 patch | Current sand/Nomad work and reported playtest fixes work together. | Combined CI, real trail/rope captures, start/save checks and smoke-tested builds on three OSes. |
| 0.3 “Sanddune” minimum | A new player can travel, sail, salvage and maintain a camp without developer guidance. | Tutorial playtest; explicit line management and understood board/rig speeds; storm preparation and recovery; measured rendering budget. |
| 0.4 “Spaceport” | One-line salvage kite as a defining feature; further navigation and suit work remain candidates, with unfinished Sanddune stretch work eligible. | Demonstrate launch, board travel, recovery and camp anchoring; select the remaining scope and acceptance checks. |
| Camp progression | Salvage and farming make the camp progressively self-sufficient. | Audit remaining crop roster, propagation, processing and equipment against the farming PRD; demonstrate sustainable clear/night/storm power, water and food. |
| Exploration progression | Better gear opens meaningful new journeys across latitude and history. | Audit biome/era loot and thermal gates; complete agreed instrument and navigation dependencies; prove viable trips and returns with ordinary finds. |
| Conclusions | Long runs have discoverable destinations and outcomes. | Choose and implement a coherent ending ladder and its prerequisites; save/resume each route and record completion/unlocks. |
| 1.0 Alpha candidate | Those systems form one understandable, persistent game. | Fresh-profile runs, long-run reliability, accessible controls and menus, supported-platform release gates, then Hunter's playtest acceptance. |

The remaining intermediate rows are dependency groups, not assigned version numbers or dates.
They can be split into named minor releases after their scope is agreed.

### Sanddune minimum and stretch work

**Agreed, 2026-10-19:** the Sanddune outcome above is a bare minimum, with stretch
goals that may ship in Sanddune or move to **0.4 “Spaceport”**. The name Spaceport is
reserved; the later agreement targets its defining salvage kite, while the rest of
its feature scope remains open (see the consolidated register below).

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

## Current playtest follow-up (2026-10-20; in progress)

The verified playtest confirms useful rope reeling/yanking, physical boom
constraints, the delivery scenario, radio stowing, voice clarity and music.
It does not establish easy sailing: skate craft tend to stall and hover
craft circle. Improve force balance through visible craft layout and ordinary
rigging; preserve the player's control and the working physical constraints.

| Next-pass work | Current status and acceptance |
| --- | --- |
| Manual sail hoist | Implemented; all nine Linux groups passed in the isolated playtest candidate, landing and native checks pending: chassis-mounted hand winch, halyard and masthead pulley. Separate sail height from the sheet; hold paid length on release. Starter/scenario and kept Nomad rigs include usable hardware; old saves retain their controls until converted. Unclaimed Nomad rig lines unload with their find and become ordinary saved lines when claimed. |
| Sail removal, board-line detachment and ground-rope recovery | Implemented; all nine Linux groups passed in the isolated candidate, landing and native checks pending. The reported rope endpoint is the board, correcting the initial sail-end report. Pick up loose rope with ordinary actions and preserve attached ends/line identity. |
| Coil recovery and presentation | Implemented; focused pickup, save, reeling and first-tie handoff checks pass; combined CI pending. Loose coils reopen independently of find ownership. Remaining coils follow the active paying end and use shared layered windings, inspected in actual ground and held captures. |
| Clear scenarios and craft naming | Landed; native checks pending. One clear-weather/radio/flare/drone setup, old names as aliases. Delivery craft is “the drone”; Surveyor origin and Guide retain their names. |
| Vault feel | Landed after all nine Linux verification groups passed; native checks and human acceptance pending. Focused checks and the GPU fixture pass. Climb the measured ledge height with continuous travel through rounded corners, retaining obstruction and moving-deck checks. |
| Radio controls and voices | Landed after all nine Linux groups passed; native acceptance pending. Focused checks and 720p captures pass: live control hints only in the tune view, distinct machine voice identities grounded in the gods' lore. Keep the approved weather voice and music. Music follows world time; current speech starts reports on tuning, so a shared continuous speech schedule is not built. |
| Halloran stock and cache | Landed after all nine Linux groups passed; native acceptance pending. Physical pickup, save and migration checks pass: ordinary pickup for visible coalcane; the completed burn unlocks physically preplaced rewards. Check individual claims, locked access, legacy saves and no duplication after return/reload. |
| Halloran models and pipeline | Landed after all nine Linux groups passed; native acceptance pending. Actual GPU captures inspected: homes with constructed openings/repairs and a connected, supported pipeline with physical terminals. |

The 0.2.2 and 0.2.3 tags remain unpublished. Although the bounded 0.2.3
source eventually passed all platform checks, publication was withheld after a
repeated-report interference bug was reproduced. The isolated 0.2.4 playtest
candidate passed all nine Linux groups; its latest playtest exposed coil pickup
and held-rope presentation follow-ups. These corrections require a fresh combined
verification. Distant mountains and post-storm exposure changes have landed
separately; their integration with these corrections is included in that check.
Camp retention, kites and pod starts remain planned.

## Consolidated feature register

This register carries forward the later kite, camp and opening discussions so they
are visible here even while their detailed design records remain on development
branches. It supersedes older claims above that Spaceport has no selected feature.
System PRDs still govern implementation; move the corresponding decisions into
current PRDs before building each feature. No release dates are assigned.

**Status definitions:** **Built** means integrated on verified master, not necessarily
published or installed in the play build. **In progress** means source work or a
prototype exists separately and still needs integration/acceptance. **Planned** means
agreed direction without a complete implementation. **Exploratory** means a possible
design, with its inclusion and details undecided. Release targets express intent;
they do not turn a prototype into a shipping feature.

### 0.3 “Sanddune”: learn, depart, discover, return

Finish more of the ordinary expedition loop before moving to Spaceport. Immediate
fixes may ship as patches on the way to this named minor release.

| Feature | Status as of 2026-10-20 | Target and remaining evidence |
| --- | --- | --- |
| Core travel, modular camp, sailing, survival, salvage, saves and deeds | **Built**, with the limitations in the system inventory above. | Sanddune foundation; continue real playtests rather than treating the presence of each system as a complete expedition. |
| Physical waist-line selection and release | **Built**: carry-view hover/select, selected-line reeling and timed release-all preserving momentum. | Sanddune minimum; keep normal sailing viable while actively controlling one line. Persistent crosshair statistics and gaze selection were rejected. |
| Surveyor's Guide and departure guidance | **Built**: carried physical guide with a short first expedition; current kit is unchanged. | Sanddune onboarding foundation. This does not implement the pod or remove starting supplies. |
| Radio, satellites and drone deliveries (PR #50) | **Built**: merged as `badc8807` after all nine Linux groups passed. Thirteen-satellite sky/broadcasts, frequency marks and flare-called container drops preserve the bundled native voice. All four review repairs are integrated: audible god/beacon data, active-delivery saves, persistent lit/called flares and private radio/satellite effect buses. Receiver controls, carried sound and Console announcements retain their regression coverage. | Native platform and build verification of the merged candidate remains pending. Delivery cargo is currently **empty**; supplies/loot and their balance are not implemented by this work. |
| Halloran’s First Fire | **Built, bounded fragment** on master: a connected Aitch–Crossing–furnace route, three finite preserved coalcane bundles, 30-second maintenance burns, one service cache and the First Fire deed. Stock, fuel consumed, burn expiry and claimed rewards persist. | Streamed hands interactions and save/resume checks pass; native platform verification remains pending. The full city/refinery, rift, crop-fuel loop and destruction ending remain unbuilt. This is an available exploration fragment, not a completed ending. |
| Cheap survey receiver | **Built**: battery-powered directional signals from real ruin beacons, persistent acquisition and Follow the Signal deed. | Sanddune discovery foundation. More receiver tiers remain planned; this is not yet a camp-homing receiver. |
| Salvager's personal shield | **Built**: carried personal shield replaces the former camp shield in this start. | Sanddune start identity; useful and reachable first salvage still needs broader opening playtests. |
| Sailing control and physics corrections | **Built**: sole-line automatic reeling, brief strength-limited yank, Varran stake/layout changes, native freely hinged boom and ordinary routed sheet. Mixed skates/hover/keel support is integrated; scalar trim/angle targets and hidden towing helpers are removed. | Sanddune fixes. Combined Linux, Windows and macOS checks pass, including active sailing, aboard motion and rig save/resume. Unassisted handling, board catch-up/counterbalance feel and player-load acceptance remain playtest gates. |
| Placeable rope hook and player routing | **Built**: removable physical hook fits suitable solid faces and redirects an ordinary line through one guide, preserving line identity, total length, bend load, visible route and save state. | Sanddune control clarity. Real-hand routing and restore checks pass; players still need to learn the interaction in ordinary sailing. Multiple guides per line remain outside this first implementation. |
| Short visual sailing notes and UI consistency | **Built**: four actual gameplay screenshot pages, brief sailing-only captions and shared UI fonts. All pages were inspected at 1280×720: 533×300 px images, two-line 20 px captions and visible navigation. | Sanddune teaching. The separate Surveyor Guide retains its prose pages. Unassisted comprehension and handling acceptance remain; refresh images if the illustrated geometry changes. |
| Deck boarding and exposed wreck traversal | **Built**: sprint/jump ledge vault, exposed wreck panel collision, board-on-roof support and the Hopper ramp repair are integrated and pass all 19 platform/build checks. | Sanddune movement polish. Physical contact, walkable tops and cut openings are covered. Near-level mixed-deck baselines reach 108 pieces; one 16-piece powered boarding and one 27-piece offset-mount battery transition passed. Steep terrain and boarding large mast/rope-loaded craft still need combined coverage and playtesting. |
| Developer playtest controls | **Built**: prevailing wind speed/bearing and reset, plus real held-cell or connected-pool charge controls. Wind drift stays continuous and saves/resumes; commands mark the run as developer use. | Support repeatable Sanddune checks. These do not establish viable ordinary play or unassisted expedition acceptance. |
| Shared terrain residency policy | **Built, foundation only**: terrain construction, collision retirement and object lifetime share the existing player-area rules. Radii, retirement margins, carried/ridden exceptions and freeze/thaw behavior are unchanged. | Sanddune preparation for a second supported area. Full Linux verification and focused origin, seam and camp warning/deletion checks pass. This does not retain a distant camp. |
| Marked camp residency | **In progress**: one claimed Home now retains bounded terrain, collision and history in the integration branch; a 2.1 km trip and distant save/restore pass. | Sanddune expedition priority. Real retained-ruin excavation and duplicate-sheet restoration checks pass. Combined CI, unassisted play and broader simulation/budget acceptance remain gates. At 512 work items graph refresh alone measured 5.6 ms p95 with frozen fixture bodies; this is not full physics/render acceptance. No unlimited moon-wide retention promise. |
| Homing beacon and basic camp return | **In progress**: physical chassis beacon, Surveyor/salvage acquisition and requested carry-view bearing/distance with live or last-known fix. | Sanddune navigation priority leading toward Spaceport. One Home, 1 W, 2 km initial reception; integration and playtest acceptance pending. No permanent minimap or automatic terrain survey. |
| Continued-release line gathering and batch mooring | **Exploratory**: continue the existing untie action to collect separate ends in hand, then tie or drop them together. | Sanddune control candidate, not an implemented “stake all” shortcut. No dedicated binding; preserve each line's length, load and identity. Decide hand/bundle and tie/drop behavior first. |

The integrated sailing and wreck state at `2bcba651` passed all 19 jobs in
[combined verification](https://github.com/hunterjsb/desert/actions/runs/39480273621),
including native Windows/macOS probes, three-platform exports and build smoke checks.
The same fixed-sheet fixture reached 2.907/2.908/2.908 m/s at 30/60/120 Hz;
the four-minute gust/turn/seam/origin-shift check passed without relaxing its
existing motion bounds. These controlled results establish the integrated
regression baseline; Hunter's unassisted playtest remains the acceptance gate
for sailing feel and the complete expedition. Detailed measurements and limits
remain in the movement, rope and menus PRDs.

The radio/delivery integration and subsequent terrain-policy extraction passed
all nine Linux groups in their respective [radio](https://github.com/hunterjsb/desert/actions/runs/39488290224)
and [terrain](https://github.com/hunterjsb/desert/actions/runs/39489022676) verification runs.
Native platform and build acceptance of the latest code remains pending in
[master verification](https://github.com/hunterjsb/desert/actions/runs/39490654541).

The marked camp should include its attached chassis assembly and claimed loose
belongings inside its attached shield's configured envelope. Shield shutdown or a
brownout must not erase membership. Support connected stakes, ropes, guides and
gear extending outside the bubble without claiming untouched salvage. Resolve
membership changes, distant terrain/collision, origin precision, weather, power,
farming, save/resume and a bounded simulation budget. Full-detail distant rendering
is not required; simply preventing item deletion is not sufficient.

Repair/salvage progression, one complete farming/processing chain and further
navigation remain the stretch candidates listed above. They can move to Spaceport;
the full crop roster is not a Sanddune gate.

### 0.4 “Spaceport”: one-line kite and the next exploration layer

| Feature | Status as of 2026-10-20 | Scope and remaining evidence |
| --- | --- | --- |
| Salvage kite | **In progress**: isolated prototype and verification exist; not integrated or accepted as finished. **Agreed Spaceport defining feature.** | Found, contained light rig using existing rope/attachment systems. One controllable tether, item-owned bridle, board/rider as keel and counterbalance. Wind, line length and rider position govern flight; looking around must not secretly steer it. |
| Kite at camp | **Planned** as part of the same kite feature. | Tie it to camp as a moving decorative landmark with possible small pull. Demonstrate launch, board travel, reel/recovery, camp anchoring and finding it again from a nearby dune. Weather and terrain may still obscure it; it complements electronic navigation. |
| Wind-powered board energy behavior | **Planned requirement**, existing motor/hover accounting is a foundation. | Wind supplies propulsion; hover/equipment still draw power and powered catch-up remains available. Measure energy under real towing, steering and motor assistance rather than assuming speed alone determines draw. |
| Camp navigation equipment and receiver progression | **Planned direction**, with the cheap survey receiver already built. | Extend the Sanddune camp-return foundation; select additional tiers and supported signals without replacing the existing radio. Starcom expansion is a possible later connection, not a built quest dependency. |
| Suit and wrist instrument | **Exploratory Spaceport candidate**. | Carry-view equipment could give the headlamp, harness, protection and beacon receiver physical homes. A wrist field instrument could show self and known beacons on an initially blank/no-data display instead of a permanent minimap. No full HUD rewrite, fixed device or extra survival meter is approved. |

Multi-line kite controls are outside the first kite. They require a deeper control
design and quicker line selection before adoption. Suit battery costs, upgrades,
physical storage limits, radiation/atmospheric protection and the HUD's eventual
relationship to equipment need separate design decisions. Existing baseline
protection remains unchanged. “Spaceport” does not itself commit to a functional
spaceport destination or an orbital travel system.

### Meaningful arrivals and repeat runs — release placement undecided

These are preserved commitments and ideas, not implicit Sanddune or Spaceport
release gates. Select a bounded slice and its release explicitly after design.

| Feature | Status | Intended experience and open decisions |
| --- | --- | --- |
| Surveyor pod arrival | **Planned, agreed direction**; guide-first step is already built. | Arrive for a purpose, crash-land in a pod, dismantle recoverable structure into the chassis and travelling camp. Use normal physical assembly. Design landing presentation, pod layout, recoverable parts, carried supplies, site placement and saving during arrival/teardown. Do not remove today's starter kit before the replacement works. |
| Starter camp cloth sail | **Planned candidate**, not built. | A small cloth in the existing frame makes the first camp a sailing toy and teaches the wind. Define fitting and balance before adding it to an opening. |
| Seeded pod/loadout variation | **Planned direction**. | Vary circumstances and usable pieces while retaining agency, origin identity and essential survival. Preserve the resolved opening through save/resume; loading must not reroll it. |
| Deed-unlocked origin variants | **Planned direction**, exact model undecided. | Reuse deeds/profile unlocks for selectable variants within an origin; favor tradeoffs rather than strictly stronger kits. Define concrete variants, actions and unlocks at implementation. |
| Salvager's first salvage opportunity | **Planned direction**, existing seeded wreck-field placement is a foundation. | Start near varied ruins/wrecks whose reachable, useful finds shape the first home. Check actual access, hazards and viability rather than proximity alone. |
| Other origins' meaningful arrivals | **Planned direction**. | Give each an appropriate reason, situation and physical equipment source; do Surveyor first rather than copy its pod to every origin. |
| Choices during descent | **Exploratory, back burner**. | An optional way to express opening variation. No decision interface or random reward selection is approved. |
| Tinkering with a carried radio or console while travelling | **Exploratory future interaction**. | Existing instruments are the foundation; select useful interactions and availability without requiring late equipment to make the opening interesting. |

### Beyond these releases

Keep the broader inventory and full Alpha audit below active: sustainable farming
and processing, repair and equipment progression, thermal travel, richer exploration,
god/module interactions and a selected set of actual conclusions. Their dependency
groups remain unnumbered until their release scope is chosen. Input remapping,
accessibility, persistence, performance and supported-platform acceptance apply
throughout. A named release is complete only when its combined playable outcome
passes, not when every branch has a commit.

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
   and era stats ([world system](world/world-system.md)). Almanac crossbreeding is an
   idea; the Almanac's god, module, yield and habitat role are agreed in the
   devices PRD. Audit those separately rather than treating all Almanac work as optional.
3. **World and weather:** reconcile [world](world/world-system.md),
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
