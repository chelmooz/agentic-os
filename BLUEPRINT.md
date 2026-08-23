# BLUEPRINT v4
## Orchestrateur local (llama.cpp · Qwen3)
### pilotant des sub-agents OpenCode sur providers gratuits en rotation

**Édition consolidée v4 — Août 2026**

---

## Table des matières

- [Résumé exécutif](#résumé-exécutif)
- [1 · Vision, périmètre & statuts](#1--vision-périmètre--statuts)
- [2 · Architecture cible](#2--architecture-cible)
- [3 · Couche providers (double cible)](#3--couche-providers-double-cible)
- [4 · Composants & contrats](#4--composants--contrats)
- [5 · Robustesse — modes de défaillance & mitigations](#5--robustesse--modes-de-défaillance--mitigations)
- [6 · Commandes de référence](#6--commandes-de-référence)
- [7 · Pistes de déploiement](#7--pistes-de-déploiement)
- [8 · Pistes de progression & watchlist](#8--pistes-de-progression--watchlist)
- [Annexe A · Constats qualité](#annexe-a--constats-qualité-audit-du-générateur-html)
- [Annexe B · Checklist de release](#annexe-b--checklist-de-release)
- [Annexe C · Procédure d'installation (en attente)](#annexe-c--procédure-dinstallation-en-attente)
- [Annexe D · Prompts de génération du code cible](#annexe-d--prompts-de-génération-du-code-cible)

---

## Résumé exécutif

1. **Le BUT** : un orchestrateur 100 % local (serveur llama.cpp exposant une API compatible OpenAI, modèle primaire **Qwen3-Coder-30B-A3B-Instruct Q4_K_M**) décompose le besoin global en micro-tâches à scopes de fichiers disjoints, les dispatche en round-robin réel vers des instances OpenCode parallèles sur providers gratuits, fait relire chaque sortie par un Verifier isolé, et n'arrête la boucle que sur assertion bash vérifiable.
2. **Infrastructure cible** : Omarchy (Arch + Hyprland) sur Xeon E5-2698 v3 / 64 Go ECC / Quadro RTX 4000 8 Go ; llama.cpp compilé CUDA avec offload GPU partiel (hybride CPU+VRAM).
3. **Le LAB (scope courant)** : générateur HTML local produisant `opencode.json` / `settings.yaml`, testant les providers, détectant la dérive — rôle conservé : personne d'autre dans le stack ne gère la couche providers cloud.
4. **Transition §1.3 close** : OpenCode reste la couche d'exécution ; Hermes Agent / DeepSeek Harness passent en watchlist (assurance), sans plan actif.
5. **UI / Mission Control** : Open WebUI en local (Docker, 127.0.0.1 uniquement) = dashboard, chat et point d'entrée unique vers l'Orchestrateur. Canaux externes (Discord, Telegram) abandonnés.
6. **Couche « OS agentique »** : les 6 primitives (Agents, Mémoire, Missions, Orchestration, Hooks, UI) sont toutes couvertes par le stack (§2.6). Nouveau : un cerveau central partagé en `.md` (§2.7) permet aux agents d'accéder à la même source de vérité sans lock-in.
7. **Principes intangibles** : aucun modèle figé (chaînes de repli par rôle) ; arrêt vérifiable ; raisonnement local gratuit, exécution cloud au strict nécessaire ; rien ne sort sans action explicite ; file-system-first ; File over App ; arbitrage par llama-bench local, jamais par leaderboard public périmé.

---

## 1 · Vision, périmètre & statuts

### 1.1 Le LAB (scope courant)

Générateur HTML 100 % local, aucune télémétrie ; produit `opencode.json` (Cible A) et `settings.yaml` (Cible B, assurance) ; enum des 6 rôles figée (Table 1 : raisonner, planifier, coder, review/audit, synthétiser, rapide) ; persistance localStorage clé `"ocg7"` ; discipline : on n'ajoute que ce qu'une session réelle a prouvé nécessaire.

**Table 1 — Enum des 6 rôles (figée par le lab)**

| Rôle | Regex heuristique |
| :--- | :--- |
| raisonner | r1 \| reasoner \| thinking \| o1 \| o3 |
| planifier | 70b \| 72b \| 405b \| command-r \| 4o \| instruct \| large |
| coder | coder \| code \| codestral |
| review / audit | 70b \| 72b \| 405b \| large |
| synthétiser | flash \| 8b \| 9b \| mini \| small |
| rapide | flash \| 8b \| 9b \| mini \| fast \| turbo |

### 1.2 Le BUT

Orchestrateur local llama.cpp (décompose / route / valide / agrège) pilotant des instances OpenCode parallèles sur providers gratuits, arrêt sur assertion bash vérifiable. Référence visuelle : Figure 1 (§2.1) — « Orchestrateur llama.cpp », entrée unique = Open WebUI local.

### 1.3 La TRANSITION — close

Décision v2/v3/v4 : le stack final (Omarchy + Open WebUI + llama.cpp + script de contrôle) couvre les avantages qui justifiaient Hermes Agent — sub-agents (dispatch round-robin), hooks (Event capture wrapper), cron (Scheduler externe), UI/messaging (Open WebUI), OS agentique (6 primitives, §2.6).

Hermes Agent et DeepSeek Harness restent en watchlist §8.3 à titre d'assurance, sans développement actif. Conséquence conservée : la couche providers reste double cible à coût zéro (le lab ne jette rien). **OpenCode demeure indispensable** : seule brique d'exécution cloud sur providers gratuits (principe intangible n°3).

### 1.4 Principes intangibles

1. **Aucun modèle figé** : chaînes de repli par rôle, sélection à l'exécution selon disponibilité réelle.
2. **Arrêt sur assertion bash vérifiable (RED/GREEN)**, jamais sur jugement qualitatif.
3. **Raisonnement de haut niveau local et gratuit** ; exécution lourde cloud, strict nécessaire.
4. **Rien ne sort sans action explicite** — aucune télémétrie ; clés jamais stockées.
5. **Aucune modélisation custom** quand le file-system suffit (config/identité en `.md`, jamais en base de données).
6. **File over App** : le cerveau central (décisions/contexte/contenu) vit dans des fichiers markdown ouverts, les outils sont interchangeables, la data reste.
7. **L'arbitre d'un modèle est llama-bench local + protocole §8.2**, jamais un leaderboard public (l'Open LLM Leaderboard est archivé et périmé).

---

## 2 · Architecture cible

### 2.1 Figure 1 — référence visuelle du BUT

*Figure 1 — Architecture cible intégrée : Orchestrateur llama.cpp, Open WebUI, pool OpenCode, Verifier isolé*

**Lecture de la figure (code couleur)** : bleu = orchestration locale (Orchestrateur llama.cpp, Mission Control, Event capture wrapper) ; rouge = Open WebUI (UI locale, point d'entrée unique) et sortie d'échec ; vert = exécution cloud (providers gratuits) ; gris = pool d'exécution ; jaune = vérification/contrôle ; violet = déclenchement périodique (Scheduler externe) ; flèche pointillée rouge = boucle de correction (montée en chaîne de repli).

**Table 2 — Correspondance Figure 1 ↔ composants**

| Élément de la Figure 1 | Composant (§4) | Couleur |
| :--- | :--- | :--- |
| Open WebUI (local) — point d'entrée unique vers l'Orchestrateur | Canal remote unique / UI | Rouge |
| Scheduler externe (systemd timer) | Scheduler externe | Violet |
| Orchestrateur llama.cpp (local) — décompose / route / valide / agrège (+ Mission Control, + Event capture wrapper) | Orchestrateur ; Script de contrôle ; Model Router | Bleu |
| `opencode run --model …` (micro-tâches A/B/C, providers i, i+1, i+2) | Instances OpenCode | Gris/Vert |
| Verifier isolé (llama.cpp) — relecture `-f` fichier par fichier | Verifier sub-agent | Jaune |
| Verdict [OK]/[Échec] ; fait.md / loop.md ; journal.jsonl | État partagé ; journal.jsonl | Vert/Rouge |
| Retour pointillé = montée en chaîne de repli | Chaînes de repli par rôle (§5) | Rouge pointillé |

### 2.2 Schéma copiable (secours)
