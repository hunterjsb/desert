#!/usr/bin/env bash
# Shoots the eclipse look-test in the clear and in a storm, then builds its
# sheet: the last of the sun going copper, second contact, mid-totality facing
# Tu and away from it, third contact, mid-totality out in a storm's dust and in
# a bubble, and a full-Tu night once the eye has adapted.
#   look/eclipse/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/eclipse_epic.png}
godot=${GODOT:-scripts/unseen.sh}

for weather in clear storm; do
	flag=()
	[[ $weather == storm ]] && flag=(--storm)
	timeout 900 "$godot" --path . --disable-vsync res://look/eclipse/eclipse.tscn -- --capture "$out" "${flag[@]}" 2>&1 |
		grep -E '^eclipse|ERROR|SHADER'
done

args=()
shot() {
	local file="$out/$1.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "$2" "$file")
}
shot copper "a second before totality: the light gone copper"
shot second "second contact: the diamond ring"
shot mid "mid-totality, in the clear"
shot mid_away "mid-totality, facing away: the glow all round"
shot third "third contact"
shot storm_out "mid-totality, out in a storm's dust"
shot storm_in "mid-totality, in a bubble at camp, in the storm"
shot full_night "a full-Tu night, the eye adapted"
montage "${args[@]}" -tile 4x -geometry 960x540+6+6 -pointsize 24 -depth 8 \
	-background '#f4efe6' -title "The eclipse, Tu 9° across, where a run begins, as the eye sees it" "$sheet"
echo "sheet: $sheet"
