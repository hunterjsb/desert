#!/usr/bin/env bash
# Shoots the dial look-test, then builds its sheet: a radio stood over, the
# view easing in as you tune it, closed in at places on the band, easing out
# as you look away, one in your hands and one at dusk.
#   look/dial/shoot.sh <out dir> [sheet]
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
sheet=${2:-$out/sheet.png}
godot=${GODOT:-scripts/unseen.sh}

timeout 900 "$godot" --path . --disable-vsync res://look/dial/dial.tscn -- --capture "$out" 2>&1 |
	grep -E '^dial'

args=()
for file in "$out"/standing.png "$out"/easing_in.png "$out"/closed_*.png "$out"/easing_out.png "$out"/out.png \
	"$out"/held.png "$out"/dusk.png; do
	[[ -f $file ]] || continue
	shot=$(basename "$file" .png)
	case $shot in
	standing) label="standing over it, before tuning" ;;
	easing_in) label="a notch: the view easing in" ;;
	closed_*) label="closed in, $((10#${shot#closed_})) kHz" ;;
	easing_out) label="looking away: easing out" ;;
	out) label="back to your own view" ;;
	held) label="in your hands, its face turned up to you" ;;
	dusk) label="at dusk, its scale lit" ;;
	esac
	args+=(-label "$label" "$file")
done
montage "${args[@]}" -tile 4x -geometry 720x405+6+6 -pointsize 22 -depth 8 \
	-background '#f4efe6' -title "the dial in your hands" "$sheet"
echo "sheet: $sheet"
