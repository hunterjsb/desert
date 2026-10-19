#!/usr/bin/env bash
# Shoots the Varran settler's look-test and the origin menu, then builds the
# sheet ~/Desktop/varran.png: his start, his rig sailing with him towed on his
# board, from abeam and behind, its navigation computer, him under his shield
# on a storm's front, the origin menu on a first run and with his start open,
# and the Surveyor's deck.
#   look/varran/shoot.sh <out dir>            shoot, then build the sheet
#   look/varran/shoot.sh <out dir> --sheet    build the sheet from what's there
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
mkdir -p "$out"
if [[ ${2:-} != --sheet ]]; then
	timeout 900 "$godot" --path . --resolution 1920x1080 res://look/varran/varran.tscn -- "$out" 2>&1 | grep -E '^varran'
	timeout 600 "$godot" --path . --resolution 1920x1080 res://look/varran/menu.tscn -- "$out" 2>&1 | grep -E '^menu'
fi

args=()
for shot in start:"his start: the rig resting, its lines at your waist, the board at your feet" \
	sailing:"his rig towing him across a breeze, his board the keel" \
	behind:"from behind him on the board" \
	computer:"the navigation computer's radar" \
	storm:"under his shield on a storm's front, the rig outside it" \
	menu_first:"a first run: four starts, three ????" \
	menu_varran:"every start open, the Varran settler highlighted" \
	surveyor:"the Surveyor's deck"; do
	file="$out/${shot%%:*}.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "${shot#*:}" "$file")
done
montage "${args[@]}" -tile 4x2 -geometry 960x540+6+6 -pointsize 22 -background '#f4efe6' -depth 8 +repage "$out/grid.png"
magick "$out/grid.png" -background '#f4efe6' -gravity north -splice 0x60 -pointsize 34 \
	-annotate +0+12 'The Varran settler' -depth 8 +repage "$HOME/Desktop/varran.png"
echo "sheet: $HOME/Desktop/varran.png ($(du -h "$HOME/Desktop/varran.png" | cut -f1))"
