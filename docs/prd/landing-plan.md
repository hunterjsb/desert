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
