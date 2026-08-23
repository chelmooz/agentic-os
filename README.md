# agentic-os
agentic os sur omarchy
# Agentic OS

Orchestrateur local (llama.cpp · Qwen3) pilotant des sub-agents OpenCode sur providers gratuits en rotation.

## Architecture

- **Orchestrateur local** : décompose le besoin global en micro-tâches à scopes disjoints
- **Pool OpenCode** : dispatch round-robin réel sur providers gratuits
- **Verifier isolé** : relecture fichier par fichier, arrêt sur assertion bash vérifiable
- **UI** : Open WebUI (local, 127.0.0.1 uniquement)

## Stack cible

| Couche | Choix |
|--------|-------|
| OS | Omarchy (Arch + Hyprland) |
| Inférence | llama.cpp (CUDA, offload partiel) |
| Modèle | Qwen3-Coder-30B-A3B-Instruct Q4_K_M |
| UI | Open WebUI (Docker) |
| Exécution cloud | OpenCode sur providers gratuits |

## Documentation

Voir [BLUEPRINT.md](./BLUEPRINT.md) pour la spécification complète.

## Installation

Voir [docs/ANNEXE_C_INSTALL.md](./docs/ANNEXE_C_INSTALL.md) (en cours).

## Licence

MIT (à venir)
