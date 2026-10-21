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
