BLUEPRINT
Orchestrateur local (llama.cpp · Qwen3)
pilotant des sub-agents OpenCode sur providers gratuits en rotation
Michel Husson — Marseille
Édition consolidée v4 — Août 2026
Statut : Architecture cible (le BUT), spécification complète. Scope courant : LAB + stack autonome Omarchy.
 
Table des matières
Table des matières	2
Résumé exécutif	4
1 · Vision, périmètre & statuts	5
1.1 Le LAB (scope courant)	5
1.2 Le BUT	5
1.3 La TRANSITION — close	5
1.4 Principes intangibles	5
2 · Architecture cible	6
2.1 Figure 1 — référence visuelle du BUT	6
2.2 Schéma copiable (secours)	6
2.3 Flux d'exécution	7
2.4 Organisation par domaine, file-system-first	7
2.5 Stack autonome cible	7
Chaînes de repli locales (validées)	8
2.6 Les 6 primitives de l'OS agentique	9
2.7 Cerveau central partagé (File over App)	9
Discipline de recall (skill graph-first-recall)	10
3 · Couche providers (double cible)	11
3.1 Cible A — OpenCode (opencode.json)	11
3.2 Cible B — DeepSeek Harness (settings.yaml) — assurance	11
3.3 Presets, dérive & santé	11
4 · Composants & contrats	12
4.1 Contrats d'interface (I/O)	13
Micro-tâche (sortie de la décomposition)	13
Verdict (sortie du Verifier isolé)	13
Ligne journal.jsonl	13
5 · Robustesse — modes de défaillance & mitigations	15
6 · Commandes de référence	16
Serveur local (orchestrateur + verifier)	16
Décomposition — sortie JSON forcée (API compatible OpenAI)	16
Round-robin réel (décalage d'index par tâche)	16
Event capture wrapper — parsing stdout/stderr + exit code	16
Verifier isolé — lecture fichier par fichier (injection HTTP)	16
Validation modèle (principe §1.4 n°7)	16
Banc de lab (généré par le HTML — préfiguration, pas le but)	16
7 · Pistes de déploiement	17
7.1 Feuille de route en cinq paliers	17
7.2 Bricks transposées du retour d'expérience	17
7.3 Garde-fous de déploiement	18
8 · Pistes de progression & watchlist	19
8.1 Acquis (✅)	19
8.2 À tester (conditions d'entrée en production — protocole)	19
8.2bis Boucle lab → but (fermeture)	19
8.3 Watchlist (hors scope — promotion uniquement sur besoin observé)	19
Annexe A · Constats qualité (audit du générateur HTML)	20
Annexe B · Checklist de release	20
Annexe C · Procédure d'installation (en attente)	21
Annexe D · Prompts de génération du code cible	22
D.1 Prompt 1 — Orchestrateur Bash & Event Capture Wrapper	22
D.2 Prompt 2 — Pipeline Open WebUI « Router & Context »	22
D.3 Prompt 3 — CLI Visualizer & Mission Tracker	23
D.4 Prompt 4 — Catalogue Skills & Édition Config (via chat)	24
D.5 Cohérence avec le Blueprint	24

 
Résumé exécutif
●	Le BUT : un orchestrateur 100 % local (serveur llama.cpp exposant une API compatible OpenAI, modèle primaire Qwen3-Coder-30B-A3B-Instruct Q4_K_M) décompose le besoin global en micro-tâches à scopes de fichiers disjoints, les dispatche en round-robin réel vers des instances OpenCode parallèles sur providers gratuits, fait relire chaque sortie par un Verifier isolé, et n'arrête la boucle que sur assertion bash vérifiable.
●	Infrastructure cible : Omarchy (Arch + Hyprland) sur Xeon E5-2698 v3 / 64 Go ECC / Quadro RTX 4000 8 Go ; llama.cpp compilé CUDA avec offload GPU partiel (hybride CPU+VRAM).
●	Le LAB (scope courant) : générateur HTML local produisant opencode.json / settings.yaml, testant les providers, détectant la dérive — rôle conservé : personne d'autre dans le stack ne gère la couche providers cloud.
●	Transition §1.3 close : OpenCode reste la couche d'exécution ; Hermes Agent / DeepSeek Harness passent en watchlist (assurance), sans plan actif.
●	UI / Mission Control : Open WebUI en local (Docker, 127.0.0.1 uniquement) = dashboard, chat et point d'entrée unique vers l'Orchestrateur. Canaux externes (Discord, Telegram) abandonnés.
●	Couche « OS agentique » : les 6 primitives (Agents, Mémoire, Missions, Orchestration, Hooks, UI) sont toutes couvertes par le stack (§2.6). Nouveau : un cerveau central partagé en .md (§2.7) permet aux agents d'accéder à la même source de vérité sans lock-in.
●	Principes intangibles : aucun modèle figé (chaînes de repli par rôle) ; arrêt vérifiable ; raisonnement local gratuit, exécution cloud au strict nécessaire ; rien ne sort sans action explicite ; file-system-first ; File over App ; arbitrage par llama-bench local, jamais par leaderboard public périmé.
 
1 · Vision, périmètre & statuts
1.1 Le LAB (scope courant)
Générateur HTML 100 % local, aucune télémétrie ; produit opencode.json (Cible A) et settings.yaml (Cible B, assurance) ; enum des 6 rôles figée (Table 1 : raisonner, planifier, coder, review/audit, synthétiser, rapide) ; persistance localStorage clé "ocg7" ; discipline : on n'ajoute que ce qu'une session réelle a prouvé nécessaire.
Table 1 — Enum des 6 rôles (figée par le lab)
Rôle	Regex heuristique
raisonner	r1 | reasoner | thinking | o1 | o3
planifier	70b | 72b | 405b | command-r | 4o | instruct | large
coder	coder | code | codestral
review / audit	70b | 72b | 405b | large
synthétiser	flash | 8b | 9b | mini | small
rapide	flash | 8b | 9b | mini | fast | turbo

1.2 Le BUT
Orchestrateur local llama.cpp (décompose / route / valide / agrège) pilotant des instances OpenCode parallèles sur providers gratuits, arrêt sur assertion bash vérifiable. Référence visuelle : Figure 1 (§2.1) — « Orchestrateur llama.cpp », entrée unique = Open WebUI local.
1.3 La TRANSITION — close
Décision v2/v3/v4 : le stack final (Omarchy + Open WebUI + llama.cpp + script de contrôle) couvre les avantages qui justifiaient Hermes Agent — sub-agents (dispatch round-robin), hooks (Event capture wrapper), cron (Scheduler externe), UI/messaging (Open WebUI), OS agentique (6 primitives, §2.6).
Hermes Agent et DeepSeek Harness restent en watchlist §8.3 à titre d'assurance, sans développement actif. Conséquence conservée : la couche providers reste double cible à coût zéro (le lab ne jette rien). OpenCode demeure indispensable : seule brique d'exécution cloud sur providers gratuits (principe intangible n°3).
1.4 Principes intangibles
●	Aucun modèle figé : chaînes de repli par rôle, sélection à l'exécution selon disponibilité réelle.
●	Arrêt sur assertion bash vérifiable (RED/GREEN), jamais sur jugement qualitatif.
●	Raisonnement de haut niveau local et gratuit ; exécution lourde cloud, strict nécessaire.
●	Rien ne sort sans action explicite — aucune télémétrie ; clés jamais stockées.
●	Aucune modélisation custom quand le file-system suffit (config/identité en .md, jamais en base de données).
●	File over App : le cerveau central (décisions/contexte/contenu) vit dans des fichiers markdown ouverts, les outils sont interchangeables, la data reste (§2.7).
●	L'arbitre d'un modèle est llama-bench local + protocole §8.2, jamais un leaderboard public (l'Open LLM Leaderboard est archivé et périmé).
 
2 · Architecture cible
2.1 Figure 1 — référence visuelle du BUT
 
Figure 1 — Architecture cible intégrée : Orchestrateur llama.cpp, Open WebUI, pool OpenCode, Verifier isolé
Lecture de la figure (code couleur) : bleu = orchestration locale (Orchestrateur llama.cpp, Mission Control, Event capture wrapper) ; rouge = Open WebUI (UI locale, point d'entrée unique) et sortie d'échec ; vert = exécution cloud (providers gratuits) ; gris = pool d'exécution ; jaune = vérification/contrôle ; violet = déclenchement périodique (Scheduler externe) ; flèche pointillée rouge = boucle de correction (montée en chaîne de repli).
Table 2 — Correspondance Figure 1 ↔ composants
Élément de la Figure 1	Composant (§4)	Couleur
Open WebUI (local) — point d'entrée unique vers l'Orchestrateur	Canal remote unique / UI	Rouge
Scheduler externe (systemd timer)	Scheduler externe	Violet
Orchestrateur llama.cpp (local) — décompose / route / valide / agrège (+ Mission Control, + Event capture wrapper)	Orchestrateur ; Script de contrôle ; Model Router	Bleu
opencode run --model … (micro-tâches A/B/C, providers i, i+1, i+2)	Instances OpenCode	Gris/Vert
Verifier isolé (llama.cpp) — relecture -f fichier par fichier	Verifier sub-agent	Jaune
Verdict [OK]/[Échec] ; fait.md / loop.md ; journal.jsonl	État partagé ; journal.jsonl	Vert/Rouge
Retour pointillé = montée en chaîne de repli	Chaînes de repli par rôle (§5)	Rouge pointillé
2.2 Schéma copiable (secours)
[Open WebUI local]      [Scheduler externe]
        \                  /
         v                v
[1. Besoin global] -> [2. Orchestrateur llama.cpp (local)]
      (+ Mission Control, + Event capture wrapper)
         | decompose -> micro-taches (role/task_id/fallback_chain injectes par script)
         v
[3. Pool OpenCode] opencode run --format json (round-robin reel, N providers)
         v
[4. Verifier isole (llama.cpp)] relit -f fichier par fichier + assertion bash
         |  [OK] continuer   [Echec] corriger (montee chaine de repli)
2.3 Flux d'exécution
1.	Besoin global via Open WebUI (local) ou Scheduler externe.
2.	Le script envoie le besoin à l'Orchestrateur (API llama.cpp, sortie JSON forcée).
3.	Décomposition en N micro-tâches scopes disjoints + validation_command.
4.	Health-check curl baseURL/models → AVAILABLE.
5.	Dispatch round-robin réel (start = task_index % n), parallèle si scopes disjoints, --attach sinon.
6.	out_i.json + Event capture wrapper → journal.jsonl + Mission Control.
7.	Verifier isolé relit chaque fichier + pertinence de la validation_command, puis l'exécute.
8.	Verdict : acceptation / correction / agrégation (montée en repli si échec répété).
9.	fait.md / loop.md mis à jour.
10.	Arrêt sur assertion bash vérifiable.
2.4 Organisation par domaine, file-system-first
.agents/<domaine>/<role>.md (identité) + <role>.memory.md (mémoire) + skills en fichiers CRUD ; jamais en base de données.
 
Figure 2 — Organisation par domaine, file-system-first (agents, mémoire, skills)
2.5 Stack autonome cible
Nouveau : le lab se prolonge désormais par une infrastructure d'inférence locale complète, choisie et validée pour tourner sans dépendance cloud pour le raisonnement de haut niveau.
Table 3 — Stack autonome cible
Couche	Composant	Choix	Statut
Matériel	Xeon E5-2698 v3 / 64 Go ECC / Quadro RTX 4000 8 Go	socle physique, ancré ici pour ne pas se perdre si le Résumé est retravaillé	Validé
OS	Omarchy (Arch + Hyprland)	DHH/37signals, rolling release	Validé
Inférence locale	llama.cpp (CUDA, offload partiel)	--n-gpu-layers ~25 à calibrer	Validé
Modèle primaire	Qwen3-Coder-30B-A3B-Instruct Q4_K_M	MoE 3B actifs → rapide sur Xeon	Validé
Dashboard / UI	Open WebUI (Docker, localhost)	Mission Control + chat	Validé
Exécution cloud	OpenCode sur providers gratuits	round-robin réel	Stable
Ordonnancement	systemd timer	Scheduler externe	Intégré
 
Figure 3 — Stack autonome cible, du matériel à l'UI
Chaînes de repli locales (validées)
Complète le principe intangible n°1 (§1.4) : les modèles de repli ne restent pas abstraits, ils sont fixés ici noir sur blanc pour les deux rôles qui tournent en local (Orchestrateur/Verifier et coding local).
Table 3bis — Chaînes de repli locales (llama.cpp)
Rôle local	Chaîne de repli (ordre d'essai)	Statut
Orchestrateur / Verifier	Qwen3-Coder-30B-A3B → Qwen3-32B → Qwen2.5-Coder-32B	Validé
Repli coding local	Qwen2.5-Coder-14B	Validé
Chaque étage n'est tenté qu'en cas d'échec constaté (sortie JSON invalide, timeout, refus) — jamais par anticipation. La montée dans cette chaîne suit le même principe RED/GREEN que la chaîne de repli côté providers cloud (§5, défaillance #1).
2.6 Les 6 primitives de l'OS agentique
Nouveau : ce Blueprint reprend le modèle mental d'un « OS agentique » en six primitives fonctionnelles, chacune couverte par un composant déjà présent dans l'architecture — sans en ajouter un seul de plus.
Table 4 — Les 6 primitives de l'OS agentique
Primitive	Couvert par
AGENTS (identité + prompts)	.agents/<domaine>/<role>.md
MÉMOIRE (fichiers vivants)	<role>.memory.md + fait.md/loop.md
MISSIONS (tâches bornées)	micro-tâches + validation_command
ORCHESTRATION (spawn parallèle)	script de contrôle + dispatch round-robin
HOOKS (capture events)	Event capture wrapper (stdout/stderr/exit code)
UI (mesh + chat + edit)	Open WebUI local
 
Figure 4 — Les 6 primitives de l'OS agentique, mappées sur le stack
2.7 Cerveau central partagé (File over App)
Nouveau : issu des observations terrain sur la mémoire multi-agents. Le principe « File over App » (Stéphane Ango, Obsidian) est appliqué ici : un vault .md centralisé contient décisions/contexte/contenu propriétaire, partagé par tous les agents et outils, sans jamais être locké dans un système spécifique.
 
Figure 5 — Cerveau central partagé : vault .md, index optionnel, sync git, outils interchangeables
Table 4bis — Discipline du cerveau central
Couche	Rôle	Discipline
Vault .md central	Mémoire humaine — décisions, contexte, contenu propriétaire	Fichiers markdown ouverts ; jamais lockés dans un outil
Index/graphe (Graphify optionnel)	Accès rapide sans consommer de tokens	Lecture graphe d'abord (~0 token), frontmatter ensuite, fichier complet seulement si nécessaire
Sync pull/push (git)	Cohérence multi-agents	Pull avant modif, push après — défaillance #7 (concurrence fichiers)
Le cerveau central est distinct des <role>.memory.md (mémoire par rôle). Ces derniers sont la mémoire propre à chaque rôle, le vault est la mémoire partagée de l'OS. La discipline de recall (skill graph-first-recall) est décrite ci-dessous.
Discipline de recall (skill graph-first-recall)
1.	Lire l'index/graphe d'abord (~0 token) pour identifier les nœuds pertinents.
2.	Lire les frontmatter/chemins des fichiers candidats.
3.	Lire le fichier complet seulement si nécessaire.
4.	Économie : ~280-499 tokens/requête vs ~20 000 pour relire 40 fichiers (~70×).
Le graphe (type Graphify, watchlist §8.3) n'entre en scope que si une session réelle mesure un gain concret sur le vault. Avant cela, la discipline s'applique manuellement via l'Orchestrateur.
 
3 · Couche providers (double cible)
 
Figure 6 — Couche providers, double cible A/B (§3)
3.1 Cible A — OpenCode (opencode.json)
Schéma $schema opencode.ai, apiKey en {env:...} / {file:...} — jamais en clair dans Git. Produit par le générateur HTML (lab).
3.2 Cible B — DeepSeek Harness (settings.yaml) — assurance
Schéma llm-pi-ai conforme à la doc officielle, conservée comme assurance : plan de migration inactif (§1.3 close). Produite par le même générateur HTML, prête à prendre le relais sans refonte si jamais nécessaire.
3.3 Presets, dérive & santé
Presets gratuits maintenus dans le HTML (Groq, GitHub Models, HF router, Cerebras, SambaNova, Mistral, NVIDIA…). Dérive traitée en deux temps : détection (drift-check HTML, sujet à CORS → non concluant possible) et confirmation (health-check curl côté script, seul faisant foi avant dispatch).
 
4 · Composants & contrats
Table 5a — Composants d'exécution
Composant	Rôle	Entrées	Sorties	Dépendances	Statut
Générateur HTML (lab)	Produire configs, tester providers, détecter dérive, journaliser	presets, clés (ponctuelles)	opencode.json, settings.yaml, journal tests, état persistant	aucun (100 % local)	Scope courant
Banc de lab (HTML §5)	Préfiguration minimale du but	micro-tâches, providers cochés	run_agents.sh, sorties, synthèse	opencode.json	Scope courant
Serveur llama.cpp	API compatible OpenAI, 127.0.0.1:8080	modèle GGUF, requêtes JSON	réponses JSON forcées	GPU/CPU local (CUDA)	Validé
Script de contrôle	Boucle, dispatch, budget réel, journal	tâche globale, AVAILABLE, journal.jsonl	out_*.json, journal.jsonl, fait.md	health-check, router	Stable
Health-checker	curl baseURL/models avant dispatch	liste providers	liste AVAILABLE	côté serveur (pas CORS)	Conforme
Model Router	Rôle → modèle disponible ; round-robin réel	rôle, AVAILABLE, index tâche	entrée provider/modèle	health-check	Stable
Orchestrateur llama.cpp	Décompose, route, valide ; chaînes de repli ; sortie JSON forcée	tâche globale, fait.md	micro-tâches JSON, verdicts	Serveur llama.cpp	Validé
État partagé (fait/loop)	Source de vérité entre tours	verdicts, assertions	contexte du tour suivant	script	Conforme
journal.jsonl	Usage réel par appel, réimportable HTML	champ usage de opencode run	stats (usage, échecs/provider)	—	Stable
Instances OpenCode	opencode run --format json, scopes disjoints	micro-tâche, provider	out_i.json	config cible A ou B	Stable
Verifier llama.cpp isolé	Relecture critique du code ET de validation_command	out_*.json (contenu injecté HTTP)	acceptation / correction	Serveur llama.cpp	Validé
Export DeepSeek Harness	Cible B — assurance	providers	settings.yaml	schéma vérifié	Assurance
Table 5b — Composants d'organisation & environnement
Composant	Rôle	Entrées	Sorties	Dépendances	Statut
Open WebUI local	Point d'entrée unique (UI + chat) vers l'Orchestrateur — jamais vers les instances dispatchées	message utilisateur local	besoin global (§2.3 étape 1)	Docker, 127.0.0.1	Validé
Mission Control via Open WebUI	Vue agrégée par tâche : provider, coût, durée, statut — extension de journal.jsonl, pas un nouveau stockage	journal.jsonl, verdicts Verifier	vue agrégée / audit post-hoc	journal.jsonl	Validé
Event capture wrapper	Capture stdout/stderr/exit code de chaque opencode run — remplace les hooks natifs absents d'OpenCode	process opencode run	événements structurés → journal.jsonl	Instances OpenCode	Intégré
Scheduler externe	Déclenche les routines périodiques (health-check dérive, purge journal) via systemd timer	systemd timer	invocation du Script de contrôle	OS hôte (Omarchy)	Intégré
Organisation par domaine (FS)	Regroupe micro-tâches et configs d'agents par domaine fonctionnel, en arborescence de fichiers	file_scope de la micro-tâche	chemin de config résolu (.agents/<domaine>/<role>.md)	aucune (file-system)	Intégré
Mémoire par rôle (FS)	Persiste le contexte propre à chaque rôle/agent, distinct de l'identité	verdicts/tours précédents	contexte injecté au prochain appel pour ce rôle	État partagé (fait/loop)	Intégré
Cerveau central (FS)	Vault .md partagé — décisions/contexte/contenu	requêtes agents	nœuds pertinents (discipline §2.7)	git (sync)	Intégré
4.1 Contrats d'interface (I/O)
Formats figés entre composants, inchangés par le passage à llama.cpp — seul le transport change (API HTTP au lieu d'un CLI ollama run).
Micro-tâche (sortie de la décomposition)
●	Champs générés par le modèle : description, file_scope, validation_command.
●	Champs injectés par le script, jamais par le modèle : task_id, role (validé contre l'enum Table 1), fallback_chain (résolue depuis AVAILABLE par le Model Router).
{
  "task_id": "<injecte par le script>",
  "role": "<enum Table 1, valide par le script>",
  "description": "<genere par le modele>",
  "file_scope": ["<genere par le modele, resolu par domaine>"],
  "validation_command": "<genere par le modele>",
  "fallback_chain": ["<resolue par le Model Router depuis AVAILABLE>"]
}
Verdict (sortie du Verifier isolé)
next_action est un enum fermé : retry | escalate | aggregate. Tout texte libre reste confiné à reason.
{
  "task_id": "<reference a la micro-tache>",
  "verdict": "accept | reject | escalate",
  "validation_command_valid": true,
  "reason": "<texte libre, jamais interprete comme une action>",
  "next_action": "retry | escalate | aggregate"
}
Ligne journal.jsonl
{
  "timestamp": "ISO8601",
  "task_id": "string",
  "provider": "string",
  "model": "string",
  "usage": {"prompt_tokens": 0, "completion_tokens": 0},
  "status": "success | failure | retry",
  "duration_ms": 0
}
 
5 · Robustesse — modes de défaillance & mitigations
Table 6 — Défaillances & mitigations
#	Défaillance	Risque	Mitigation	Statut
1	Fences ```json / texte autour	jq casse, set -euo pipefail arrête tout	réponse JSON forcée sur tous les appels API	Résolu
2	Tâches parallèles même 1er prov.	429 cumulés, effet inverse	Round-robin réel : start=(task_index % n)	Résolu
3	Budget forfaitaire (length*2000)	Budget décoratif, non fiable	Lecture du champ usage réel de opencode run	Résolu
4	cat out_*.json en argument shell	ARG_MAX ; blob non JSON	Verifier fichier par fichier (contenu injecté HTTP)	Résolu
5	validation_command triviale	Condition d'arrêt toujours vraie	Verifier relit la pertinence ; test anti-trivial	Résolu + testé
6	Endpoint mort (dérive)	Dispatch vers 404/410	Health-check curl côté script ; drift-check HTML ; Scheduler externe	Conforme
7	Concurrence fichiers	Conflits, locks git	Scopes strictement disjoints, ou --attach ; sync pull/push (git)	Maintenu
8	Sortie JSON non supportée	Chaîne de repli cassée	Tester chaque modèle avec response_format avant prod	À tester
9	Champ penv mort	Dépendance implicite non documentée	Supprimé ou exporté explicitement	Résolu
10	Sur-ingénierie (DAG, sandbox…)	Lab inmaintenable, features non prouvées	Hors scope : watchlist §8.3, entrée sur besoin	Discipline
11	Modèle invente prov/modèle	Dispatch fantôme vers entrée absente	task_id, role, fallback_chain injectés par script	Résolu
12	Amnésie locale (localStorage)	Perte des providers configurés	Export/import opencode.json existant	Résolu
13	Hooks natifs absents (OpenCode)	Événements de tool-call non capturés, Mission Control aveugle	Event capture wrapper : parsing stdout/stderr + exit code	Résolu
14	Arbitrage par leaderboard public périmé	Choix de modèle obsolète	llama-bench local + grille §8.2 (Open LLM Leaderboard archivé)	Résolu
15	Fragmentation mémoire multi-agents	5 outils = 5 mémoires isolées, perte de contexte	Cerveau central partagé §2.7 (File over App)	Résolu
 
6 · Commandes de référence
Serveur local (orchestrateur + verifier)
llama-server -m qwen3-coder-30b-a3b-instruct-q4_k_m.gguf \
  --n-gpu-layers 25 --ctx-size 32768 --threads 16 \
  --host 127.0.0.1 --port 8080
Décomposition — sortie JSON forcée (API compatible OpenAI)
curl -s http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "model": "qwen3-coder-30b-a3b",
  "response_format": {"type":"json_object"},
  "messages":[{"role":"user","content":"Decompose en micro-taches a scope de fichiers
    disjoint (description, file_scope, validation_command). Tache globale : $TASK"}]}' | jq .
Round-robin réel (décalage d'index par tâche)
idx=$(( (i + task_index) % n ))
opencode run --model "$provider" --format json "${TASKS[$i]}" > "out_$i.json" &
wait
Event capture wrapper — parsing stdout/stderr + exit code
opencode run --model "$provider" --format json "$task" \
  > "out_$i.json" 2> "err_$i.log"; ec=$?
jq -n --arg tid "$task_id" --arg prov "$provider" --argjson ec "$ec" \
  '{task_id:$tid, provider:$prov, status:(if $ec==0 then "ok" else "error" end)}' \
  >> journal.jsonl
Verifier isolé — lecture fichier par fichier (injection HTTP)
La lecture -f "$f" devient l'injection du contenu du fichier dans le message HTTP ; même prompt : « Relis ce fichier et la validation_command associée. Rejette si triviale. Réponds au format Verdict. »
Validation modèle (principe §1.4 n°7)
llama-bench -m qwen3-coder-30b-a3b-instruct-q4_k_m.gguf -ngl 25
Banc de lab (généré par le HTML — préfiguration, pas le but)
#!/usr/bin/env bash
# run_agents.sh — genere par le lab, providers coches en rotation
set -euo pipefail
for p in "${CHECKED_PROVIDERS[@]}"; do
  opencode run --model "$p" --format json "$TASK" > "out_${p}.json" 2> "err_${p}.log" &
done
wait
 
7 · Pistes de déploiement
Cette section transpose, au périmètre du Blueprint, un retour d'expérience terrain sur la construction d'un « OS agentique » : mêmes briques fonctionnelles (channels, config, mémoire, orchestration, hooks, cron, dashboard), réappliquées à l'Orchestrateur llama.cpp / pool OpenCode. Principe directeur : ne jamais reconstruire ce que l'existant fait déjà, rester la surcouche la plus fine possible.
7.1 Feuille de route en cinq paliers
 
Figure 7 — Feuille de route de déploiement, du MVP à l'ouverture
●	1. MVP / stack de base : install Omarchy ; compile llama.cpp CUDA ; chargement Qwen3 ; Open WebUI connecté au serveur local ; lab pour la couche providers. Procédure concrète : Annexe C (à recevoir des transcripts / plan de développement).
●	2. CLI : script de contrôle + Orchestrateur llama.cpp autonomes en ligne de commande ; condition d'entrée de toute la suite : pattern décomposition/Verifier validé sur OpenCode.
●	3. Observabilité : Open WebUI = Mission Control (coût, durée, statut via journal.jsonl) ; kanban board reste watchlist.
●	4. Automatisation : Scheduler externe (systemd timer) : health-check dérive, purge journal.jsonl.
●	5. Ouverture : publication MIT après ≥ 1 run multi-provider réel ; conditions bloquantes : clés jamais committées, contrats §4.1 stabilisés, Annexe B passée.
7.2 Bricks transposées du retour d'expérience
Table 7 — Correspondance briques observées ↔ composants du Blueprint
Brique observée	Équivalent Blueprint	Note d'adaptation
Channels / remote control	Open WebUI local (entrée unique)	Canaux externes (Discord, Telegram) abandonnés au profit d'un point d'entrée local unique.
Visualiseur d'agents (mesh live)	Vue Open WebUI (Mission Control)	Un visuel façon mesh graphique reste hors scope tant que non prouvé utile (§8.3).
Édition de config par agent (fichier .md)	Organisation par domaine, file-system-first (§2.4)	Principe directement repris : CRUD sur fichiers, jamais de base de données pour l'identité des agents.
Mémoire par agent	Mémoire par rôle, <role>.memory.md (§2.4)	Repris à l'échelle du rôle plutôt que de l'agent nommé.
Orchestration (spawn de sous-agents)	Orchestrateur llama.cpp + Model Router (§2, §4)	Dispatch round-robin vers le pool OpenCode plutôt que spawn direct de sous-agents.
Hooks natifs (stop, tool-call)	Event capture wrapper (§4, Table 5b)	OpenCode n'expose pas ces hooks ; parsing stdout/stderr/exit code en substitut (défaillance #13).
Routines / cron natif	Scheduler externe, systemd timer (§4)	Ollama/OpenCode n'ont pas de cron natif ; ordonnanceur externe déclenche le script de contrôle.
Kanban board (tâches préparées à l'avance)	Piste de déploiement, palier 3 (§7.1)	Non retenu au scope courant ; entrée conditionnée à un besoin observé, comme le reste de la watchlist (§8.3).
Dashboard de coûts	Mission Control via Open WebUI (§2.5, §4)	Usage/coût déjà exposés par journal.jsonl (§4.1) ; un rendu graphique reste optionnel.
7.3 Garde-fous de déploiement
●	Un seul point d'entrée vers l'Orchestrateur (Open WebUI), jamais vers les instances dispatchées.
●	Rester au plus près du file-system et des mécanismes natifs (sortie JSON forcée, API llama.cpp) — pas de sur-modélisation.
●	Chaque palier de la feuille de route (§7.1) reste candidat watchlist tant qu'une session réelle ne l'a pas réclamé.
●	Nouveau : Open WebUI lié à 127.0.0.1 uniquement — un tunnel Tailscale reste en watchlist, jamais d'exposition sur 0.0.0.0 nu.
●	Nouveau : le cerveau central (§2.7) ne contient que des .md — jamais de base de données vectorielle, jamais de système propriétaire. Les outils qui y accèdent (Open WebUI, Orchestrateur, Hermes futur) sont interchangeables.
 
8 · Pistes de progression & watchlist
8.1 Acquis (✅)
Verifier isolé, journal.jsonl, chaînes de repli, budget réel, round-robin réel, anti-trivialité testée, organisation par domaine, Mission Control / Event capture wrapper / Scheduler externe intégrés, stack cible validé (Omarchy + llama.cpp + Qwen3 + Open WebUI), transition §1.3 close, cerveau central partagé (File over App).
8.2 À tester (conditions d'entrée en production — protocole)
●	Grille sortie JSON forcée : modèle × chaîne de repli × 3 prompts types ; chaque sortie parsée par jq ; verdict binaire pass/fail par cellule ; un seul fail = modèle retiré de la chaîne.
●	Anti-trivialité de validation_command : corpus de 10 commands triviales + 10 non triviales ; le Verifier doit rejeter 10/10 triviales avant d'être promu.
●	Exposition des stats journal.jsonl dans le HTML : condition bloquante = §4.1 implémenté côté banc de lab.
●	Grille llama-bench (n-gpu-layers 20/25/30) → tok/s mesuré avant promotion de tout modèle local.
●	Discipline de recall graph-first : sur un corpus de 20 requêtes, mesurer tokens consommés avec vs sans lecture graphe d'abord ; entrée en watchlist §8.3 si gain non probant.
8.2bis Boucle lab → but (fermeture)
Constat : le banc de lab (run_agents.sh) écrit out_*.json et err_*.log, mais aucun journal.jsonl. Condition d'entrée en scope lab : run_agents.sh écrit une ligne journal.jsonl (format §4.1) à chaque appel, via l'Event capture wrapper. Tant que cette écriture n'existe pas : 8.1 reste un acquis de l'orchestrateur cible, pas du lab.
8.3 Watchlist (hors scope — promotion uniquement sur besoin observé)
1.	Graphe de dépendances entre micro-tâches / verrouillage de fichiers.
2.	Sandboxing des exécutions (Docker éphémère / bwrap) + timeouts — dernier vrai gap du stack.
3.	Retry avec injection du stderr dans le prompt avant montée en chaîne de repli.
4.	Routage par complexité de tâche ; backoff exponentiel sur 429.
5.	Checkpoint / reprise sur crash via journal.jsonl.
6.	Hermes Agent / DeepSeek Harness — assurance uniquement, plan inactif (§1.3 close).
7.	Kanban board de préparation de tâches et dashboard graphique de coûts (§7.1, §7.2).
8.	Tunnel remote (Tailscale) sur besoin observé (§7.3).
9.	Graphify (graphe requêtable) : entrée conditionnée à mesure §8.2 pt 5.
10.	Base de données vectorielle — rejetée tant que le cerveau central .md suffit (principe n°6).
 
Annexe A · Constats qualité (audit du générateur HTML)
Table 8 — Constats qualité
#	Élément	Verdict	Détail
1	Export DeepSeek Harness (settings.yaml)Mockup — à revalider post-JSHTML actuel sans JS fonctionnel (v7 perdue). Verdict théorique, à confirmer après implémentation réelle.
2	Presets (Groq/GitHub/HF/Cohere…)Mockup — à revalider post-JSPresets listés mais aucune validation JS effective dans le HTML actuel.
3	Sortie JSON non forcée	Bug réel	Fences/texte → jq casse, set -e arrête tout.
4	Rotation round-robin annoncée vs impl.	Incohérence	Boucle même ordre à chaque tâche → surcharge 1er provider.
5	tokens_used() — budget	Approx.	length*2000 arbitraire ; usage réel non exploité.
6	Variable penv inutilisée	Code mort	4e champ jamais lu → dépendance implicite.
7	verify() — argument shell concaténé	Fragile	ARG_MAX ; documents concaténés sans enveloppe.
8	Fiabilité de validation_command	Risque	Risque de condition d'arrêt toujours vraie.
9	Health-check côté script (curl)Mockup — à revalider post-JSDesign cohérent mais non implémenté dans le HTML actuel (pas de JS).
Annexe B · Checklist de release
Vérifications à exécuter avant toute publication du document, dans l'ordre :
●	Champs Word : F9 global (ou clic droit → Mettre à jour les champs) sur ToC et légendes — aucun champ affichant "Erreur ! Signet non défini".
●	Numérotation continue : Figures 1-7 et Tables 1-9 (dont 3bis, 4bis) incrémentent sans trou ni doublon.
●	Encodage : UTF-8 vérifié sur les caractères accentués et les puces dans tous les blocs de code et tableaux.
●	Export PDF : texte extractible (pas d'image plein-page), pagination stable, aucune coupure de mot disgracieuse dans les tableaux (§4, §5).
●	Impression : marges et sauts de page vérifiés section par section — chaque § principal démarre en haut de page.
●	Cohérence de fond : les composants d'organisation (Table 5b) restent séparés des composants d'exécution (Table 5a) — statut « Intégré »/« Validé » ≠ « Stable » tant qu'aucun run réel multi-provider ne les a éprouvés en production (§8.3).
●	Cohérence des pistes de déploiement (§7) : chaque palier de la feuille de route reste soumis à la même discipline que la watchlist (§8.3) — aucune promotion sans besoin observé en session réelle.
●	Cohérence du stack (§2.5) : toute modification de couche (OS, moteur d'inférence, modèle, UI) doit être validée par llama-bench avant promotion (principe §1.4 n°7).
●	Cohérence File over App (§2.7) : le cerveau central reste en fichiers markdown ouverts, jamais migré vers une base de données propriétaire ou un système fermé.
 
Annexe C · Procédure d'installation (en attente)
Emplacement réservé. Cette annexe restera vide tant que les transcripts et le plan de développement proposés n'auront pas été fournis — elle ne doit pas être improvisée à partir d'hypothèses non vérifiées sur la machine cible.
Table 9 — Contenu attendu, à loger ici à réception
Bloc	Contenu attendu	Source
Compilation CUDA	Étapes de compilation llama.cpp avec support CUDA sur Omarchy (dépendances, flags de build)	transcripts / plan de dev
Calibrage --n-gpu-layers	Procédure de mesure (llama-bench, §1.4 n°7) pour fixer la valeur réelle sur la RTX 4000 8 Go, au-delà du ~25 indicatif de la Table 3	transcripts / plan de dev
Unit systemd du Scheduler externe	Fichier .timer + .service concret déclenchant le Script de contrôle (health-check dérive, purge journal.jsonl)	transcripts / plan de dev
Config Docker Open WebUI	docker-compose ou commande docker run, binding 127.0.0.1 uniquement (§7.3), connexion au serveur llama.cpp local	transcripts / plan de dev
Condition de clôture de cette annexe : chaque bloc validé sur la machine réelle (pas seulement documenté) avant d'être marqué « Validé » dans la Table 3 (§2.5) — même discipline que le reste du Blueprint (§1.1, §7.3).
 
Annexe D · Prompts de génération du code cible
Note liminaire : les concepts originaux (Next.js, Telegram, Tailscale, SQLite, UI custom) ont été élagués pour respecter les principes du Blueprint v4. L'UI custom est abandonnée au profit d'Open WebUI (via ses Pipelines Python) et de scripts CLI (Bash/Python). Cette annexe sert de « pont » entre l'architecture (v4) et l'implémentation sur Omarchy. Ces prompts peuvent être collés directement dans le LLM de code (Qwen3-Coder via Open WebUI) pour générer les scripts exacts du stack.
D.1 Prompt 1 — Orchestrateur Bash & Event Capture Wrapper
(Remplace le « Système de spawn Node.js/PTY » — trop lourd pour notre scope)
Implemente un script Bash strict (orchestrator.sh) qui sert de chef
d'orchestre local pour un OS agentique.

Contraintes d'architecture :
- Aucun Node.js, aucun SQLite. Uniquement Bash (set -euo pipefail),
  curl, et jq.
- Le script recoit un "besoin global" en argument.
- Il appelle l'API llama.cpp locale
  (http://127.0.0.1:8080/v1/chat/completions) avec
  response_format: {"type": "json_object"} pour decomposer le
  besoin en micro-taches.
- Pour chaque micro-tache, il dispatch en round-robin reel sur une
  liste de providers OpenCode (opencode run --model <provider>
  --format json).

Event capture wrapper (Hook substitut) :
- OpenCode n'a pas de hooks natifs. Le script doit capturer stdout,
  stderr et le code de retour (exit code) de chaque instance
  opencode run.
- Il doit formater ces donnees et faire un append atomique d'une
  ligne JSON structuree dans journal.jsonl (format §4.1 du
  Blueprint : timestamp, task_id, provider, status, duration_ms).
- Si une tache echoue, le script doit gerer la montee en chaine de
  repli (fallback_chain) definie dans le JSON de decomposition.

Structure de fichiers attendue :
- ~/.mos/agents/<domaine>/<role>.md (identite et prompts)
- ~/.mos/state/fait.md / loop.md (etat partage)
- ~/.mos/logs/journal.jsonl

Code propre, modulaire, avec des fonctions bash claires pour le
health-check (curl baseURL/models) avant le dispatch.
D.2 Prompt 2 — Pipeline Open WebUI « Router & Context »
(Remplace les « Channels Telegram/Discord » et le « Remote Control » — abandonnés au profit d'une entrée unique locale)
Implemente une "Pipeline" (Function) pour Open WebUI en Python.
Role : Agir comme le point d'entree unique et le routeur de
contexte de l'OS agentique local.

Architecture :
1. Injection de contexte (File over App) :
   - Avant d'envoyer le message utilisateur a llama.cpp, la
     Pipeline doit lire les fichiers .md pertinents (ex: fait.md,
     <role>.memory.md) et les injecter dynamiquement dans le
     System Prompt.
   - Si le vault central (§2.7) est configure, interroger l'index
     local pour n'injecter que les noeuds pertinents (discipline
     graph-first-recall — economie de tokens).

2. Detection de Mission (Routing) :
   - Si le message utilisateur commence par /mission ou si
     l'intention detectee est une tache complexe, la Pipeline ne
     repond pas directement.
   - Elle declenche le script orchestrator.sh en arriere-plan (via
     subprocess.Popen).
   - Elle renvoie immediatement a l'utilisateur un message de
     confirmation avec le task_id et un lien vers le log.

3. Securite & Scope :
   - Aucune authentification JWT, aucun tunnel Tailscale. La
     Pipeline tourne en local (Docker Open WebUI sur 127.0.0.1).
   - Pas de Telegram, pas de Discord. Le chat Open WebUI EST le
     channel unique.

Stack : Python 3.11, API Open WebUI Pipelines, subprocess, json.
D.3 Prompt 3 — CLI Visualizer & Mission Tracker
(Remplace le « Visualizer Mesh D3 » et le « Kanban Next.js » — remplacés par une interface Terminal riche)
Implemente un script Python (mos-cli) utilisant la librairie rich
pour le terminal (Omarchy/Hyprland).
Objectif : Remplacer le dashboard web graphique par une interface
CLI sobre, rapide et lisible.

Commandes a implementer :
1. mos status :
   - Parse journal.jsonl.
   - Affiche un arbre ASCII des missions en cours, avec le statut,
     le provider utilise, et les tokens consommes.
   - Affiche une barre de progression du budget quotidien.

2. mos radar :
   - Agrege les couts/tokens de journal.jsonl par domaine (Dev,
     Content, Ops, etc.).
   - Genere un Radar Chart en ASCII directement dans le terminal
     (ou exporte un SVG local simple viewable dans le navigateur).

3. mos memory compact <role> :
   - Lit le fichier ~/.mos/agents/<domaine>/<role>.memory.md.
   - L'envoie a llama.cpp avec un prompt de
     "consolidation/resume" pour reduire la taille (et donc les
     tokens futurs).
   - Reecrit le fichier avec l'historique compacte.

Style : Dark mode terminal, sobre, technique. Pas de
sur-ingenierie, lecture directe des fichiers JSON/MD.
D.4 Prompt 4 — Catalogue Skills & Édition Config (via chat)
(Remplace l'UI « Edit Config + Skills Catalog » — remplacé par des commandes Slash dans le chat)
Implemente un module de "Skills" pour l'OS agentique, gerable
directement depuis le chat Open WebUI via des commandes Slash.

Concept :
Un "Skill" est simplement un fichier Markdown
(~/.mos/skills/<skill_name>.md) contenant un prompt ou une
procedure standardisee.

Fonctionnalites a integrer dans la Pipeline Open WebUI (Prompt
D.2) :
1. Commande /skills list :
   - Scanne le dossier ~/.mos/skills/.
   - Renvoie dans le chat un tableau Markdown avec le nom du
     skill, sa categorie, et les agents (roles) qui l'ont active
     dans leur config.

2. Commande /skills activate <name> pour <role> :
   - Modifie le fichier de config du role (ou un fichier de
     mapping JSON local) pour lier le skill au role.

3. Commande /skill run <name> :
   - Injecte le contenu du skill directement dans le contexte de
     la session de chat courante avant de traiter la demande de
     l'utilisateur.

Pas d'interface graphique de type "Card" ou "Toggle". Le CRUD se
fait via le chat ou l'editeur de texte natif (Neovim/VSCode) sur
les fichiers .md.
D.5 Cohérence avec le Blueprint
Ces quatre prompts forment un ensemble cohérent et respectent intégralement les principes de la v4 :
●	Zéro sur-ingénierie (défaillance #10) : aucun frontend React/Next.js maintenu, Open WebUI fournit déjà l'interface.
●	File over App (principe n°6) : skills, mémoire et configs restent des .md ou .json manipulables par bash/python/jq. Aucun lock-in.
●	Adhésion à Omarchy : rich pour le terminal s'intègre dans un workflow tiling (Hyprland).
●	Surface d'attaque nulle : suppression des endpoints REST publics, webhooks Telegram et tokens JWT. Sécurité par isolation réseau (Docker sur 127.0.0.1).



