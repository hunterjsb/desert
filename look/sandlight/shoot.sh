#!/usr/bin/env bash
# Shoots the sand's light before and after, in the clear and in a storm, then
# builds the sheet: each moment before beside after, and the glitter close up
# frame by frame as the camera moves, blown up. Anything after the sheet goes
# to the look-test, such as --try name=value,...
#   look/sandlight/shoot.sh <out dir> [sheet] [look-test arguments]
# "Before" is master's sand shader; BEFORE names another ref.
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$HOME/Desktop/sandlight.png}
shift $(($# < 2 ? $# : 2))
godot=${GODOT:-scripts/unseen.sh}
mkdir -p "$out"
git show "${BEFORE:-master}:game/world/sand.gdshader" >"$out/before.gdshader" || exit 2

# --only without the storm skips the storm's pass.
only=$(printf '%s\n' "$@" | grep -A1 -x -- --only | tail -n +2)
for weather in clear storm; do
	flag=()
	[[ $weather == storm ]] && flag=(--storm)
	[[ $weather == storm && -n $only && ,$only, != *,storm,* ]] && continue
	timeout 900 "$godot" --path . --disable-vsync res://look/sandlight/sandlight.tscn -- \
		--capture "$out" --before "$out/before.gdshader" "${flag[@]}" "$@" 2>&1 | grep -E '^sandlight|SHADER ERROR'
done

args=()
for pair in "noon:noon" "low_into:low sun, facing it" "air_low:the same from 200 m up" \
	"low_behind:low sun behind you" "dusk:dusk, the sun behind you" "night:a full-Tu night, Tu behind you" \
	"lamp:the same, by the headlamp" "storm:deep in a storm by day" "track:a walked track, midmorning" \
	"feet:at your feet, noon" "ripples:ripples over a dune, a low sun" "slip:a slip face from its foot"; do
	[[ -f $out/${pair%%:*}_after.png ]] || continue
	for look in before after; do
		file="$out/${pair%%:*}_$look.png"
		label="${pair#*:}, $look"
		[[ -f $file ]] || file="xc:gray"
		[[ -f $out/${pair%%:*}_$look.txt ]] && label="$label: $(cat "$out/${pair%%:*}_$look.txt")"
		args+=(-label "$label" "$file")
	done
done
montage "${args[@]}" -tile 2x -geometry 1446x813+6+6 -pointsize 24 -background '#f4efe6' "$out/moments.png"

# The glitter: a patch of each frame at three times, nearest-neighbour, so a
# pixel that crawls shows: sliding sideways, then walking on.
crops=()
for motion in "slide:+0+60:sliding sideways" "walk:+0+140:walking on"; do
	IFS=: read -r name offset words <<<"$motion"
	for look in before after; do
		for i in 0 1 2; do
			file="$out/${name}_${i}_$look.png"
			if [[ -f $file ]]; then
				magick "$file" -gravity center -crop "320x180$offset" +repage -filter point -resize 300% \
					"$out/crop_${name}_${i}_$look.png"
				file="$out/crop_${name}_${i}_$look.png"
			else
				file="xc:gray"
			fi
			crops+=(-label "$words, $look, frame $i" "$file")
		done
	done
done
parts=(-label "" "$out/moments.png")
if [[ -f $out/slide_0_after.png ]]; then
	montage "${crops[@]}" -tile 3x -geometry 960x540+6+6 -pointsize 20 -background '#f4efe6' "$out/glitter.png"
	parts+=(-label "" "$out/glitter.png")
fi
montage "${parts[@]}" -tile 1x -geometry +0+12 -background '#f4efe6' \
	-title "The sand's own light: before (left) and after (right); then the glitter as the camera moves, blown up three times" \
	-pointsize 28 -depth 8 "$sheet"
echo "sheet: $sheet"
