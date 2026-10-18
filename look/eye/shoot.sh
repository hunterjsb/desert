#!/usr/bin/env bash
# Shoots the eye look-test in the clear and in a storm, then builds its sheet:
# each moment at the fixed exposure the game had before beside the eye's, and
# the eclipse as the eye lives through it.
#   look/eye/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/eye_adaptation.png}
godot=${GODOT:-scripts/unseen.sh}

for weather in clear storm; do
	flag=()
	[[ $weather == storm ]] && flag=(--storm)
	timeout 900 "$godot" --path . --disable-vsync res://look/eye/eye.tscn -- --capture "$out" "${flag[@]}" 2>&1 |
		grep -E '^eye'
done

args=()
shot() {
	local file="$out/$1.png" label="$2"
	[[ -f $file ]] || file="xc:gray"
	[[ -f $out/$1.txt && -z ${3:-} ]] && label="$2: $(cat "$out/$1.txt")"
	args+=(-label "$label" "$file")
}
for pair in "noon:noon" "full:a full-Tu night" "full_tu:the same, facing Tu" "crescent:a crescent night" \
	"far:the far side" "storm:deep in a storm"; do
	shot "${pair%%:*}_fixed" "${pair#*:}"
	shot "${pair%%:*}_eye" "${pair#*:}"
done
shot full_x3 "a full-Tu night, Tu-shine x3 as once suggested" plain
shot totality_start "totality begins"
shot totality_late "totality, its last second"
shot sun_back_1s "the sun 1 s back"
montage "${args[@]}" -tile 4x -geometry 640x360+5+5 -pointsize 18 -depth 8 \
	-background '#f4efe6' -title "The eye: 9° Tu where a run begins, before (fixed) and after (the eye)" "$sheet"
echo "sheet: $sheet"
