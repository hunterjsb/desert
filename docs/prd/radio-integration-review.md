# Radio upgrades integration corrections

Selected 2026-10-22 for PR51 after source review against current Sanddune master.
The radio, physical rope/power, save and presentation PRDs govern the feature;
this account records the bounded corrections required before landing it.

## Save and receiver continuity

Moving the beacon from1930 to530 kHz must not leave saved survey receivers outside
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

## Existing CI failures

The high-observer drone check must obtain an observer genuinely above the current
deliveryship ephemeris, preserving finite depth, below-observer geometry and the
actual same-clock orbital placement. Do not lower the ship or relax the depth
assertion to make the check pass. Reproduce the radio static fixture's reported
failure before choosing a correction; keep real reception/noise requirements.
The streaming budget remains unchanged; do not weaken it to mask a noisy run.

## Integration and outputs

Use one shared task checkout, with separate file ownership for radio and kite
corrections. Main stays on verified source. Run focused regressions locally and
the combined suite through exact-commit CI, then land through the temporary
integration checkout. Update next-release notes and reconcile deed/catalog/probe
registration. Keep compact measured results; remove temporary capture output after
inspection. Retire the completed task checkout and branches when landed.
