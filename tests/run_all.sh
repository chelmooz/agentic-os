#!/usr/bin/env bash
set -euo pipefail

GATES=(
  "Gate JSON:tests/run_format_json_gate.sh"
  "Gate Verifier:tests/run_verifier_gate.sh"
  "Gate Journal:tests/run_journal_gate.sh"
)

failures=()

for entry in "${GATES[@]}"; do
  name="${entry%%:*}"
  script="${entry#*:}"
  echo "=== $name ==="
  if ! bash "$script"; then
    failures+=("FAILED: $name")
    echo "FAILED: $name"
  fi
  echo
done

if [[ ${#failures[@]} -gt 0 ]]; then
  echo "RELEASE=RED"
  printf '%s\n' "${failures[@]}"
  exit 1
fi

echo "RELEASE=GREEN"
