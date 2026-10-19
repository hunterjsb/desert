#!/usr/bin/env bash
# Shoots the power box look-test, then builds its sheet: the four models on
# their decks, each close with its bays in different states, the Console's
# power page mirroring the cabinet and the dock, and the strips at dusk.
#   look/powerbox/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

timeout 900 "$godot" --path . --disable-vsync res://look/powerbox/powerbox.tscn -- --capture "$out" 2>&1 |
	grep -E '^powerbox|SCRIPT ERROR'

args=()
for shot in decks cabinet dock rack shrine page standing dusk; do
	file="$out/$shot.png"
	[[ -f $file ]] || file="xc:gray"
	case $shot in
	decks) label="the four on their decks: a colonial camp charging, a nomad raft supplying" ;;
	cabinet) label="colonial cabinet: eight bays charging, one held, one empty" ;;
	dock) label="company issue: the four-bay dock" ;;
	rack) label="skimmer rack: mismatched bays supplying, three dead" ;;
	shrine) label="temple shrine: three niches, sand-glass tubes" ;;
	page) label="the Console's power page mirroring the cabinet and the dock" ;;
	standing) label="the page, standing a step or two back" ;;
	dusk) label="the strips at dusk" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 4x -geometry 720x405+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the power box" "$sheet"
echo "sheet: $sheet"
