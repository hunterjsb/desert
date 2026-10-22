# Probes and builds

## Purpose

Keep iteration short while preserving the vision's headless proof of behavior.
Every probe keeps its checks, fixed seeds, simulated duration and physics step.
Every exported desktop build still runs its native smoke check. Imports remain
mandatory so a changed asset cannot silently use an old imported resource.

## Faster probe runs (agreed 2026-10-21)

- Speed a probe up with its own simulation clock, never by shortening walks,
  removing assertions or raising timeouts.
- Schedule from measured durations: a per-platform, per-group timing history kept
  apart from the imported-asset cache, so long probes start first. A retry's
  duration replaces its failed attempt's.
- Balance groups by the measured critical path. `.github/workflows/probes.yml`
  owns the groups; new folders fall into its catch-all.
- A probe that needs the worker pool to itself says so in its header, and still
  runs on native platforms, unlike a real-frame `## Runs alone` probe.
  `scripts/probe.sh` owns the markers.
- Measure packaging compression before changing it, preserving archive contents,
  permissions, macOS symlinks and every native smoke check.
- Runner changes prove selection, exclusive scheduling and failure propagation in
  `scripts/probe-runner-test.sh`, beside the real-engine selftest.

## CI speed pass (agreed 2026-10-22)

*Hunter, 2026-10-21: “we really need to speed up these probe test and build times”;
“we cannot compromise on reliability or performance.”*

- Rebalance Linux folders using recent measured group times while keeping every probe,
  threshold, failure path and build smoke check. Shorten simulated time only when the
  same behavior and coverage remain proved; leave sampled real-frame, travel and
  long-duration hazard checks intact when shortening them would weaken coverage.
- Keep native platform grouping separate unless its own measurements support a change.

### As built

The ruin-opening traversal runs at `set_rate(60, 6)` with every tour and per-tick
check kept: 345 s became 88 s locally. Exports use ZIP level 1, 21% faster with
identical contents and attributes; downloads grow about 5%.

On 2026-10-22, the Linux `the rest` group was the critical path in green run
39847859847 (15:35). Moving all nine `probes/wrecks` probes into
`probes/weather probes/salvage` made the groups more balanced; the combined
green run 39861825439 kept all 520 probes and finished in 22:54, with the
longest group at 13:53. No probe logic, simulated duration, threshold or
failure path changed. The earlier green runs varied: group times below are
`verify-batch6 / combined after`, in minutes and seconds. The after run also
contains ten more probes than the baseline.

| Linux group | Probes before → after | Group wall before / after |
| --- | ---: | ---: |
| foundation, world, dev, radio | 98 → 98 | 14:44 / 13:53 |
| the rest | 88 → 80 | 15:35 / 13:20 |
| devices, menus | 68 → 69 | 7:44 / 8:14 |
| weather, salvage → weather, salvage, wrecks | 36 → 45 | 8:49 / 11:13 |
| saves, kits | 65 → 67 | 11:19 / 14:04 |
| survival, sail | 46 → 51 | 9:40 / 11:36 |
| movement | 43 → 43 | 13:08 / 13:06 |
| power, farming | 33 → 34 | 5:05 / 6:57 |
| rope | 33 → 33 | 6:17 / 4:23 |

Probe-wall seconds marked to run alone (`Runs alone`) or exclusively (`Exclusive`)
were:

| Linux group | Runs alone before → after (count / seconds) | Exclusive before → after (count / seconds) |
| --- | ---: | ---: |
| foundation, world, dev, radio | 4 / 63 → 4 / 64 | 1 / 230 → 1 / 230 |
| the rest | 10 / 290 → 9 / 276 | 1 / 13 → 1 / 13 |
| devices, menus | 0 / 0 → 0 / 0 | 0 / 0 → 0 / 0 |
| weather, salvage → weather, salvage, wrecks | 1 / 22 → 2 / 41 | 1 / 143 → 1 / 200 |
| saves, kits | 1 / 43 → 1 / 46 | 1 / 166 → 1 / 186 |
| survival, sail | 3 / 82 → 5 / 117 | 0 / 0 → 0 / 0 |
| movement | 7 / 155 → 7 / 152 | 1 / 219 → 1 / 221 |
| power, farming | 1 / 32 → 1 / 34 | 0 / 0 → 0 / 0 |
| rope | 1 / 22 → 1 / 21 | 0 / 0 → 0 / 0 |

The `verify-batch6 / master` group-wall pairs were, respectively: foundation
14:44 / 14:46; rest 15:35 / 16:32; devices 7:44 / 7:59; weather/salvage
8:49 / 9:09; saves/kits 11:19 / 15:39; survival/sail 9:40 / 7:30; movement
13:08 / 12:51; power/farming 5:05 / 4:30; rope 6:17 / 6:13. Hosted runner
load and the extra probes affect comparisons, so these runs are evidence for
the rebalance, not a stable per-group speed guarantee. The 25 slowest probes
and their wall times were sent with the verification report. Recent master build
measurements were 62 s for export and 46 s for the Linux smoke check; build
steps were not changed.

## Performance dashboard (agreed 2026-10-21)

*Hunter, 2026-10-21: "let's add github pages... after deploys we should rebuild a
github page that give us stats on probes and build stats".* He then asked for a
scatter chart to pick a run, simpler tables, and "dashboard-only changes just run
the dashboard checks".

- A static Pages site, rebuilt after completed master Probes and Release runs
  (failures included) or by hand. It reads existing Actions evidence, never starts
  Godot and never gates a release.
- A bounded run history in its own Actions cache. Losing the cache starts a new
  history; it never invents measurements. Each result links its source run and names
  its commit, platform, attempt and any missing logs.
- CI durations, per-probe wall time and retry cost stay apart from in-game
  measurements. A probe reports one with `metric(label, value, unit, budget)`;
  `check()` still owns pass and fail. A missing measurement is never zero, a failed
  first attempt stays visible, headless numbers say GPU cost is absent, and a change
  is a signal on variable hosted hardware, not a proven regression.
- The page: a scatter of the selected workflow's runs, start time against elapsed
  minutes, where a click or a key selects a run; then plain tables for that run:
  summary, measurements with their limit (or "No limit") and nearest earlier passing
  sample, slow probes, jobs and artifacts. No runtime dependencies. Logs are data,
  never executed or interpolated, read with a read-only token.
- Dashboard-only changes run only the dashboard's checks. Any game, probe, runner or
  verifier change keeps the game suite.

### As built

`scripts/ci_dashboard/collect.py` (standard-library Python, checked by
`test_collect.py`) collects; `site/` renders; `.github/workflows/performance-pages.yml`
checks, collects and deploys to <https://hunterjsb.github.io/desert/>. `scripts/verify.sh`
routes dashboard-only changes, checked by `scripts/test_verify.py`. The streaming,
rope-tick and long-walk probes report measurements.
