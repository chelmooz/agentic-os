# CHEATSHEET — Antisèche des commandes utiles

## Rendre un script exécutable (sur Omarchy / Linux, PAS sur Windows)
chmod +x orchestrator.sh
# Puis le lancer :
./orchestrator.sh "ma tache globale"

## A retenir
- chmod +x ne se fait qu'UNE fois par script.
- Ca se fait sur la machine qui execute le script (le serveur Omarchy), jamais sur Windows.

## Git (tous les jours)
git status
git add .
git commit -m "message clair"
git push origin main

## Tester le serveur llama.cpp (plus tard, sur Omarchy)
curl -s http://127.0.0.1:8080/v1/models | jq .
