#!/usr/bin/env bash
# Shoots the crops look-test, then builds its sheet: a row a crop, a column a
# stage, the saltbush open and then folded.
#   look/crops/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

timeout 600 "$godot" --path . --disable-vsync res://look/crops/crops.tscn -- --capture "$out" 2>&1 |
	grep -E '^crops'

args=()
for shot in root_tuber_seedling root_tuber_growing root_tuber_mature none \
	vat_fungus_seedling vat_fungus_growing vat_fungus_mature vat_fungus_fruited \
	saltbush_seedling saltbush_growing saltbush_open saltbush_folded; do
	file="$out/$shot.png"
	label=${shot//_/ }
	if [[ $shot == none ]]; then
		file="xc:#f4efe6"
		label=" "
	elif [[ ! -f $file ]]; then
		file="xc:gray"
	fi
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 4x -geometry 640x360+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the crops, by stage" "$sheet"
echo "sheet: $sheet"
