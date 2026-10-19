#!/usr/bin/env bash
# Shoots the bedroll look-test unseen, then builds its strip: rolled,
# unrolling, flat, and taken, rolling back up where it lay.
#   look/bedroll/shoot.sh <out dir> [strip]
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
strip=${2:-$out/strip.png}

timeout 600 scripts/unseen.sh --path . --resolution 1280x720 --disable-vsync res://look/bedroll/bedroll.tscn -- "$out" 2>&1 |
	grep -E '^bedroll'

args=()
for shot in rolled unrolling flat taken; do
	file="$out/$shot.png"
	[[ -f $file ]] || file="xc:gray"
	label=$shot
	[[ $shot == taken ]] && label="taken, rolling up"
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 4x -geometry 640x360+4+4 -pointsize 22 -depth 8 -background '#f4efe6' "PNG24:$strip"
echo "strip: $strip"
