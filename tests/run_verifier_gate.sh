#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="tests"
RESULTS_DIR="$TEST_DIR/results/verifier"
REPORT_CSV="$RESULTS_DIR/report.csv"
VERIFIER_MODEL="${VERIFIER_MODEL:-llama3.1:8b}"
PROMPT_FILE="$TEST_DIR/prompts/verifier_validation_command.txt"

mkdir -p "$RESULTS_DIR"
echo "timestamp,test_id,expected_valid,validation_command_valid,status" > "$REPORT_CSV"

echo "GATE_VERIFIER=NOT_IMPLEMENTED"
echo "Voir Blueprint §8.2 pt 2 pour les critères"
exit 1
