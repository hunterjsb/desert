#!/usr/bin/env bash
# Deterministic scheduling checks; no engine or world generation needed.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .probe_tmp
scratch=$(mktemp -d .probe_tmp/runner.XXXXXX)
trap 'rm -rf -- "${scratch:?}"' EXIT
export RUNNER_TEST_DIR="$PWD/$scratch"
cat >"$scratch/godot" <<'FAKE'
#!/usr/bin/env bash
set -eu
for arg do
  case $arg in
    --version) echo "$(cat .godot-version).test"; exit ;;
    --import) exit ;;
  esac
  probe=$arg
done
name=${probe##*/}
active="$RUNNER_TEST_DIR/active-$name-$$"
touch "$active"
trap 'rm -f "$active"' EXIT
sleep 0.2
for peer in "$RUNNER_TEST_DIR"/active-exclusive.gd-* "$RUNNER_TEST_DIR"/active-broken.gd-*; do
  [[ ! -e $peer || $peer == "$active" ]] || { echo "SCRIPT ERROR: overlapped exclusive probe"; exit 1; }
done
if [[ $name == exclusive.gd || $name == broken.gd ]]; then
  for peer in "$RUNNER_TEST_DIR"/active-*; do
    [[ $peer == "$active" ]] || { echo 'SCRIPT ERROR: exclusive probe overlapped'; exit 1; }
  done
fi
echo "$name" >>"$RUNNER_TEST_DIR/ran"
sleep 1
[[ $name != broken.gd ]] || exit 1
echo 'PROBE PASS'
FAKE
chmod +x "$scratch/godot"
export PROBE_TIMES="$RUNNER_TEST_DIR/times"
export GODOT="$PWD/$scratch/godot" PROBE_JOBS=2
printf '## Exclusive on noisy runners\n' >"$scratch/exclusive.gd"
printf '## Runs alone\n' >"$scratch/realtime.gd"
printf '\n' >"$scratch/ordinary.gd"
PROBE_NOISY=1 scripts/probe.sh "$scratch/ordinary.gd" "$scratch/exclusive.gd" "$scratch/realtime.gd" >"$scratch/out"
grep -q '^2 probes, 0 not passing$' "$scratch/out"
grep -q '^exclusive.gd$' "$scratch/ran"
if grep -q '^realtime.gd$' "$scratch/ran"; then
  echo 'real-frame probe ran on a noisy runner' >&2; exit 1
fi
# Ordinary runners still execute real-frame probes.
PROBE_NOISY='' scripts/probe.sh "$scratch/realtime.gd" >"$scratch/out"
grep -q '^realtime.gd$' "$scratch/ran"
# An exclusive failure must fail the run, even after its permitted retry.
printf '## Exclusive on noisy runners\n' >"$scratch/broken.gd"
if PROBE_NOISY=1 scripts/probe.sh "$scratch/ordinary.gd" "$scratch/broken.gd" >"$scratch/out"; then
  echo 'exclusive failure was lost' >&2; exit 1
fi
grep -q '^2 probes, 1 not passing$' "$scratch/out"
[[ $(grep -c '^broken.gd$' "$scratch/ran") == 2 ]]
echo 'probe scheduling checks passed'
