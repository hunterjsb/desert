#!/usr/bin/env bash
# Shoots the lineage look-test and builds its sheet: a chassis piece and a battery in
# each era and lineage, close up and from 5 m, and the row whole.
#   look/lineage/shoot.sh <out dir>    sheet to ~/Desktop/lineage.png
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
timeout 900 "$godot" --path . --disable-vsync res://look/lineage/lineage.tscn -- --look grey --capture "$out" 2>&1 |
	grep -E '^(style|  )'
if [[ ! -f $out/row.png ]]; then
	echo "no shots: is the GPU up? (scripts/unseen.sh)" >&2
	exit 1
fi
args=()
for name in issued colonial first skimmer remade second cistern; do
	for shot in close 5m; do
		file="$out/${name}_$shot.png"
		[[ -f $file ]] || file="xc:gray"
		args+=(-label "$name, $shot" "$file")
	done
done
montage "${args[@]}" -tile 2x7 -geometry 960x540+4+4 -pointsize 22 -background '#f4efe6' -title "lineage" \
	-depth 8 "$HOME/Desktop/lineage.png"
cp "$out/row.png" "$HOME/Desktop/lineage_row.png"
echo "sheet: $HOME/Desktop/lineage.png"
