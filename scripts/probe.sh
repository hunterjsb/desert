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
#   scripts/probe.sh smoke <game>     an exported build's smoke test (Smoke),
#                                     judged as a probe; <game> may be a command
#
# GODOT picks the binary (default: godot on PATH). PROBE_TIMEOUT is in seconds;
# a probe whose header says "## Time limit: N s" gets N instead.
# PROBE_EXCEPT lists folders to leave out of a full run, so CI can split the
# suite into parallel jobs and still catch every folder nobody listed.
# PROBE_JOBS probes run at once (default one per physical core, at least 4, or
# 2 while someone is playing), the slowest first by the last run's times; a
# probe whose header says "## Runs alone" times real frames, so it runs after
# the rest, by itself. PROBE_RETRY runs each probe that didn't pass once more,
# by itself, and the second verdict counts: for CI's macOS and Windows
# runners, slower and noisier than the machines the probes' timings were set
# on. Both verdicts are printed.
#
# Bash 3.2 and up, so it runs as it is on macOS and in Git Bash on Windows:
# no mapfile, wait -n or flock, and no timeout where there's none.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

godot=${GODOT:-godot}
limit=${PROBE_TIMEOUT:-300}

# Its own log, never the user's: probes writing there would rotate a played
# game's crash log out of the last five within seconds.
reports=$(mktemp -d)
trap 'rm -rf -- "${reports:?}"' EXIT
log=$reports/godot.log

# The command, killed after $1 s: 124 or 137 then, or 142 from perl's alarm
# where there's no GNU timeout (macOS; Windows' own timeout only waits).
timeout --version >/dev/null 2>&1 && gnu_timeout=1 || gnu_timeout=""
limited() {
	local secs=$1
	shift
	if [[ -n $gnu_timeout ]]; then
		timeout --kill-after=5 "$secs" "$@"
	else
		perl -e 'alarm shift; exec @ARGV or die "$ARGV[0]: $!\n"' "$secs" "$@"
	fi
}

verdict=""
output=""
took=0
# The verdict on the output and exit code of what ran.
judge() {
	if grep -qE 'SCRIPT ERROR|Parse Error|Failed to load script|Failed loading resource|No loader found' <<<"$output"; then
		verdict=error
	elif (($1 == 124 || $1 == 137 || $1 == 142)); then
		verdict=timeout
	elif (($1 == 0)) && grep -q '^PROBE PASS' <<<"$output"; then
		verdict=pass
	else
		verdict=fail
	fi
}

say_verdict() {
	printf '%-8s %s (%ds)\n' "$(tr '[:lower:]' '[:upper:]' <<<"$verdict")" "$1" "$took"
}

run_probe() {
	local started=$SECONDS own
	own=$(sed -n 's/^## Time limit: \([0-9][0-9]*\) s.*/\1/p' "$1" 2>/dev/null | head -n 1)
	output=$(limited "${own:-$limit}" "$godot" --headless --log-file "$log" --path . \
		res://probes/lib/host.tscn -- "res://$1" 2>&1)
	judge $?
	took=$((SECONDS - started))
	say_verdict "$1"
}

show_output() {
	tail -n 30 <<<"$output" | sed 's/^/    /'
}

if [[ ${1:-} == smoke ]]; then
	shift
	started=$SECONDS
	output=$(limited "$limit" "$@" --headless --log-file "$log" -- --smoke 2>&1)
	judge $?
	took=$((SECONDS - started))
	grep '^smoke: ' <<<"$output" | sed 's/^/    /'
	say_verdict smoke
	[[ $verdict == pass ]] || show_output
	[[ $verdict == pass ]]
	exit
fi

want=$(cat .godot-version)
have=$("$godot" --version 2>/dev/null | tail -n 1)
if [[ $have != "$want".* ]]; then
	echo "warning: $godot is '$have', the project pins $want" >&2
fi

# Godot serves assets from .godot/imported, so a change is invisible to a
# probe until it has been imported.
if ! limited 600 "$godot" --headless --log-file "$log" --path . --import >/dev/null 2>&1; then
	echo "import failed; open the project in the editor to see why" >&2
	exit 2
fi

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
	together=$(PROBE_TIMEOUT=15 "$BASH" "$0" probes/selftest/fail.gd probes/selftest/pass.gd probes/selftest/fail.gd 2>&1)
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

# One path a line, the folders named expanded.
{
	if (($# > 0)); then
		for arg in "$@"; do
			if [[ -d $arg ]]; then every_probe "$arg"; else echo "$arg"; fi
		done
	else
		skip='^$'
		for folder in ${PROBE_EXCEPT:-}; do
			skip="$skip|^${folder%/}/"
		done
		every_probe probes | grep -vE "$skip" || true
	fi
} >"$reports/list"
probes=()
together=()
alone=()
while IFS= read -r probe; do
	[[ -n $probe ]] || continue
	probes+=("$probe")
	if grep -q '^## Runs alone' "$probe"; then
		alone+=("$probe")
	else
		together+=("$probe")
	fi
done <"$reports/list"

trap 'kill $(jobs -p) 2>/dev/null; exit 130' INT TERM

# One probe's verdict, with its output if it didn't pass, whole in its own
# file; marked done last, so it's printed only once it's all there.
report() {
	run_probe "$2" >"$reports/$1"
	echo "$took $2" >"$reports/$1.took"
	if [[ $verdict != pass ]]; then
		show_output >>"$reports/$1"
		touch "$reports/$1.failed"
	fi
	touch "$reports/$1.done"
}

# Printed here, one at a time as they finish, so reports never interleave.
running=0
collect() {
	local finished
	for finished in "$reports"/*.done; do
		[[ -e $finished ]] || continue
		cat "${finished%.done}"
		rm -f "$finished"
		running=$((running - 1))
	done
}

# Slowest first, so a long probe never starts last and runs on by itself; one
# never timed counts as slowest.
times=.godot/probe_times
if ((${#together[@]} > 0)); then
	sorted=()
	while IFS= read -r probe; do
		sorted+=("$probe")
	done < <(printf '%s\n' "${together[@]}" |
		awk -v f="$times" 'BEGIN { while ((getline line < f) > 0) { split(line, a, " "); took[a[2]] = a[1] } }
			{ print ($0 in took ? took[$0] : 999999), $0 }' | sort -s -rn -k1,1 | cut -d' ' -f2-)
	together=("${sorted[@]}")
fi

if command -v nproc >/dev/null; then
	cores=$(($(nproc) / 2))
else
	cores=$(sysctl -n hw.physicalcpu 2>/dev/null || echo 4)
fi
# Someone is playing, the game in a window or a Steam game: leave them the machine.
playing() {
	pgrep -a -x godot | grep -qv -- '--headless' || pgrep -f 'steamapps/common/' >/dev/null
}
if [[ -z ${PROBE_JOBS:-} && $(uname -s) == Linux ]] && playing; then
	echo "someone is playing: 2 probes at once, on half the cores" >&2
	PROBE_JOBS=2
	# Off the game's cores and their hyperthreads, not only lower in the queue:
	# a niced probe on a sibling thread still slows the game's main thread.
	half=$(lscpu -p=CPU,CORE | awk -F, -v n=$((cores / 2)) '!/^#/ && $2 < n {printf "%s%s", c, $1; c=","}')
	[[ -n $half ]] && taskset -p -c "$half" $$ >/dev/null
fi
jobs_at_once=${PROBE_JOBS:-$((cores > 4 ? cores : 4))}

# Numbered here, not in the background job: a job's own arithmetic happens in
# its subshell and never reaches the next one.
n=0
for probe in ${together[@]+"${together[@]}"}; do
	while ((running >= jobs_at_once)); do
		collect
		((running < jobs_at_once)) || sleep 0.2
	done
	report "$n" "$probe" &
	running=$((running + 1))
	n=$((n + 1))
done
while ((running > 0)); do
	collect
	((running == 0)) || sleep 0.2
done
wait
for probe in ${alone[@]+"${alone[@]}"}; do
	running=1
	report "$n" "$probe"
	collect
	n=$((n + 1))
done
if [[ -n ${PROBE_RETRY:-} ]]; then
	for failed in "$reports"/*.failed; do
		[[ -e $failed ]] || continue
		probe=$(cut -d' ' -f2- "${failed%.failed}.took")
		printf 'again, by itself: '
		run_probe "$probe"
		if [[ $verdict == pass ]]; then rm -f "$failed"; else show_output; fi
	done
fi
# This run's times, then the last known for any probe it didn't run.
{ cat "$reports"/*.took "$times" 2>/dev/null || true; } | awk '!seen[$2]++' >"$reports/times" && mv "$reports/times" "$times"
failed=$(($(find "$reports" -name '*.failed' | wc -l)))
echo "${#probes[@]} probes, $failed not passing"
((failed == 0))
