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

## Four-run result and limits

The candidate/baseline/baseline/candidate comparison uses baseline `5ac5ae09`
and candidate `5513ce4c` with identical counter/timer instrumentation. Each run
uses fresh actual bodies and terrain; instrumentation is removed afterward.

| CPU per physical tick | Baseline runs | Candidate runs |
| --- | ---: | ---: |
| Whole process, falling | 13.604 / 13.625 ms | 13.708 / 13.604 ms |
| Whole process, settled | 12.729 / 12.438 ms | 12.229 / 12.083 ms |
| Native model construction, falling | 1.788 / 1.785 ms | 1.675 / 1.689 ms |
| Native model construction, settled | 1.192 / 1.184 ms | 1.109 / 1.102 ms |

Two-run medians reduce measured model work by 5.84% falling and 6.99% settled.
Settled whole-process CPU is 12.583 → 12.156 ms/tick (3.39% lower), with both
paired comparisons improving. Falling whole-process CPU is 13.615 → 13.656 ms
(0.31% higher); this does not establish a falling frame-time benefit. Shared-host
noise also means the larger whole-process settled difference cannot all be
attributed to the smaller measured model-work saving. This is a bounded settled
CPU improvement, not a general budget, removal of the original correctness cost,
or a claim about larger camps, multiple booms, rougher terrain or GPU time.

All printed non-timing outputs match exactly across all four runs: 1,017 corner
candidates, 12.477 / eight near contacts, 2.223 / three impulses per tick and the
complete final heel, speed and spin values. Fresh native velocity reads, model
construction, terrain queries, ordinary contact/impulse order and native policy
are unchanged. No physics snapshot is cached.

## One assembly per carrier a tick (2026-10-22)

Geometry and masses hold within a physics tick; only velocities change as each
contact lands. `RopeArticulation.native` now configures a carrier's hinged
assembly once a tick (rebuilt if a boom is made or freed, or the carrier moves)
and re-reads and projects only its velocities per contact, so sequential contact
response is unchanged; with the cache disabled, sailing probe 4 gives the same
numbers to the third digit. The root's unit-impulse mobility is worked out once
per assembly too. A camp lying over meets its near points together
(`Runners.rest_on`): every near point once, then those still pushing twice more,
so the masthead, met alone and first before, holds instead of sinking 0.54 m.

Sailing probe 25 runs alone and bounds the tipped contact work of the 2x2 sailing
rig lying over at 1 ms a tick; on the shared, loaded development host it measured
about 0.72 ms (nine near points of 41). The 108-piece camp above was not re-timed.
