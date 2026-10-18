#!/usr/bin/env bash
# Shoots the Console look-test, then builds its sheet: the Console, its screen
# with one instrument, with the full set, and its storm map with the front near.
#   look/console/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

timeout 900 "$godot" --path . --disable-vsync res://look/console/console.tscn -- --capture "$out" 2>&1 |
	grep -E '^console'

args=()
for shot in console one full map; do
	file="$out/$shot.png"
	[[ -f $file ]] || file="xc:gray"
	case $shot in
	console) label="the Console on its deck, every instrument and a radio" ;;
	one) label="its screen, one instrument: the anemometer" ;;
	full) label="the full set: every reading and the storm map" ;;
	map) label="the front near: the map, and the shield switched on" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 2x -geometry 960x540+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the Console" "$sheet"
echo "sheet: $sheet"
