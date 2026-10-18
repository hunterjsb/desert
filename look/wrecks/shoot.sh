#!/usr/bin/env bash
# Shoots every wreck whole, at work, with a cutter firing and stripped
# (look/wrecks/wrecks.gd), into <out dir>.
#   look/wrecks/shoot.sh <out dir>
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone
# plays; GODOT=<a godot> runs it in a window of its own instead.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
timeout 1200 "$godot" --path . --disable-vsync --resolution 1280x720 res://look/wrecks/wrecks.tscn -- --capture "$out" 2>&1 |
	grep -E '^wrecks'
