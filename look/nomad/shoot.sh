#!/usr/bin/env bash
# Shoots the nomads' gear's look-test, then builds the sheet ~/Desktop/nomad.png:
# a wrecked nomad rig, a nomads' camp, a streamer in your hand and streamers
# on a rig, the crow's nest and the view from it, and the Varran rig on each tack.
#   look/nomad/shoot.sh <out dir>            shoot, then build the sheet
#   look/nomad/shoot.sh <out dir> --sheet    build the sheet from what's there
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
mkdir -p "$out"
if [[ ${2:-} != --sheet ]]; then
	timeout 1200 "$godot" --path . --resolution 1920x1080 res://look/nomad/nomad.tscn -- "$out" 2>&1 | grep -E '^nomad'
fi

args=()
for shot in rig:"a wrecked nomad rig: its mast down by its post, its sail on it" \
	camp:"a nomads' camp, just left: their rig kept, their tracks leading off" \
	hand:"a wind streamer in your hand in a breeze" \
	telltale:"streamers up the mast and on the deck: telltales" \
	nest:"the crow's nest on its mast's head" \
	view:"the view from the crow's nest" \
	tack_left:"the Varran rig, the wind on your left" \
	tack_right:"the same rig and lines, the wind on your right"; do
	file="$out/${shot%%:*}.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "${shot#*:}" "$file")
done
montage "${args[@]}" -tile 4x2 -geometry 960x540+6+6 -pointsize 22 -background '#f4efe6' -depth 8 +repage "$out/grid.png"
magick "$out/grid.png" -background '#f4efe6' -gravity north -splice 0x60 -pointsize 34 \
	-annotate +0+12 "The nomads' gear" -depth 8 +repage "$HOME/Desktop/nomad.png"
echo "sheet: $HOME/Desktop/nomad.png ($(du -h "$HOME/Desktop/nomad.png" | cut -f1))"
