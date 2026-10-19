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
# Quiet: GitHub's remote lines offer a pull request for every new branch.
git push -q -f origin "HEAD:refs/heads/verify-$name" 2> >(grep -v '^remote:' >&2)
id=""
for _ in $(seq 60); do
	id=$(gh run list -c "$sha" --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
	[[ -n $id ]] && break
	sleep 10
done
[[ -n $id ]] || { echo "no CI run for ${sha:0:7}" >&2; exit 1; }
while [[ $(gh run view "$id" --json status -q .status) != completed ]]; do
	sleep 30
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
