#!/usr/bin/env bash
# Shoots the rift's live vent and its plume in the run's own weather (a calm,
# a strong wind, dusk, a storm coming over it and one swallowing it, a burst,
# night) from near, mid and far, and its mouth up close, then builds the
# sheet ~/Desktop/plume.png. Each shot also times the GPU with the plume and
# without; the times print at the end.
#   look/plume/shoot.sh <out dir>            shoot, then build the sheet
#   look/plume/shoot.sh <out dir> --sheet    build the sheet from what's there
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
if [[ ${2:-} != --sheet ]]; then
	timeout 1500 "$godot" --path . --disable-vsync --resolution 1280x720 res://look/plume/plume.tscn -- --capture "$out" 2>&1 |
		grep -E '^plume'
fi

declare -A says=([calm]="the calm" [wind]="a strong wind" [dusk]="dusk" [storm]="a storm coming over it"
	[swallowed]="a storm over it" [burst]="a burst" [night]="night")
rows=()
for moment in calm wind burst dusk storm swallowed night; do
	shots=()
	for range in near mid far; do
		shot="$out/${moment}_${range}.png"
		[[ -f $shot ]] && shots+=(-label "${says[$moment]}, $range" "$shot")
	done
	((${#shots[@]} > 0)) || continue
	row="$out/row_$moment.png"
	montage "${shots[@]}" -tile 3x1 -geometry 640x360+4+4 -pointsize 20 -background '#f4efe6' "$row"
	rows+=("$row")
done
if [[ -f $out/mouth_close.png ]]; then
	montage -label "its mouth, up close" "$out/mouth_close.png" -tile 1x1 -geometry 640x360+4+4 -pointsize 20 \
		-background '#f4efe6' "$out/row_mouth.png"
	rows+=("$out/row_mouth.png")
fi
magick "${rows[@]}" -background '#f4efe6' -gravity west -append \
	-gravity north -splice 0x60 -pointsize 34 -annotate +0+12 "The rift's live vent and its plume" \
	+repage -depth 8 -define png:color-type=2 "$HOME/Desktop/plume.png"
echo "sheet: $HOME/Desktop/plume.png ($(du -h "$HOME/Desktop/plume.png" | cut -f1))"
