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
All 21 postlanding Linux, native and build checks passed in
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

## Performance dashboard (agreed 2026-10-21)

Publish a small static GitHub Pages site after completed master Probes runs and
Release runs, including failed runs; allow manual refresh. It reads existing
Actions evidence and never starts Godot or adds a dependency to release gates.
A bounded history (40 completed runs, backfilled from the latest eight per workflow
when empty) lives in a separate Actions cache. Cache loss starts a clearly bounded
new history rather than inventing measurements. The page links every result to its
source run and records the commit, platform, attempt, collection time and missing
log coverage. Retried jobs replace their older attempt's result when refreshed.

Separate CI elapsed/job/step duration, per-probe wall time and retry cost from
in-game measurements. Expose existing streaming, rope tick and long-walk memory
measurements as structured probe output even on success. Real-frame checks remain
Linux-only; headless measurements say explicitly that GPU/shader cost is absent.
Do not infer frame rate from a probe's runtime. Compare a probe only with earlier
successful measurements on the same platform/workflow; describe changes as signals
on variable hosted hardware, not proven game regressions. Failed first attempts
remain visible even when the retry passes. Missing measurements are never zero.

Show run history, platform/search filters, slow probes, job/step bottlenecks,
retry cost, exported archive artifact sizes and game measurements with existing
budgets where applicable. Use accessible, responsive HTML/CSS/JavaScript without
third-party runtime dependencies. Treat collected logs as data: no execution, no
raw log publication or HTML interpolation. Publish only trusted default-branch
site code, with a read-only collection token and Pages/OIDC deploy permissions.
The dashboard has its own lightweight checks; failure never bypasses game checks.

### First implementation

The collector is Python standard-library code and the page has no runtime packages.
A six-run real-data preview held 732 KB of JSON; a cached refresh took 1.19 s locally.
It excludes runner selftests, preserves failed-attempt cost, labels unavailable logs,
and measures elapsed time from original run creation even after a partial rerun.
Jobs that never acquired a runner have no execution-time measurement.

Focused streaming, rope, world-walk and salvage-walk checks passed (16, 20, 109 and
88 s respectively), preserving all assertions and emitting ten structured metrics.
Five collector checks, runner scheduling/metric retention checks, shell and workflow
lint pass. Desktop and 390 px browser checks exercised platform/search filtering,
full result expansion and job details without script errors or page overflow;
metric cards rendered all ten actual local samples in a separate preview fixture.
The production site consumes CI evidence only. Full CI and initial deployment are
checked when this change lands; local preview measurements are not CI baselines.

A probe opts in with `metric(label, value, unit, optional_budget)`; its existing
`check()` still owns pass/fail. The metric helper only reports evidence and never
asserts a limit. Keep labels and units stable for history comparisons. The runner
prints the verdict before the metric records, associating measurements with the
correct first attempt or retry. Failed measurements stay marked failed; missing
ones do not enter passing trend lines.

The initial [Pages deployment](https://github.com/hunterjsb/desert/actions/runs/39669517833)
published [the observatory](https://hunterjsb.github.io/desert/) with 15 historical
runs. Checks took 6 s, the cold backfill/build 65 s, and deployment 12 s, excluding
runner queue delay. Desktop and narrow-layout checks also passed on the public
site. Linux verification passed all nine groups in
[39667591018](https://github.com/hunterjsb/desert/actions/runs/39667591018).

The first full run passed 20 of 21 jobs; macOS salvage retention timed out at
301 s and 300 s before reaching its measurement output. Across 110 passing probes
in that job, median runtime was 2.1 times the preceding master run; this alone does
not establish the cause. No assertion or timeout was changed. The
[completion-triggered refresh](https://github.com/hunterjsb/desert/actions/runs/39675753373)
succeeded and publicly reported the failed run, both attempts, their 601 s total,
and 16 available game measurements. Browser checks confirmed those results on the
live page. Missing measurements stayed absent. A targeted retry of the failed job
is tracked in [the source run](https://github.com/hunterjsb/desert/actions/runs/39669517959).


### Plain run report (agreed 2026-10-21)

Replace the large summary cards with a compact selected-run table. Move the game
measurements into that same report, without a separate “Game performance” section
or decorative sparklines. Each measurement names its platform, value, assertion
limit when supplied, and whether it is below, at or above that limit. Keep the
probe's actual verdict separate: a measurement alone cannot certify a whole probe.
Without a limit, say “No limit” rather than implying good or bad. Show the nearest
earlier passing sample on the same platform and workflow, with its source run and
numeric change; absent history is explicitly “No earlier sample”. Keep history,
slow probes, job details and artifacts. Favor compact tables over presentation.

The plain report replaces the four summary cards and measurement cards with tables,
removes the large introductory heading and the separate game-performance section,
and preserves source links and filters. Desktop and 390 px browser checks passed:
summary rows, limit/no-limit states, absent history, metric search, empty results,
probe expansion and job details. Five collector checks and JavaScript syntax pass.


Combined master [39672634648](https://github.com/hunterjsb/desert/actions/runs/39672634648)
passed all 21 jobs, including macOS salvage retention. The redundant retry of the
original run was cancelled; no assertions or budgets changed. The public report
contains all 18 measurements from the successful combined run.

The plain-table revision passed all nine Linux verification groups in
[39680975173](https://github.com/hunterjsb/desert/actions/runs/39680975173) and
[deployed successfully](https://github.com/hunterjsb/desert/actions/runs/39683448632).
Public desktop/mobile checks confirmed the tables, limit/no-limit labels, filtering,
and actual earlier-run references; a controlled comparison also verified numeric
and percentage deltas. Missing history remains explicit rather than implying zero.


### Dashboard-only verification (agreed 2026-10-21)

Changes confined to `site/`, `scripts/ci_dashboard/`, and the Performance pages
workflow, optionally alongside documentation, run dashboard checks instead of the
game suite. Push and pull-request filters exclude these paths from Probes;
manual Probes dispatch and tag coverage remain available. The copied verifier
selects Performance pages for this narrow scope, waits for the exact branch and
commit, and lands only on success. Its fallback dispatches the selected workflow.
Any game, probe, shared runner, verifier or other infrastructure change retains
game verification. Documentation alone still skips CI. Master dashboard pushes
run checks, collect existing evidence and deploy, without starting Godot.


Eight local-remote checks prove dashboard routing/landing, mixed and shared-runner
changes retaining game checks, moving game files into dashboard paths retaining
game checks, failure blocking, both fallback dispatches, and docs-only skipping.
Shell syntax, ShellCheck and both affected workflow lints pass. The routing change
itself changes shared CI infrastructure and therefore takes the game-check path.


### Run scatter plot (agreed 2026-10-21)

Replace the history bars with a scatter chart before the selected-run tables.
Horizontal position is the run's start date/time; vertical position is elapsed
minutes, including waits and reruns. Plot the selected workflow's retained runs,
so releases and probes are not mixed. Clicking a dot selects its run and refreshes
the report. Dots expose date, duration, result and commit, support keyboard selection,
and distinguish the selected run without relying on color alone. Keep date and
minute axes visible; missing elapsed time is not plotted as zero.


The SVG chart uses actual timestamps and elapsed minutes with labeled axes and no
charting dependency. Desktop and 390 px browser checks passed for click and keyboard
selection, the selected-dot ring, report updates and placement before the tables.
