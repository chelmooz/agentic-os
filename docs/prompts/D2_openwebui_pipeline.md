# Prompt D.2 — Pipeline Open WebUI "Router & Context"

## Objectif
Générer la Pipeline Python pour Open WebUI qui agit comme point d'entrée unique.

## Prompt à coller dans Qwen3-Coder (via Open WebUI)

```text
Implémente une "Pipeline" (Function) pour Open WebUI en Python.
Rôle : Agir comme le point d'entrée unique et le routeur de contexte de l'OS agentique local.

Architecture :
1. Injection de contexte (File over App) :
   - Avant d'envoyer le message utilisateur à llama.cpp, la Pipeline doit lire les fichiers .md pertinents (ex: fait.md, <role>.memory.md) et les injecter dynamiquement dans le System Prompt.
   - Si le vault central (§2.7 du Blueprint) est configuré, interroger l'index local pour n'injecter que les nœuds pertinents (discipline graph-first-recall — économie de tokens).

2. Détection de Mission (Routing) :
   - Si le message utilisateur commence par /mission ou si l'intention détectée est une tâche complexe, la Pipeline ne répond pas directement.
   - Elle déclenche le script orchestrator.sh en arrière-plan (via subprocess.Popen).
   - Elle renvoie immédiatement à l'utilisateur un message de confirmation avec le task_id et un lien vers le log.

3. Sécurité & Scope :
   - Aucune authentification JWT, aucun tunnel Tailscale. La Pipeline tourne en local (Docker Open WebUI sur 127.0.0.1).
   - Pas de Telegram, pas de Discord. Le chat Open WebUI EST le channel unique.

Stack : Python 3.11, API Open WebUI Pipelines, subprocess, json.