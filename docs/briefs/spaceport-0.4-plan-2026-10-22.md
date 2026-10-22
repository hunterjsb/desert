# 0.4 Spaceport: a wind-powered expedition that comes home

*Proposal for Hunter, 2026-10-22. Docs only. Existing agreements are identified below;
release scope, acceptance numbers and recommended deferrals remain proposed.*

SANDGAME suggests “you can go far and find your way home”. That is a useful direction,
but Home already promises return navigation and a persistent camp. Spaceport needs a
new playable outcome: **find a salvage kite, travel under wind with useful cargo, land
and recover it, and find your living camp again through honest signals and landmarks.**
The wind changes the expedition's power budget and handling; the trip brings something
worth carrying home. A wrist display can support that journey without defining it.

The [roadmap](../alpha-roadmap.md#04-spaceport-one-line-kite-and-the-next-exploration-layer)
selects the one-line salvage kite as Spaceport's defining feature. It explicitly does
not promise orbital travel or a working launch site. This brief does not change that
agreement or the [version policy](../version-policy.md), and authorizes no implementation.
Baseline inspected: `fdd24400`. DESERT owns the forthcoming salvage-kite implementation.

## Existing foundations, not new release promises

- Marked Home, a requested bearing/distance view and live versus last-known fixes exist.
  The camp remains simulated while away; a beacon is not protection against storms.
- Console Map now has weather, survey and navigation filters. The sailing aid remains
  separate in-flight work; a proposed ideal sheet/heading is not already on master.
- The directional survey receiver finds real ruin beacons. It is not a broadcast radio,
  compass, map or interstellar transmitter.
- Crystal sets and field radios, FM/SW converters, reels and an **antenna kite** exist.
  The former tier-2 survey broadcast set was retired. The roadmap's older tier inventory
  is stale; a further tier needs a purpose, not another body with a higher number.
- The antenna kite improves reception; it is not the agreed salvage traction kite.
  Likewise, the older sail-and-chassis “kitesurf” rig is not proof that this item is done.
- Surveyor arrival already has seeded pod survival and physical recovered equipment.
  Randomization exists; deed-unlocked variants within an origin are a different feature.

## 1. Salvage kite: one contained rig, one controlled line

**Hunter's words, 2026-10-20 kite discussion** (verbatim excerpts supplied by SANDGAME):
“it's like its own little rig, contained, so like a super light version of a rig.”
“So just like you'd be the keel of your hoverboard, you could be the keel of this kite.”
“But no, I probably like one line”; later, “I think kites can probably go in Spaceport.”
The roadmap records the resulting agreed defining feature, beyond that tentative last line.

**Built:** board grip, sail forces, physical ropes, attachment/reeling, wind and terrain
are foundations (`game/board`, `game/sail`, `game/rope`). The roadmap reports an isolated
prototype; the inspected master has an antenna kite, not a catalog salvage traction kite.
**Needed:** a discoverable traction rig, flight/bridle balance, one-line player control,
launch, useful towing, landing, recovery and persistence through each physical state.
**Smallest complete path, proposed:** find it in reachable salvage, carry and attach it,
launch in suitable wind, tow a loaded board to a nearby ruin, land, salvage and return.
The item's internal bridle is its own rig; ordinary play manages one tether. Looking
around must not steer. Crosswind travel, loss of tension and grounded recovery must read
through the body, line and wind rather than a hidden flight mode.
**Dependencies:** DESERT's physical implementation; ordinary hands/rope controls; real
mass, collision and power accounting. No new tether system or flight-only save format.
Physical failure may cost an expedition, but a routine landing must not require a reload.

## 2. Wind-powered board: spend less propulsion energy, still pay for equipment

**Hunter, same discussion:** “Kite-powered board is such a good idea. And honestly, we
should make if you're on the board and being pulled by the wind, it should not really
take much battery.” This is part of the kite outcome, not a second milestone feature.
**Built:** `Board`/`Ride` meter hover, drive and towing work; the power ledger and actual
board charge already exist. Existing sailing is a comparison baseline, not proof of the
new kite's cost. A speed reading cannot tell whether wind or the motor supplied the work.
**Needed:** an integrated measured kite trip showing low motor use while wind does the
pulling; honest hover/load draw, powered catch-up and readable remaining reserve.
**Smallest complete path, proposed:** compare matched routes/load/weather under motor-only
and kite towing; log propulsion, hover and attached-equipment energy separately. Use a
motor-disabled segment to prove the kite supplies real motion, then restore assistance.
**Dependencies:** one real force path, motor demand reflecting actual assistance, load
and stall behavior. Propose at least 50% lower propulsion energy per distance on a suitable
wind-powered leg; set a total battery budget only after measuring the rig. Hover is not free.
Do not grant charging or zero draw merely because a kite is attached or the board is moving.

## 3. Camp landmark and return navigation: useful when visible, honest when lost

**Hunter, same discussion:** “anchoring it to your camp is almost like a decorative piece,
or, you know, a little bit of extra pull.” He described leaving the shield on to see camp
while scouting and concluded, “Adding a kite solves that problem.”
[Home's agreed rule](../prd/bubble-shield-and-camp.md#marked-home-a-camp-that-does-not-despawn-selected-2026-10-20)
already distinguishes a live beacon from a last-known fix; the kite complements it.

**Built:** one marked Home, supported remote simulation and saves, powered beacon, requested
`HomeView`, and Console navigation (`CampHome`, `HomeBeacon`, `HomeView`, `Chart`). Initial
beacon range is 2 km. Day/night/storm still affect the distant silhouette and camp safety.
**Needed:** normal camp anchoring/recovery for the traction kite, a useful distant silhouette,
and proof it stays manageable under load without destabilizing an ordinary parked camp.
**Smallest complete path, proposed:** secure the kite to camp, scout a nearby dune, identify
its motion above the skyline, return and recover the same item. Repeat in haze/night and
show where visibility fails. Electronic navigation must never pretend a lost fix is live.
**Dependencies:** bounded Home membership, rope load/anchor behavior, terrain occlusion,
wind and rendering LOD. No always-visible icon, invulnerable anchor or guaranteed beacon.
**Important choice:** one kite cannot tow the player and simultaneously mark the camp.
The first acceptance trip can return by beacon/known bearings; test the camp-landmark role
on a separate scouting leg. A second kite is optional equipment, not a concealed requirement.

## 4. Signals and the Map: progression through information you can actually acquire

**Hunter:** “Instead of more tabs im thinking one map tab with filters: weather, archeology,
and navigation.” [Devices, One map](../prd/devices-and-mods.md#the-console-proposed-first-version-built)
records this as built. [Radio](../prd/radio-sound-and-atmosphere.md#the-radios-tiers-and-makers-looks-2026-10-21-built)
attributes “three tiers of radio and several visual styles” to Gonk, not Hunter; the current
catalog differs from that earlier lab proposal. Preserve that distinction when choosing scope.

**Built:** survey-receiver needle/pulse acquisition, crystal/field radio behavior and band
converters, antenna gain, bearings/triangulation, Home fixes and the filtered Console Map.
The radio PRD still lists ruin acquisition for new radio bodies as unfinished. Verify the
actual salvage path; availability in the creative menu is not ordinary-player progression.
**Needed:** a chosen, obtainable sequence with distinct benefits and comprehensible limits;
possibly acquisition/readability fixes rather than any new tier. Any greater Home range,
new signal or portable map transfer needs explicit design, power and equipment rules.
**Smallest complete path, proposed:** early receiver leads to a real nearby find; acquired
broadcast gear supplies useful weather or a bearing; the existing Map retains real evidence
for planning; Home supplies the return fix. No compulsory tour of all receiver bodies.
**Dependencies:** normal loot, band/range/window rules, mounted versus carried equipment,
and saved evidence. Coordinate radio assets/behavior with Gonk and Nav work with DESERT.
Radio can lead to Starcom; it cannot independently make an interstellar call. No fictional
new transmission should masquerade as a finished Starcom quest or free global navigation.

## 5. Suit and wrist instrument: a physical place for information

**Hunter, quoted in [Home](../prd/bubble-shield-and-camp.md#marked-home-a-camp-that-does-not-despawn-selected-2026-10-20):**
“Maybe it's pretty much blank and it says no data, but if you put a beacon down, you at
least have that one point and yourself”; “maybe it's like a Pip-Boy-type thing”.
The roadmap extends this as a direction for headlamp, harness, protection and beacon gear;
it explicitly does not approve a full HUD rewrite, fixed device or extra survival meter.

**Built:** first-person suit/body, functional headlamp, tether interactions, survival readouts
and requested Home view. The suit is not a fully modular equipment device. A physical body
model does not settle battery costs, protection upgrades or spatial inventory rules.
**Needed:** select what is carried on the wrist versus the camp Console, access/posture,
readability while moving, actual equipment ownership and unavailable-data behavior.
**Smallest complete path, proposed:** a requested wrist view of the existing Home fix, with
no-data/live/last-known states and shared saved source. Keep current navigation usable until
this demonstrably works. If it shows a point map, do not imply surveyed terrain or unseen sites.
**Dependencies:** input/pose ownership, field of view, readable real rendering, baseline
accessibility and the same Home signal contract. Protection/harness/battery systems remain
separate choices; a display must not silently remove existing survival or navigation abilities.
**Recommendation:** optional polish unless Hunter makes one narrow wrist interaction a gate.
A convincing instrument is valuable; a complete suit/inventory redesign would dominate 0.4.

## 6. Origins and repeat runs: distinct equipment choices, not stronger starter kits

**Hunter, [Surveyor opening](../prd/surveyor-opening.md#hunters-decisions):** “We do want some
randomization. So some drop pod randomization, and that could be part of the unlock tree
too… We gotta keep our deeds in mind.” SANDGAME also relays his direction for sub-unlocks
within a class and the Salvager near randomized ruins; those details are not quoted here
as a complete agreed spec. The roadmap lists origin variants as Spaceport direction.

**Built:** profile/deed unlocks, selectable origins, seeded Surveyor pod manifest/damage and
persisted recovery. Salvager has its own kit/personal shield and seeded world placement.
None of that demonstrates a sub-variant selector or guaranteed useful reachable starting ruins.
**Needed:** exact variants, unlocking deeds, balanced equipment tradeoffs, selection UI/save
identity, and Salvager access/viability checks. Don't give a fresh profile a locked kit merely
to make the kite acceptance easier. Don't reroll equipment when reloading the opening.
**Smallest complete path, proposed if selected:** one earned Surveyor loadout variant with
an explicit tradeoff and saved choice; separately, a Salvager start whose nearby real ruins
provide a usable first salvage opportunity. Neither needs a unique cinematic opening.
**Dependencies:** profile/run compatibility, loot/spawn guarantees and meaningful deed actions.
**Recommendation:** defer broader variants to a later replay pass unless Hunter selects one
bounded example. This is a proposed change to release scope, not an already accepted move
out of Spaceport, and not a promise to finish every origin for 1.0.

## Proposed acceptance: acquire, travel, recover, return

Use a fresh profile and normal Surveyor start on three fixed ordinary seeds. No dev grants,
forced wind, prebuilt rig or unlocked origin. Record how the player acquires the kite and
navigation gear; acquisition is part of the check, not a debug precondition.

After a safe camp is established, propose a real salvage objective 1–2 km away, beyond normal
local retention but initially within the beacon's designed range. Carry water, food and an
agreed useful payload; return with a real find. Distance is a provisional test scale, not a
world boundary or universal safety recommendation. Record load, wind, travel time and reserve.
Launch, travel, land, release/recover and relaunch through ordinary controls. Looking aside
must leave control unchanged. Demonstrate useful crosswind progress and a recoverable lull
or aborted launch; choose a viable route instead of demanding flight directly into the wind.

Meet the wind-leg propulsion criterion above without hiding hover/gear consumption. Return
before supplies expire with a recorded emergency motor reserve. Player and camp should live
because they were prepared, not because remote simulation paused or weather was disabled.
On a separate nearby scouting leg, anchor the kite at camp and find its silhouette again.
Test a genuinely lost beacon signal: label last-known data, then reacquire it on return.
Do not require a helpless player to find a moving Home from a stale fix with no other clue.

Save/resume with kite carried, flying/tethered and camp-anchored; cross streaming/origin
boundaries and return without lost anchors, duplicate gear or frozen Home consumption.
Inspect real day/haze/night captures and active-play performance. Use focused physical/
energy/save checks plus human unassisted play; a stationary screenshot cannot accept flight.
Scope any wrist or variant gate separately if selected. Full CI, supported-platform checks
and the version policy still apply before release; this brief needs docs checks only.

## Scope boundary and Hunter's decisions

**Core recommendation:** salvage traction kite, its board energy behavior, recovery and camp
anchoring, using current navigation with only necessary acquisition/usability fixes.
**Optional:** a narrowly scoped wrist view, a justified new receiver capability, one origin
variant. **Out by default:** multi-line flight controls, global terrain minimap, HUD/suit
rewrite, orbital travel, launch-site gameplay, Starcom repair, full god quests, and Saltbush's
repair/farming/processing package. Existing antenna kite and radio systems remain compatible.

1. Does the wind-powered salvage expedition and return define 0.4, rather than general travel?
2. Accept the proposed 1–2 km three-seed trip and separate camp-kite scouting check? What useful
   payload and emergency reserve should the trial require?
3. Should navigation work focus on acquiring/understanding existing gear, or is a specific new
   receiver capability required? If new, what information or range does it unlock?
4. Is the wrist instrument a gate? If so, is a requested Home display enough, or which exact
   additional functions belong on it without making the whole suit a release dependency?
5. Keep broader origin variants in 0.4, select one bounded variant, or defer them to a replay pass?
6. What measured total battery advantage should count as “not really take much battery”, after
   preserving real hover and equipment costs? Accept the provisional propulsion-only criterion?
