#!/usr/bin/env bash
# Shoots the camp in every candidate look, clear and in a storm, then builds
# one contact sheet per shot with the looks side by side.
#   look/style/shoot.sh <out dir> [look ...]
#   look/style/shoot.sh <out dir> --sheets    (rebuild the sheets from what's there)
# Each run opens a small window that never takes focus. A game running
# (Proton, Wine, gamescope) holds each launch until it's gone.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
shift
godot=${GODOT:-godot}
looks=("$@")
[[ ${#looks[@]} -gt 0 ]] || looks=(grey a b c d)
[[ ${looks[0]} == --sheets ]] && looks=()
all=(grey a b c d)
shots=(camp8_morning camp8_midmorning camp8_noon camp8_dusk camp50 crate5 crate finds storm)
declare -A titles=([grey]="the game (today)" [a]="A: Sand Game's models" [b]="B: chunky worn industrial"
	[c]="C: low-poly, flat, tight palette" [d]="D: cel-shaded, inked")

gaming() {
	ps -eo args | grep -iE 'proton|wine|gamescope|\.exe' | grep -v grep >/dev/null
}

for look in "${looks[@]+"${looks[@]}"}"; do
	for weather in clear storm; do
		while gaming; do
			echo "a game is running; waiting to open a window"
			sleep 60
		done
		flags=(--look "$look" --capture "$out/$look")
		[[ $weather == storm ]] && flags+=(--storm)
		timeout 600 "$godot" --path . --disable-vsync res://look/style/style.tscn -- "${flags[@]}" 2>&1 |
			grep -E '^(style|  )'
	done
done

# The 50 m and 5 m shots again, their middles blown up: what's there is a few pixels.
for look in "${all[@]}"; do
	for shot in camp50 crate5; do
		[[ -f $out/$look/$shot.png ]] && magick "$out/$look/$shot.png" -gravity center -crop 960x540+0+0 +repage \
			-resize 1920x1080 "$out/$look/${shot}_crop.png"
	done
done

for shot in "${shots[@]}" camp50_crop crate5_crop; do
	args=()
	for look in "${all[@]}"; do
		file="$out/$look/$shot.png"
		[[ -f $file ]] || file="xc:gray"
		args+=(-label "${titles[$look]}" "$file")
	done
	montage "${args[@]}" -tile 3x2 -geometry 1280x720+6+6 -pointsize 32 \
		-background '#f4efe6' -title "${shot//_/ }" "$out/sheet_$shot.png"
	echo "sheet: $out/sheet_$shot.png"
done
