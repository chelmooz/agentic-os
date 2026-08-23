# STATUS — État réel du dépôt

Ce fichier documente l'état actuel du repo pour éviter toute confusion entre spécification (Blueprint) et implémentation réelle.

## Dossiers à contenu réel

| Dossier | Contenu | Statut |
|---|---|---|
| 	ests/ | 14 fichiers : corpus, prompts, scripts bash (gates de release) | ✅ Réel |
| docs/ | CHEATSHEET, ANNEXE_C, prompts D1-D4 | ✅ Réel |
| config/ | Templates *.example (pas de clés réelles) | ✅ Réel |

## Dossiers stubs (code cible à générer via Annexe D)

| Dossier | Contenu actuel | À générer avec |
|---|---|---|
| gents/ | .gitkeep + sous-dossiers dev/, ops/ | Prompt D.4 |
| orchestrator/ | .gitkeep | Prompt D.1 |
| skills/ | .gitkeep | Prompt D.4 |
| state/ | .gitkeep | Prompt D.1 |
| logs/ | .gitkeep | Prompt D.1 |
| lab/ | .gitkeep | — |

## Fichiers à requalifier

| Fichier | Statut réel | Note |
|---|---|---|
| opencode-generator.html | Mockup HTML/CSS statique (v7 renommée v8) | Aucun JavaScript câblé — audit Claude 23/08/2026 |
| BLUEPRINT.md Annexe A Table 8 | Verdicts "Conforme" partiellement théoriques | À revalider après implémentation JS du générateur |

## Prochaine étape

Implémentation réelle sur machine Omarchy (Xeon E5-2698 v3 / RTX 4000 8 Go) selon INSTALL.md, puis génération du code cible via les prompts de l'Annexe D.
