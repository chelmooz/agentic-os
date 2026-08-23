# Agentic OS

**Orchestrateur local (llama.cpp · Qwen3) pilotant des sub-agents OpenCode sur providers gratuits en rotation.**



## 🎯 Vision

Un orchestrateur 100 % local (serveur llama.cpp exposant une API compatible OpenAI, modèle primaire **Qwen3-Coder-30B-A3B-Instruct Q4_K_M**) :
1. Décompose le besoin global en micro-tâches à scopes de fichiers disjoints
2. Les dispatche en **round-robin réel** vers des instances OpenCode parallèles sur providers gratuits
3. Fait relire chaque sortie par un **Verifier isolé**
4. N'arrête la boucle que sur **assertion bash vérifiable** (RED/GREEN)

## 🖥️ Stack cible

| Couche | Choix | Statut |
|--------|-------|--------|
| Matériel | Xeon E5-2698 v3 / 64 Go ECC / Quadro RTX 4000 8 Go | Validé |
| OS | Omarchy (Arch + Hyprland) | Validé |
| Inférence locale | llama.cpp (CUDA, offload partiel) | Validé |
| Modèle primaire | Qwen3-Coder-30B-A3B-Instruct Q4_K_M | Validé |
| Dashboard / UI | Open WebUI (Docker, localhost) | Validé |
| Exécution cloud | OpenCode sur providers gratuits | Stable |
| Ordonnancement | systemd timer | Intégré |

## 📚 Documentation

- **[BLUEPRINT.md](./BLUEPRINT.md)** — Spécification complète de l'architecture cible
- **[docs/ANNEXE_C_INSTALL.md](./docs/ANNEXE_C_INSTALL.md)** — Procédure d'installation (en cours)
- **[docs/prompts/](./docs/prompts/)** — Prompts pour génération du code cible (Annexe D)

## 🏗️ Structure du repo
agentic-os/
├── BLUEPRINT.md              # Spécification architecturale (source de vérité)
├── README.md                 # Présentation du projet
├── .gitignore                # Protection des secrets et artefacts
├── lab/                      # Scope courant (générateur HTML)
├── orchestrator/             # Le BUT (scripts de contrôle)
├── agents/                   # Organisation par domaine (file-system-first)
├── state/                    # État partagé (fait.md, loop.md)
├── skills/                   # Fichiers CRUD réutilisables
├── logs/                     # Journal (ignoré par git)
├── docs/                     # Documentation annexe
└── config/                   # Configs générées (templates)
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
