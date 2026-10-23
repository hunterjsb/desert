#!/usr/bin/env bash
# Shoots the near and far side looks, then builds the sheet: two rows for each
# look, the near side's and the far side's, by day, by night and by the
# headlamp across them. Anything after
# the output directory goes to the look-test, such as --gpu or --only 0,A.
#   look/sides/shoot.sh <out dir> [look-test arguments]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
shift
godot=${GODOT:-scripts/unseen.sh}
mkdir -p "$out"
timeout 1500 "$godot" --path . --disable-vsync res://look/sides/sides.tscn -- --capture "$out" "$@" 2>&1 |
	grep -E '^sides|SHADER ERROR|SCRIPT ERROR|ERROR: sides'

args=()
for look in 0 A B C; do
	case $look in
	0) what="the game as it is" ;;
	A) what="A, Tu's light in the air" ;;
	B) what="B, the far side's frost" ;;
	C) what="C, both" ;;
	esac
	for shot in near-day near-night near-lamp far-day far-night far-lamp; do
		file="$out/$look-$shot.png"
		[[ -f $file ]] || file="xc:gray"
		args+=(-label "$what: ${shot%-*} side, ${shot#*-}" "$file")
	done
done
montage "${args[@]}" -tile 3x -geometry 720x405+6+6 -pointsize 20 -background '#f4efe6' -depth 8 \
	-title "Near and far side: 07:00, 04:00, and 04:00 by the headlamp, local, looking past Tu's bearing" "$out/sheet.png"
echo "sheet: $out/sheet.png"
