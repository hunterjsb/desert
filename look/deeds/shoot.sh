#!/usr/bin/env bash
# Shoots the deeds look-test, then builds its sheet: the grid with a few deeds
# done over the main menu and over a run.
#   look/deeds/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

mkdir -p "$out"
timeout 600 "$godot" --path . --resolution 1920x1080 res://look/deeds/deeds.tscn -- "$out" 2>&1 | grep -E '^shot'

args=()
for shot in menu run; do
	file="$out/deeds_$shot.png"
	[[ -f $file ]] || file="xc:gray"
	case $shot in
	menu) label="the deeds over the main menu, five done" ;;
	run) label="the same over a run" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 1x -geometry 1600x900+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the deeds" "$sheet"
echo "sheet: $sheet"
