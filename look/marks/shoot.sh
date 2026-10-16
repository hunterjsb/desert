#!/usr/bin/env bash
# Shoots the maker's marks look-test, then builds one sheet per marked thing:
# before and after, close up, from 5 m, and the 5 m frame's middle blown up.
#   look/marks/shoot.sh <out dir>                  shoot this build
#   look/marks/shoot.sh --sheets <before> <after>  sheets to ~/Desktop/marks_<thing>.png
# The window never takes focus. A game running (Proton, Wine, gamescope)
# holds the launch until it's gone.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

things=(crate_deep crate_surface crate_yours crates shield light_shield turbine condenser board ruin)

if [[ ${1:-} == --sheets ]]; then
	before=${2:?a before directory}
	after=${3:?an after directory}
	for thing in "${things[@]}"; do
		args=()
		for shot in close 5m 5m_crop; do
			for side in before after; do
				dir=$before
				[[ $side == after ]] && dir=$after
				file="$dir/${thing}_$shot.png"
				if [[ $shot == 5m_crop ]]; then
					file="$dir/${thing}_5m.png"
					[[ -f $file ]] && file="$file[960x540+480+270]"
				fi
				[[ -f ${file%%\[*} ]] || file="xc:gray"
				args+=(-label "$side, ${shot//_/ }" "$file")
			done
		done
		montage "${args[@]}" -tile 2x3 -geometry 960x540+4+4 -pointsize 24 -background '#f4efe6' \
			-title "${thing//_/ }" -depth 8 "$HOME/Desktop/marks_$thing.png"
		echo "sheet: $HOME/Desktop/marks_$thing.png ($(du -h "$HOME/Desktop/marks_$thing.png" | cut -f1))"
	done
	exit 0
fi

out=${1:?an output directory}
godot=${GODOT:-godot}
while ps -eo args | grep -iE 'proton|wine|gamescope|\.exe' | grep -v grep >/dev/null; do
	echo "a game is running; waiting to open a window"
	sleep 60
done
timeout 600 "$godot" --path . --disable-vsync res://look/marks/marks.tscn -- --look grey --capture "$out" 2>&1 |
	grep -E '^(style|  )'
