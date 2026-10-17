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
#   scripts/probe.sh probes/a         every probe in a folder
#   scripts/probe.sh selftest         proves the runner itself can fail
#
# GODOT picks the binary (default: godot on PATH). PROBE_TIMEOUT is in seconds;
# a probe whose header says "## Time limit: N s" gets N instead.
# PROBE_EXCEPT lists folders to leave out of a full run, so CI can split the
# suite into parallel jobs and still catch every folder nobody listed.
# PROBE_JOBS probes run at once (default one per physical core, at least 4, or
# 2 while someone is playing),
# the slowest first by the last run's times; a probe whose header says "## Runs alone" times real frames, so
# it runs after the rest, by itself.
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
took=0
run_probe() {
	local started=$SECONDS code own
	own=$(sed -n 's/^## Time limit: \([0-9]\+\) s.*/\1/p' "$1" 2>/dev/null | head -n 1)
	output=$(timeout --kill-after=5 "${own:-$limit}" "$godot" --headless --path . \
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
	took=$((SECONDS - started))
	printf '%-8s %s (%ds)\n' "${verdict^^}" "$1" "$took"
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
	# Run side by side, every failure still counts as its own.
	together=$(PROBE_TIMEOUT=15 "$0" probes/selftest/fail.gd probes/selftest/pass.gd probes/selftest/fail.gd 2>&1)
	if ! grep -q '^3 probes, 2 not passing$' <<<"$together"; then
		echo "    expected 3 probes, 2 not passing, side by side" >&2
		sed 's/^/    /' <<<"$together"
		ok=1
	fi
	exit "$ok"
fi

every_probe() {
	find "$@" -name '*.gd' -not -path 'probes/lib/*' -not -path 'probes/selftest/*' | sort
}

probes=()
if (($# > 0)); then
	for arg in "$@"; do
		if [[ -d $arg ]]; then
			mapfile -t -O "${#probes[@]}" probes < <(every_probe "$arg")
		else
			probes+=("$arg")
		fi
	done
else
	mapfile -t probes < <(every_probe probes)
	for skip in ${PROBE_EXCEPT:-}; do
		mapfile -t probes < <(printf '%s\n' "${probes[@]}" | grep -v "^${skip%/}/" || true)
	done
	if ((${#probes[@]} == 1)) && [[ -z ${probes[0]} ]]; then
		probes=()
	fi
fi

reports=$(mktemp -d)
trap 'rm -rf -- "${reports:?}"' EXIT
trap 'kill $(jobs -p) 2>/dev/null; exit 130' INT TERM

# One probe's verdict, with its output if it didn't pass, printed whole as it
# finishes so parallel reports never interleave.
report() {
	run_probe "$2" >"$reports/$1"
	echo "$took $2" >"$reports/$1.took"
	if [[ $verdict != pass ]]; then
		show_output >>"$reports/$1"
		touch "$reports/$1.failed"
	fi
	flock "$reports/.lock" cat "$reports/$1"
}

together=()
alone=()
for probe in "${probes[@]}"; do
	if grep -q '^## Runs alone' "$probe"; then
		alone+=("$probe")
	else
		together+=("$probe")
	fi
done
# Slowest first, so a long probe never starts last and runs on by itself; one
# never timed counts as slowest.
times=.godot/probe_times
if ((${#together[@]} > 0)); then
	mapfile -t together < <(printf '%s\n' "${together[@]}" |
		awk -v f="$times" 'BEGIN { while ((getline line < f) > 0) { split(line, a, " "); took[a[2]] = a[1] } }
			{ print ($0 in took ? took[$0] : 999999), $0 }' | sort -s -rn -k1,1 | cut -d' ' -f2-)
fi
# Numbered here, not in the background job: a job's own arithmetic happens in
# its subshell and never reaches the next one.
n=0
cores=$(($(nproc) / 2))
# Someone is playing, the game in a window or a Steam game: leave them the machine.
playing() {
	pgrep -a -x godot | grep -qv -- '--headless' || pgrep -f 'steamapps/common/' >/dev/null
}
if [[ -z ${PROBE_JOBS:-} ]] && playing; then
	echo "someone is playing: 2 probes at once" >&2
	PROBE_JOBS=2
fi
jobs_at_once=${PROBE_JOBS:-$((cores > 4 ? cores : 4))}
for probe in "${together[@]}"; do
	while (($(jobs -rp | wc -l) >= jobs_at_once)); do
		wait -n
	done
	report "$n" "$probe" &
	n=$((n + 1))
done
wait
for probe in "${alone[@]}"; do
	report "$n" "$probe"
	n=$((n + 1))
done
# This run's times, then the last known for any probe it didn't run.
{ cat "$reports"/*.took "$times" 2>/dev/null || true; } | awk '!seen[$2]++' >"$reports/times" && mv "$reports/times" "$times"
failed=$(find "$reports" -name '*.failed' | wc -l)
echo "${#probes[@]} probes, $failed not passing"
((failed == 0))
