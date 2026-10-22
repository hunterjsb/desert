#!/usr/bin/env bash
# Shoots the archaeology look-test at 1920x1080, then builds the sheet
# ~/Desktop/dunes.png, 8-bit: a big dune's ruin bared after a big storm, the
# light things a storm let fall in a crest's lee, the Map's survey, and
# the archaeology setup on a deck.
#   look/archaeology/shoot.sh <out dir>            shoot, then build the sheet
#   look/archaeology/shoot.sh <out dir> --sheet    build the sheet from what's there
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
mkdir -p "$out"
godot=${GODOT:-scripts/unseen.sh}
if [[ ${2:-} != --sheet ]]; then
	timeout 1800 "$godot" --path . --disable-vsync --resolution 1920x1080 res://look/archaeology/archaeology.tscn \
		-- --capture "$out" 2>&1 | tee "$out/godot.txt" | grep -E '^archaeology' | tee "$out/log.txt"
fi

declare -A labels=([ruin]="a big dune's ruin after a big storm" [lee]="light loot in a crest's lee"
	[page]="the Map's survey" [deck]="the archaeology setup on a deck")
shots=()
for shot in ruin lee page deck; do
	[[ -f $out/$shot.png ]] || continue
	said=$(grep -m1 "^archaeology: $shot," "$out/log.txt" 2>/dev/null | sed "s/^archaeology: $shot, //")
	shots+=(-label "${labels[$shot]}: $said" "$out/$shot.png")
done
montage "${shots[@]}" -tile 2x -geometry 960x540+6+6 -pointsize 18 -background '#f4efe6' -depth 8 +repage "$out/grid.png"
magick "$out/grid.png" -background '#f4efe6' -gravity north -splice 0x60 -pointsize 34 \
	-annotate +0+12 'Let the ruins come to you' -depth 8 +repage "$HOME/Desktop/dunes.png"
echo "sheet: $HOME/Desktop/dunes.png ($(du -h "$HOME/Desktop/dunes.png" | cut -f1))"
