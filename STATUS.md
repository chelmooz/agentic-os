# STATUS — État réel du dépôt

Ce fichier documente l'état actuel du repo pour éviter toute confusion entre spécification (Blueprint) et implémentation réelle. Mis à jour après l'audit du 23/08/2026 (commit cca700f + correctifs 35bd814, 6596ff7).

## Dossiers à contenu réel

| Dossier | Contenu | Statut |
|---------|---------|--------|
| tests/ | 14 fichiers : corpus, prompts, scripts bash (gates de release) | Réel |
| docs/ | CHEATSHEET, ANNEXE_C, prompts D1-D4 | Réel |
| config/ | Templates *.example (aucune clé réelle) | Réel |

## Dossiers stubs (code cible à générer via Annexe D)

| Dossier | Contenu actuel | À générer avec |
|---------|----------------|----------------|
| agents/ | .gitkeep + sous-dossiers dev/, ops/ | Prompt D.4 |
| orchestrator/ | .gitkeep | Prompt D.1 |
| skills/ | .gitkeep | Prompt D.4 |
| state/ | .gitkeep | Prompt D.1 |
| logs/ | .gitkeep | Prompt D.1 |
| lab/ | .gitkeep | — |

## Fichiers à requalifier

| Fichier | Statut réel | Note |
|---------|-------------|------|
| opencode-generator.html | Mockup HTML/CSS statique (v7 perdue, v8 sans JS) | Bandeau MOCKUP présent, radio clé en clair désactivée, commentaire HTML ajouté |
| BLUEPRINT.md Annexe A Table 8 | Verdicts "Conforme" partiellement théoriques | À revalider après implémentation JS du générateur |
| tests/run_journal_gate.sh | Non exécutable | Appelle ./scripts/run_agents.sh qui n'existe pas encore (généré par prompt D.1) |
| tests/run_all.sh | Logique à revoir | Force RELEASE=GREEN même si les sous-scripts échouent |

## Prochaine étape

Implémentation réelle sur machine Omarchy (Xeon E5-2698 v3 / RTX 4000 8 Go) selon INSTALL.md, puis génération du code cible via les prompts de l'Annexe D.

## Historique des commits d'assainissement

| Commit | Action |
|--------|--------|
| 06595e2 | Bandeau MOCKUP initial + README "MIT" |
| dec4e30 | Tentative désactivation clé en clair (non effective) |
| ed8f64a | Ajout STATUS.md (encoding dégradé) |
| cca700f | Re-application bandeau (dupliqué involontairement) |
| 35bd814 | Bandeau unique + clé en clair vraiment désactivée + commentaire JS |
| 6596ff7 | README réécrit en version unique |
