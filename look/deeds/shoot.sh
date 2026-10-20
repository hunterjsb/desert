#!/usr/bin/env bash
# Shoots the deeds look-test, then builds its sheet: the main menu marking the
# deeds and the starts they opened as new; the whole tree, its top and its foot,
# with a few deeds done over the main menu and over a run; two badges done at
# once; and Resume counting them.
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
for shot in marked new_starts menu_top menu_foot badge badge_next run_top run_foot resume; do
	file="$out/deeds_$shot.png"
	[[ -f $file ]] || file="xc:gray"
	case $shot in
	marked) label="the main menu, Deeds marked new" ;;
	new_starts) label="who you come as, the two starts the deeds opened marked" ;;
	menu_top) label="over the main menu, its top: Six Pack early, the Eye done, Tells hidden" ;;
	menu_foot) label="scrolled to the foot: Slept It Off highlighted" ;;
	badge) label="two deeds done at once in a run: the first's badge" ;;
	badge_next) label="then the second's" ;;
	run_top) label="over a run, at the top: Tells highlighted, hidden" ;;
	run_foot) label="scrolled to the foot: Thunder highlighted" ;;
	resume) label="Resume, counting the deeds" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 2x -geometry 960x540+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the deeds" "$sheet"
echo "sheet: $sheet"
