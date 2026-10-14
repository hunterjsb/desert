#!/usr/bin/env bash
# Runs headless probes and prints one verdict per probe.
#
# A probe passes only if it prints "PROBE PASS", exits 0, prints no script
# error, and finishes in time. Each condition catches a failure the others
# miss: a runtime script error still lets the probe exit 0, and a script that
# fails to parse never calls quit(), so a hang has to count as a failure.
#
#   scripts/probe.sh                  every probe except the selftest
#   scripts/probe.sh probes/a/b.gd    just the named probes
#   scripts/probe.sh selftest         proves the runner itself can fail
#
# GODOT picks the binary (default: godot on PATH). PROBE_TIMEOUT is in seconds.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

godot=${GODOT:-godot}
limit=${PROBE_TIMEOUT:-300}

want=$(cat .godot-version)
have=$("$godot" --version 2>/dev/null | tail -n 1)
if [[ $have != "$want".* ]]; then
	echo "warning: $godot is '$have', the project pins $want" >&2
fi

# Godot serves assets from .godot/imported, so a change is invisible to a
# probe until it has been imported.
if ! timeout 600 "$godot" --headless --path . --import >/dev/null 2>&1; then
	echo "import failed; open the project in the editor to see why" >&2
	exit 2
fi

verdict=""
output=""
run_probe() {
	local started=$SECONDS code
	output=$(timeout --kill-after=5 "$limit" "$godot" --headless --path . \
		res://probes/lib/host.tscn -- "res://$1" 2>&1)
	code=$?
	if grep -qE 'SCRIPT ERROR|Parse Error|Failed to load script' <<<"$output"; then
		verdict=error
	elif ((code == 124 || code == 137)); then
		verdict=timeout
	elif ((code == 0)) && grep -q '^PROBE PASS' <<<"$output"; then
		verdict=pass
	else
		verdict=fail
	fi
	printf '%-8s %s (%ds)\n' "${verdict^^}" "$1" $((SECONDS - started))
}

show_output() {
	tail -n 30 <<<"$output" | sed 's/^/    /'
}

if [[ ${1:-} == selftest ]]; then
	limit=15
	ok=0
	expect() {
		run_probe "$1"
		if [[ $verdict != "$2" ]]; then
			echo "    expected $2" >&2
			show_output
			ok=1
		fi
	}
	expect probes/selftest/pass.gd pass
	expect probes/selftest/fail.gd fail
	expect probes/selftest/hang.gd timeout
	expect probes/selftest/crash.gd error
	# A script that fails to parse can't live in the repo, or the editor would
	# complain every time the project opens, so it's written here and removed.
	mkdir -p .probe_tmp
	printf 'extends Probe\nfunc run(:\n' >.probe_tmp/parse_error.gd
	expect .probe_tmp/parse_error.gd error
	rm -f .probe_tmp/parse_error.gd
	rmdir .probe_tmp 2>/dev/null
	exit "$ok"
fi

if (($# > 0)); then
	probes=("$@")
else
	mapfile -t probes < <(find probes -name '*.gd' \
		-not -path 'probes/lib/*' -not -path 'probes/selftest/*' | sort)
fi

failed=0
for probe in "${probes[@]}"; do
	run_probe "$probe"
	if [[ $verdict != pass ]]; then
		show_output
		failed=$((failed + 1))
	fi
done
echo "${#probes[@]} probes, $failed not passing"
((failed == 0))
