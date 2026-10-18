#!/usr/bin/env bash
# Shoots the menus look-test, then builds its sheet: the main menu in its storm,
# in the clear and with its music off; Options and the question with the prop
# aside; who you come as with each origin's piece and gear, one locked, and the
# modes; the main menu after a Homesteader's run; the system menu; Resume with
# that run's camp (and LOOK_SAVE's, if set); the main menu and Resume at night.
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

shots=(main_storm main main_muted options origin_surveyor origin_salvager origin_homesteader origin_locked
	modes main_homesteader system question resume)
[[ -f $out/menu_resume_yours.png ]] && shots+=(resume_yours)
shots+=(main_night resume_night)
args=()
for shot in "${shots[@]}"; do
	file="$out/menu_$shot.png"
	[[ -f $file ]] || file="xc:gray"
	case $shot in
	main_storm) label="the main menu in its storm" ;;
	main) label="the main menu in the clear" ;;
	main_muted) label="its music switched off" ;;
	options) label="Options, the prop aside" ;;
	origin_surveyor) label="New game: the Surveyor's crate" ;;
	origin_salvager) label="the Salvager's board" ;;
	origin_homesteader) label="the Homesteader's planter" ;;
	origin_locked) label="the Salvager locked" ;;
	modes) label="the modes, for the Homesteader" ;;
	main_homesteader) label="the main menu after a Homesteader's run" ;;
	system) label="the system menu over a run" ;;
	question) label="New game over a save asks" ;;
	resume) label="Resume: the Homesteader's camp" ;;
	resume_yours) label="Resume: LOOK_SAVE's camp" ;;
	main_night) label="the main menu at its darkest" ;;
	resume_night) label="Resume at its darkest" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 4x -geometry 800x450+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the menus" +repage "$sheet"
echo "sheet: $sheet"
