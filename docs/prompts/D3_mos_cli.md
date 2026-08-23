# Prompt D.3 — CLI Visualizer & Mission Tracker

## Objectif
Générer le script mos-cli avec interface terminal riche (librairie rich).

## Prompt à coller dans Qwen3-Coder (via Open WebUI)

```text
Implémente un script Python (mos-cli) utilisant la librairie rich pour le terminal (Omarchy/Hyprland).
Objectif : Remplacer le dashboard web graphique par une interface CLI sobre, rapide et lisible.

Commandes à implémenter :
1. mos status :
   - Parse journal.jsonl.
   - Affiche un arbre ASCII des missions en cours, avec le statut, le provider utilisé, et les tokens consommés.
   - Affiche une barre de progression du budget quotidien.

2. mos radar :
   - Agrège les coûts/tokens de journal.jsonl par domaine (Dev, Content, Ops, etc.).
   - Génère un Radar Chart en ASCII directement dans le terminal (ou exporte un SVG local simple viewable dans le navigateur).

3. mos memory compact <role> :
   - Lit le fichier ~/.mos/agents/<domaine>/<role>.memory.md.
   - L'envoie à llama.cpp avec un prompt de "consolidation/résumé" pour réduire la taille (et donc les tokens futurs).
   - Réécrit le fichier avec l'historique compacté.

Style : Dark mode terminal, sobre, technique. Pas de sur-ingénierie, lecture directe des fichiers JSON/MD.