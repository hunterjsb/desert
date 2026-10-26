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

On 2026-10-25, a profiled run (40241045337) showed the parallel phase at
95–100% of the runner's four vCPUs and the alone phase at 5–35%. Hosted
runners came as three CPU models, and the EPYC 7763 ran the same probes up
to twice as slowly as the 9V74 or 9V45. Setup outside the probe step was
10–15 s per job, with about 10 s more for the import, so neither was worth
cutting. Three changes followed:

- Salvage probe 2's 73 hand-laid finds now settle at `speed_up(6)`. Each one
  still gets its 270 ticks of 1/60 s. The probe took 343 s locally and now
  takes 69 s, with the same tally and the same worst errors. On CI it went
  from 358 s to 107–120 s.
- The nine Linux groups were rebalanced from per-folder medians over eight
  runs. A probe that runs alone or exclusively counts for the whole runner's
  time. There are still nine jobs, so a run asks for no more runners.
- A regrouped group restores another group's timing history instead of
  starting with none. `test_verify.py` fails if `REST_EXCEPT` and the
  grouped folders disagree.

All 533 probes still run. No check, threshold, simulated duration or failure
path changed. The table below divides each group's probe time by its
runner's speed: that runner's probe seconds over the eight-run medians.

| Linux runs | Slowest job | Runner speed | Heaviest group at median speed | Spread between groups |
| --- | ---: | ---: | ---: | ---: |
| six green runs before, 40214486894–40227315812 | 12:12–16:15 (median 15:01) | 0.55–1.51 | 13:06–13:24 | 7:06–7:36 |
| 40242535618, history from old groups | 13:24 | 0.60–1.29 | 10:56 | 2:28 |
| 40243679401, its own history | 13:52 | 0.62–1.38 | 10:37 | 2:12 |

At median runner speed, the critical path is about a fifth shorter. In both
runs after the change, a slow runner landed on a full group. The hardware
draw still decides most of a run's wall time.

`verify.sh` now checks its run's status every 20 s instead of 60 s. If one
status request fails, it asks once more; two failures in a row stop the wait,
as one did before. It never reruns a job. For a run that was rerun, it names
each failed job of an earlier attempt and that job's failing lines. A green
rerun still counts as green. The dashboard keeps every attempt's jobs, and
labels the earlier ones. While five lanes landed at once, the account's
20-job limit queued Linux jobs for up to 20 minutes. Each verify run asks for
about 90 runner-minutes. Each master run asked for about 280: 90 on Linux,
185 on macOS and Windows, and 4 for builds.

At the coordinator's request the same day, master stopped repeating proven
work. A landing pushes the very commit its verify run passed, so master's
Linux probes repeated that run on the same workflow. A `proven` job now
finds a successful verify-branch run at the pushed commit. When it finds
one, master skips its nine Linux jobs and still runs macOS, Windows and the
builds. Any other push runs them, and so does a failed lookup. The dashboard
takes that verify run's Linux jobs as the commit's evidence. Master's Linux
timing history then refreshes only on pushes that no verify run proved.

Kits probe 8 is a known real-frame flake. Its check "the seeds cost a frame
under 0.2 ms" measured 0.480 ms in run 39603518301 (2026-10-21) and 0.244 ms
in run 40243679401, attempt 1 (2026-10-25). Both were on hosted runners, and
the 2026-10-25 rerun passed. Its threshold stays as it is.

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
