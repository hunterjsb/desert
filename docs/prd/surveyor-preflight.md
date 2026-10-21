# Surveyor ship, scouting and pod preparation

Selected 2026-10-21. Extends the Surveyor arrival in [Survival](survival.md) and
answers to the [vision](../vision.md). In progress; no completion/release claim.

## Playable outcome

Begin a new Surveyor run inside a small walkable ship overlooking Zan. Use its
launch computer to inspect limited orbital survey information, choose a landing
zone and approach, physically load equipment into the pod, enter it and launch.
Continue through existing ejection/descent/landing. Recover actual surviving
cargo and dismantle the actual pod into a first camp. Other origins, developer
scenarios and existing saves retain their starts.

## Room and physical continuity

SurveyorShip supplies real floors/walls, observation window, computer, racks and
a docked PodShell. The window renders ArrivalOrbit in an isolated viewport, not
the surface sky. Use the same World and Player, real walking and ordinary hands.
Cabin time/exposure must not consume the surface survival opening. The ship is a
bounded preparation room, not a flight simulator or another survival sandbox.

Static room presentation is disposable. Real pod/cargo use ordinary world-content
roots, nested fittings and stable arrival identities so Snapshot preserves them.
Restoring the room must not duplicate pod or rack gear. Scene moves use the safe
native teleport path. All equipment and structure retain their actual identity.

## Limited scouting and trajectory

Initially survey a bounded drop corridor around the starting region. Several
candidate zones use actual seeded terrain/history, coarse structure classes and
distance bands, and validated pod/exit footprints. Prefer meaningful detectable
salvage nearby; retain a validated fallback and report unavailable alternatives.
Do not reveal precise loot or treat illustrative orbital albedo as terrain truth.

Persist the zone, geographic point, world position, approach heading and profile
in arrival_state.landing_plan. Profiles shallow/standard/steep affect approach,
descent timing and bounded seeded impact severity, with short clear tradeoffs.
They are not simulated orbital mechanics. Revalidate before launch; refusal
preserves selection and cargo. See [Landing plan](landing-plan.md) for sampling.

## Loading and readiness

Available equipment is real and visible on racks. Emergency water, food, a light
shield and compatible cell are visible preloaded stores. Missing/empty required
stores block launch with an actionable readiness list. Optional gear includes a
board with its cell fitted, beacon, guide, shelter/power and anchoring gear.
Players choose what fits; omitted equipment stays aboard and never appears on
the surface. This is not an unlimited inventory checklist.

Recognize loaded cargo from complete physical bounds in the pod volume and real
fitted attachments; reserve the player's seat/entry space. Preserve identity,
charge, contents, conditions and line relationships. Launch seals the selection
and resolves seeded impact survival once. Protect required emergency stores from
initial loss; optional cargo can be lost/damaged. Land the same surviving bodies,
not catalog replacements. Never add the legacy equipment grant or reroll on load.

## Saved state and input

arrival_state.preflight records version, ship world position/height, seated state,
loaded identities and whether launch committed. Existing object refs reconnect
real bodies. Persist computer selection as plain data, not its open modal or held
input. Save/load must work while preparing, partly loaded, seated, in flight and
after recovery without duplication. Legacy states without preflight keep the
automatic sequence; new normal Surveyor starts enter preparation.

Use ordinary Use/Take/carry actions and the existing theme. The computer opens a
bounded modal; closing restores cabin movement. Entering the pod is an explicit
physical interaction. Launch requires seated player, valid plan and ready cargo;
no timer fires while the player prepares. Deeds record successful actual actions,
never reconstruction.

## Acceptance

- Real-input walk to computer/racks/pod and solid geometry.
- Honest survey; selectable sites/headings/profiles; refusal of unsafe plans.
- Ordinary physical load/unload, capacity and clear readiness.
- Enter/launch/descent/landing/recovery with only selected real cargo arriving.
- Real disk saves across phases, no reroll/duplication, legacy compatibility.
- Focused checks, inspected unseen first-person captures, combined CI and native
  builds, followed by ordinary-player acceptance. As-built results remain pending.
