# Guide d'installation — Agentic OS

**Machine cible** : Xeon E5-2698 v3 / 64 Go ECC / Quadro RTX 4000 8 Go / Omarchy (Arch + Hyprland)
**Vérifié contre** : `chelmooz/agentic-os` @ tag `v0.1.0-predeploy`

Ce guide décrit l'installation complète du stack Blueprint, en 8 phases (0 à 7), chacune avec un **critère de succès mesurable** et une procédure de rollback. Si tu es débutant : ne saute pas les commandes de vérification, elles existent pour te dire clairement si l'étape a marché ou non avant de passer à la suivante.

---

## 📊 Résumé exécutif

| Phase | Durée estimée | Critère de succès | Rollback |
|-------|--------------|-------------------|----------|
| 0. Préparation Windows | 30 min | Clé USB bootable + repo complet | N/A |
| 1. Installation système | 2-3 h | `nvidia-smi` + `llama-server` répondent | Réinstaller Omarchy |
| 2. Calibration & validation | 1 h | `llama-bench` tok/s mesuré + JSON strict | N/A |
| 3. Permissions & sécurité | 15 min | Tous scripts exécutables + `~/.mos` en 700 | `git checkout` |
| 4. Configuration OpenCode | 30 min | `opencode.json` valide + providers testés | Supprimer config |
| 5. Génération code cible | 1-2 h | D1-D4 générés + commités | `git reset --hard` |
| 6. Tests E2E | 1 h | `RELEASE=GREEN` sur 3 gates | Voir §Dépannage |
| 7. Automatisation & monitoring | 30 min | systemd actif + logs rotatifs | `systemctl disable` |

**Temps total estimé** : 6-9 h (première installation)

### Table des matières

0. [Préparation Windows](#phase-0--préparation-windows-pré-déploiement)
1. [Installation système (Omarchy)](#phase-1--installation-système-omarchy)
2. [Calibration & validation](#phase-2--calibration--validation)
3. [Permissions & sécurité](#phase-3--permissions--sécurité)
4. [Configuration OpenCode](#phase-4--configuration-opencode)
5. [Génération du code cible (D1-D4)](#phase-5--génération-du-code-cible-d1-d4)
6. [Tests E2E (Release Gates)](#phase-6--tests-e2e-release-gates)
7. [Automatisation & monitoring](#phase-7--automatisation--monitoring)

---

## Phase 0 — Préparation Windows (pré-déploiement)

- [ ] **Sauvegarde des clés API** dans un gestionnaire de mots de passe (KeePass, Bitwarden, 1Password)
  - [ ] `GROQ_API_KEY`
  - [ ] `GITHUB_TOKEN`
  - [ ] Autres providers selon `tests/providers.csv` (actuellement : `groq` et `github`)
  - [ ] ⚠️ Ne jamais les stocker en clair dans un fichier texte ou un email
  - [ ] 🔰 *Débutant* : crée les clés avec le **minimum de droits nécessaires** (scope "read-only" côté GitHub, par exemple) — c'est plus rapide à faire maintenant qu'à corriger après une fuite.

- [ ] **Vérification du hardware cible**
  ```
  CPU : Xeon E5-2698 v3 (16 cores)
  RAM : 64 Go ECC minimum
  GPU : Quadro RTX 4000 (8 Go VRAM, Turing)
  Disque : SSD NVMe avec 100 Go libres minimum
  ```

- [ ] **ISO Omarchy gravée en exFAT**, hash vérifié
  ```powershell
  Get-FileHash omarchy-latest.iso -Algorithm SHA256
  # comparer avec le hash publié sur https://omarchy.org
  ```

- [ ] **Repo cloné/copié sur la clé exFAT**, au bon tag
  ```powershell
  git clone https://github.com/chelmooz/agentic-os.git
  cd agentic-os
  git tag -l                # doit lister v0.1.0-predeploy (ou plus récent)
  git log --oneline -1
  ```

- [ ] **Ouvrir le générateur HTML sur Windows** (mockup, juste pour vérifier qu'il s'ouvre)
  ```powershell
  start opencode-generator.html
  # bandeau ⚠ MOCKUP visible attendu — ce fichier ne génère RIEN tout seul,
  # c'est juste une prévisualisation. Le vrai config/opencode.json se copie
  # à la main en Phase 4.
  ```

- [ ] **Copier les templates de config en référence**
  ```powershell
  Copy-Item config\opencode.json.example D:\backup\
  Copy-Item config\settings.yaml.example D:\backup\
  ```

- [ ] **Vérifier la connectivité réseau du PC cible** (Omarchy devra télécharger le modèle ~18-19 Go)
  ```powershell
  ping -n 4 huggingface.co
  ping -n 4 github.com
  ```
  🔰 *Débutant* : un forfait/une box avec 20-30 Mbit/s de descendant met le téléchargement du modèle à ~1-2 h. En dessous, prévois de le lancer avant de dormir.

### 🎯 Critère de succès Phase 0
```
✓ Clé USB bootable
✓ Repo complet, tag v0.1.0-predeploy présent
✓ Clés API sauvegardées dans un gestionnaire sécurisé
✓ Connectivité réseau vérifiée
```

---

## Phase 1 — Installation système (Omarchy)

### 1.1 Prérequis hardware & BIOS

```bash
lspci | grep -i nvidia     # Attendu : "Quadro RTX 4000" (Turing TU104)
free -h                    # Attendu : ~64 Go
df -h                      # Au moins 100 Go libres, SSD NVMe de préférence
```

- **Secure Boot** : `DISABLED` (Omarchy ne le supporte pas nativement)
- **Boot mode** : `UEFI`
- **Boot USB en premier** dans l'ordre de démarrage

### 1.2 Installation Omarchy

1. Boot sur la clé USB
2. Wizard Omarchy (clavier, timezone, user, password)
3. Post-install :

```bash
uname -r
echo $XDG_SESSION_TYPE   # attendu : wayland
hyprctl version
```

### 1.3 Paquets de base

```bash
sudo pacman -Syu
sudo pacman -S base-devel git cmake wget curl jq dos2unix htop \
               docker docker-compose python python-pip neovim
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# ⚠️ Déconnexion/reconnexion obligatoire pour que le groupe docker soit actif
```

Vérification :
```bash
docker --version
groups | grep docker
```

**🔴 Check** : `docker` installé, tu es dans le groupe `docker`.

### 1.4 Drivers NVIDIA + CUDA

> **Pourquoi `nvidia-open-dkms` ?** La Quadro RTX 4000 est une Turing (TU104). Sur Wayland/Hyprland, les modules open-source NVIDIA offrent la meilleure intégration KMS et évitent les écrans noirs au boot.

```bash
sudo pacman -S linux-headers
sudo pacman -S nvidia-open-dkms nvidia-utils lib32-nvidia-utils \
               nvidia-settings opencl-nvidia cuda
```

> **Note** : si `nvidia-open-dkms` pose des régressions (rares sur Turing), bascule sur `nvidia-dkms`. Évite le pilote libre `nouveau` pour les performances IA.

GRUB — édite `/etc/default/grub`, ajoute à `GRUB_CMDLINE_LINUX_DEFAULT` :
```
nvidia-drm.modeset=1 nvidia-drm.fbdev=1
```
puis :
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Hyprland (`~/.config/hypr/hyprland.conf`) :
```
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
```

Reboot puis vérification :
```bash
sudo reboot
nvidia-smi          # RTX 4000 détectée, driver chargé
nvcc --version      # CUDA 12.x disponible
```

**🔴 Check** : `nvidia-smi` affiche la RTX 4000, `nvcc --version` fonctionne.

### 1.5 Compilation llama.cpp (ciblage Turing, compute capability 7.5)

```bash
cd ~
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="75" -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j$(nproc)
```

Validation binaires :
```bash
ls -lh build/bin/llama-server build/bin/llama-bench
./build/bin/llama-server --help | head -5
./build/bin/llama-bench --help | head -5
```

**🔴 Check** : les deux binaires existent et répondent à `--help`.

### 1.6 Modèle Qwen3-Coder-30B-A3B

```bash
mkdir -p ~/models && cd ~/models
wget -c https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf
```
🔰 *Débutant* : le `-c` permet de **reprendre** le téléchargement si ta connexion coupe — relance juste la même commande, `wget` continuera là où il s'est arrêté au lieu de recommencer à zéro.

**Vérification intégrité (critique)** :
```bash
ls -lh ~/models/*.gguf   # attendu ~18-19 Go
sha256sum Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf
# comparer avec le hash affiché sur la page HuggingFace du fichier (bouton "Copy SHA256")
# si hash différent : NE PAS UTILISER, re-télécharger
```

**🔴 Check** : fichier GGUF présent, taille correcte, hash vérifié.

### 1.7 Serveur llama.cpp

Calibrage `--n-gpu-layers` (grille de mesure obligatoire — 8 Go de VRAM, il faut trouver l'optimal) :
```bash
cd ~/llama.cpp
./build/bin/llama-bench -m ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf -ngl 20
./build/bin/llama-bench -m ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf -ngl 25
./build/bin/llama-bench -m ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf -ngl 30
```
**Note la valeur tok/s pour chaque `-ngl`**. Garde la meilleure valeur *sans OOM* (~25-30 typique sur 8 Go).

Lancement manuel (test) :
```bash
./build/bin/llama-server \
  -m ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf \
  --n-gpu-layers 25 --ctx-size 32768 --threads 16 \
  --host 127.0.0.1 --port 8080 2>&1 | tee ~/llama-server.log
```

Test + **isolation réseau (critique)**, dans un autre terminal :
```bash
curl -s http://127.0.0.1:8080/v1/models | jq .
ss -tlnp | grep 8080
# doit afficher 127.0.0.1:8080, PAS 0.0.0.0:8080
```
⚠️ Si tu vois `0.0.0.0:8080`, ton serveur est exposé sur tout le réseau local — corrige `--host` avant de continuer.

**🔴 Check** : JSON valide retourné, réponse cohérente, pas d'erreur CUDA dans `~/llama-server.log`, bind sur `127.0.0.1` uniquement.

### 1.8 Open WebUI (Docker, 127.0.0.1 uniquement)

```bash
docker volume create open-webui
docker run -d --name open-webui \
  -p 127.0.0.1:3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data --restart always \
  ghcr.io/open-webui/open-webui:main
docker ps | grep open-webui   # doit être "Up"
```

Config : ouvre `http://127.0.0.1:3000` → crée un compte admin local → **Admin Settings → Connections → OpenAI API** → URL `http://host.docker.internal:8080/v1`, clé API vide → **Save**, puis le bouton de test.

**🔴 Check** : Open WebUI accessible, modèle Qwen3 visible dans la liste.

### 1.9 Installation d'OpenCode

> ⚠️ Ce point n'est couvert nulle part ailleurs dans le repo — sans lui, `opencode --version` échoue en Phase 1.10.

```bash
# Méthode recommandée (script officiel) :
curl -fsSL https://opencode.ai/install | bash

# Alternative si tu préfères npm :
npm install -g opencode-ai
```
🔰 *Débutant* : après l'installation, ouvre un **nouveau terminal** (ou `source ~/.bashrc`) pour que la commande `opencode` soit reconnue dans le `PATH`.

### 1.10 OpenCode — vérification

```bash
opencode --version
opencode --help | head -5
```

### 🎯 Critère de succès Phase 1
```
✓ nvidia-smi affiche la RTX 4000
✓ nvcc --version retourne CUDA 12.x
✓ llama-server répond sur 127.0.0.1:8080 (pas 0.0.0.0)
✓ llama-bench a mesuré tok/s pour ngl 20/25/30
✓ Open WebUI accessible sur 127.0.0.1:3000, modèle visible
✓ OpenCode installé et fonctionnel
```

**⏱️ Point de non-retour** : après cette phase, Omarchy est installé. Retour en arrière = réinstallation complète (rollback = réinstaller Omarchy depuis la clé USB).

---

## Phase 2 — Calibration & validation (Blueprint §8.2)

Test de sortie JSON forcée :
```bash
curl -s http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model": "qwen3-coder-30b-a3b", "response_format": {"type": "json_object"}, "messages": [{"role": "user", "content": "Decompose en micro-taches (description, file_scope, validation_command). Besoin : creer un fichier hello.txt contenant hello"}]}' | jq .
# doit être du JSON parsable, sans fences ```json ni texte libre
```

Grille sur les 3 prompts fournis dans le repo :
```bash
for prompt in tests/prompts/p1_nominal.txt tests/prompts/p2_ambiguous.txt tests/prompts/p3_edge.txt; do
  echo "=== $prompt ==="
  curl -s http://127.0.0.1:8080/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d "{\"model\": \"qwen3-coder-30b-a3b\", \"response_format\": {\"type\": \"json_object\"}, \"messages\": [{\"role\": \"user\", \"content\": \"$(cat $prompt)\"}]}" \
    | jq -e . >/dev/null && echo "✓ PASS" || echo "✗ FAIL"
done
```

Remplis le **Journal de bord** en bas de ce document (date, `--n-gpu-layers` optimal, tok/s, bugs rencontrés).

### 🎯 Critère de succès Phase 2
```
✓ 3/3 prompts produisent du JSON strict
✓ tok/s mesurés et documentés
✓ --n-gpu-layers optimal identifié
```

---

## Phase 3 — Permissions & sécurité

> exFAT ne stocke aucune permission Unix : `chmod +x` reste obligatoire quelle que soit l'origine du fichier (même s'il vient d'un `git clone` fait directement sur Omarchy).

```bash
cd ~/agentic-os
chmod +x tests/*.sh
ls -la tests/*.sh   # -rwxr-xr-x attendu sur les 4
```

Vérification CRLF (déjà nettoyé dans le repo au commit `11a801f`, réflexe utile si un fichier a été rouvert sous Windows) :
```bash
file tests/*.sh
# ne doit PAS afficher "with CRLF"
# si détecté : dos2unix tests/*.sh   (ou sed -i 's/\r$//' fichier.sh)
```

Dossier `~/.mos` créé et restreint :
```bash
mkdir -p ~/.mos/{agents/dev,agents/ops,state,logs,skills}
chmod 700 ~/.mos
ls -la ~/.mos   # drwx------ attendu
```

Filet de sécurité, tout d'un coup :
```bash
find . -name "*.sh" -type f -exec chmod +x {} \;
find . -name "*.sh" -type f -exec ls -la {} \;
```

### 🎯 Critère de succès Phase 3
```
✓ Tous les .sh en -rwxr-xr-x
✓ Aucun CRLF résiduel
✓ ~/.mos en 700
```

---

## Phase 4 — Configuration OpenCode

Le HTML (`opencode-generator.html`) est un **mockup sans JS fonctionnel** (bandeau MOCKUP visible) — ne pas compter dessus pour générer le fichier, utiliser le template directement :
```bash
cp config/opencode.json.example config/opencode.json
nvim config/opencode.json
# remplacer les placeholders, utiliser {env:GROQ_API_KEY} — jamais de clé en clair
```

Validation JSON : `jq . config/opencode.json`

Vérifier l'exclusion git (déjà dans `.gitignore` du repo) :
```bash
git status --short
# config/opencode.json ne doit PAS apparaître
```

Variables d'environnement persistées :
```bash
echo 'export GROQ_API_KEY="gsk_..."' >> ~/.bashrc
echo 'export GITHUB_TOKEN="ghp_..."' >> ~/.bashrc
source ~/.bashrc
```

Test individuel de chaque provider avant `run_all.sh` :
```bash
opencode run --model groq "Dis bonjour en une phrase" --format json
```

### 🎯 Critère de succès Phase 4
```
✓ opencode.json valide (jq parse OK)
✓ config/opencode.json exclu du git
✓ Variables d'env persistées
✓ Chaque provider répond individuellement
```

---

## Phase 5 — Génération du code cible (D1-D4)

> Aucun de ces fichiers n'existe encore dans le repo (`orchestrator/`, `lab/`, `skills/` ne contiennent qu'un `.gitkeep`).

**D.1** (`docs/prompts/D1_orchestrator_bash.md`) → générer et sauvegarder dans `orchestrator/orchestrator.sh` :
```bash
nvim orchestrator/orchestrator.sh
chmod +x orchestrator/orchestrator.sh
```

**D.3** (`docs/prompts/D3_mos_cli.md`) → générer `mos-cli.py` (commandes attendues : `mos status`, `mos radar`, `mos memory compact <role>`) :
```bash
nvim mos-cli.py
chmod +x mos-cli.py
python3 mos-cli.py --help
```

**D.4** (`docs/prompts/D4_skills_catalog.md`) → fichiers dans `skills/` :
```bash
chmod +x skills/*.sh 2>/dev/null || echo "Pas de .sh dans skills/"
```

Vérification CRLF sur les fichiers fraîchement générés :
```bash
file orchestrator/orchestrator.sh mos-cli.py
dos2unix orchestrator/orchestrator.sh mos-cli.py 2>/dev/null || true
```

Commit :
```bash
git add orchestrator/ lab/ skills/ mos-cli.py
git commit -m "feat: generate target code via prompts D1-D4"
git push origin main
```

### 🎯 Critère de succès Phase 5
```
✓ orchestrator/orchestrator.sh existe et est exécutable
✓ mos-cli.py fonctionne
✓ skills/ contient les fichiers générés
✓ Tout est commité et poussé
```

---

## Phase 6 — Tests E2E (Release Gates)

```bash
cd ~/agentic-os
./tests/run_all.sh
```

Résultat attendu **avant** génération D1-D4 : `RELEASE=RED` sur les 3 gates avec `NOT_IMPLEMENTED` — c'est le comportement correct depuis le fix du 23/08, pas un bug.

Après génération de `orchestrator/orchestrator.sh` (D.1), le **gate Journal** doit être le premier à passer. Ses résultats s'écrivent dans :
```bash
cat results/journal/journal.jsonl          # ⚠️ à la racine du repo, PAS sous tests/
cat tests/results/format-json/report.csv
cat tests/results/verifier/report.csv
```

Gates JSON et Verifier : implémentation encore à écrire (voir `BLUEPRINT.md` §8.2 pt 1 et pt 2) — pas couverts par D1-D4 actuellement.

Une fois `RELEASE=GREEN` :
```bash
git tag -a v1.0.0-rc -m "Release candidate after gates validation"
git push origin v1.0.0-rc
```

### 🎯 Critère de succès Phase 6
```
✓ RELEASE=GREEN sur les 3 gates
✓ Tag v1.0.0-rc poussé
```

---

## Phase 7 — Automatisation & monitoring

Service systemd pour que `llama-server` démarre au boot et redémarre en cas de crash :
```bash
sudo nvim /etc/systemd/system/llama-server.service
```

Coller :
```ini
[Unit]
Description=llama.cpp Server (Qwen3-Coder-30B-A3B)
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME/llama.cpp
ExecStart=/home/YOUR_USERNAME/llama.cpp/build/bin/llama-server \
  -m /home/YOUR_USERNAME/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf \
  --n-gpu-layers 25 \
  --ctx-size 32768 \
  --threads 16 \
  --host 127.0.0.1 --port 8080
Restart=on-failure
RestartSec=10
StandardOutput=append:/home/YOUR_USERNAME/llama-server.log
StandardError=append:/home/YOUR_USERNAME/llama-server.log

[Install]
WantedBy=multi-user.target
```
> **Remplace** `YOUR_USERNAME` par ton nom d'utilisateur Omarchy.

Activation :
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now llama-server
sudo systemctl status llama-server   # active (running) attendu
```

Vérification au reboot :
```bash
sudo reboot
systemctl status llama-server
curl -s http://127.0.0.1:8080/v1/models | jq .
```

Rotation des logs :
```bash
echo "0 0 * * 0 find ~/.mos/logs -name 'journal.jsonl' -mtime +30 -delete" | crontab -
```

Alias utiles (`~/.bashrc`) :
```bash
alias mos-status='cd ~/agentic-os && python3 mos-cli.py status'
alias mos-radar='cd ~/agentic-os && python3 mos-cli.py radar'
alias mos-gates='cd ~/agentic-os && ./tests/run_all.sh'
alias llama-logs='journalctl -u llama-server -f'
```

Monitoring 24h : `htop`, `watch -n 1 nvidia-smi`, `journalctl -u llama-server -f`

### 🎯 Critère de succès Phase 7
```
✓ llama-server démarre automatiquement au boot
✓ Logs rotatifs configurés
✓ Monitoring stable pendant 24h
```

---

## 📝 Journal de bord d'installation

| Date | Phase | Statut | Notes (tok/s, valeurs réelles, bugs) |
|------|-------|--------|--------------------------------------|
| | 0. Préparation Windows | | |
| | 1. Installation système | | `-ngl` optimal : ___ |
| | 2. Calibration & validation | | |
| | 3. Permissions & sécurité | | |
| | 4. Configuration OpenCode | | |
| | 5. Génération code (D1-D4) | | |
| | 6. Tests E2E | | |
| | 7. Automatisation & monitoring | | |

---

## 🆘 Dépannage rapide

| Problème | Solution |
|----------|----------|
| `nvidia-smi` ne trouve pas le GPU | Vérifier `nvidia-open-dkms` installé + reboot |
| Écran noir au boot Hyprland | Vérifier `nvidia-drm.modeset=1` dans GRUB |
| `docker: permission denied` | `sudo usermod -aG docker $USER` + relog |
| CUDA OOM à `--n-gpu-layers 30` | Redescendre à 25 ou 20 |
| Open WebUI ne voit pas le modèle | Vérifier `http://host.docker.internal:8080/v1/models` |
| `llama-server` crash au démarrage | `journalctl -u llama-server -e` |
| Script bash `$'\r': command not found` | CRLF résiduel → `dos2unix fichier.sh` |
| `opencode` : commande introuvable | Réinstaller via `curl -fsSL https://opencode.ai/install \| bash`, ouvrir un nouveau terminal |
| `opencode` ne trouve pas la config | Vérifier `OPENCODE_CONFIG_FILE` ou `~/.config/opencode/config.json` |
| Provider retourne 401/403 | Vérifier la variable d'environnement (`echo $GROQ_API_KEY`) |
| Gate Journal échoue avec "Missing: orchestrator/orchestrator.sh" | Normal tant que D.1 n'est pas généré — pas une erreur |
| Téléchargement du modèle interrompu | Relancer la même commande `wget -c ...` (reprise automatique) |

---

## 📊 Métriques de succès post-déploiement

| Métrique | Valeur cible | Mesure |
|----------|-------------|--------|
| tok/s inférence | > 10 tok/s | `llama-bench` |
| Latence première réponse | < 5 s | Chronomètre manuel |
| Taux de réussite JSON | 100 % sur 3 prompts | `tests/run_format_json_gate.sh` (une fois implémenté) |
| Journal écrit | 1 ligne JSONL par appel | `tests/run_journal_gate.sh` |
| Uptime llama-server | > 99 % sur 7 jours | `systemctl status` |

---

## ✅ Definition of Done

```
✓ Toutes les phases 0-7 cochées
✓ RELEASE=GREEN sur les 3 gates
✓ Tag v1.0.0-rc poussé
✓ Journal de bord rempli (ci-dessus)
✓ Monitoring stable pendant 24h
```

---

## 📚 Références

- Blueprint : [`BLUEPRINT.md`](./BLUEPRINT.md)
- Annexe C (historique) : [`docs/ANNEXE_C_INSTALL.md`](./docs/ANNEXE_C_INSTALL.md)
- Cheatsheet commandes : [`docs/CHEATSHEET.md`](./docs/CHEATSHEET.md)
- Prompts de génération code : [`docs/prompts/`](./docs/prompts/)
- Statut du projet : [`STATUS.md`](./STATUS.md)

*Sources de vérité en cas de doute : `BLUEPRINT.md`, `INSTALL.md` (ce document), `STATUS.md`.*

---

*Document mis à jour le 24/08/2026 — fusion checklist v2.1 + guide détaillé, pour le pré-déploiement du projet Agentic OS.*
