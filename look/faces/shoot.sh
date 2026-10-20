#!/usr/bin/env bash
# Shoots the wind-on-faces look-test and builds its sheet: a camp resting in a
# gale behind its windbreak with fabric taut beside it, the same camp from its
# lee, fabric slack in a breeze, and a scoop open into a fresh wind.
#   look/faces/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

timeout 900 "$godot" --path . --disable-vsync res://look/faces/faces.tscn -- --capture "$out" 2>&1 |
	grep -E '^faces|SCRIPT ERROR'

args=()
for shot in camp lee breeze scoop; do
	file="$out/$shot.png"
	[[ -f $file ]] || file="xc:gray"
	case $shot in
	camp) label="a gale: the windbreak broadside, fabric beside it taut and bellied in, an awning" ;;
	lee) label="the same camp from its lee" ;;
	breeze) label="fabric slack in a breeze, fluttering" ;;
	scoop) label="a scoop open into a fresh wind, its fabric back filled" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 2x -geometry 960x540+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "wind on faces" "$sheet"
echo "sheet: $sheet"
