#!/usr/bin/env bash
# Shoots the tracks look-test, then builds one contact sheet per light: the
# walked path, the board's wake and the dragged crate's groove down, before,
# fresh and aged across.
#   look/tracks/shoot.sh <out dir> [sheet prefix]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
prefix=${2:-$out/sheet}
godot=${GODOT:-scripts/unseen.sh}

timeout 600 "$godot" --path . --disable-vsync res://look/tracks/tracks.tscn -- --capture "$out" 2>&1 |
	grep -E '^(tracks|  )'

for light in day storm night storm_night storm_night_lamp; do
	args=()
	for subject in walk board drag; do
		for state in before fresh aged; do
			file="$out/${subject}_${light}_${state}.png"
			[[ -f $file ]] || file="xc:gray"
			args+=(-label "$subject, $state" "$file")
		done
	done
	montage "${args[@]}" -tile 3x -geometry 960x540+6+6 -pointsize 24 -depth 8 \
		-background '#f4efe6' -title "${light//_/ }" "${prefix}_$light.png"
	echo "sheet: ${prefix}_$light.png"
done
