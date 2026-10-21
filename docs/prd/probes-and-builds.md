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
- Add `## Exclusive on noisy runners` for measured contention-sensitive probes.
  Under `PROBE_NOISY`, run these sequentially without first attempting them in the
  parallel pool. Unlike `## Runs alone`, they must still run on native platforms.
  Linux keeps its existing parallel schedule and real-frame checks.
- Preserve scheduling durations separately from the immutable imported-asset
  cache. Save a fresh per-platform, per-group timing cache after each CI run so
  long probes actually start first on subsequent runs. Retry durations should
  replace the failed attempt's duration, not perpetually record its timeout.
- Measure packaging compression before changing it; preserve archive contents,
  executable permissions, macOS symlinks and all native smoke checks.

Runner changes must prove selection, exclusive scheduling and failure propagation
with a deterministic shell check, as well as the existing real-engine selftest.
No timeout increases, shorter walks or removed assertions are part of this pass.

## As built

The ruin-opening traversal uses `set_rate(60, 6)`: all tours and per-tick
assertions remain, while the focused local run fell from 345 s to 88 s (74% less).
Native exclusivity is attached to world 3, salvage 7 and movement 5. The runner
still retries failures and records the retry duration. Scheduling checks exercise
exclusivity, retained native coverage, real-frame exclusion and failure propagation.

All three local exports fell from 43.905 s to 34.609 s (21% less) using ZIP
level 1 instead of the default level 6. Archive contents, CRCs, file sizes and
Unix attributes (including executable bits and macOS symlinks) match exactly;
archive integrity checks pass. Downloads grow 4.6% on Linux, 5.9% on Windows and
6.3% on macOS. The real-engine runner selftest, scheduling checks, shell syntax,
ShellCheck warnings and actionlint pass. Full combined CI verification pending.
