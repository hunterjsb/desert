#!/usr/bin/env bash
# Shoots the Console look-test, then builds its sheet: the Console on its deck
# and alone, its map and stats read standing a step or two back, its map at
# each resolution its gear gives, its stats close, and the front near.
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
for shot in deck alone standing_map standing_stats estimate radar radar_two full linked stats near; do
	file="$out/$shot.png"
	[[ -f $file ]] || file="xc:gray"
	case $shot in
	deck) label="on its floating deck, beside the shield" ;;
	alone) label="alone on its own tray" ;;
	standing_map) label="the map, standing a step or two back" ;;
	standing_stats) label="the stats, standing a step or two back" ;;
	estimate) label="no radar, three instruments: an estimate, 7 across" ;;
	radar) label="a radar alone: 8 across" ;;
	radar_two) label="a radar and two more: 16 across" ;;
	full) label="the full set: 28 across" ;;
	linked) label="two Consoles linked: 42 across" ;;
	stats) label="the stats, close" ;;
	near) label="the front near, the shield switched on" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 4x -geometry 720x405+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the Console" "$sheet"
echo "sheet: $sheet"
