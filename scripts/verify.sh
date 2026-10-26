#!/usr/bin/env bash
# CI on what's checked out, before it reaches master: pushes HEAD to
# verify-<name>, waits for its run, and prints each job and what failed. With
# --land, a green run moves master to it and drops the branch, unless master's
# latest macOS/Windows run failed a real check: then only its fix lands
# (FIXES_PLATFORMS=1). A platform timeout or runner fault only warns.
#   scripts/verify.sh <name> [--land]
# DESERT_LAND_WAIT caps the wait for another driver's landing, DESERT_CI_WAIT
# the wait for a run, both in seconds.
set -euo pipefail
# Bash reads a script as it runs, so editing or recopying this file under a
# live run garbles it: every run first moves to a private copy of itself.
if [[ -z ${VERIFY_PRIVATE_COPY:-} ]]; then
	copy=$(mktemp "${TMPDIR:-/tmp}/desert-verify.XXXXXX")
	cp "$0" "$copy"
	VERIFY_PRIVATE_COPY=$copy exec bash "$copy" "$@"
fi
trap 'rm -f -- "${VERIFY_PRIVATE_COPY:?}"' EXIT
name=${1:?a name for the verify branch}
land=${2:-}
land_wait=${DESERT_LAND_WAIT:-2700}
ci_wait=${DESERT_CI_WAIT:-5400}
# Lands $sha while holding the lock shared by every driver, which is taken
# only for the landing itself, never the run. If master gained only docs
# meanwhile they're merged in without another run; if it gained code, the
# combined result needs verifying.
land_it() {
	local target=$sha base tree lock
	if command -v flock >/dev/null; then
		lock=${DESERT_LAND_LOCK:-$(git rev-parse --show-toplevel)/../.desert-land.lock}
		exec 9>"$lock"
		if ! flock -n 9; then
			echo "another landing holds the lock: waiting up to $((land_wait / 60)) min"
			flock -w "$land_wait" 9 || { echo "the landing queue stayed busy for $((land_wait / 60)) min: land again" >&2; exit 1; }
		fi
	fi
	git fetch -q origin
	if ! git merge-base --is-ancestor origin/master "$sha"; then
		base=$(git merge-base origin/master "$sha")
		if [[ -n $(git diff --name-only "$base" origin/master -- . ':!docs' ':!*.md') ]]; then
			echo "master moved past it with code: merge master and verify again" >&2
			exit 1
		fi
		tree=$(git merge-tree --write-tree --no-messages origin/master "$sha") ||
			{ echo "master's new docs conflict with it: merge master and verify again" >&2; exit 1; }
		target=$(git commit-tree "$tree" -p origin/master -p "$sha" -m "Merge master's docs into ${sha:0:7} as it lands")
		echo "master moved only by docs: merged them in as ${target:0:7}"
	fi
	git push -q origin "$target:master"
	echo "landed ${target:0:7} on master"
}
# Waits for run $1 to finish, at most ci_wait seconds. Checked often, since
# every landing waits on it; one failed status request is asked again, two
# in a row stop the wait.
wait_run() {
	local waited=0 status missed=0
	while :; do
		if status=$(gh run view "$1" --json status -q .status); then
			missed=0
		else
			((missed == 0)) || { echo "run $1: its status could not be read twice running" >&2; return 1; }
			missed=1
		fi
		[[ $status == completed ]] && return 0
		if ((waited >= ci_wait)); then
			echo "run $1 still $status after $((ci_wait / 60)) min: check it" >&2
			return 1
		fi
		sleep 20
		waited=$((waited + 20))
	done
}
sha=$(git rev-parse HEAD)
git fetch -q origin
# Docs alone run no CI (probes.yml ignores them): nothing to wait for.
if [[ -z $(git diff --name-only origin/master "$sha" -- . ':!docs' ':!*.md') ]]; then
	echo "docs only at ${sha:0:7}: no CI to run"
	[[ $land == --land ]] && land_it
	exit 0
fi
# Only dashboard-owned paths may bypass game checks. Renames out of game paths
# must still count as game changes; git diff's path filtering retains deletions.
workflow=probes.yml
if git diff --quiet origin/master "$sha" -- . ':!docs' ':!*.md' \
	':!site' ':!scripts/ci_dashboard' ':!.github/workflows/performance-pages.yml'; then
	workflow=performance-pages.yml
fi
echo "verifying ${sha:0:7} with $workflow"
# Quiet: GitHub's remote lines offer a pull request for every new branch.
git push -q -f origin "HEAD:refs/heads/verify-$name" 2> >(grep -v '^remote:' >&2)
branch="verify-$name"
# Workflow, branch and commit all matter: a release or another branch may
# have a successful run of this same commit without verifying this push.
find_run() {
	gh run list -w "$workflow" -b "$branch" -c "$sha" --limit 20 \
		--json databaseId,event \
		-q 'map(select(.event == "push" or .event == "workflow_dispatch")) | .[0].databaseId'
}
id=""
for attempt in $(seq 7); do
	id=$(find_run)
	[[ -n $id ]] && break
	[[ $attempt == 7 ]] || sleep 5
done
if [[ -z $id ]]; then
	# Dispatch resolves a branch now, so refuse if another verifier moved it.
	remote_sha=$(git ls-remote origin "refs/heads/$branch" | cut -f1)
	[[ $remote_sha == "$sha" ]] || { echo "$branch moved: verify again" >&2; exit 1; }
	echo "no push run after 30s: dispatching $workflow for $branch at ${sha:0:7}"
	if [[ $workflow == probes.yml ]]; then
		gh workflow run "$workflow" --ref "$branch" -f full_platforms=false
	else
		gh workflow run "$workflow" --ref "$branch"
	fi
	for attempt in $(seq 6); do
		id=$(find_run)
		[[ -n $id ]] && break
		[[ $attempt == 6 ]] || sleep 60
	done
fi
[[ -n $id ]] || { echo "no $workflow run for $branch at ${sha:0:7}" >&2; exit 1; }
wait_run "$id" || exit 1
conclusion=$(gh run view "$id" --json conclusion -q .conclusion)
echo "$conclusion: run $id at ${sha:0:7}"
gh run view "$id" --json jobs -q '.jobs[] | "  \(.conclusion)  \(.name)"'
# Prints the failing lines of each job id read from stdin.
failures() {
	while read -r job; do
		# Log lines open with a 29-character timestamp.
		gh api --allow-escape-sequences "repos/{owner}/{repo}/actions/jobs/$job/logs" | sed 's/\x1b\[[0-9;]*m//g' |
			grep -E ' (FAIL|ERROR|TIMEOUT) |CHECK FAILED|SCRIPT ERROR|PROBE FAIL' | grep -v -e 'probes/selftest/' -e '.probe_tmp/' |
			cut -c30- | head -20 || true
	done
}
# A rerun's earlier attempts stay on record: what failed before is named.
attempts=$(gh run view "$id" --json attempt -q .attempt)
for ((n = 1; n < ${attempts:-1}; n++)); do
	if ! earlier=$(gh api "repos/{owner}/{repo}/actions/runs/$id/attempts/$n/jobs" \
		-q '.jobs[] | select(.conclusion == "failure") | "\(.id) \(.name)"'); then
		echo "  attempt $n: its jobs could not be read"
		continue
	fi
	while read -r job name; do
		[[ -n $job ]] || continue
		echo "  attempt $n failed  $name"
		echo "$job" | failures
	done <<<"$earlier"
done
if [[ $conclusion != success ]]; then
	gh run view "$id" --json jobs -q '.jobs[] | select(.conclusion == "failure") | .databaseId' | failures
	exit 1
fi
# Platforms run only on master, so a real failure there stops the line until
# it's fixed. A timeout on those slower runners, or a job that failed with no
# probe failing (a setup or runner fault), is named but doesn't stop it.
platforms_red() {
	local run jobs lines
	for run in $(gh run list -w probes.yml -b master -e push -s completed --limit 10 \
		--json databaseId -q '.[].databaseId'); do
		jobs=$(gh run view "$run" --json jobs -q '.jobs[] | select(.name | test("^(macOS|Windows) |smoke \\((macos|windows)"))
			| select(.conclusion == "success" or .conclusion == "failure") | "\(.conclusion) \(.databaseId) \(.name)"')
		[[ -n $jobs ]] || continue
		grep -q '^failure ' <<<"$jobs" || return 1
		grep '^failure ' <<<"$jobs" | cut -d' ' -f3- | sed "s/^/  red on master (run $run): /"
		lines=$(grep '^failure ' <<<"$jobs" | cut -d' ' -f2 | failures)
		[[ -z $lines ]] || printf '%s\n' "$lines"
		if grep -qE 'CHECK FAILED|SCRIPT ERROR|PROBE FAIL|^(FAIL|ERROR) ' <<<"$lines" || grep -q 'smoke' <<<"$jobs"; then
			return 0
		fi
		echo "  only timeouts or a runner fault: not stopping the line, but fix what's named"
		return 1
	done
	return 1
}
if [[ $land == --land && $workflow == probes.yml && -z ${FIXES_PLATFORMS:-} ]] && platforms_red; then
	echo "master's platform run failed a real check: land its fix first, with FIXES_PLATFORMS=1" >&2
	exit 1
fi
if [[ $land == --land ]]; then
	land_it
	git push -q origin --delete "verify-$name"
fi
