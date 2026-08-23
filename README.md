# Agentic OS

**Orchestrateur local (llama.cpp · Qwen3) pilotant des sub-agents OpenCode sur providers gratuits en rotation.**

Projet personnel de Michel Husson — Marseille.  
Édition consolidée v4 — Août 2026.  
Statut : **pré-déploiement** (spécification aboutie, code cible à générer sur machine Omarchy).

---

## 📘 Documentation

| Fichier | Contenu |
|---|---|
| [`BLUEPRINT.md`](./BLUEPRINT.md) | Spécification complète (v4, 527 lignes) : architecture cible, contrats I/O, 15 modes de défaillance, Annexe D (prompts de génération) |
| [`INSTALL.md`](./INSTALL.md) | Guide d'installation Omarchy / CUDA / llama.cpp / Open WebUI (9 phases) |
| [`STATUS.md`](./STATUS.md) | État réel du dépôt : stubs vs code fonctionnel |
| [`docs/CHEATSHEET.md`](./docs/CHEATSHEET.md) | Antisèche commandes (chmod +x, git, curl) |

## 🧪 Lab (scope courant)

- [`opencode-generator.html`](./opencode-generator.html) — **MOCKUP v8** (HTML/CSS statique, bandeau ⚠ visible, JS reporté volontairement — voir STATUS.md)
- [`config/opencode.json.example`](./config/opencode.json.example) — Template de config (aucune clé réelle)
- [`config/settings.yaml.example`](./config/settings.yaml.example) — Template DeepSeek Harness (assurance inactive, Blueprint §1.3)

## 🎯 Code cible (stubs, à générer via Annexe D sur Omarchy)

| Dossier | Prompt générateur |
|---|---|
| `orchestrator/` | D.1 — Orchestrateur Bash & Event Capture Wrapper |
| `agents/{dev,ops}/` | D.4 — Catalogue Skills |
| `skills/` | D.4 |
| `state/`, `logs/` | D.1 |

Voir [`docs/prompts/`](./docs/prompts/) pour les 4 prompts.

## ✅ Tests — Release Gates (Blueprint §8.2)

| Gate | Fichier | Critère |
|---|---|---|
| JSON | `tests/run_format_json_gate.sh` | 3 prompts (P1/P2/P3) passent pour chaque modèle |
| Verifier | `tests/run_verifier_gate.sh` | 10/10 triviales rejetées, ≥9/10 non triviales acceptées |
| Journal | `tests/run_journal_gate.sh` | Une ligne JSONL valide par tâche |

Exécution : `./tests/run_all.sh`  
Si une seule gate échoue : `RELEASE=RED`, pas de production.

## 📂 Structure
agentic-os/
├── BLUEPRINT.md, INSTALL.md, README.md, STATUS.md, LICENSE
├── opencode-generator.html  (mockup)
├── config/                  (templates)
├── docs/                    (cheatsheet, annexe C, prompts D1-D4)
├── tests/                   (gates, corpus, fixtures, prompts)
├── agents/, orchestrator/, skills/, state/, logs/, lab/  (stubs)
└── .gitignore

## 🔒 Sécurité

- `.gitignore` solide : `.env`, `config/opencode.json`, `config/settings.yaml`, clés, logs, modèles GGUF
- Aucune clé réelle dans le dépôt
- Principe intangible n°4 appliqué : clé en clair désactivée dans l'UI

## 📜 Licence

**MIT** — Copyright 2026 Michel Husson. Voir [`LICENSE`](./LICENSE).
