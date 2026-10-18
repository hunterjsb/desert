#!/usr/bin/env bash
# Shoots the menus look-test, then builds its sheet: the main menu in its storm
# and in the clear, who you come as with each origin highlighted and with one
# locked, the modes, the main menu after a Homesteader's run, and the system menu.
#   look/menus/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

mkdir -p "$out"
timeout 900 "$godot" --path . --resolution 1920x1080 res://look/menus/menus.tscn -- "$out" 2>&1 |
	grep -E '^(menus|shot)'

args=()
for shot in main_storm main origin_surveyor origin_salvager origin_homesteader origin_locked modes main_homesteader system; do
	file="$out/menu_$shot.png"
	[[ -f $file ]] || file="xc:gray"
	case $shot in
	main_storm) label="the main menu in its storm" ;;
	main) label="the main menu in the clear" ;;
	origin_surveyor) label="New game: the Surveyor highlighted" ;;
	origin_salvager) label="the Salvager highlighted" ;;
	origin_homesteader) label="the Homesteader highlighted" ;;
	origin_locked) label="the Salvager locked" ;;
	modes) label="the modes, for the Homesteader" ;;
	main_homesteader) label="the main menu after a Homesteader's run" ;;
	system) label="the system menu over a run" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 3x -geometry 800x450+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the menus" "$sheet"
echo "sheet: $sheet"
