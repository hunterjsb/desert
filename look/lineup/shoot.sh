#!/usr/bin/env bash
# Shoots the model lineup and builds its sheets: the whole at 20 m, each block
# at 5 m (the small things close too) numbered with its legend, the world's
# row and the deliveryship, dusk, and a storm.
#   look/lineup/shoot.sh [out dir]    default ~/Desktop/fidelity/lineup; shots in <out>/shots
# No window: it runs unseen (scripts/unseen.sh), one run at a time.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:-$HOME/Desktop/fidelity/lineup}
shots=$out/shots
mkdir -p "$shots"
: >"$shots/log.txt"
godot=${GODOT:-scripts/unseen.sh}
scene=res://look/lineup/lineup.tscn
for run in --labels "" --storm; do
	flags=(--look grey --capture "$shots")
	[[ -n $run ]] && flags+=("$run")
	timeout 900 "$godot" --path . --disable-vsync "$scene" -- "${flags[@]}" 2>&1 | tee -a "$shots/log.txt" |
		grep -E '^(style|lineup|  )'
done
if [[ ! -f $shots/all20.png ]]; then
	echo "no shots: is the GPU up? (scripts/unseen.sh)" >&2
	exit 1
fi
# Each block's legend from the labelled run: "n id" in its order.
legend() { awk -F'\t' -v b="$1" '$1 == "legend" && $2 == b && !seen[$3]++ { printf "%s %s%s   ", $3, $4, ($5 ? " (GREY)" : "") }' "$shots/log.txt"; }
blocks=(camp power boards held parts food lineage)
args=()
for block in "${blocks[@]}"; do
	[[ -f $shots/${block}5.png ]] || continue
	close=()
	[[ -f $shots/${block}_close.png ]] && close=("$shots/${block}_close.png")
	magick "$shots/${block}5.png" "${close[@]}" \( -size 1920x -background '#f4efe6' -pointsize 26 \
		caption:"$block, 5 m${close:+ and close}:  $(legend "$block")" \) -append "$out/row_$block.png"
	args+=(-label "$block, 5 m" "$shots/${block}5.png")
	[[ -n ${close[*]} ]] && args+=(-label "$block, close" "${close[0]}")
done
montage "${args[@]}" -tile 2x -geometry 960x+4+4 -pointsize 22 -background '#f4efe6' -title "lineup, each block at 5 m" \
	-depth 8 "$out/lineup_rows.png"
cp "$shots/all20.png" "$out/lineup_all20.png"
world=()
for file in "$shots"/world*.png "$shots/sky.png"; do
	[[ -f $file ]] || continue
	name=$(basename "$file" .png)
	what=$(awk -F'\t' -v n="$name" '$1 == "worldshot" && $2 == n { print $3; exit }' "$shots/log.txt")
	world+=(-label "$name${what:+: $what}" "$file")
done
montage "${world[@]}" -tile 2x -geometry 960x540+4+4 -pointsize 20 -background '#f4efe6' -title "lineup, the world's own" \
	-depth 8 "$out/lineup_world.png"
for pair in "dusk:dusk20 dusk_camp5" "storm:storm_camp storm_power"; do
	args=()
	for shot in ${pair#*:}; do
		[[ -f $shots/$shot.png ]] && args+=(-label "$shot" "$shots/$shot.png")
	done
	montage "${args[@]}" -tile 2x1 -geometry 960x540+4+4 -pointsize 22 -background '#f4efe6' -title "lineup, ${pair%%:*}" \
		-depth 8 "$out/lineup_${pair%%:*}.png"
done
echo "sheets: $out/lineup_{all20,rows,world,dusk,storm}.png, $out/row_<block>.png"
