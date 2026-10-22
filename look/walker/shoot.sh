#!/usr/bin/env bash
# Shoots the Walker's look-test and builds the sheet ~/Desktop/walker.png: the
# Walker on the Rim beside you, its front quarter and its port, far off at
# its own size and that far off closer up, the Console's Map with the
# bearings it noted and their fix, the Map after teaching, and the
# living city's lights at night from two km and one.
#   look/walker/shoot.sh <out dir>            shoot, then build the sheet
#   look/walker/shoot.sh <out dir> --sheet    build the sheet from what's there
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
mkdir -p "$out"
if [[ ${2:-} != --sheet ]]; then
	timeout 900 "$godot" --path . --resolution 1920x1080 res://look/walker/walker.tscn -- "$out" 2>&1 | grep -E '^walker'
fi

args=()
for shot in near:"the Walker on the Rim, passing you" \
	front:"its front quarter: the survey head, the snapped leg dragged" \
	port:"its data port, where a Console plugs in" \
	far:"1.2 km off, its stand-in at its own size" \
	far_close:"the same, through a 4° lens" \
	chart:"the Console's Map, navigation: six bearings noted, their fix" \
	taught_map:"taught: the Map's weather shows the anomaly" \
	taught_chart:"taught: weather and navigation together" \
	city_far:"the living city at night, 2 km off" \
	city:"its lights from 1 km"; do
	file="$out/${shot%%:*}.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "${shot#*:}" "$file")
done
montage "${args[@]}" -tile 4x3 -geometry 960x540+6+6 -pointsize 22 -background '#f4efe6' -depth 8 +repage "$out/grid.png"
magick "$out/grid.png" -background '#f4efe6' -gravity north -splice 0x60 -pointsize 34 \
	-annotate +0+12 "The Walker and the living city" -depth 8 +repage "$HOME/Desktop/walker.png"
echo "sheet: $HOME/Desktop/walker.png ($(du -h "$HOME/Desktop/walker.png" | cut -f1))"
