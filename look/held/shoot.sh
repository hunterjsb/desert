#!/usr/bin/env bash
# Shoots the held tools and food (look/held/held.tscn) and each tool in your
# hands (look/held/hold.tscn), then builds the sheets: each thing close at
# morning and dusk, the food laid out, the planters beside their packs, the holds.
#   look/held/shoot.sh <out dir>
# No window: it runs unseen (scripts/unseen.sh), one run at a time.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
shots=$out/shots
mkdir -p "$shots"
godot=${GODOT:-scripts/unseen.sh}
timeout 900 "$godot" --path . --disable-vsync res://look/held/held.tscn -- --capture "$shots" 2>&1 | grep -E '^held|ERROR|SCRIPT'
timeout 900 "$godot" --path . --resolution 1280x720 res://look/held/hold.tscn -- "$shots" 2>&1 | grep -E '^hold|ERROR|SCRIPT'
sheet() {
	local name=$1 tile=$2 geometry=$3 title=$4
	shift 4
	local args=()
	for shot in "$@"; do
		args+=(-label "${shot//_/ }" "$shots/$shot.png")
	done
	montage "${args[@]}" -tile "$tile" -geometry "$geometry" -pointsize 20 -depth 8 \
		-background '#f4efe6' -title "$title" "$out/$name.png"
}
tools=(compass cutter sand_scoop flare sealant med_kit)
food=(ration tubers fungus_caps salt saltbush_leaves coalcane_bundle)
for moment in morning dusk; do
	sheet "tools_$moment" 3x 640x360+4+4 "held tools, about 1 m, $moment" "${tools[@]/%/_$moment}"
	sheet "food_close_$moment" 3x 640x360+4+4 "food, about 1 m, $moment" "${food[@]/%/_$moment}"
done
sheet laid 2x 960x540+4+4 "the food laid out, the planters beside their packs, a ration beside a cell" \
	food_morning food_dusk planter_morning planter_dusk ration_cell_morning ration_cell_dusk
sheet eras 2x 960x540+4+4 "each tool in its lineages: issued, colonial, First Kingdoms, skimmer, second age" \
	eras_cutter eras_compass eras_sand_scoop eras_sealant eras_med_kit
holds=()
for id in "${tools[@]}" ration; do
	holds+=("${id}_hold_0" "${id}_hold_35" "${id}_hold_60")
done
sheet holds 3x 640x360+4+4 "in your hands: level, looking down, well down" "${holds[@]}"
echo "sheets: $out/{tools,food_close}_{morning,dusk}.png $out/{laid,eras,holds}.png"
