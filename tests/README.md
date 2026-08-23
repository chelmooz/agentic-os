# Protocoles de test — Release Gate

Ce dossier contient les 3 gates de validation pour l'entrée en production, conformément au Blueprint v4 §8.2.

## Les 3 gates

### 1. Gate JSON — robustesse de --format json
Valide que chaque modèle produit du JSON exploitable sur 3 prompts types (P1 nominal, P2 ambigu, P3 edge).
Script : run_format_json_gate.sh
Critère : tous les prompts doivent passer pour chaque modèle sélectionné.

### 2. Gate Verifier — anti-trivialité de validation_command
Valide que le Verifier rejette 10/10 commandes triviales et accepte au moins 9/10 non triviales.
Script : run_verifier_gate.sh
Critère : trivial_reject = 10/10 obligatoire, nontrivial_accept >= 9/10 recommandé.

### 3. Gate Journal — fermeture LAB → BUT
Valide que le banc de lab écrit une ligne journal.jsonl par appel, schéma conforme au §4.1.
Script : run_journal_gate.sh
Critère : une ligne JSONL valide par tâche du fixture.

## Exécution

Lancer les 3 gates : ./tests/run_all.sh

## Décision de release

GATE_JSON=PASS
GATE_VERIFIER_TRIVIAL=PASS
GATE_VERIFIER_NONTRIVIAL=PASS
GATE_JOURNAL=PASS

Si une seule gate échoue : RELEASE=RED, pas de production.

## Références

- Blueprint v4 §8.2 : Conditions d'entrée en production
- Blueprint v4 §4.1 : Contrats d'interface (I/O)
- Blueprint v4 §1.4 n°2 : Arrêt sur assertion bash vérifiable
