#!/usr/bin/env bash
# Shoots the exposure look-test at 1920x1080, then builds the sheet
# ~/Desktop/exposure.png: a hab pod before a storm, rising half out of the
# sand in it, at its height and after, and from out in the dust its bared
# windows glinting through.
#   look/exposure/shoot.sh <out dir>            shoot, then build the sheet
#   look/exposure/shoot.sh <out dir> --sheet    build the sheet from what's there
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
if [[ ${2:-} != --sheet ]]; then
	timeout 1200 "$godot" --path . --disable-vsync --resolution 1920x1080 res://look/exposure/exposure.tscn \
		-- --capture "$out" 2>&1 | tee "$out/godot.txt" | grep -E '^exposure' | tee "$out/log.txt"
fi

declare -A labels=([before]="before the storm" [rising]="in it, rising out of the sand"
	[mid]="at the storm's height" [after]="after it" [glint]="from out in the dust"
	[glint_zoom]="zoomed round the middle")
shots=()
for shot in before rising mid after glint glint_zoom; do
	[[ -f $out/$shot.png ]] || continue
	said=$(grep -m1 "^exposure: ${shot%_zoom}," "$out/log.txt" 2>/dev/null | sed "s/^exposure: ${shot%_zoom}, //")
	shots+=(-label "${labels[$shot]}: $said" "$out/$shot.png")
done
montage "${shots[@]}" -tile 2x -geometry 960x540+6+6 -pointsize 18 -background '#f4efe6' -depth 8 +repage "$out/grid.png"
magick "$out/grid.png" -background '#f4efe6' -gravity north -splice 0x60 -pointsize 34 \
	-annotate +0+12 'A storm lays a ruin bare and buries it again' -depth 8 +repage "$HOME/Desktop/exposure.png"
echo "sheet: $HOME/Desktop/exposure.png ($(du -h "$HOME/Desktop/exposure.png" | cut -f1))"
