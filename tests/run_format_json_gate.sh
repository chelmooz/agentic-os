#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="tests"
PROMPTS_DIR="$TEST_DIR/prompts"
RESULTS_DIR="$TEST_DIR/results/format-json"

mkdir -p "$RESULTS_DIR"

echo "GATE_JSON=NOT_IMPLEMENTED"
echo "Voir Blueprint §8.2 pt 1 pour les critères"
echo "Matrix : modèle × chaîne de repli × 3 prompts (P1/P2/P3)"
exit 1
