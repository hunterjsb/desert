#!/usr/bin/env bash
# Shoots every dune style, plain and with the look-test's sand shader, then
# builds one contact sheet per time of day: styles across, shots down.
#   look/dunes/shoot.sh <out dir> [styles...]
# Each style opens a small window that never takes focus. A game running
# (Proton, Wine, gamescope) holds each launch until it's gone.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
shift
all=(Noise Ridges Crescents Scalloped Regions)
styles=("${@:-${all[@]}}")
godot=${GODOT:-godot}
shots=(sea_eye_upwind sea_eye_downwind sea_30m sea_200m edge_eye_upwind edge_200m)
moments=(morning noon dusk)

gaming() {
	ps -eo args | grep -iE 'proton|wine|gamescope|\.exe' | grep -v grep >/dev/null
}

for style in "${styles[@]}"; do
	for look in plain sand; do
		while gaming; do
			echo "a game is running; waiting to open a window"
			sleep 60
		done
		flags=()
		[[ $look == sand ]] && flags=(--sand)
		timeout 600 "$godot" --path . --disable-vsync res://look/dunes/dunes.tscn -- --style "$style" \
			"${flags[@]}" --capture "$out/$look/$style" 2>&1 | grep -E '^(dunes|  )'
	done
done

# Contact sheets: one per time of day and look, styles across, shots down.
for look in plain sand; do
	for moment in "${moments[@]}"; do
		args=()
		for shot in "${shots[@]}"; do
			for style in "${all[@]}"; do
				file="$out/$look/$style/${shot}_$moment.png"
				[[ -f $file ]] || file="xc:gray"
				args+=(-label "$style  ${shot//_/ }" "$file")
			done
		done
		title="$moment, flat sand"
		[[ $look == sand ]] && title="$moment, sand shader"
		montage "${args[@]}" -tile "${#all[@]}x" -geometry 640x360+6+6 -pointsize 22 \
			-background '#f4efe6' -title "$title" "$out/sheet_${moment}_$look.png"
		echo "sheet: $out/sheet_${moment}_$look.png"
	done
done
