#!/usr/bin/env bash
# Shoots the storm-wear look-test and builds its sheet: a turbine and a panel
# fresh, after one storm and after many, close up, and the row whole.
#   look/storm_wear/shoot.sh <out dir>    sheet to <out dir>/storm_wear.png
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
timeout 900 "$godot" --path . --disable-vsync res://look/storm_wear/storm_wear.tscn -- --look grey --capture "$out" 2>&1 |
	grep -E '^(style|storm_wear|  |SCRIPT ERROR|ERROR)'
if [[ ! -f $out/row.png ]]; then
	echo "no shots: is the GPU up? (scripts/unseen.sh)" >&2
	exit 1
fi
args=()
for name in fresh one_storm many_storms row; do
	args+=(-label "${name//_/ }" "$out/$name.png")
done
montage "${args[@]}" -tile 2x2 -geometry 960x540+4+4 -pointsize 22 -background '#f4efe6' -title "storm wear" \
	-depth 8 "$out/storm_wear.png"
echo "sheet: $out/storm_wear.png"
