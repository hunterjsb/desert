#!/usr/bin/env bash
# Shoots the sightlines look-test at 1920x1080, then builds the sheet
# ~/Desktop/sightlines.png: each origin's start looking at what's in sight,
# a far mast or watchtower, a glint, a saltbush line and a row of pylon
# stubs from a distance, each beside a zoom round what it's of.
#   look/sightlines/shoot.sh <out dir>            shoot, then build the sheet
#   look/sightlines/shoot.sh <out dir> --sheet    build the sheet from what's there
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
if [[ ${2:-} != --sheet ]]; then
	timeout 3600 "$godot" --path . --disable-vsync --resolution 1920x1080 res://look/sightlines/sightlines.tscn \
		-- --capture "$out" 2>&1 | tee "$out/godot.txt" | grep -E '^sightlines' | tee "$out/log.txt"
fi

declare -A labels=([start_surveyor]="the Surveyor's start" [start_salvager]="the Salvager's start"
	[start_homesteader]="the Homesteader's start" [far_tower]="a far mast or watchtower"
	[glint]="a glint" [road_saltbush]="a saltbush line from a distance" [road_pylons]="a row of pylon stubs")
rows=()
for shot in start_surveyor start_salvager start_homesteader far_tower glint road_saltbush road_pylons; do
	[[ -f $out/$shot.png ]] || continue
	said=$(grep -m1 "^sightlines: $shot," "$out/log.txt" 2>/dev/null | sed "s/^sightlines: $shot, //; s/; .*//")
	montage -label "${labels[$shot]}: ${said}" "$out/$shot.png" -label "zoomed three times round the middle" \
		"$out/${shot}_zoom.png" -tile 2x1 -geometry 960x540+6+6 -pointsize 22 -background '#f4efe6' -depth 8 +repage "$out/row_$shot.png"
	rows+=("$out/row_$shot.png")
done
# Walking in across the hand-over, each distance's zoom side by side: as you
# see it, then from the same spot as only its real look and only its stand-in.
declare -A as=([seen]="as you see it" [real]="its real look only" [far]="its stand-in only")
for only in seen real far; do
	hand=()
	tail=_$only
	[[ $only == seen ]] && tail=
	for shot in "$out"/handover_*_zoom.png; do
		[[ $shot =~ /handover_([0-9]+)${tail}_zoom\.png$ ]] || continue
		hand+=(-label "${BASH_REMATCH[1]} m off" "$shot")
	done
	((${#hand[@]} > 0)) || continue
	montage "${hand[@]}" -tile 5x1 -geometry 384x216+6+6 -pointsize 20 -background '#f4efe6' -depth 8 +repage \
		"$out/row_handover_$only.png"
	montage -label "walking in to the Surveyor's mast across the hand-over, zoomed six times: ${as[$only]}" \
		"$out/row_handover_$only.png" -tile 1x1 -geometry +0+0 -pointsize 22 -background '#f4efe6' -depth 8 +repage \
		"$out/row_handover_$only.png"
	rows+=("$out/row_handover_$only.png")
done
magick "${rows[@]}" -background '#f4efe6' -gravity center -append \
	-gravity north -splice 0x60 -pointsize 34 -annotate +0+12 'Sites found by eye from far off, at 1920x1080' \
	-depth 8 +repage "$HOME/Desktop/sightlines.png"
echo "sheet: $HOME/Desktop/sightlines.png ($(du -h "$HOME/Desktop/sightlines.png" | cut -f1))"
