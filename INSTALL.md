# Guide d'installation — Agentic OS

**Machine cible** : Xeon E5-2698 v3 / 64 Go ECC / Quadro RTX 4000 8 Go / Omarchy (Arch + Hyprland)

Ce guide décrit l'installation complète du stack Blueprint v4 sur la machine serveur Omarchy. Il couvre 7 phases : prérequis, installation OS, pilotes NVIDIA/CUDA, compilation llama.cpp, modèle, serveur, Open WebUI.

---

## Table des matières

1. [Prérequis hardware & BIOS](#1-prérequis-hardware--bios)
2. [Installation Omarchy](#2-installation-omarchy)
3. [Pilotes NVIDIA & CUDA](#3-pilotes-nvidia--cuda-spécifique-omarchy-hyprland)
4. [Compilation llama.cpp](#4-compilation-llamacpp-ciblage-turing)
5. [Modèle Qwen3-Coder-30B-A3B](#5-modèle-qwen3-coder-30b-a3b)
6. [Serveur llama.cpp](#6-serveur-llamacpp--test-curl)
7. [Open WebUI (Docker)](#7-open-webui-docker-local)
8. [Automatisation systemd](#8-automatisation-systemd)
9. [Premier test E2E](#9-premier-test-e2e)

---

## 1. Prérequis hardware & BIOS

### Vérifications matérielles

```bash
# GPU détecté
lspci | grep -i nvidia
# Attendu : "Quadro RTX 4000" (Turing TU104)

# RAM suffisante
free -h
# Attendu : ~64 Go

# Espace disque
df -h
# Au moins 100 Go libres sur SSD NVMe de préférence
```

### Configuration BIOS

- **Secure Boot** : `DISABLED` (Omarchy ne le supporte pas nativement)
- **Boot mode** : `UEFI`
- **Disque** : SSD NVMe recommandé

### Téléchargement ISO Omarchy

```bash
# Depuis https://omarchy.org/
wget https://omarchy.org/iso/omarchy-latest.iso
# Vérifier signature SHA256 fournie sur le site
sha256sum omarchy-latest.iso
```

### Clé USB bootable

```bash
# Utiliser dd (Linux) ou balenaEtcher (Windows/Mac)
sudo dd if=omarchy-latest.iso of=/dev/sdX bs=4M status=progress conv=fsync
# ⚠ Remplacer /dev/sdX par ta clé USB (vérifier avec lsblk)
```

**🔴 Check** : Clé USB bootable, BIOS configuré (Secure Boot OFF, UEFI).

---

## 2. Installation Omarchy

### Processus

1. **Boot sur la clé USB**
2. **Suivre le wizard** : clavier, timezone, user, password
3. **Post-install** :

```bash
# Mise à jour système
sudo pacman -Syu

# Outils de base
sudo pacman -S base-devel git cmake wget curl jq \
               docker docker-compose python python-pip htop \
               neovim  # ou vim

# Activer Docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# ⚠ Déconnexion/reconnexion obligatoire pour que le groupe docker soit actif
```

### Vérifications

```bash
uname -r              # Kernel récent
docker --version      # Docker installé
groups | grep docker  # Tu dois être dans le groupe docker
```

**🔴 Check** : `docker` installé, tu es dans le groupe `docker`.

---

## 3. Pilotes NVIDIA & CUDA (spécifique Omarchy / Hyprland)

> **Pourquoi `nvidia-open-dkms` ?** La Quadro RTX 4000 est une Turing (TU104). Sur Wayland/Hyprland, les modules open-source NVIDIA offrent la meilleure intégration KMS et évitent les écrans noirs au boot.

### Headers du noyau

```bash
# Adapter selon ton noyau (linux, linux-zen, linux-lts)
sudo pacman -S linux-headers
```

### Pilotes NVIDIA (variante DKMS)

```bash
sudo pacman -S nvidia-open-dkms \
               nvidia-utils lib32-nvidia-utils \
               nvidia-settings opencl-nvidia cuda
```

> **Note** : Si `nvidia-open-dkms` pose des régressions (rares sur Turing), bascule sur `nvidia-dkms`. Évite le pilote libre `nouveau` pour les performances IA.

### Configuration KMS (bootloader)

Édite la config GRUB :

```bash
sudo nvim /etc/default/grub
```

Ajoute aux paramètres du noyau (ligne `GRUB_CMDLINE_LINUX_DEFAULT`) :

```
nvidia-drm.modeset=1 nvidia-drm.fbdev=1
```

Régénère GRUB :

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Variables d'environnement Hyprland

Édite `~/.config/hypr/hyprland.conf` et ajoute ces lignes :

```
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
```

### Reboot & Validation

```bash
sudo reboot
```

Après reboot :

```bash
nvidia-smi          # RTX 4000 détectée, driver chargé
nvcc --version      # CUDA 12.x disponible
```

**🔴 Check** : `nvidia-smi` affiche la RTX 4000, `nvcc --version` fonctionne.

---

## 4. Compilation llama.cpp (ciblage Turing)

La RTX 4000 est une **Turing** (compute capability **7.5**). C'est le flag crucial pour la compilation.

```bash
cd ~
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp

# Compilation avec ciblage explicite Turing
cmake -B build \
  -DGGML_CUDA=ON \
  -DCMAKE_CUDA_ARCHITECTURES="75" \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build --config Release -j$(nproc)
```

### Validation binaires

```bash
ls -lh build/bin/llama-server
ls -lh build/bin/llama-bench
./build/bin/llama-server --help | head -5
./build/bin/llama-bench --help | head -5
```

**🔴 Check** : Les deux binaires existent et répondent à `--help`.

---

## 5. Modèle Qwen3-Coder-30B-A3B

```bash
mkdir -p ~/models
cd ~/models

# Téléchargement du GGUF Q4_K_M (~18-19 Go)
wget https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf
```

### Vérification intégrité

```bash
ls -lh ~/models/*.gguf
# Attendu : ~18-19 Go
sha256sum Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf
# Comparer avec le hash fourni sur HuggingFace
```

**🔴 Check** : Fichier GGUF présent, taille correcte.

---

## 6. Serveur llama.cpp + test curl

### Calibrage `--n-gpu-layers` (principe §1.4 n°7 du Blueprint)

La RTX 4000 a **8 Go de VRAM**. On doit trouver l'optimal via `llama-bench`.

```bash
cd ~/llama.cpp
./build/bin/llama-bench \
  -m ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf \
  -ngl 20
./build/bin/llama-bench \
  -m ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf \
  -ngl 25
./build/bin/llama-bench \
  -m ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf \
  -ngl 30
./build/bin/llama-bench \
  -m ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf \
  -ngl 35
```

**Note la valeur tok/s pour chaque `-ngl`**. Choisis la plus haute sans OOM. Sur Turing 8 Go, **~25-30** est typique.

### Lancement manuel (test)

```bash
cd ~/llama.cpp
./build/bin/llama-server \
  -m ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf \
  --n-gpu-layers 25 \
  --ctx-size 32768 \
  --threads 16 \
  --host 127.0.0.1 --port 8080 \
  2>&1 | tee ~/llama-server.log
```

### Test (dans un autre terminal)

```bash
# Vérifier que le serveur répond
curl -s http://127.0.0.1:8080/v1/models | jq .

# Test de génération
curl -s http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen3-coder-30b-a3b-instruct",
    "messages": [{"role": "user", "content": "Dis bonjour en une phrase."}],
    "temperature": 0.7
  }' | jq .choices[0].message.content
```

**🔴 Check** : JSON valide retourné, réponse cohérente, pas d'erreur CUDA dans `~/llama-server.log`.

---

## 7. Open WebUI (Docker local)

```bash
# Volume persistant
docker volume create open-webui

# Lancement sur 127.0.0.1 uniquement (principe §7.3 Blueprint)
docker run -d \
  --name open-webui \
  -p 127.0.0.1:3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main

# Vérifier le conteneur
docker ps | grep open-webui
```

### Configuration connexion llama.cpp

1. Ouvrir `http://127.0.0.1:3000`
2. Créer un compte admin local
3. **Settings → Admin Settings → Connections**
4. Section **OpenAI API** :
   - URL : `http://host.docker.internal:8080/v1`
   - Clé API : laisser vide
5. Cliquer **Save**, puis le bouton de test

**🔴 Check** : Open WebUI accessible, modèle Qwen3 visible dans la liste des modèles.

---

## 8. Automatisation systemd

Pour que `llama-server` démarre au boot et redémarre en cas de crash.

### Création du service

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

### Activation

```bash
sudo systemctl daemon-reload
sudo systemctl enable llama-server
sudo systemctl start llama-server

# Vérifier le statut
sudo systemctl status llama-server
journalctl -u llama-server -f  # Voir les logs en direct
```

**🔴 Check** : `systemctl status` affiche `active (running)`.

---

## 9. Premier test E2E

Dans Open WebUI (`http://127.0.0.1:3000`), créer un chat et envoyer :

```
Décompose en micro-tâches à scope de fichiers disjoint :
"Créer un script Python qui lit un fichier CSV et génère un rapport markdown."

Chaque micro-tâche doit avoir les champs suivants :
- description : ce que la tâche fait
- file_scope : quels fichiers elle touche
- validation_command : commande bash pour vérifier

Réponds UNIQUEMENT en JSON, format :
{"tasks": [...]}
```

### Validation

- ✅ Réponse JSON valide (parsable par `jq`)
- ✅ Champs `description`, `file_scope`, `validation_command` présents
- ✅ Temps de réponse < 30s pour cette taille de tâche
- ✅ Pas d'erreur CUDA dans `journalctl -u llama-server`

---

## 📝 Journal de bord d'installation

| Date | Phase | Statut | Notes (tok/s, valeurs réelles, bugs) |
|------|-------|--------|--------------------------------------|
| | 1. Prérequis | | |
| | 2. Omarchy | | |
| | 3. NVIDIA/CUDA | | |
| | 4. llama.cpp | | |
| | 5. Modèle | | |
| | 6. Serveur | | `-ngl` optimal : ___ |
| | 7. Open WebUI | | |
| | 8. systemd | | |
| | 9. E2E | | |

---

## 🆘 Dépannage rapide

| Problème | Solution |
|----------|----------|
| `nvidia-smi` ne trouve pas le GPU | Vérifier que `nvidia-open-dkms` est installé + reboot |
| Écran noir au boot sous Hyprland | Vérifier `nvidia-drm.modeset=1` dans GRUB |
| `docker: permission denied` | `sudo usermod -aG docker $USER` + relog |
| CUDA OOM avec `--n-gpu-layers 30` | Redescendre à 25 ou 20 |
| Open WebUI ne voit pas le modèle | Vérifier `http://host.docker.internal:8080/v1/models` depuis l'hôte |
| `llama-server` crash au démarrage | Vérifier `journalctl -u llama-server -e` |

---

## 📚 Références

- Blueprint v4 : [`BLUEPRINT.md`](./BLUEPRINT.md)
- Annexe C (historique) : [`docs/ANNEXE_C_INSTALL.md`](./docs/ANNEXE_C_INSTALL.md)
- Cheatsheet commandes : [`docs/CHEATSHEET.md`](./docs/CHEATSHEET.md)
- Prompts de génération code : [`docs/prompts/`](./docs/prompts/)

---

*Document créé pour le pré-déploiement du projet Agentic OS — Août 2026*