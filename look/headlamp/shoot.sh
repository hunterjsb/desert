#!/usr/bin/env bash
# Shoots the headlamp look-test, then builds its sheet: the walked path, then
# the camp, each without the headlamp and with it.
#   look/headlamp/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

timeout 600 "$godot" --path . --disable-vsync res://look/headlamp/headlamp.tscn -- --capture "$out" 2>&1 |
	grep -E '^headlamp'

args=()
for shot in path_dark path_headlamp camp_dark camp_headlamp; do
	file="$out/$shot.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "${shot//_/, }" "$file")
done
montage "${args[@]}" -tile 2x -geometry 960x540+6+6 -pointsize 24 -depth 8 \
	-background '#f4efe6' -title "a storm at midnight" "$sheet"
echo "sheet: $sheet"
