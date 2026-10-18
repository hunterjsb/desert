#!/usr/bin/env bash
# Godot on a real GPU with no window: gamescope's headless backend gives it an
# invisible screen of its own, so a look-test shoots while someone plays and
# nothing ever opens over their game. Takes Godot's own arguments; the screen
# is the --resolution given, else 1920x1080.
#   scripts/unseen.sh --path . --resolution 1920x1080 res://look/capture.tscn -- out.png
size=1920x1080
args=("$@")
for ((i = 0; i < ${#args[@]} - 1; i++)); do
	[[ ${args[i]} == --resolution ]] && size=${args[i + 1]}
done
exec nice -n 10 gamescope --backend headless -W "${size%x*}" -H "${size#*x}" -w "${size%x*}" -h "${size#*x}" \
	-- godot --audio-driver Dummy "$@"
