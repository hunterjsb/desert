# Working on Desert

## Sources of truth

- Read `docs/vision.md` and the relevant system's `docs/prd/*.md` before changing its design.
- Use `docs/code-map.md` to find that system's entry points and checks.
- Record agreed design decisions in the PRD before implementation; update its as-built account with measured results.
- `docs/art-direction.md` governs looks; `docs/world/world-system.md` describes the world. `README.md` has release steps.
- Personal preferences, machine details, in-flight handoffs and session records belong outside the repository.

## Worktrees and landing

- Keep the main checkout on verified master. Make changes in a sibling worktree; use `codex/` for new branches.
- Keep only main, play, integration and one worktree per active implementation task. Reuse an idle task worktree before creating another; audit existing worktrees before fanning out.
- After landing, remove the completed task worktree and its local branch immediately. Remove its remote verification branch too. Archive abandoned unmerged commits and dirty patches outside the repository before retiring their checkouts; never accumulate parked task worktrees.
- Before removal, inspect current changes and exact process working directories, and coordinate with other agents. Preserve actively used checkouts and the user’s play build.
- The detached `desert-wt-play` worktree is the user's play build. Coordinate before moving or launching it.
- Import a new worktree, and again after merging master: `godot --headless --path . --import`.
- Integrate in the detached sibling `desert-wt-merge2`. Land one change at a time.
- Push work for verification to `verify-*`. Copy `scripts/verify.sh` outside the checkout before running the copy from the worktree: `<copy> <name>` verifies, and `<copy> <name> --land` lands after green CI.
- Merge current `origin/master` before landing; resolve conflicts and verify the combined result. Keep master green and push each completed commit through this flow.
- Follow the release version policy in `README.md`: fixes bump patch; named alpha sub-releases bump minor. Update version and release notes together.
- Documentation-only changes skip CI. Platform jobs run on master; check their results after landing.

## Checks and captures

- Use the Godot version pinned in `.godot-version`, matching CI.
- Run targeted probes with `scripts/probe.sh <folder|file>`. On this shared machine, take the suite lock at `../.desert-suite.lock` and run at low priority: `flock ../.desert-suite.lock nice -n 19 scripts/probe.sh <file>`.
- Whole suites run on CI through `verify.sh`; reserve local runs for focused checks.
- Use `scripts/unseen.sh` for visual checks. It takes the shared GPU lock and runs gamescope unseen; never cover the user's game with a window.
- Headless Godot does not compile shaders. Inspect actual captures before judging visual changes.
- Give each probe one real failure mode. Keep checks terse; avoid wording pins and copies of implementation logic. Mark probes that time real frames with `## Runs alone`.
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
- Inspect and record exact PIDs before stopping processes. Never kill from an unseen `pgrep -f` match or wait on a pattern that can match the waiting shell itself.
- Use literal paths or guarded variables for recursive deletion.

## Shared edit hazards

Coordinate overlapping work on `Deeds.TABLE`, profile PRD deed counts, creative menu `GROUPS`, audio `CREDITS.md`, and probe numbering. Reconcile all of them against master before landing.
