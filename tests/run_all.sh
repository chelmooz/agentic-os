#!/usr/bin/env bash
set -euo pipefail

echo "=== Gate JSON ==="
./tests/run_format_json_gate.sh

echo "=== Gate Verifier ==="
./tests/run_verifier_gate.sh

echo "=== Gate Journal ==="
./tests/run_journal_gate.sh

echo "RELEASE=GREEN"
