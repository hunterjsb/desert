# Desert Launcher

The launcher is a standalone desktop app for installing and playing published Desert
builds, or launching one of the local repository's Git worktrees. It is independent of
the game and Godot.

## Run from source

Use Python 3.11 or newer.

```sh
python -m venv .venv
. .venv/bin/activate
pip install -r launcher/requirements.txt
python launcher/main.py
```

On Windows, activate with `.venv\\Scripts\\activate`.

## Build

The `launcher-release.yml` workflow creates platform packages on Linux and Windows,
plus Apple Silicon and Intel macOS app bundles, for a `launcher-v*` tag. Packages are
separate from game releases. Public
distribution may require signing/notarization on Windows and macOS.

Launcher settings and managed game installations are stored in the operating system's
per-user data directory. Game saves remain in Godot's normal per-user save directory.

The launcher is a separate Python application. `.gdignore` keeps its assets out of
the game’s Godot import and export.
