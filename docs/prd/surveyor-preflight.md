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

### Physical cargo helper slice (2026-10-21; private development)

PreflightCargo stages the sixteen existing equipment roles once as actual catalog
bodies. Four emergency stores are preloaded: water, food, a light shield mounted
on the pod floor and a compatible battery stuck to that same real chassis pool.
The light shield has no battery socket; none is invented. The board's own cell
uses its actual battery socket. Other gear is placed on the physical rack shelves.

Loaded recognition uses complete collision bounds, excludes the actual prone
seat capsule and held/grasped/waist/suit objects, and accepts bounded optional
external fittings on the actual pod. Required stores must remain inside. The
cargo volume begins at the actual chassis floor top (THICK/2, 0.06 m), preserving
its previous 0.92 m top. A 0.00001 m enclosure tolerance covers transform rounding
only; it is not usable extra capacity. Parts are centered by actual bounds rather
than assuming their attachment origin is their geometric center.

Seal refuses without mutation when stores/profile/landing point are absent. A
successful seal retains selected uid/relative poses and the copied impact profile;
Manifest resolves only those selected equipment rows. The existing automatic
manifest and materializer paths remain unchanged. Landing reuses named physical
bodies and parts; its full integration/save/placement checks are still pending.

Focused Arrival20 passes (6 s): all 28 actual structure/equipment identities exist
once, visible emergency readiness, no implicit board load, removed/empty stores
refuse, restaging preserves depleted contents, invalid seal is read-only, and a
repeat seal cannot reroll or refill. Real input loading, save/resume, external
board fitting and descended cargo placement remain the next acceptance checks.

### Connected opening acceptance (private candidate, 2026-10-21)

Arrival16 passes (4 s) through actual Main input: a fresh Surveyor starts walking
in the ship; entering the pod cannot bypass a missing course; leaving restores
walking; Use opens the real computer collider; its destination control commits
the plan; closing restores input; entering and launching starts ejection with the
original pod and leaves the optional rack board behind. Surface time remains
frozen during preparation. Same-frame flight saves exclude omitted gear before
deferred deletion.

The unseen `look/surveyor_preflight` capture passes the connected fresh flow at
1280×720: ship, computer, pod approach, seated view, ejection, descent, entry,
landing and recovery. All nine captures were inspected. The selected landing
reaches recovery with 13 real roles, empty suit inventory and zero ground rescues.
This fresh-flow result does not certify restored cargo: real disk preparation,
seated, flight and post-impact saves remain under focused acceptance, including
lost-frame ownership cleanup and extended-rope identity. Combined CI, native
builds and ordinary-player acceptance are still pending.
#### Actual cargo and disk acceptance follow-up

Arrival21 passes (6 s) with a board mounted to a real pod side panel and its
original fitted cell: actual selected body identities survive landing; partial
water/charge remain unchanged, omitted rack equipment stays aboard and repeated
landing does not duplicate bodies. The mounted board/cell reaches 0.82 m from
the pod centreline, so its external envelope is corrected to 0.83 m including
the existing 0.01 m spacing. All real shell bodies use native custom COM before
first teardown, including pieces that had never entered the tree themselves.

Arrival22 passes (13 s) through actual Main disk saves in preparation with a
partly used store held, seated, immediately after launch, in resumed flight and
after landing. The immediate-flight save first reproduced omitted rack gear
being saved before deferred deletion; removing those actual roots before queueing
free fixes it. A second actual failure exposed restored joined-floor ownership
indices still listing a removed frame's nodes: prune only nodes no longer in the
actual deck after unseating the lost frame, before freeing that frame. No Snapshot
filter or assertion was suppressed.

Arrival23 passes (9 s) for ordinary coil→original end→coil identity transfer and
a fully attached original line with a real fairlead. Loaded recognition rejects
a line still leading to the hand/waist or another ship object. A line whose ends
and guide are on the actual pod keeps its original ends, full/paid lengths and
route through physical landing and disk restore. No new rope item or input is
introduced. System staging and automatic hatch resealing suppress assembly deeds;
actual launch/recovery actions retain their own deed recording.

Optional carrier-loss cases and ordinary first-person packing/collision captures
remain pending; these focused checks are not full milestone acceptance.

#### Lost-carrier material continuity

Arrival24 first fails cleanly (6 s) when a selected line survives but one of its
untagged original ends is destroyed with its impact-lost carrier panel. Store
each actual endpoint pose under qualified keys in the existing plain cargo_poses
dictionary. Before deleting lost carriers, unseat both surviving original ends;
land the detached far end at its saved local pose as the same body. This adds no
second inventory item, replacement line or synthetic identity. The same check
now passes (6 s): the side-mounted board keeps its original cell after its carrier
is lost, both actual rope ends and their original line remain, and only the two
protected real floors stay joined when all outer panels/frames are lost.
