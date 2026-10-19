#!/usr/bin/env bash
# Shoots the wind map look-test and builds its sheet: light air, a breeze, the
# breeze turned and a storm down, the wind's arrows, the lee and the sand it
# moves across. It
# prints the map's check against the CPU and what it costs the GPU.
#   look/wind/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/wind_map.png}
godot=${GODOT:-scripts/unseen.sh}

timeout 900 "$godot" --path . --disable-vsync res://look/wind/wind.tscn -- --capture "$out" 2>&1 |
	grep -E '^wind|SCRIPT ERROR|ERROR'

args=()
for weather in calm breeze turned storm; do
	for view in arrows:"the wind's arrows" lee:"the lee, read in vertex()" sand:"the sand it moves"; do
		file="$out/${weather}_${view%%:*}.png"
		[[ -f $file ]] || file="xc:gray"
		args+=(-label "$weather: ${view#*:}" "$file")
	done
done
montage "${args[@]}" -tile 3x -geometry 960x540+6+6 -pointsize 24 -depth 8 \
	-background '#f4efe6' -title "The wind map over the dune sea: 256 m, north up" "$sheet"
echo "sheet: $sheet"
