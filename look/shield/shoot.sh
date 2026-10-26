#!/usr/bin/env bash
# Shoots the shield-by-era look-test and builds its sheet: the row from 5 m,
# close, front and back, at dusk and morning; the camp from 20 m with its
# bubble up; the light shield placed and carried; inside the bubble in a storm.
#   look/shield/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}
scene=res://look/shield/eras.tscn

run() {
	timeout 900 "$godot" --path . --disable-vsync "$scene" -- --look grey --capture "$out" "$@" 2>&1 |
		grep -E '^(style|  )'
}
run --only eras_5m,eras_close,eras_dusk,eras_morning,light_placed,light_carried,issued_close,colonial_close,skimmer_close,first_close,second_close,light_close,colonial_back,skimmer_back,first_back,second_back,light_back
run --bubble --only camp20
run --storm
if [[ ! -f $out/eras_5m.png ]]; then
	echo "no shots: is the GPU up? (scripts/unseen.sh)" >&2
	exit 1
fi
args=()
for shot in eras_5m eras_close eras_dusk eras_morning colonial_close skimmer_close first_close second_close \
	colonial_back skimmer_back first_back second_back light_close light_back light_placed light_carried \
	camp20 storm_in storm_light issued_close; do
	file="$out/$shot.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "${shot//_/ }" "$file")
done
montage "${args[@]}" -tile 4x -geometry 800x450+4+4 -pointsize 20 -background '#f4efe6' -title "the shield by era" \
	-depth 8 "$sheet"
echo "sheet: $sheet"
