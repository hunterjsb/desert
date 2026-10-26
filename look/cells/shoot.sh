#!/usr/bin/env bash
# Shoots the commodity parts' look-test and builds its sheets: each id in its
# five looks close at midmorning and dusk, the camp with them seated at 5 m and
# in a storm under its bubble, and a battery in your hands.
#   look/cells/shoot.sh <out dir> [prefix]    sheets <out>/<prefix>eras.png, <out>/<prefix>camp.png
# No window: it runs unseen (scripts/unseen.sh), one run at a time.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
prefix=${2:-}
shots=$out/${prefix}shots
mkdir -p "$shots"
godot=${GODOT:-scripts/unseen.sh}
for run in "" --storm; do
	flags=(--look grey --capture "$shots")
	[[ -n $run ]] && flags+=("$run")
	timeout 900 "$godot" --path . --disable-vsync res://look/cells/cells.tscn -- "${flags[@]}" 2>&1 |
		grep -E '^(style|  )|SCRIPT ERROR'
done
timeout 600 "$godot" --path . --resolution 1280x720 res://look/player_body/held.tscn -- "$shots" 2>&1 | grep -E 'SCRIPT ERROR'
# The metre shots cropped to their middle, as the eye picks the row out.
args=()
for id in battery big_battery plug strong_plug hose_end hook canister lamp; do
	for shot in close midmorning dusk; do
		file="$shots/${id}_$shot.png"
		[[ -f $file ]] || continue
		if [[ $shot != close ]]; then
			magick "$file" -gravity center -crop 1152x648+0+0 +repage "$shots/${id}_${shot}_mid.png"
			file="$shots/${id}_${shot}_mid.png"
		fi
		args+=(-label "$id, $([[ $shot == close ]] && echo "midmorning, narrow lens" || echo "$shot, about 1 m")" "$file")
	done
done
montage "${args[@]}" -tile 3x -geometry 640x360+4+4 -pointsize 18 -background '#f4efe6' \
	-title "${prefix}commodity parts, left to right: issued, colonial, First Kingdoms, skimmer, second age" \
	-depth 8 "$out/${prefix}eras.png"
args=()
for shot in camp5 camp5_dusk camp5_side camp2 bubble5 bubble2 battery_0 battery_35; do
	file="$shots/$shot.png"
	[[ -f $file ]] || continue
	args+=(-label "$shot" "$file")
done
montage "${args[@]}" -tile 2x -geometry 960x540+4+4 -pointsize 22 -background '#f4efe6' \
	-title "${prefix}seated in the camp, 5 m; in the storm's bubble; in your hands" -depth 8 "$out/${prefix}camp.png"
echo "sheets: $out/${prefix}eras.png $out/${prefix}camp.png"
