#!/usr/bin/env bash
# Shoots the plumes in the run's own weather (the rift vent in a calm, a
# strong wind, a burst, dusk, a front and a storm over it, night; a burst over
# a storm from 15 km; a gas pocket; the far side's flank vent) from near and
# far, and the rift vent's mouth up close, then builds the sheet
# ~/Desktop/plume.png. Each shot also times the GPU with the plumes and
# without; the times print at the end.
#   look/plume/shoot.sh <out dir>            shoot, then build the sheet
#   look/plume/shoot.sh <out dir> --sheet    build the sheet from what's there
#   look/plume/shoot.sh <out dir> --only calm_far,burst_near   just those shots, no sheet
# No window: it runs unseen (scripts/unseen.sh), so it shoots while someone plays.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

out=${1:?an output directory}
godot=${GODOT:-scripts/unseen.sh}
if [[ ${2:-} != --sheet ]]; then
	timeout 1500 "$godot" --path . --disable-vsync --resolution 1280x720 res://look/plume/plume.tscn -- --capture "$out" \
		"${@:2}" 2>&1 | grep -E '^plume'
	[[ ${2:-} == --only ]] && exit 0
fi

declare -A says=([calm_near]="the calm, 260 m" [calm_mid]="the calm, 1.5 km" [calm_far]="the calm, 7 km"
	[wind_near]="a strong wind, 260 m" [wind_mid]="a strong wind, 1.5 km" [wind_far]="a strong wind, 7 km"
	[burst_near]="a burst, 1.5 km" [burst_mid]="a burst, 7 km" [burst_far]="a burst, 25 km"
	[over_far]="a burst over a storm by the vent, 15 km" [dusk_mid]="dusk, 1.5 km" [dusk_far]="dusk, 7 km"
	[storm_mid]="a front coming over it, 1.5 km" [swallowed_mid]="a storm over it, 1.5 km" [night_mid]="night, 1.5 km"
	[pocket_far]="a gas pocket blowing, 6 km" [flank_far]="the far-side volcano's flank vent, 7 km"
	[mouth_close]="the rift vent's mouth, 48 m")
rows=()
n=0
for group in "calm_near calm_mid calm_far" "wind_near wind_mid wind_far" "burst_near burst_mid burst_far" \
	"over_far dusk_mid dusk_far" "storm_mid swallowed_mid night_mid" "pocket_far flank_far mouth_close"; do
	shots=()
	for name in $group; do
		[[ -f $out/$name.png ]] && shots+=(-label "${says[$name]}" "$out/$name.png")
	done
	((${#shots[@]} > 0)) || continue
	row="$out/row_$n.png"
	n=$((n + 1))
	montage "${shots[@]}" -tile 3x1 -geometry 640x360+4+4 -pointsize 20 -background '#f4efe6' "$row"
	rows+=("$row")
done
magick "${rows[@]}" -background '#f4efe6' -gravity west -append \
	-gravity north -splice 0x60 -pointsize 34 -annotate +0+12 "Zan's plumes" \
	+repage -depth 8 -define png:color-type=2 "$HOME/Desktop/plume.png"
echo "sheet: $HOME/Desktop/plume.png ($(du -h "$HOME/Desktop/plume.png" | cut -f1))"
