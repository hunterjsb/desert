#!/usr/bin/env bash
# Shoots the tumble look-test and builds its strip: a skid's gouge beside a
# carve's line, from above and from beside it, then a wipeout's tumble through
# your own eyes from the throw till you're up, and from behind.
#   look/tumble/shoot.sh <out dir>    strip to ~/Desktop/tumble.png
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
mkdir -p "$out"
godot=${GODOT:-scripts/unseen.sh}
timeout 900 "$godot" --path . --resolution 1920x1080 --disable-vsync res://look/tumble/tumble_shots.tscn -- "$out" 2>&1 |
	grep -E '^(gouge|eyes|behind|tracks)'
if [[ ! -f $out/eyes_150.png ]]; then
	echo "no shots: is the GPU up? (scripts/unseen.sh)" >&2
	exit 1
fi
args=()
labels=("a carve's line and, inside it, a skid's gouge" "the gouge, from beside it" "thrown: hitting the sand"
	"at rest, the board tumbled away" "0.07 s: thrown" "0.23 s: going over" "0.37 s: the first hit" "0.57 s: rolling"
	"0.8 s: face down" "1.1 s: the last hit" "1.67 s: at rest" "2.5 s: getting up")
names=(gouge_above gouge_beside behind_22 behind_100 eyes_4 eyes_14 eyes_22 eyes_34 eyes_48 eyes_66 eyes_100 eyes_150)
for i in "${!names[@]}"; do
	file="$out/${names[i]}.png"
	[[ -f $file ]] || file="xc:#f4efe6"
	args+=(-label "${labels[i]}" "$file")
done
montage "${args[@]}" -tile 4x3 -geometry 960x540+4+4 -pointsize 22 -background '#f4efe6' -title "skids gouge, falls tumble" \
	-depth 8 "$HOME/Desktop/tumble.png"
echo "strip: $HOME/Desktop/tumble.png"
