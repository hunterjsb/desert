# Sandgame

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
  `scripts/probe.sh selftest` proves the runner itself can fail. CI runs both on every
  push.
- **Writing a probe:** extend `Probe`, put the body in `run()`, and call `check()`. Probes
  run on a fixed seed and never find nodes by name.

## Layout

```
game/      the game, one folder per system
probes/    headless probes, one folder per PRD (lib/ is the framework)
look/      look-tests, judged by eye
assets/    only what's in use, copied from the archive branch
docs/      vision, PRDs, the moon, the skeleton plan
```
