#!/usr/bin/env bash
# Shoots the dunes with the sand shader and without, then builds one contact
# sheet per time of day: the two looks across, the shots down.
#   look/dunes/shoot.sh <out dir> [--tune name=value ...]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
shift
godot=${GODOT:-scripts/unseen.sh}
shots=(sea_eye_upwind sea_eye_downwind sea_30m sea_200m edge_eye_upwind edge_200m)
moments=(morning midmorning noon dusk)
looks=(shader flat)


for look in "${looks[@]}"; do
	timeout 600 "$godot" --path . --disable-vsync res://look/dunes/dunes.tscn -- "$@" \
		--tune "sand_shader=$([[ $look == shader ]] && echo true || echo false)" --capture "$out/$look" 2>&1 |
		grep -E '^(dunes|  )'
done

for moment in "${moments[@]}"; do
	args=()
	for shot in "${shots[@]}"; do
		for look in "${looks[@]}"; do
			file="$out/$look/${shot}_$moment.png"
			[[ -f $file ]] || file="xc:gray"
			args+=(-label "${shot//_/ }, $look sand" "$file")
		done
	done
	montage "${args[@]}" -tile "${#looks[@]}x" -geometry 960x540+6+6 -pointsize 24 \
		-background '#f4efe6' -title "$moment" "$out/sheet_$moment.png"
	echo "sheet: $out/sheet_$moment.png"
done
