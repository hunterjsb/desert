# Desert

A cozy survival game on a dead desert moon. Working title.

Docs first: [docs/vision.md](docs/vision.md) says what the game is, each system has a PRD
in `docs/prd/`, and [docs/README.md](docs/README.md) maps the full documentation set.
[docs/skeleton-plan.md](docs/skeleton-plan.md) records the original build order.
Sand Game, the prototype this replaces, lives on the
[`archive`](https://github.com/hunterjsb/desert/tree/archive) branch.

## Working on it

- **Godot 4.7.2**, pinned in `.godot-version`. Open the project in the editor and run
  it. The dev overlay shows every number the game publishes; the game lists its keys,
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
that copy from the worktree with `<name>`, or `<name> --land` after merging current
`origin/master`. It pushes `verify-<name>`, waits for that commit's run and prints what
failed; failures block landing. Docs-only changes skip CI, and dashboard-only changes
run only the dashboard's checks. Branch pushes run the Linux groups; master and tags
also run native macOS/Windows probes and build smoke checks (`.github/workflows/probes.yml`
owns the groups). While master's latest macOS/Windows run is red, `--land` names the
failing probe and lands no game change but its fix (`FIXES_PLATFORMS=1`).
`scripts/probe.sh`'s header describes its scheduling markers.

## Releasing

Versions follow the [version policy](docs/version-policy.md); milestones and their
gates are in the [Alpha roadmap](docs/alpha-roadmap.md).

The version lives in one place, `application/config/version` in `project.godot`, and
shows in the main menu's corner alongside `application/config/release_name`.
The release name also appears in the GitHub release title. `scripts/export.sh` exports the Linux, Windows and
macOS builds (`export_presets.cfg`) and zips each as `desert-<version>-<os>.zip`; it
needs the pinned export templates installed. CI runs it on every push, then launches
each build on its own OS for a smoke test (`scripts/probe.sh smoke <game>`).

- **Dry run:** `gh workflow run release.yml --ref <branch>`. The zips are the run's
  artifacts; nothing is published.
- **Cut a release:** set the version in `project.godot`, give it a `## <version>`
  section in `RELEASE_NOTES.md`, merge to master, then tag that commit `v<version>` and push the tag. The Release
  workflow builds and smoke-tests it again and publishes a GitHub pre-release with the
  zips and that version's notes (plus How to start and Known issues) only after that tag's full Probes run succeeds. A failed,
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
GitHub Pages configured to use GitHub Actions. It keeps a bounded run history and
backfills recent runs if its cache is lost. Source and
checks live in `site/` and `scripts/ci_dashboard/`; requirements and measured results
live in [Probes and builds](docs/prd/probes-and-builds.md).
