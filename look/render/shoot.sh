#!/usr/bin/env bash
# Shoots the renderer's look-test before (master's drawing) and at each graphics
# quality, clear and in a storm, then builds one sheet per shot: each quality's
# frame across, and under it the same patch at twice its size, so edges, contact
# shade, glow and shadows read. The motion sheet holds four running frames of
# the rope at three times, and the walk's last moving frame.
#   look/render/shoot.sh <out dir> [sheet dir]
#   look/render/shoot.sh --time <out dir>     each quality's GPU cost against master's
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

timing=()
[[ ${1:-} == --time ]] && timing=(--time) && shift
out=${1:?an output directory}
sheets=${2:-$out}
godot=${GODOT:-scripts/unseen.sh}
tries=(--try low:quality=low --try medium:quality=medium --try high:quality=high)
looks=(master low medium high)
mkdir -p "$out" "$sheets"

# Night by the eye's exposure there (Eye adaptation), which every look-test otherwise holds at 1.
for weather in clear storm night; do
	for run in stills motion; do
		args=(--capture "$out" "${tries[@]}" "${timing[@]}")
		[[ $weather == storm ]] && args+=(--storm)
		[[ $weather == night ]] && args+=(--only camp5_night --base tuning.exposure=6)
		[[ $run == motion ]] && args+=(--motion)
		[[ ($run == motion || $weather == night) && ${#timing[@]} -gt 0 ]] && continue
		[[ $run == motion && $weather == night ]] && continue
		timeout 3000 "$godot" --path . --disable-vsync res://look/render/render.tscn -- --look grey "${args[@]}" 2>&1 |
			grep -E '^(style|  time |  [a-z_0-9]+$)'
	done
done
[[ ${#timing[@]} -gt 0 ]] && exit 0

# Each shot and the patch blown up: name, title, patch.
for row in "camp5_noon:the camp from 5 m, noon:480x270+640+380" "camp5_dusk:the camp from 5 m, dusk:480x270+640+380" \
	"camp20_noon:the camp from 20 m, noon:480x270+720+420" "camp20_dusk:the camp from 20 m, dusk:480x270+720+420" \
	"storm:a storm, inside the bubble:480x270+700+420" "rope_close:the rope close up:480x270+720+405" \
	"rope4:the rope from 4 m:480x270+720+405" "feet:where devices meet the sand:480x270+900+480" \
	"camp5_night:a full-Tu night, the eye open:480x270+640+380"; do
	IFS=: read -r shot title patch <<<"$row"
	args=()
	for look in "${looks[@]}"; do
		file="$out/${shot}_$look.png"
		[[ -f $file ]] || file="xc:gray"
		args+=(-label "$look" "$file")
	done
	for look in "${looks[@]}"; do
		file="$out/${shot}_$look.png"
		[[ -f $file ]] && file="$file[$patch]" || file="xc:gray"
		args+=(-label "$look, twice size" "$file")
	done
	montage "${args[@]}" -tile 4x -geometry 960x540+4+4 -filter point -pointsize 22 -background '#f4efe6' \
		-title "$title" -depth 8 "$sheets/$shot.png"
	echo "sheet: $sheets/$shot.png"
done

args=()
for look in "${looks[@]}"; do
	for i in 10 11 12 13; do
		file="$out/rope_${look}_c$i.png"
		[[ -f $file ]] && file="$file[160x120+300+60]" || file="xc:gray"
		args+=(-label "$look, frame $i" "$file")
	done
done
for look in "${looks[@]}"; do
	file="$out/walk_${look}_moving.png"
	[[ -f $file ]] || file="xc:gray"
	args+=(-label "$look, walking" "$file")
done
montage "${args[@]}" -tile 4x -geometry 480x360+4+4 -filter point -pointsize 18 -background '#f4efe6' \
	-title "creeping past the rope, then walking the path" -depth 8 "$sheets/motion.png"
echo "sheet: $sheets/motion.png"
