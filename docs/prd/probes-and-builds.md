# Probes and builds

## Purpose

Keep iteration short while preserving the vision's headless proof of behavior.
Every probe keeps its checks, fixed seeds, simulated duration and physics step.
Every exported desktop build still runs its native smoke check. Imports remain
mandatory so a changed asset cannot silently use an old imported resource.

## First optimization pass (agreed 2026-10-21)

The green master run 39615663839 spent 887 s in its slowest Linux probe group,
1659 s in its slowest Windows group, and 51 s exporting all three platforms.
The ruin-opening traversal alone took 361–374 s. Native terrain walks and camp
warnings timed out under contention, then passed alone: Windows spent 300 + 194 s
on the world walk, 601 + 339 s on warnings, and 301 + 243 s on salvage retention.

- Accelerate the ruin-opening traversal using MovementProbe's existing clock:
  retain 60 physics steps per simulated second, every tour and every per-tick check.
- Add `## Exclusive` for checks that need the worker pool to themselves on every
  platform, and `## Exclusive on noisy runners` for measured contention-sensitive probes.
  Under `PROBE_NOISY`, run these sequentially without first attempting them in the
  parallel pool. Unlike `## Runs alone`, they must still run on native platforms.
  Real-frame checks retain their existing semantics. Both 20 km walks need exclusivity on Linux too: world 3 hit 300 s in
  run 39632652358, and salvage 7 did the same in run 39634871098.
- Preserve scheduling durations separately from the immutable imported-asset
  cache. Save a fresh per-platform, per-group timing cache after each CI run so
  long probes actually start first on subsequent runs. Retry durations should
  replace the failed attempt's duration, not perpetually record its timeout.
- Keep nine Linux groups, moving radio into foundation/world/dev and menus into
  devices. The next master run (39629562854) took 1028 s in the catch-all group
  against 320 s for foundation and 345 s for devices; radio and menus account
  for 1370 s of its summed probe time. Its fallback must still include new folders.
- Balance the existing four native groups after measuring the landed pass. In
  run 39640555594, saves/kits/sail/power/farming/survival took 2101 s while the
  other Windows groups took 972–1022 s. Move survival beside arrival/camp/movement. Retain power/farming beside
  saves/kits/sail: moving both beside physical gear made the slowest Windows
  step worse (2271 s versus 2149 s on the same runtime baseline).
  Kits 3 hit its 400 s limit in the pool then passed alone in 196 s, so mark it
  exclusive on noisy runners. No additional jobs or timeout increases.
- Measure packaging compression before changing it; preserve archive contents,
  executable permissions, macOS symlinks and all native smoke checks.

Runner changes must prove selection, exclusive scheduling and failure propagation
with a deterministic shell check, as well as the existing real-engine selftest.
No timeout increases, shorter walks or removed assertions are part of this pass.

## As built

The ruin-opening traversal uses `set_rate(60, 6)`: all tours and per-tick
assertions remain, while the focused local run fell from 345 s to 88 s (74% less).
World 3 and salvage 7 run exclusively everywhere; movement 5 does so on native
runners, as does kits 3. Radio 39 retains the shared integration's five-FPS reproduction and observes
two process-frame signals so the speech diagnostic consumer has completed its
callback. Both god words and the actual beacon bearing remain checked. The runner
still retries failures and records the retry duration. Scheduling checks exercise
exclusivity, retained native coverage, real-frame exclusion and failure propagation.

All three local exports fell from 43.905 s to 34.609 s (21% less) using ZIP
level 1 instead of the default level 6. Archive contents, CRCs, file sizes and
Unix attributes (including executable bits and macOS symlinks) match exactly;
archive integrity checks pass. Downloads grow 4.6% on Linux, 5.9% on Windows and
6.3% on macOS. The real-engine runner selftest, scheduling checks, shell syntax,
ShellCheck warnings and actionlint pass. The first landed pass passed all 21 Linux, Windows, macOS and exported-build
checks in [run 39640555594](https://github.com/hunterjsb/desert/actions/runs/39640555594).
Its final Linux verification's slowest job fell from 1046 s to 736 s (30% less)
against the pre-pass baseline; hosted timing varies. CI export/ZIP time fell
from 52 s to 41 s (21% less).

The native regrouping also passed all 21 checks in
[run 39648194997](https://github.com/hunterjsb/desert/actions/runs/39648194997),
but moved the bottleneck rather than improving the critical path. Its Windows
saves/kits/sail step fell to 1435 s while the enlarged equipment group took
2271 s. Power/farming are therefore restored to the saves group; survival stays
with movement. Kits 3 passed first attempt in 199 s with exclusive scheduling,
avoiding its previous 400 s timeout plus 196 s retry. The corrected distribution
passed all nine Linux groups in
[run 39654283432](https://github.com/hunterjsb/desert/actions/runs/39654283432).
Its postlanding native/build verification is
[run 39656106279](https://github.com/hunterjsb/desert/actions/runs/39656106279).
The corrected Windows critical probe step took 1867 s, versus 2149 s on the
same-runtime pre-regrouping baseline (13% less); equipment took 1127 s and
saves/kits/sail/power/farming remained the bottleneck. The slowest Linux probe
step was 629 s. Export/ZIP took 46 s on this run versus 41 s on the earlier
landed pass. One macOS job never acquired a hosted runner and required a retry;
runner queue delay is excluded from these step timings.
These scheduling changes retain nine Linux and four groups per native OS, every
probe, and existing timeout limits. No universal native speedup is claimed:
hosted timing varies, and whole-suite critical path matters more than an
individual group's improvement.
