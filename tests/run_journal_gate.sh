#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TASKS="$PROJECT_ROOT/fixtures/tasks.txt"
JOURNAL="$PROJECT_ROOT/results/journal/journal.jsonl"
RUN_AGENTS="$PROJECT_ROOT/orchestrator/orchestrator.sh"

mkdir -p "$(dirname "$JOURNAL")"
rm -f "$JOURNAL"

# Vérifier que le script cible existe (sera généré via prompt D.1 sur Omarchy)
if [[ ! -x "$RUN_AGENTS" ]]; then
  echo "GATE_JOURNAL=NOT_IMPLEMENTED"
  echo "Missing: $RUN_AGENTS"
  echo "Generate it with prompt D.1 (docs/prompts/D1_orchestrator_bash.md) on Omarchy."
  exit 1
fi

"$RUN_AGENTS" --tasks "$TASKS" --journal "$JOURNAL"

expected_lines=$(wc -l < "$TASKS")
actual_lines=$(wc -l < "$JOURNAL")

if [[ "$actual_lines" -ne "$expected_lines" ]]; then
  echo "GATE_JOURNAL=FAIL"
  echo "expected_lines=$expected_lines actual_lines=$actual_lines"
  exit 1
fi

echo "GATE_JOURNAL=PASS"
