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

### As built

The ruin-opening traversal runs at `set_rate(60, 6)` with every tour and per-tick
check kept: 345 s became 88 s locally. Exports use ZIP level 1, 21% faster with
identical contents and attributes; downloads grow about 5%. Regrouping moved the
Windows bottleneck rather than removing it. Hosted timing varies, so no general
speedup is claimed.

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
