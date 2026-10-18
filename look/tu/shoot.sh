#!/usr/bin/env bash
# Shoots the Tu look-tests, then builds the sheet: the whole of Tu unrolled;
# each size on a full-Tu night, at dusk and in the eclipse, Tu blown up pixel
# for pixel from the frame the game draws; that frame at 9°; Tu close; and the
# same three minutes, one true turn, watched at each rate under trial.
#   look/tu/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/tu.png}
godot=${GODOT:-scripts/unseen.sh}

mkdir -p "$out"
timeout 2400 "$godot" --path . --disable-vsync res://look/tu/tu.tscn -- --capture "$out" "${@:3}" 2>&1 | grep -E '^tu'
timeout 600 "$godot" --path . --resolution 1920x1080 res://look/tu/unrolled.tscn -- --capture "$out/unrolled.png" 2>&1 |
	grep -E 'ERROR'

shot() {
	local file="$out/$1.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "$2" "$file")
}
row() {
	montage "${args[@]}" -tile "$1"x1 -geometry "$2"+6+6 -pointsize 22 -background '#f4efe6' ${4:+-title "$4"} \
		"$out/row_$3.png"
	rows+=("$out/row_$3.png")
	args=()
}
rows=()
args=()
shot unrolled "the whole of Tu unrolled, its far side too: longitude across, latitude up"
row 1 1440x720 map
for size in 6 9 13; do
	shot "tu${size}_night_cut" "$size°: a full-Tu night, Tu blown up pixel for pixel"
	shot "tu${size}_dusk_cut" "$size°: dusk, 18:14 where a run begins"
	shot "tu${size}_eclipse_cut" "$size°: mid-totality"
	row 3 480x480 "size$size"
done
shot tu9_night "9°: the frame the game draws, a full-Tu night"
shot tu9_close "9°: close, through a narrow view, as bright"
row 2 960x540 frame
for rate in true 3 1; do
	case $rate in
	true) what="9°, true to scale, 6.8 turns a day: one turn, 22 s apart" ;;
	3) what="three turns a day: the same three minutes" ;;
	1) what="one turn a day: the same three minutes" ;;
	esac
	for k in 0 1 2 3 4 5 6 7; do
		shot "spin_${rate}_${k}_cut" "+$((k * 22)) s"
	done
	row 8 300x300 "spin$rate" "$what"
done
magick "${rows[@]}" -background '#f4efe6' -gravity center -append +repage -depth 8 "$sheet"
echo "sheet: $sheet"
