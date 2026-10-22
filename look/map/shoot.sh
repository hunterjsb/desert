#!/usr/bin/env bash
# Shoots the Console's Map with each filter alone and all three, and builds
# <out dir>/sheet.png from them.
#   look/map/shoot.sh <out dir>
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
mkdir -p "$out"
timeout 600 "$godot" --path . --resolution 1280x720 res://look/map/map.tscn -- "$out" 2>&1 | grep -E '^map'
args=()
for shot in weather:"weather" survey:"survey" nav:"navigation" all:"all three"; do
	file="$out/${shot%%:*}.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "${shot#*:}" "$file")
done
montage "${args[@]}" -tile 4x1 -geometry 580x1080+8+8 -pointsize 28 -background '#f4efe6' -depth 8 +repage "$out/sheet.png"
echo "sheet: $out/sheet.png"
