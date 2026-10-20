#!/usr/bin/env bash
# The seeded city, through its furnace cycle; optional --storm.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
out=${1:?absolute output directory}
shift
exec "$root/scripts/unseen.sh" --path "$root" --resolution 1280x720 \
	res://look/halloran/halloran.tscn -- "$out" "$@"
