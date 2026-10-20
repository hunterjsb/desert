#!/usr/bin/env bash
# Shoots the chassis look-test, then builds its sheet: placing by hand (shown
# where it would stick, red where it would clip, amber where it would sink a
# floating piece, a Console from your hold, a row laid by aim alone) and camps
# built (the Surveyor's start, a camp in stations from two sides, a frame
# with walls and a shelf).
#   look/chassis/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

timeout 900 "$godot" --path . --disable-vsync res://look/chassis/chassis.tscn -- --capture "$out" 2>&1 |
	grep -E '^chassis|SCRIPT ERROR'

args=()
for shot in preview blocked heavy grasped rows surveyor stations stations_back frame; do
	file="$out/$shot.png"
	[[ -f $file ]] || file="xc:gray"
	case $shot in
	preview) label="held: the battery itself, where it would stick" ;;
	blocked) label="where it would clip: red, \"blocked\"" ;;
	heavy) label="past a floating piece's lift: amber, \"too heavy\"" ;;
	grasped) label="a Console from your hold, where it would stand" ;;
	rows) label="laid by aim alone, edged into rows" ;;
	surveyor) label="the Surveyor's start" ;;
	stations) label="a camp in stations: weather, power, a workstation" ;;
	stations_back) label="the same camp from behind" ;;
	frame) label="a frame with walls, a shelf and fabric" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 3x -geometry 720x405+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the chassis" "$sheet"
echo "sheet: $sheet"
