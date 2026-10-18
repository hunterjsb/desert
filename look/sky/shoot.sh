#!/usr/bin/env bash
# Shoots the sky look-test, then builds its sheets: the three sizes of Tu under
# trial side by side at the same moments, and Tu low, the far side's stars and
# a full-Tu night's ground at a few Tu-shine scales.
#   look/sky/shoot.sh <out dir> [sheet dir]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheets=${2:-$out}
godot=${GODOT:-scripts/unseen.sh}

timeout 900 "$godot" --path . --disable-vsync res://look/sky/sky.tscn -- --capture "$out" 2>&1 | grep -E '^sky'

shot() {
	local file="$out/$1.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "$2" "$file")
}
args=()
for moment in noon before totality night; do
	for size in 6 9 13; do
		case $moment in
		noon) what="local noon, the eclipse coming" ;;
		before) what="10 s before the sun meets Tu" ;;
		totality) what="totality" ;;
		night) what="a full-Tu night" ;;
		esac
		shot "tu${size}_$moment" "$size°: $what"
	done
done
montage "${args[@]}" -tile 3x -geometry 960x540+6+6 -pointsize 24 -depth 8 \
	-background '#f4efe6' -title "Tu 6°, 9° and 13° across, where a run begins" "$sheets/tu_sizes.png"
args=()
for size in 6 9 13; do
	shot "tu${size}_low" "$size°: Tu low at dawn, 12° up, the dune across it"
done
for size in 6 9 13; do
	shot "tu${size}_ground" "$size°: a full-Tu night's ground, Tu-shine x1 (physical)"
done
shot far_side "the far side at midnight, 30° north: the pole star"
shot ground_x3 "9°: a full-Tu night's ground, Tu-shine x3"
shot ground_x10 "9°: the same, x10"
montage "${args[@]}" -tile 3x -geometry 960x540+6+6 -pointsize 24 -depth 8 \
	-background '#f4efe6' -title "Tu low, the far side, and how bright a near-side night is" "$sheets/tu_more.png"
echo "sheets: $sheets/tu_sizes.png $sheets/tu_more.png"
