# Prompt D.4 — Catalogue Skills & Édition Config (via chat)

## Objectif
Générer le module de Skills gérable via commandes Slash dans Open WebUI.

## Prompt à coller dans Qwen3-Coder (via Open WebUI)

```text
Implémente un module de "Skills" pour l'OS agentique, gérable directement depuis le chat Open WebUI via des commandes Slash.

Concept :
Un "Skill" est simplement un fichier Markdown (~/.mos/skills/<skill_name>.md) contenant un prompt ou une procédure standardisée.

Fonctionnalités à intégrer dans la Pipeline Open WebUI (Prompt D.2) :
1. Commande /skills list :
   - Scanne le dossier ~/.mos/skills/.
   - Renvoie dans le chat un tableau Markdown avec le nom du skill, sa catégorie, et les agents (rôles) qui l'ont activé dans leur config.

2. Commande /skills activate <name> pour <role> :
   - Modifie le fichier de config du rôle (ou un fichier de mapping JSON local) pour lier le skill au rôle.

3. Commande /skill run <name> :
   - Injecte le contenu du skill directement dans le contexte de la session de chat courante avant de traiter la demande de l'utilisateur.

Pas d'interface graphique de type "Card" ou "Toggle". Le CRUD se fait via le chat ou l'éditeur de texte natif (Neovim/VSCode) sur les fichiers .md.