# Working on Desert

## Sources of truth

- Read `docs/vision.md` and the system's `docs/prd/*.md` before changing its design; `docs/code-map.md` finds its code and checks.
- Record Hunter's decisions in the PRD, dated and in his words, before building. Keep its as-built account short. Give each fact one owner and link to it rather than restating it.
- `docs/art-direction.md` governs looks; `docs/world/world-system.md` describes the world.
- Versions follow `docs/version-policy.md`; release steps are in `README.md`.
- Personal notes, machine details, handoffs and session records live outside the repository.

## Worktrees and landing

- Keep the main checkout on master. Work in one sibling worktree per active task, on its own branch; reuse an idle one before making another.
- Import a new worktree, and again after merging master: `godot --headless --path . --import`.
- Merge current `origin/master`, then verify with a copy of `scripts/verify.sh` kept outside the checkout: `<copy> <name>` verifies on `verify-<name>`, and `<copy> <name> --land` lands after green CI. Land one change at a time: `--land` holds the shared lock `../.desert-land.lock` for its whole run, so another driver's landing waits.
- Several drivers (Claude and Codex sessions) work here. Before starting, read `../desert-agents.md` beside the checkouts and add your claim: driver, task, branch, and the folders or files you'll change. Don't start on a claimed area; remove your claim when your work lands.
- `--land` refuses game changes while master's latest macOS/Windows run is red; land that fix with `FIXES_PLATFORMS=1`.
- After landing, remove the task's worktree, local branch and `verify-*` branch. Before removing one, check it has no uncommitted work and nothing running in it; archive abandoned work outside the repository.
- Documentation-only changes skip CI.

## Checks and captures

- Use the Godot version pinned in `.godot-version`, matching CI.
- Run focused probes with `scripts/probe.sh <folder|file>` under the shared suite lock at low priority: `flock ../.desert-suite.lock nice -n 19 scripts/probe.sh <file>`. Whole suites run on CI.
- Use `scripts/unseen.sh` for visual checks; it takes the GPU lock and renders off-screen. Headless Godot compiles no shaders, so inspect real captures before judging visuals. Captures stay out of the repository.
- Give each probe one real failure mode. Avoid wording pins, copies of game logic and staged state. Mark probes that time real frames with `## Runs alone`.
- Number new probes after the numbers on current master when integrating; move their `.gd.uid` files with them.

## Conventions and engine traps

- Put tuning numbers in `game/tuning.tres` rather than code.
- Docs and comments name actions, never keys. Key bindings live in `game/core/controls.gd`.
- Comments briefly explain the domain's why.
- New features come with deeds, recorded where the action happens.
- Add new catalog ids to the creative menu's `GROUPS`; credit new CC0 sounds in `assets/audio/CREDITS.md`.
- Check `is_instance_valid` at the moment an object is freed, including after awaiting frames.
- Jolt uses the lesser of two frictions; use the sand's actual friction.
- Hash integers in shaders (`lattice()`, `hash6`); `sin` hashes tear far from the origin.
- Use `game/ui/page_bar.gd` for scroll bars; ScrollContainer's own styling fails the one-theme probe.
- Stop processes only by exact, inspected PIDs, never by an unseen `pgrep -f` match. Delete recursively only literal or guarded paths.

## Shared edit hazards

Coordinate overlapping work on `Deeds.TABLE`, profile PRD deed counts, creative menu `GROUPS`, audio `CREDITS.md`, and probe numbering. Reconcile all of them against master before landing.
