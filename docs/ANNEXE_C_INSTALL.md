# Annexe C — Procédure d'installation

**Statut** : En cours de validation sur machine réelle (Xeon E5-2698 v3 / 64 Go ECC / RTX 4000 8 Go / Omarchy)

## Table des matières

1. [Prérequis hardware & BIOS](#1-prérequis-hardware--bios)
2. [Installation Omarchy](#2-installation-omarchy)
3. [Pilotes NVIDIA & CUDA](#3-pilotes-nvidia--cuda)
4. [Compilation llama.cpp](#4-compilation-llamacpp)
5. [Modèle Qwen3-Coder-30B-A3B](#5-modèle-qwen3-coder-30b-a3b)
6. [Serveur llama.cpp](#6-serveur-llamacpp)
7. [Open WebUI (Docker)](#7-open-webui-docker)
8. [Premier test E2E](#8-premier-test-e2e)

---

## 1. Prérequis hardware & BIOS

### Vérifications
```bash
# GPU détecté
lspci | grep -i nvidia
# Attendu : "Quadro RTX 4000"

# RAM suffisante
free -h
# Attendu : ~64 Go