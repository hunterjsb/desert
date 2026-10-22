# Native contact projection cost

Selected experiment, 2026-10-22. Extends the capsized large-camp audit in the
[movement PRD](movement.md#final-capsized-large-camp-cost) and answers to the
[vision](../vision.md). This is a bounded CPU experiment, not a new contact model.

## Design before experiment

Every near-ground frame contact constructs a fresh native hinged-assembly model
and projects its actual velocities. `RopeArticulation.native` creates new
`RopeBody` values whose external expected velocity/spin are zero. The current
projection also runs a second, full assembly response over those zero external
terms; that response leaves all external terms zero.

Skip only that predicted/external projection for these newly created native
snapshots. Preserve the normal projection of fresh actual native velocities on
every call. Ordinary rope models keep the existing default projection of both
actual and nonzero predicted terms. Do not cache geometry, mass models, velocities,
terrain reads or origin coordinates; preserve contact traversal/impulse order.

The existing physical 108-piece fixture is the acceptance measurement: 1,772 kg,
54 skates, 54 trays, 18 batteries, 18 camp devices and one freely hinged mast.
Fall freely from 100 degrees onto real terrain, then settle, sampling 480 ticks
per phase. Use identical timing/counter instrumentation and compare candidate /
baseline / baseline / candidate. Require exact printed physical/contact outputs
and a bounded measurable benefit before accepting. Existing rope/hinge checks
and a nonzero-external projection check must retain their behavior.

## Initial baseline profile

Current verified source `5ac5ae09` gives 1,017 corner candidates per tick,
12.477 falling and eight settled near contacts, 2.223 / three impulses, and
whole-process CPU 13.688 / 12.521 ms per tick. Fresh model construction accounts
for 1.776 / 1.176 ms per tick within that work. These are one warm shared-host
profile, not the four-run comparison or a general performance budget.
