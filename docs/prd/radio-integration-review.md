# Radio upgrades integration corrections

Selected 2026-10-22 for PR #51 after source review against current Sanddune master.
The radio, physical rope/power, save and presentation PRDs govern the feature;
this account records the bounded corrections required before landing it.

## Save and receiver continuity

Moving the beacon from 1930 to 530 kHz must not leave saved survey receivers outside
their new tuning range. Restore genuine legacy receiver states with their relative
beacon offset preserved. Current saves retain their current frequency; do not
silently reacquire or refill equipment. Check normal disk/Snapshot restoration.

## Station identity and powered modules

Changing audible FM station identity, including an AM-to-FM change within the same
channel category, must stop the previous station's queued speech before new words
play. Preserve ordinary interruption, reception and per-station voice timing.
The crystal set remains passive. Counter and logger functions require their real
module power contract, just as the existing preamp does; fitting a powered module
must not make it operate for free on a passive host.

## Aerial coordinates and broken leads

The decorative airborne aerial and its saved/derived engine position must follow
World's actual origin displacement in the same frame as its host. Preserve the
line geometry, geographic position, effective height and charge/reception behavior
through recentering; do not hide a jump by teleporting to a new wind target.
A snapped StrongCable still has recoverable plugs, but no electrical connection.
Treat its absent rope as disconnected in kite rig discovery and grounding. Its
route through a stake must not provide reception gain or arc protection after
rupture. Ordinary intact leads and their saved routes keep working.

## Existing developer histories

Keep the former drone/surveyor console commands and scenario names as aliases
to the renamed deliveryship setup. Existing playtest histories should still
reach the same real flight path; the new display name is unchanged.

## Existing CI failures

The high-observer drone check must obtain an observer genuinely above the current
deliveryship ephemeris, preserving finite depth, below-observer geometry and the
actual same-clock orbital placement. Do not lower the ship or relax the depth
assertion to make the check pass. Reproduce the radio static fixture's reported
failure before choosing a correction; keep real reception/noise requirements.
The existing failed radio log shows clean 0.50/dirt 0.50 but audible 0.00 and full
static: an intentional time-sliced dropout, not a loss of the thin-storm signal.
When testing gain during reception, advance through a bounded number of actual
dropout slices until the receiver is not cut, retaining every loudness, dirt and
static threshold. Do not suppress cuts or change the production receiver.
The streaming budget remains unchanged; do not weaken it to mask a noisy run.

## Integration and outputs

Use one shared task checkout, with separate file ownership for radio and kite
corrections. Main stays on verified source. Run focused regressions locally and
the combined suite through exact-commit CI, then land through the temporary
integration checkout. Update next-release notes and reconcile deed/catalog/probe
registration. Keep compact measured results; remove temporary capture output after
inspection. Retire the completed task checkout and branches when landed.

## Focused integration results

Weather27 reproduces the old high-observer failure and passes with its observer
placed 4 km above the actual orbit. Static18 retains its original thresholds
and samples a received slice between genuine dropouts; it passes alongside
Weather27 (9/7 s). The real console test executes both legacy commands, observes
the requested overhead flight and confirms the old scenario aliases (21 s).
The separate radio and kite accounts record all five reproduced runtime defects
and their corrected focused checks. Combined CI remains required before landing.

## Rendered scale calibration

Actual runtime Forward+ inspection found the live shortwave needle at30 MHz
against a printed26 MHz end tick; AM and FM also retained prototype ranges.
Printed marks must use each live band's actual limits and their corresponding
fraction of the same needle travel. Keep meaningful legible labels, placing
nonuniform label intervals at their actual frequencies. This changes the face
markings, not tuning, reception or needle response. Check all three production
bands, and inspect the corrected shortwave maximum in the renderer.
