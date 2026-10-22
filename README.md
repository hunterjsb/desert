# Desert

A cozy survival game on a dead desert moon. Working title.

Docs first: [docs/vision.md](docs/vision.md) says what the game is, each system has a PRD
in `docs/prd/`, and [docs/README.md](docs/README.md) maps the full documentation set.
[docs/skeleton-plan.md](docs/skeleton-plan.md) records the original build order.
Sand Game, the prototype this replaces, lives on the
[`archive`](https://github.com/hunterjsb/desert/tree/archive) branch.

## Working on it

- **Godot 4.7.2**, pinned in `.godot-version`. Open the project in the editor and press
  F5. The dev overlay shows every number the game publishes; the game lists its keys,
  which are defaults set in `game/core/controls.gd`.
- **Tuning** lives in `game/tuning.tres`. Change numbers there, never in code.
- **Probes** are headless checks, one folder per PRD under `probes/`. Run them with
  `scripts/probe.sh`; it needs a `godot` binary on your PATH, or set `GODOT`.
  `scripts/probe.sh selftest` proves the runner itself can fail. It runs in bash 3.2 and
  up, so in macOS's own and in Git Bash on Windows too. CI runs both on every push, on
  Linux; master and tags also run the native macOS and Windows checks.
- **Writing a probe:** extend `Probe`, put the body in `run()`, and call `check()`. Probes
  run on a fixed seed and never find nodes by name.

## Verifying a change

Work in a sibling worktree. Copy `scripts/verify.sh` outside the checkout, then run
that copy from the worktree with `<name>` (or `<name> --land` after merging current
`origin/master`). It pushes `verify-<name>` and waits only for that branch's exact
commit, accepting push or manual-dispatch runs. Changes confined to `site/`,
`scripts/ci_dashboard/` and `.github/workflows/performance-pages.yml` (plus docs)
wait for `performance-pages.yml` checks. Other code and infrastructure changes wait
for `probes.yml`. If no push run appears within about 30 seconds, it dispatches the
selected workflow on the same branch; game verification uses `full_platforms=false`
for the existing nine Linux groups. Failures block landing. Run polling is once a
minute. Documentation-only changes skip CI.

Game-affecting master pushes and tags run Linux, native macOS/Windows probes and
build smoke checks. Dashboard-only master pushes check and deploy Pages without
running the game suite. Manual Probes dispatches retain their existing coverage.
Native probes balance survival with arrival/camp/movement, power/farming with
saves/kits/sailing, and physical gear together to keep each group within budget. New folders still join “the rest”.
Linux balances radio with foundation/world checks and menus with devices, leaving
the catch-all group for unlisted folders.
Probe durations have their own per-platform/group cache so long checks start first.
`## Exclusive` runs a check alone on every platform.
`## Exclusive on noisy runners` keeps measured contention-sensitive checks out of the
native parallel pool; those checks still run, unlike real-frame timing checks.
`scripts/probe-runner-test.sh` checks scheduling without starting Godot.
Manual Probes dispatches default to `full_platforms=true`, retaining full preview
coverage; only an explicit branch dispatch with `full_platforms=false` omits the native
and build jobs. Master/tag coverage cannot be disabled by that input.

## Releasing

Desert uses [milestone versioning](docs/version-policy.md), with compatibility
stated separately in release notes. A new named playable milestone increments
the middle number and resets the patch; fixes, tuning, polish and bounded
improvements within it increment the patch. Patch names retain the milestone's
base name, with an optional adjective. Versions change per release, not per commit.

This release is **0.3.0-alpha “Sanddune”**, followed by Sanddune patches as
playtesting continues. The next planned milestone is **0.4 “Spaceport”**.
**1.0.0-alpha** earns the [full Alpha roadmap gate](docs/alpha-roadmap.md#full-alpha-acceptance-gate);
Beta and the public **1.0.0** each have later quality gates in the version policy.

The version lives in one place, `application/config/version` in `project.godot`, and
shows in the main menu's corner alongside `application/config/release_name`.
The release name also appears in the GitHub release title. `scripts/export.sh` exports the Linux, Windows and
macOS builds (`export_presets.cfg`) and zips each as `desert-<version>-<os>.zip`; it
needs the pinned export templates installed. CI runs it on every push, then launches
each build on its own OS for a smoke test (`scripts/probe.sh smoke <game>`).

- **Dry run:** `gh workflow run release.yml --ref <branch>`. The zips are the run's
  artifacts; nothing is published.
- **Cut a release:** set the version in `project.godot`, update `RELEASE_NOTES.md`,
  merge to master, then tag that commit `v<version>` and push the tag. The Release
  workflow builds and smoke-tests it again and publishes a GitHub pre-release with the
  zips and the notes only after that tag's full Probes run succeeds. A failed,
  cancelled or missing probe run blocks publication. A tag that doesn't match
  the version publishes nothing.

## Layout

```
game/      the game, one folder per system
probes/    headless probes, one folder per PRD (lib/ is the framework)
look/      look-tests, judged by eye
assets/    only what's in use, copied from the archive branch
docs/      vision and PRDs, with world references and supporting briefs grouped by topic
launcher/  the standalone desktop app for published releases and local source worktrees
```

## Desert Launcher

The separate desktop launcher installs and runs published game releases or opens a
checked-out source worktree in Godot. See [launcher/README.md](launcher/README.md) and
the [launcher PRD](docs/prd/launcher.md). Its cross-platform builds publish from
`launcher-v*` tags independently of the game version.

## Performance observatory

[The GitHub Pages dashboard](https://hunterjsb.github.io/desert/) refreshes after
completed master Probes and Release workflows, including failures. It shows
probe/retry costs, job and build steps, artifact sizes and opt-in game measurements.
It consumes existing evidence; it never reruns the suite or gates a game release.
Real-frame metrics are Linux-only and headless, so they do not measure GPU cost.

Refresh manually with `gh workflow run performance-pages.yml`. The site requires
GitHub Pages configured to use GitHub Actions. Its bounded history cache retains
40 runs; on cache loss it backfills eight recent runs per workflow. Source and
checks live in `site/` and `scripts/ci_dashboard/`; requirements and measured results
live in [Probes and builds](docs/prd/probes-and-builds.md).
