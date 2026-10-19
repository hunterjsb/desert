#!/usr/bin/env bash
# Shoots the boards look-test and builds its sheet: each make on the sand and
# all four together, a skid's spray, a hard landing sliding out, and a pop's
# pitch as it flies.
#   look/boards/shoot.sh <out dir>    sheet to ~/Desktop/boards.png
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
mkdir -p "$out"
godot=${GODOT:-scripts/unseen.sh}
timeout 900 "$godot" --path . --resolution 1920x1080 --disable-vsync res://look/boards/boards_shots.tscn -- "$out" 2>&1 |
	grep -E '^(make|skid|landing|pop)'
if [[ ! -f $out/pop_3.png ]]; then
	echo "no shots: is the GPU up? (scripts/unseen.sh)" >&2
	exit 1
fi
args=()
labels=("Hoverboard: the company's issue" "Skimmer racer" "Knights' patrol board" "Temple board"
	"all four" "a skid, and its spray" "a hard landing, crossed, sliding out" ""
	"a pop: rising" "at its top" "falling" "landing")
names=(make_0 make_1 make_2 make_3 makes skid landing - pop_0 pop_1 pop_2 pop_3)
for i in "${!names[@]}"; do
	file="$out/${names[i]}.png"
	[[ -f $file ]] || file="xc:#f4efe6"
	args+=(-label "${labels[i]}" "$file")
done
montage "${args[@]}" -tile 4x3 -geometry 960x540+4+4 -pointsize 22 -background '#f4efe6' -title "boards by make" \
	-depth 8 "$HOME/Desktop/boards.png"
echo "sheet: $HOME/Desktop/boards.png"
