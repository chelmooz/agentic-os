#!/usr/bin/env bash
set -euo pipefail

TASKS="tests/fixtures/tasks.txt"
JOURNAL="tests/results/journal/journal.jsonl"

mkdir -p "$(dirname "$JOURNAL")"
rm -f "$JOURNAL"

./scripts/run_agents.sh --tasks "$TASKS" --journal "$JOURNAL"

expected_lines=$(wc -l < "$TASKS")
actual_lines=$(wc -l < "$JOURNAL")

if [[ "$actual_lines" -ne "$expected_lines" ]]; then
  echo "GATE_JOURNAL=FAIL"
  echo "expected_lines=$expected_lines"
  echo "actual_lines=$actual_lines"
  exit 1
fi

if ! jq -s '
  all(.[];
    has("timestamp")
    and has("task_id")
    and has("provider")
    and has("model")
    and has("usage")
    and has("status")
    and has("duration_ms")
  )
' "$JOURNAL"; then
  echo "GATE_JOURNAL=FAIL"
  exit 1
fi

echo "GATE_JOURNAL=PASS"
