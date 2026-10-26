#!/usr/bin/env bash
# Shoots the boards' fidelity look-test in clear air and in a storm, then its
# sheet: the makes at 2 m by morning and dusk and hovering lit at night, each
# from its rider's eye, the company's board by era, the rig, and the storm
# from inside the bubble.
#   look/boards/fidelity.sh <out dir>    sheet to <out dir>/sheet.png
# No window: it runs unseen (scripts/unseen.sh), one run at a time.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
mkdir -p "$out"
godot=${GODOT:-scripts/unseen.sh}
for run in "" --storm; do
	flags=(--look grey --capture "$out")
	[[ -n $run ]] && flags+=("$run")
	timeout 900 "$godot" --path . --disable-vsync res://look/boards/fidelity.tscn -- "${flags[@]}" 2>&1 |
		grep -E '^(style|  )|SCRIPT ERROR'
done
args=()
for shot in makes2_morning makes2_dusk hover_night deck_0 deck_1 deck_2 deck_3 eras2 rig2 rig_dusk floater \
	hover_storm storm_makes storm_floater; do
	file="$out/$shot.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "${shot//_/ }" "$file")
done
montage "${args[@]}" -tile 3x -geometry 960x540+4+4 -pointsize 22 -background '#f4efe6' -title "boards and rig" \
	-depth 8 "$out/sheet.png"
echo "sheet: $out/sheet.png"
