#!/usr/bin/env bash
# Shoots every structure kit piece by era in each exposure state, and a road
# with its sites strung along it, then builds the sheet ~/Desktop/structures.png.
#   look/kits/shoot.sh <out dir>            shoot, then build the sheet
#   look/kits/shoot.sh <out dir> --sheet    build the sheet from what's there
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
if [[ ${2:-} != --sheet ]]; then
	timeout 1200 "$godot" --path . --disable-vsync --resolution 1280x720 res://look/kits/kits.tscn -- --capture "$out" 2>&1 |
		grep -E '^kits'
fi

declare -A eras=([colonial]="colonial" [skimmer]="skimmer era" [first]="First Kingdoms" [second]="second age")
rows=()
for era in colonial skimmer first second; do
	for shot in "$out/${era}"_*_buried.png; do
		[[ -f $shot ]] || continue
		kind=${shot#"$out/${era}_"}
		kind=${kind%_buried.png}
		row="$out/row_${era}_${kind}.png"
		montage -label "${eras[$era]}: ${kind//_/ }, buried" "$out/${era}_${kind}_buried.png" \
			-label "partly exposed" "$out/${era}_${kind}_partly.png" \
			-label "exposed" "$out/${era}_${kind}_exposed.png" \
			-tile 3x1 -geometry 640x360+4+4 -pointsize 20 -background '#f4efe6' "$row"
		rows+=("$row")
	done
done
montage -label "the artery out of Halfrise, from beside it" "$out/road_low.png" \
	-label "and from above: a line of pylon stubs, shrines and towers" "$out/road_high.png" \
	-tile 2x1 -geometry 964x542+4+4 -pointsize 22 -background '#f4efe6' "$out/row_road.png"
magick "${rows[@]}" "$out/row_road.png" -background '#f4efe6' -gravity center -append \
	-gravity north -splice 0x60 -pointsize 34 -annotate +0+12 'Structure kits by era, in each exposure state' \
	"$HOME/Desktop/structures.png"
echo "sheet: $HOME/Desktop/structures.png ($(du -h "$HOME/Desktop/structures.png" | cut -f1))"
