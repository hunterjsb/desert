#!/usr/bin/env bash
# Exports the game for Linux, Windows and macOS (export_presets.cfg) and zips
# each as a release asset, desert-<version>-<os>.zip, into the folder given
# (default build/). Needs the pinned export templates installed; runs on Linux.
#   scripts/export.sh [out]
set -euo pipefail
cd "$(dirname "$0")/.."

godot=${GODOT:-godot}
out=${1:-build}
version=$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)
[[ -n $version ]] || { echo "project.godot has no config/version" >&2; exit 2; }
stage=$(mktemp -d)
trap 'rm -rf -- "${stage:?}"' EXIT
# Its own log, never the user's, which keeps a played game's crash.
log=$stage/godot.log

# macOS wants plain numbers for its bundle version; the project's version
# is the only one written by hand.
sed -i -E "s/^application\/(short_version|version)=.*/application\/\1=\"${version%%-*}\"/" export_presets.cfg

if ! timeout 600 "$godot" --headless --log-file "$log" --path . --import >/dev/null 2>&1; then
	echo "import failed; open the project in the editor to see why" >&2
	exit 2
fi

# The engine's licences and its parts', and the font's, ride along with every build.
cat >"$stage/licences.gd" <<'EOF'
extends SceneTree


func _init() -> void:
	var out := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	out.store_string("This game is made with the Godot Engine.\n\n%s\n\nGodot's parts:\n" % Engine.get_license_text())
	for component: Dictionary in Engine.get_copyright_info():
		for part: Dictionary in component.parts:
			out.store_string("  %s: %s (%s)\n" % [component.name, "; ".join(part.copyright), part.license])
	var texts := Engine.get_license_info()
	for name: String in texts:
		out.store_string("\n---- %s ----\n\n%s\n" % [name, texts[name]])
	out.close()
	quit()
EOF
mkdir -p "$stage/empty"
"$godot" --headless --log-file "$log" --path "$stage/empty" -s "$stage/licences.gd" -- "$stage/LICENSES.txt" >/dev/null
{
	printf '\n---- The Geist fonts, under the SIL Open Font License ----\n\n'
	cat assets/fonts/OFL.txt
} >>"$stage/LICENSES.txt"

mkdir -p "$out"
out=$(cd "$out" && pwd)
# preset, its file in the zip, the zip's name for the OS.
for each in "Linux:Desert.x86_64:linux-x86_64" "Windows:Desert.exe:windows-x86_64" "macOS:Desert.app:macos-universal"; do
	IFS=: read -r preset file os <<<"$each"
	name=desert-$version-$os
	dir=$stage/$name
	mkdir -p "$dir"
	if ! timeout 900 "$godot" --headless --log-file "$log" --path . --export-release "$preset" "$dir/$file" >"$stage/$os.out" 2>&1 \
		|| grep -qE 'ERROR|SCRIPT ERROR' "$stage/$os.out"; then
		grep -E 'ERROR|WARNING' -A2 "$stage/$os.out" >&2 || tail -n 30 "$stage/$os.out" >&2
		echo "export for $preset failed" >&2
		exit 1
	fi
	cp "$stage/LICENSES.txt" "$dir/"
	rm -f "$out/$name.zip"
	# Fast deflate trades a small download increase for shorter build waits.
	# The game's folder as the zip's top, but an app at the top of its own,
	# as a Mac unzips it.
	if [[ $os == macos-* ]]; then
		(cd "$dir" && zip -1qry "$out/$name.zip" .)
	else
		(cd "$stage" && zip -1qry "$out/$name.zip" "$name")
	fi
	echo "$out/$name.zip $(du -h "$out/$name.zip" | cut -f1)"
done
