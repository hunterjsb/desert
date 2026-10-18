#!/usr/bin/env bash
# Shoots the feral look-test, then builds its sheet: the saltbush line across
# the dunes and down its length, a wild bush close, and folded before a storm.
#   look/feral/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

timeout 900 "$godot" --path . --disable-vsync res://look/feral/feral.tscn -- --capture "$out" 2>&1 |
	grep -E '^feral'

args=()
for shot in across down close folded folded_across; do
	file="$out/$shot.png"
	label=${shot//_/ }
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 2x -geometry 960x540+6+6 -pointsize 24 -depth 8 \
	-background '#f4efe6' -title "wild saltbush on a pilgrim road" "$sheet"
echo "sheet: $sheet"
