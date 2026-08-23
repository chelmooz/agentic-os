# Prompt D.1 — Orchestrateur Bash & Event Capture Wrapper

## Objectif
Générer le script orchestrator.sh qui sert de chef d'orchestre local.

## Prompt à coller dans Qwen3-Coder (via Open WebUI)

```text
Implémente un script Bash strict (orchestrator.sh) qui sert de chef d'orchestre local pour un OS agentique.

Contraintes d'architecture :
- Aucun Node.js, aucun SQLite. Uniquement Bash (set -euo pipefail), curl, et jq.
- Le script reçoit un "besoin global" en argument.
- Il appelle l'API llama.cpp locale (http://127.0.0.1:8080/v1/chat/completions) avec response_format: {"type": "json_object"} pour décomposer le besoin en micro-tâches.
- Pour chaque micro-tâche, il dispatch en round-robin réel sur une liste de providers OpenCode (opencode run --model <provider> --format json).

Event capture wrapper (Hook substitut) :
- OpenCode n'a pas de hooks natifs. Le script doit capturer stdout, stderr et le code de retour (exit code) de chaque instance opencode run.
- Il doit formater ces données et faire un append atomique d'une ligne JSON structurée dans journal.jsonl (format §4.1 du Blueprint : timestamp, task_id, provider, status, duration_ms).
- Si une tâche échoue, le script doit gérer la montée en chaîne de repli (fallback_chain) définie dans le JSON de décomposition.

Structure de fichiers attendue :
- ~/.mos/agents/<domaine>/<role>.md (identité et prompts)
- ~/.mos/state/fait.md / loop.md (état partagé)
- ~/.mos/logs/journal.jsonl

Code propre, modulaire, avec des fonctions bash claires pour le health-check (curl baseURL/models) avant le dispatch.
