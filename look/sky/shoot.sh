#!/usr/bin/env bash
# Shoots the sky look-test, then builds its sheets: the two sizes of Tu under
# trial side by side at the same moments, and Tu low, the far side's stars and
# a full-Tu night's ground at a few Tu-shine scales.
#   look/sky/shoot.sh <out dir> [sheet dir]
# The window never takes focus. A game running holds the launch until it's gone.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheets=${2:-$out}
godot=${GODOT:-godot}

gaming() {
	pgrep -a -x godot | grep -qv -- '--headless' || ps -eo args | grep -iE 'proton|wine|gamescope|\.exe' | grep -v grep >/dev/null
}
while gaming; do
	echo "a game is running; waiting to open a window"
	sleep 60
done
timeout 900 "$godot" --path . --disable-vsync res://look/sky/sky.tscn -- --capture "$out" 2>&1 | grep -E '^sky'

shot() {
	local file="$out/$1.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "$2" "$file")
}
args=()
for moment in noon before totality night; do
	for size in near far; do
		case $moment in
		noon) what="local noon, the eclipse coming" ;;
		before) what="10 s before the sun meets Tu" ;;
		totality) what="totality" ;;
		night) what="a full-Tu night" ;;
		esac
		shot "${size}_$moment" "$size: $what"
	done
done
montage "${args[@]}" -tile 2x -geometry 960x540+6+6 -pointsize 24 -depth 8 \
	-background '#f4efe6' -title "Tu near (13.3°) and far (7.0°), where a run begins" "$sheets/tu_sizes.png"
args=()
shot near_low "near: Tu low at dawn, 12° up, the dune across it"
shot far_low "far: the same"
shot far_side "the far side at midnight, 30° north: the pole star"
shot ground_x1 "a full-Tu night's ground, near, Tu-shine x1 (physical)"
shot ground_x3 "the same, x3"
shot ground_x10 "the same, x10"
montage "${args[@]}" -tile 2x -geometry 960x540+6+6 -pointsize 24 -depth 8 \
	-background '#f4efe6' -title "Tu low, the far side, and how bright a near-side night is" "$sheets/tu_more.png"
echo "sheets: $sheets/tu_sizes.png $sheets/tu_more.png"
