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

## First-person flight and impact (agreed; next pass, 2026-10-21)

Keep the seated first-person viewpoint from launch through atmospheric entry and
impact. Replace exterior pod shots with a readable capsule interior and a real
sealed viewing aperture, consistent before and after flight. Zan approaches through
that aperture; entry heats its edges and builds wind and hull noise. Orbital and
surface renderers may change under entry dust, but the seat, perspective and
interior must remain continuous. No cut to a standing player outside the pod.

Impact should feel violent through a brief bounded jolt, sound, dust and nearby
panel debris, without persistent camera jitter. Surviving actual gear stays
clustered around the landing site and keeps its existing saved identity, charge,
contents and deterministic survival. Dust clears onto the real surface and
recoverable shell. Resume does not replay impacts or duplicate debris or cargo.
This is presentation over the selected approach, not full orbital rigid-body
simulation. Existing legacy arrival saves retain compatibility.

Acceptance requires actual unseen captures through launch, entry, impact and
recovery, focused phase/save continuity checks, and the normal combined CI gate.
These changes are planned here; the preceding interactive-preflight baseline is
already on master and still uses the exterior flight presentation.

### Impact effects helper (private implementation, 2026-10-21)

`ArrivalImpactEffects` samples saved phase/elapsed time without changing it. Its
normalized aperture rectangle confines heat and dust to the view through the
capsule; the caller owns that rectangle and the base camera pose. A single recoil
lobe supplies local camera offset/rotation, with no accumulated transforms,
random shake, new audio, particle spawning or effect timer. Restore samples the
remaining effect rather than replaying an impact event.

The existing `surveyor_arrival` tuning dictionary supplies a 0.42 s recoil,
0.035 m maximum offset, 1.3 degree maximum pitch, 1.15 s dust clearance and 0.65
entry edge heat. Arrival28 passes (3 s): movement stays within those bounds,
saved impact sampling is identical, and later restore/recovery has no fresh jolt.

The isolated unseen GPU fixture uses the real shell with its hatch open, pending
the separate sealed-window integration. At 1280x720, heat changes 109,900 pixels
and impact dust changes 268,284; zero pixels outside the aperture change. At
1.16 s the image matches the clear frame exactly. Entry, impact, bounded recoil
and cleared frames were inspected. This certifies the helper's real shader and
mask, not the connected first-person launch or the new sealed window.

A separate actual cargo audit selects the standard preload and an externally
mounted original board on seeds 1234/5678/9012 with shallow/standard/steep profiles.
The 18/15/15 surviving selected roles stay within 3.006 m of the pod centre after
180 native physics frames with ordinary world time; all retain their original
identity and no ground rescue occurs. Joined pieces and fitted parts are measured
at their actual deck/socket poses, excluding gear forgotten aboard the ship.
This bounded result requires no scatter change and does not certify arbitrary
extra cargo, every landing slope or the connected first-person save transition.

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

Arrival25 passes (7 s) through actual bound Take input in real Main: pick the
original Guide from its rack, obtain the existing fitting preview on a real pod
side face, attach that same item, then take it back. Loaded selection follows
those actual physical changes and never counts the held item. The fixture uses
standing waypoints within the cabin; it does not claim unscripted walking or
ordinary-player discovery acceptance.

A real GPU cargo fixture has been inspected at rack, external-board loaded,
sealed and landed views. Shelf gear is physically supported; the original board
and cell clear the actual shell before and after closure/landing. Opened real
roof/hatch and recovered supplies remain visible beside the surface pod. This
is a fitting/continuity fixture, not a player-input recording or body-grip polish
claim. Arrival21/22/23 also pass again after the carrier-loss correction (7/14/11 s).

Seal also rejects non-finite/non-unit landing points and unknown or malformed
impact profiles before any physical closure or state change, protecting the
manifest's geographic assertion. Stronger Arrival20 passes (6 s) for invalid
point and out-of-range profile refusal with unchanged state; real disk Arrival22
passes again (13 s). This validates input rather than changing impact balance.

### Structural launch readiness (selected 2026-10-21)

Ordinary dismantling remains available in preparation, so launch must refuse a
broken or missing pod rather than invent replacement parts or retry landing
forever. Require the actual two-floor core and fitted supporting frames/panels
to retain their authored assembly relationships. The retained roof/hatch pieces
must exist and be available for ordinary automatic closing: not held, worn or
fitted to some other craft. Intentional parked closure panels remain valid.

Report a short repair/readiness reason, preserve all objects/state on refusal,
and permit normal repair with the same actual parts. This guard adds no binding,
part grant, new assembly system or silent reconstruction of dismantled supports.
A focused check must remove a real support/closure piece, prove refusal without
mutation, repair it through existing attachment operations and allow launch.

Structural readiness is now implemented in the private preflight candidate. It
checks the same two original floors in one deck at their authored relative pose,
the original frames centred on their named floor tops, and every fixed panel on
its proper original frame face. Roof/hatch parts may already be correctly joined
or remain loose under ordinary world content; a carried part, another craft, an
incorrect attachment face, or an occupied closing face refuses before resealing.
No additional distance restriction is placed on intentionally parked loose lids.

Arrival26 passes (7 s): actual side/frame/floor removal, hand/suit/waist custody,
other-craft attachment, a roof on the wrong pod face and an occupied closing face
all refuse without changing arrival state, body poses or content count. Ordinary
refitting/rejoining and suit retrieval of the same original parts make readiness
valid again; the repaired shell seals normally. Existing focused20/22/24/25 pass
(8/14/9/6 s), including actual restored preflight saves and impact carrier loss.
This guard changes no generic Chassis, Snapshot, controller or input behavior.

### Combined opening acceptance (development candidate, 2026-10-21)

The integrated ship/cargo/planner/closure flow has been checked with the current
large-moon model, boarding movement and visible player body. Focused Arrival15/16/22/26
pass (13/5/13/6 s), including real preparation/flight disk saves and repaired shell
launch. The saved automatic flight path remains compatible: Arrival11 passes (8 s)
with preparation explicitly disabled. Powered boarding43 and body-vault44 pass
(17 s each). These focused results do not replace full cross-platform CI.

The real unseen GPU run completes all nine connected phases at1280×720: ship,
computer, pod approach, seated preparation, ejection, descent, entry, landing and
recovery. Every capture was inspected. It lands13 real roles, zero ground rescues
and an empty suit inventory; omitted rack equipment is not granted. Actual shell
and supplies remain readable through the current atmosphere. No shader, script or
resource errors were emitted. Landing/native verification and ordinary player
acceptance remain pending; this does not declare a release or migrate old saves.

### Recoverable viewing panel (selected geometry, 2026-10-21)

The existing tail chassis becomes a sealed double-glazed viewing panel. Its
opaque mesh has a genuine 0.68 m wide by 0.56 m high opening; glazing spans that
opening on both original mounting faces. The ordinary closed native chassis
collision envelope, mass, sockets and twelve named roles remain unchanged.
The clear panes occupy the same external envelope: this is a sealed window,
not a player passage or a new survival/pressure system. `pod_skin = viewport`
persists through ordinary Snapshot reconstruction and chassis rerooting.

`PodShell.ensure_aperture(parts)` upgrades the actual retained tail idempotently,
including older armor metadata. `seat_pose()` gives pod-local feet and facing;
the controller owns eye height. `flight_interior(parts)` makes only meshes at
the real parts' pod-local poses, excluding cargo. A mesh-only authored fallback
serves legacy flight without spawning bodies or supplies. The orbital controller
owns placement and camera continuity; the geometry helper never moves equipment.

The viewing panel is implemented in the isolated first-person geometry branch.
Arrival29 passes (9 s): complete twelve-role pod, unchanged mass/collision shape
count, genuine opening through the opaque mesh, idempotent skin update, mesh-only
actual/legacy interiors, ordinary detach, real disk save/resume, and rejoining the
same saved window. Existing dismantled-pod8 and reroot-save12 pass (9/10 s).
Actual1280×720 GPU captures show the sealed berth and the same shell framing Zan
in an isolated orbital viewport; the authored legacy shell matches that seat.
The current berth eye sits below the ship observation-window sill, so its straight
preflight view sees the real ship wall beyond the clear pod glass. That physical
room/window alignment remains an integration decision; no seat or object was moved
to conceal it. These geometry checks do not claim full connected-flight acceptance.
The capture fixture drains the disposable world/viewport across three process
frames and the final render fence before exit. The final GPU run emits no script,
shader, ObjectDB or resource-in-use errors. An earlier two-frame fixture shutdown
intermittently reported retained resources; the verbose repeat and final cleanup
run completed without those warnings. No production teardown behavior was changed.


### Cabin readability pass (selected 2026-10-21)

Keep the shared worn industrial material, with explicitly low dust on sheltered
cabin panels, neutral task lighting, dark inset deck plates and fine traction
ribs. The pod bay has a closed boundary with broken entry chevrons and a short
physical POD BAY sign, rather than two unexplained yellow lines. These are
appearance changes; gear, cargo bounds, normal walkable floors and pod identities
remain unchanged. Lower the actual observation aperture sill and all matching
hull/window geometry to clear the existing seated eye; do not move the seat.

The enlarged launch-station bezel exposes `computer_screen_pose()` and
`computer_screen_size()` in room coordinates; the controller owns the live
always-on display and focus transition. Remove painted imitation display rows.
`computer_focus_pose()` is a camera pose 0.72 m outside the real display.

The orbital window may show Zan's close limb and actual Tu by choosing a real
ship orbital position. It must share the saved departure clock/frame with the
flight controller; selecting a landing site does not imply it lies directly
under the ship window. No Tu texture is pasted onto glass or moved in the sky.
### Launch refusal readability (selected 2026-10-21)

Ordinary play exposed two hidden blockers: a loose rear roof had another real
panel joined to it, and the untouched ration settled18 micrometres through its
contact floor, exceeding the previous10 micrometre bounds tolerance. Keep the
structural/custody safety checks, name the actual repair (separate joined panels
from the rear roof), and report missing stores alongside structural blockers.
Show current launch blockers while aiming at the pod before seating as well as
when seated; the computer consumes the same live readiness list. A visibly
preselected course still needs an explicit confirmation, clearly named.

Use0.0001m solely as bounds-rounding/contact tolerance; this is0.1mm, not usable
cargo capacity. A focused check must accept the observed20 micrometre floor
settlement and refuse a1mm displacement, while preserving ordinary panel repair
and required-store refusal. No automatic unjoining, store grant or save edit.

Arrival30 first fails on the prior source for all four observed readability and
contact-containment regressions, then passes4s after the correction. It also
refuses1mm outside, keeps panel/state unchanged during readiness inspection,
and permits ordinary same-part separation/return of the ration. Existing
Arrival16/20/26 remain green5/6/7s. A copied ordinary-player save restores with
the same rear-roof/hatch join and all four original stores counted; only the
actionable rear-roof repair remains. The player's save is never rewritten.
The orbital window must use the model's saved regional departure clock/frame,
so one short departure impulse reaches the real landing corridor without a
position jump. Tu appears only if that actual viewpoint sees it; visibility is
not guaranteed by moving the ship to a different hemisphere. No Tu texture is
pasted onto glass or moved in the sky. The cabin pass leaves that frame API to
the shared trajectory integration.

The pod's inner thermal liner also receives an explicit0.02 dust coefficient.
Its local underside previously sat in the outdoor shader's foot-deposit band,
turning a black protected liner sandy brown. Exterior armor/vents and ordinary
recovered kit keep their original materials; no shared shader was altered.

Cabin geometry15 and recoverable aperture29 pass (14/8 s), preserving normal
walking/crawling. The cabin check also raycasts from the focused eye to the actual
console collider and confirms more than0.6 m clearance. Actual1280×720 GPU cabin,
window, pod bay and station captures were inspected: deck ribs and clear paint
replace sand deposits, with the same real kit geometry. The live screen is owned
by the controller integration; this capture intentionally shows its empty recess.
A corrected real-player-camera seated capture shows Zan through both actual
apertures. The berth remains at its original pose. Current old orbital framing
is a placeholder pending the saved regional departure model, and does not claim
Tu visibility. Root's integrated display capture caught a2 mm recess overlap;
the screen pose is now0.089 m outward, beyond its0.086 m opaque backing face.

### Seated flight renderer (selected 2026-10-21)

ArrivalView uses the real pod's mesh-only interior at the inverse of the same
pod-local seat/eye transform as preparation and landing. Old flights without
physical parts use the nominal mesh-only shell. No exterior pod proxy remains.
The arrival controller owns the body's ground pose and freezing; this renderer
owns only camera recoil and presentation, never body velocity or gameplay forces.

Entry heat and landing dust are clipped to the projected real window rectangle.
One saved-time recoil moves the camera within the fixed shell, without replaying
an impact on resume. At materialized landing, ordinary ground rendering replaces
the orbital viewport while the matched real seated camera is briefly recoiled;
the renderer restores its unmodified local transform on disposal. The shared
regional trajectory will supply orbital position/orientation separately; the
old orbit interpolation remains a temporary renderer path until that integration.

Renderer33 passes (6 s): real shell held at one seat through orbit/ejection/
descent/entry, projected window wholly on screen, bounded nonaccumulating ground
recoil, exact settled/disposal camera restoration and no extra physical bodies.
Saved-time effects28 passes (4 s). Actual GPU renderer captures at1280×720 were
inspected for orbit, ejection, descent, hot entry, impact and settled ground.
With the same real renderer pose/light held fixed, entry changes30,940 pixels
inside the aperture and zero outside; the first fixture incorrectly varied
orbital attitude as well, so sunlight changed the surrounding shell. The revised
fixture isolates only the effect without relaxing its zero-outside threshold.

This fixture uses the real View with an explicitly positioned ground-seat body;
it does not claim controller transport, the new trajectory model, normal recovery
crawl or full saved-run acceptance. Ground HUD bars remain visible under the
transparent renderer in this isolated fixture; controller flight suppression is
owned by the connected integration. The old orbital path remains temporary.

## Connected physical station and first-person candidate (2026-10-21)

The current candidate replaces the modal planner with a persistent physical glass
screen using the shared theme. The ordinary Use action smoothly focuses the
actual camera on that same screen; projected mouse events reach its viewport.
Stepping back restores the prior viewpoint and normal camera processing. Menus
and the console cover the station's input, cancel a pending drag and restore its
pointer when uncovered. The hand readout yields to the focused display.

The diagram shows the seeded globe, carrier, one draggable pulse and a predicted
landing. Numeric heading/profile controls and the site-button grid are removed.
The single saved departure model supplies the rotating globe, cabin viewpoint,
ballistic path, actual landing point and arrival time. The powered carrier's
bounded survey loiter leaves time to load gear. Pulse edits persist as a draft;
setting the pulse explicitly confirms it. Actual launch revalidates the current
continuous forecast and the real cargo/shell. Outside-survey or unsafe forecasts
remain refusals. See the landing-plan PRD for the model's scope and assumptions.

New launches retain a seated first-person capsule interior through ejection,
descent and entry. The same path and clock drive the horizon approaching through
its actual glazed panel; heat builds at the aperture. Impact uses a bounded jolt,
existing credited hull/boom sounds and dust. When the viewing panel is lost,
dust fills the opened view rather than leaving a floating window rectangle.
Recovery stays prone at the real pod floor; ordinary movement resumes there.
Survival/damage and the identities of selected cargo remain unchanged.

The ordinary Feel controller is suspended while the scripted camera owns the
seat, flight or screen focus, then restored. Mid-impact disk restore establishes
the authoritative seat pose before sampling remaining recoil; it does not add
recoil to an already-recoiled saved camera or replay impact audio.

The combined candidate passes twelve focused checks covering physical planning
and launch, projected mouse input, draft save, modal coverage, ordinary cargo
and seated disk saves, legacy flight, aperture teardown and mid-impact resume.
The actual 1280×720 GPU run reaches recovery with13 surviving roles, zero rescues
and an empty suit. Its cabin, physical screen, pod, seat, ejection, descent,
entry, impact and recovery captures were inspected. This is candidate evidence;
combined CI/native verification and Hunter's feel/comprehension acceptance are
separate gates. No release or version bump is declared here.
