# Launcher

*New product, agreed by Hunter, 2026-10-20. Canonical source and eventual cross-platform
GitHub release. This PRD governs the external desktop app; it is not an in-game menu.*

## Purpose

Desert Launcher is the player-facing way to install, update and play a published Desert
build, and the developer-facing way to launch a local source tree. It should feel like a
small, deliberate game launcher, not a script-shaped utility. The normal player path is
to open the launcher, see the latest available game version, and install or play it.

## Agreed behavior

- Keep **Play** and **Source** as distinct areas. Play is the default and shows published
  GitHub game releases, installed versions and install state. Source is a developer tool.
- In Play, list releases newest first, identify the latest release, show its version and
  release notes, and let the user install, launch, update or uninstall a game version.
  Download the matching Linux, Windows or macOS archive from the repository's GitHub
  release. Keep user saves outside managed install folders.
- Find existing installations in the launcher's known user-data locations and let users
  choose another installation folder. Let them choose a local repository folder if the
  configured repo path is unavailable. Remember user-selected paths in per-user settings.
- Manage only launcher-owned install folders. Uninstall removes the selected game build
  and its files, after a clear confirmation; it does not remove saves or user-selected
  folders.
- In Source, present known Git worktrees as a sortable table with branch/worktree name,
  latest commit time, truncated latest commit message, project version and local-change
  state. Offer explicit **Run game** and **Open editor** buttons. Do not show arbitrary
  branches without a checked-out project; provide a refresh and a way to hide stale
  entries. Never delete worktrees or branches automatically.
- Source discovery is scoped to a selected repository and its Git worktrees. Users can
  choose a different repository path when discovery fails. No machine-specific absolute
  paths are part of the app.
- The launcher itself is versioned and packaged for Linux, Windows and macOS, with builds
  published on GitHub after the launcher is polished. Game release assets remain the
  existing `desert-<version>-<platform>.zip` archives.
- The app must clearly report offline, unsupported-platform, missing-runtime and
  download/extraction errors, with a retry path where useful.

## Product decisions still open

- Whether launcher's first public release is a separately tagged GitHub release or part
  of each game release. Initial implementation should use a separate launcher tag and
  release workflow so launcher updates do not require a game version bump.
- Whether an update replaces the prior installed version or keeps multiple versions.
  Initial implementation should keep multiple versions so the version browser remains
  useful and rollback is straightforward.
- Whether stale source worktrees can be removed from inside the app. For the first
  version, allow hiding stale rows and explain how to remove them with Git; actual Git
  worktree/branch deletion needs a separate, explicit design.
- How installer signing/notarization will be handled for public Windows and macOS
  distribution. Initial CI may produce unsigned packages and must label them accurately.

## Implementation shape

- Keep the launcher in a standalone `launcher/` folder with its own dependencies and
  cross-platform packaging workflow. It must run independently of Godot and the game.
- Query GitHub's releases API without requiring authentication. Match assets to the
  running OS and architecture, download to a temporary file, validate the archive's
  expected project layout, and only then install into a launcher-owned directory.
- Keep launcher settings separate from the repository and installed builds. Store only
  user preferences and install/repository paths there.
- Source table metadata comes from Git (`worktree list`, `log`, `status`) and each tree's
  `project.godot`; failed or missing trees are surfaced as unavailable rows, not silently
  mistaken for valid game versions.

## As built

**First implementation, 2026-10-20:** `launcher/main.py` is a standalone PySide6 desktop
app. Play opens on the GitHub release list, selects the newest release, shows release
notes and supports platform-matched download, launch, update, uninstall and opening the
install folder. It remembers a custom install location, searches standard user game
folders for version-named exports, and limits uninstall to folders registered with the
launcher. Game saves are outside these install folders.

Source discovers checked-out Git worktrees, with branch, local folder name, commit date,
truncated summary, `project.godot` version and dirty state. Run and editor are separate
buttons. Users can select a repository path and hide or show worktrees without removing
files. Branch-only refs are not shown because they have no checked-out game to launch.

`launcher-release.yml` packages Linux x86_64, Windows x86_64, and macOS arm64 and x86_64
builds on launcher tags. Signing and notarization remain open. This is an initial
implementation; cross-platform CI and desktop interaction have not yet been run.
