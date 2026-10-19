# Desert

A cozy survival game on a dead desert moon. Working title.

Docs first: [docs/vision.md](docs/vision.md) says what the game is, each system has a PRD
in `docs/prd/`, and [docs/skeleton-plan.md](docs/skeleton-plan.md) is the build order.
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
  Linux, macOS and Windows.
- **Writing a probe:** extend `Probe`, put the body in `run()`, and call `check()`. Probes
  run on a fixed seed and never find nodes by name.

## Releasing

Fix releases increment the patch version (for example `0.2.1-alpha`). Alpha
sub-releases increment the minor version, reset the patch to zero, and always
have a name. The current 0.2 line is **“Sailboat”**; the next minor release is
**0.3 “Sanddune”**. Patch releases keep
their minor release's identity. Versions change per release, not per commit.
The [1.0 Alpha roadmap](docs/alpha-roadmap.md) tracks the proposed completion gate.

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
docs/      vision, PRDs, the moon, the skeleton plan
```
