#!/usr/bin/env bash
# CI on what's checked out, before it reaches master: pushes HEAD to
# verify-<name>, waits for its run, and prints each job and what failed. With
# --land, a green run moves master to it and drops the branch.
#   scripts/verify.sh <name> [--land]
set -euo pipefail
name=${1:?a name for the verify branch}
land=${2:-}
sha=$(git rev-parse HEAD)
git fetch -q origin
# Docs alone run no CI (probes.yml ignores them): nothing to wait for.
if [[ -z $(git diff --name-only origin/master "$sha" -- . ':!docs' ':!*.md') ]]; then
	echo "docs only at ${sha:0:7}: no CI to run"
	if [[ $land == --land ]]; then
		git merge-base --is-ancestor origin/master "$sha" || { echo "master moved past it: merge master and verify again" >&2; exit 1; }
		git push -q origin "$sha:master"
		echo "landed ${sha:0:7} on master"
	fi
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
while :; do
	status=$(gh run view "$id" --json status -q .status)
	[[ $status == completed ]] && break
	sleep 60
done
conclusion=$(gh run view "$id" --json conclusion -q .conclusion)
echo "$conclusion: run $id at ${sha:0:7}"
gh run view "$id" --json jobs -q '.jobs[] | "  \(.conclusion)  \(.name)"'
if [[ $conclusion != success ]]; then
	for job in $(gh run view "$id" --json jobs -q '.jobs[] | select(.conclusion == "failure") | .databaseId'); do
		# Log lines open with a 29-character timestamp.
		gh api --allow-escape-sequences "repos/{owner}/{repo}/actions/jobs/$job/logs" | sed 's/\x1b\[[0-9;]*m//g' |
			grep -E ' (FAIL|ERROR|TIMEOUT) |CHECK FAILED|SCRIPT ERROR|PROBE FAIL' | cut -c30- | head -20 || true
	done
	exit 1
fi
if [[ $land == --land ]]; then
	git fetch -q origin
	if ! git merge-base --is-ancestor origin/master "$sha"; then
		echo "master moved past it: merge master and verify again" >&2
		exit 1
	fi
	git push -q origin "$sha:master"
	git push -q origin --delete "verify-$name"
	echo "landed ${sha:0:7} on master"
fi
