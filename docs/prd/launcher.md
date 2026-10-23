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
- In Play, use a version dropdown ordered newest first, identify the latest published
  release, show its version and scrollable release notes, and let the user install,
  launch, update or uninstall a game version.
  Download the matching Linux, Windows or macOS archive from the repository's GitHub
  release. Keep user saves outside managed install folders.
- Find existing installations in the launcher's known user-data locations and let users
  choose another installation folder. Let them choose a local repository folder if the
  configured repo path is unavailable. Remember user-selected paths in per-user settings.
- Manage only launcher-owned install folders. Uninstall removes the selected game build
  and its files, after a clear confirmation; it does not remove saves or user-selected
  folders.
- In Source, present known Git worktrees in a searchable table with branch/worktree name,
  latest commit time, truncated latest commit message, project version and local-change
  state. Keep pinned branches at the top, with `master` pinned by default. Offer explicit
  **Run game** and **Open editor** buttons. Do not show arbitrary branches without a
  checked-out project; provide a refresh and a way to hide stale entries. Never delete
  worktrees or branches automatically.
- Source discovery is scoped to a selected repository and its Git worktrees. Users can
  choose a different repository path when discovery fails. No machine-specific absolute
  paths are part of the app.
- The launcher itself is versioned and packaged for Linux, Windows and macOS, with builds
  published on GitHub after the launcher is polished. Game release assets remain the
  existing `desert-<version>-<platform>.zip` archives.
- The app must clearly report offline, unsupported-platform, missing-runtime and
  download/extraction errors, with a retry path where useful.
- Show an edge-to-edge widescreen in-game desert image in a compact banner at the top of
  the launcher, shared by Play and Source. Keep the launcher title and short line readable
  over the image, with a dark overlay; the image is atmosphere, not a control.

## Product decisions still open

- Whether an update replaces the prior installed version or keeps multiple versions.
  Initial implementation should keep multiple versions so the version browser remains
  useful and rollback is straightforward.
- Whether stale source worktrees can be removed from inside the app. For the first
  version, allow hiding stale rows and explain how to remove them with Git; actual Git
  worktree/branch deletion needs a separate, explicit design.
- How installer signing/notarization will be handled for public Windows and macOS
  distribution. Initial CI may produce unsigned packages and must label them accurately.

## Resolved release decisions

- The launcher releases independently of the game, starting with tag
  `launcher-v0.1.0`.
- The initial Windows and macOS builds are unsigned; the GitHub release must say so and
  note that macOS builds are not notarized.

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
app. Play opens on a GitHub release version dropdown, selects the newest published game
release and shows its full release notes in a scrollable panel. It supports
platform-matched download, launch, update, uninstall and opening the install folder. It
remembers a custom install location, searches standard user game folders for version-
named exports, and limits uninstall to folders registered with the launcher. Game saves
are outside these install folders.

Source discovers checked-out Git worktrees, with branch, local folder name, commit date,
truncated summary, `project.godot` version and dirty state. A text filter narrows the
list; pinned branches sort above recent unpinned worktrees, with `master` pinned by
default. Run and editor are separate buttons. Users can select a repository path and
hide or show worktrees without removing files. Branch-only refs are not shown because
they have no checked-out game to launch.

The app uses a compact orbital monogram rather than the game's dune illustration for its
window and launcher icon.

The window has a compact, full-width banner above the Play and Source tabs. The banner uses
a real in-game capture with a storm approaching over the dunes, with the launcher title and
subtitle over a darkened area for contrast. It adds atmosphere without taking space from
either page's controls.

The Play browser shows published game releases only. The current source project's
`project.godot` version can be newer than GitHub's latest published release; the UI
labels the selected version as the latest **published** release so these states are clear.

**Storm banner, 2026-10-21:** a shared edge-to-edge header now sits above both tabs. Its
art is a real fixed-seed world capture from `look/dunes/dunes.tscn` (`sea_200m_noon`,
seed 1234, storm threshold -0.15) at 1920x1080, cropped to
`launcher/assets/desert-storm-banner.jpg` at 1920x450 (56,479 bytes). A left-side gradient
keeps the title readable. PyInstaller now bundles the launcher asset directory so the
banner appears in packaged builds as well as when run from source.

**Source launch import, 2026-10-22:** before opening a checked-out source worktree in the
editor or game, the launcher runs Godot's headless import so its class cache and imported
resources match the current source. The Source page shows an “Updating…” state while this
runs; downloaded release builds launch directly.

`launcher-release.yml` packages Linux x86_64, Windows x86_64, and macOS arm64 and x86_64
builds on launcher tags. Its first `workflow_dispatch` packaging run on master passed all
four platform jobs on 2026-10-20. The workflow was also updated to label the Windows and
macOS builds as unsigned, with macOS not notarized. Signing and notarization remain
open. The first public release, `launcher-v0.1.0`, published all four packages on
2026-10-21. The initial automated publish job exposed that `gh release create` needs an
explicit repository in the no-checkout publish job; the workflow now passes
`GITHUB_REPOSITORY` directly.
