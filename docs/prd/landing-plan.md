# Surveyor landing planner

## Selected 2026-10-21; implementation in progress

The ship's launch computer offers a bounded drop corridor on the existing regional
sheet, not a complete orbital survey. Resolve three to five seeded candidate
locations once, retaining the known Surveyor start as a fallback when its actual
footprint is safe. Each alternative is within walking distance of a real, exposed
built structure from the same history/anchor mapping. Show only a coarse structure
class, bearing and distance band; never expose contents or an exact salvage map.
The terrain read is TerrainShape's real height function, not orbital albedo.

Persist the plain `landing_plan` dictionary inside arrival state: version, seed,
anchor geography/world/facing, candidate id/geographic point/world coordinates,
footprint result, coarse signals, selected id, approach heading and trajectory id.
Choices are stable across global random calls and Variant save/restore. Selection
returns a copy and accepts only safe candidates and finite headings. Revalidate
the chosen footprint before launch; decline stale/foreign seeds or sheet anchors.
Use the same conservative pod-and-exit square for every heading, so changing the
approach cannot place its tail or exit outside the checked ground. Enumerate the
terrain lattice within that square, reject structure/landmark overlap and excess
height spread; normal terrain streaming/collision readiness still gates landing.

Trajectory ids are shallow, standard and steep. The arrival controller owns their
descent timing, presentation and impact consequences. This module does not perform
orbital simulation, change terrain truth, travel the player or create cargo. Numeric
planner choices live in its dedicated rules Resource. The computer uses the existing
theme, exposes the corridor's limits and commits selections through a callback;
its owner keeps ship movement suspended while the modal view is open.

## Model measured 2026-10-21

Arrival 17 passes on seeds 1234, 42 and 9876 with three to five choices, actual
footprint revalidation, deterministic repeated builds and Variant save round
trips preserving destination/heading/profile. Alternatives have exposed,
far-rendered socket-bearing structures within the configured walking band.
Arrival 18 rejects a foreign seed, different sheet, missing destination,
nonfinite heading and a real history structure substituted behind a stale safe
flag. These are model checks, not integrated ship/launch/save acceptance.

For seed 1234 the model resolves four sites with 0.326–0.592 m footprint rise.
Readings include real pylon stubs, a relay mast and a nomad rig, at coarse bands;
contents are uninspected. Planning does not join sites, move history anchors,
change the world or promise that any particular find will be intact on arrival.

## Computer measured 2026-10-21

LaunchComputer exposes `setup(world, plan, changed)`, `closed` and `dispose()`.
The owner suspends cabin movement and owns launch; the modal commits destination,
approach and trajectory through independent plain-data copies. Closing consumes
the cancel action and restores the previous mouse mode. Selection preserves
control focus; readings scroll with the shared PageBar, and repeated structure
classes show their nearest coarse band. The regional diagram marks candidate
coordinates and the selected approach, with no illustrative surface imagery.

Arrival 19 passes actual button/heading/profile callbacks, caller-data isolation,
initial viewport containment at 1280x720 and closing/restored mouse state. Arrival
17 also confirms a validated fallback on each of its three seeds. Inspected unseen
1280x720 captures show fallback and alternate selections using actual seed 1234;
that GPU run passes without script or resource teardown errors. A first capture
exposed container overflow on initial layout; fitting after container measurement
and scrollable readings corrected it. These checks exercise the independent view,
not terminal reach, modal interaction with pause/save, trajectory severity or the
complete physical launch/recovery sequence. Those remain integrated acceptance.

The final layout uses existing MenuListApart, Columns and AsideList theme
variations and the shared panel padding, with no layout/theme overrides.
Focused Menus 5 (one theme) and Arrival 19 pass together; refreshed fallback
and alternate GPU captures were inspected after that correction.

## Test coverage separation for interactive preparation (selected 2026-10-21)

New Surveyor preparation is the normal production path. Arrival 16 explicitly
exercises it through Main with preparation enabled. Existing automatic-flight,
legacy-save, eclipse-notice and surface-recovery fixtures retain their original
scope by disabling preparation only in their own tuning setup. The shared
MenuProbe convenience fixture also selects automatic arrival so unrelated menu,
spawn, dev and save checks can reach the surface without simulating a launch.
Direct World/run fixtures, other origins and scenarios remain unchanged. No
production auto-launch or test-mode bypass is added, and existing flight, recovery
and input assertions remain intact. Interactive launch/cargo/trajectory and its
save round trips require the dedicated integrated acceptance, not these helpers.

Combined preflight-controller acceptance (2026-10-21): Arrival 10/11/13/14 pass
in 6/10/26/10 seconds. Arrival 11 now enables preparation for new games after
saving an automatic flight and before resuming it: the exact saved phase and
elapsed time reconnect, survivors remain identical, and no preflight state or
ship controller appears. Its subsequent partially recovered resume still keeps
the actual food in hand with no duplicate inventory grant. This establishes
legacy compatibility under the new default; it does not replace interactive
ship/cargo/launch or modal pause/save acceptance.

## Physical launch station revision (selected 2026-10-21; implementation pending)

The modal site grid and numeric heading controls failed the ordinary playtest:
selected defaults looked ready without being confirmed, the map was ambiguous,
and the player could not launch. Replace this interaction with an always-visible
physical screen on the cabin computer, using the established Console display
pattern and theme. Using it smoothly focuses the existing camera on that same
screen and enables mouse interaction; leaving returns to the previous viewpoint.
Do not open a separate planning window or require degree entry/readouts.

Show Zan as a rotating globe with the ship, a single ejection impulse, its
predicted descent path and landing footprint. Drag the impulse handle to explore
approach and impact; communicate the result spatially and with brief plain words.
Planet motion, orbital window and forecast must share one saved clock and frame;
launch timing must affect the forecast consistently. Maintain the distinction
between compressed navigation and lore/presentation scale, and between coarse
orbital survey and actual validated terrain. Never claim illustrative albedo is
precise terrain data, silently snap to unknown coordinates or bypass readiness.

The station visibly reports course and cargo readiness; the pod approach also
shows actionable launch blockers before entering. A default shown as ready must
be genuinely committed. Loading, launching and save restoration must remain real
ordinary interactions. This revision supersedes the numeric/modal UI above;
prior measured results describe the previous implementation, not acceptance here.

### Shared departure model (selected 2026-10-21)

Persist one regulated carrier survey pass, initialized once from the original
regional anchor so its initial default pulse reaches the validated fallback.
The powered carrier holds latitude and nearly matches the moon's rotation, with
a small residual ground-track drift. This is stationkeeping, not an unpowered
Kepler orbit. It gives ordinary packing time without reanchoring the ship when
the pulse is confirmed. Do not move the carrier to an unrelated Tu-facing point
merely to compose the window; the window shows Tu only when that geometry permits.

The pod receives one inward/retrograde/cross-track impulse and then follows a
bounded point-mass ballistic integration. The numerical field and time are a
gameplay trajectory model, not a derivation of physical gravity from the visual
moon radius. It neither changes 9.8 m/s² surface gravity nor claims a full orbital
simulation. The computer, window and flight use the same sampled path and saved
clock; the model never advances time. The controller advances departure time by
actual unpaused preparation time and carries it into the world at launch.

Body-fixed geography rotates into a shared inertial frame once per existing game
day. Public positions and paths use planet-radius units; physical navigation
continues to use the 150 km compressed circumference. A ray-dragged pulse changes
the same velocity used by the path and landing prediction. Launch time changes
the predicted ground point. No numeric angle interaction, continuous pod thrust,
candidate snapping, hidden time advance or selection-dependent ship relocation.

Only points inside the original surveyed corridor are supported. Convert the
predicted body point through the original Sites.Anchor, then sample its actual
seeded footprint and coarse history again. A clear continuous landing point may
be committed as an ordinary LandingPlan candidate; an unsafe or outside-survey
point has an explicit unsupported state and cannot be committed. Revalidate at
actual launch time; stale forecasts need updating at the station. The regulated
pass's default residual drift is 3 compressed metres per second, leaving minutes
for packing instead of a few seconds. This is not an indefinite launch guarantee.
