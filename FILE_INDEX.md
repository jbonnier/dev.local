# 📑 Index des Fichiers - Dev.Local 2.0

## 🎯 Vue d'Ensemble

**Total des fichiers** : ~25 fichiers  
**Lignes de code** : ~5000+ lignes  
**Documentation** : ~3500+ lignes  
**Langages** : PowerShell + Bash + YAML + Markdown  

---

## 📜 Scripts Principaux

### PowerShell (Windows)

| Fichier | Lignes | Description |
|---------|--------|-------------|
| **menu.ps1** | 256 | Menu interactif TUI avec 16 options |
| **manage-profiles.ps1** | 773 | Gestion des profils, génération compose/traefik |
| **launch.ps1** | 210 | Orchestration services, AWS, secrets |

**Total PowerShell** : 1239 lignes

### Bash (Linux/macOS)

| Fichier | Lignes | Description |
|---------|--------|-------------|
| **menu.sh** | ~190 | Menu interactif TUI identique à PowerShell |
| **manage-profiles.sh** | ~850 | Gestion profils (conversion complète) |
| **launch.sh** | ~220 | Orchestration services (conversion complète) |
| **test-bash-scripts.sh** | ~200 | Script de validation automatique |

**Total Bash** : ~1460 lignes

---

## 📚 Documentation

### Guides Utilisateurs

| Fichier | Lignes | Audience | Description |
|---------|--------|----------|-------------|
| **README.md** | ~600 | Tous | Documentation principale du projet |
| **QUICKSTART.md** | ~300 | Débutants | Guide de démarrage rapide |
| **SUMMARY.md** | ~250 | Management | Vue d'ensemble exécutive |
| **CHEATSHEET.md** | ~400 | Utilisateurs | Aide-mémoire commandes essentielles |

### Documentation Bash

| Fichier | Lignes | Audience | Description |
|---------|--------|----------|-------------|
| **BASH_README.md** | ~350 | Linux/macOS | Guide complet scripts bash |

**Total Documentation** : ~350 lignes

---

## ⚙️ Configuration

### Fichiers de Configuration

| Fichier | Type | Description |
|---------|------|-------------|
| **config.yml** | YAML | Config globale (Dozzle enabled/port) |
| **.sops.yaml** | YAML | Configuration SOPS (KMS/Age) |
| **docker-compose.yml** | YAML | Généré automatiquement, NE PAS ÉDITER |
| **secrets.env** | Encrypted | Secrets chiffrés avec SOPS |
| **secrets.env.example** | Text | Template pour secrets |

### Traefik

| Fichier | Type | Description |
|---------|------|-------------|
| **traefik/traefik.yml** | YAML | Config Traefik statique |
| **traefik/dynamic.yml** | YAML | Généré automatiquement (routers/services) |

---

## 📋 Profils de Services

### Dossier `profiles/`

| Fichier | Status | Description |
|---------|--------|-------------|
| **profiles/ui.yml** | Active | Service UI (always_active: true) |
| **profiles/emp.yml** | Active | Service EMP (always_active: true) |
| **profiles/andoc.yml** | Active | Service ANDOC (docker_profile: andoc) |
| **profiles/recpro.yml** | Active | Service RECPRO (docker_profile: recpro) |
| **profiles/example.yml** | Disabled | Exemple de profil (enabled: false) |

**Structure d'un profil** :
```yaml
name: service-name
description: "..."
enabled: true
always_active: true/false
docker_profile: null/profile-name

docker-compose:
  image: ...
  container_name: ...
  environment: ...

traefik:
  enabled: true/false
  prefix: /path
  strip_prefix: true/false
  port: 8000

secrets:
  - name: SECRET_VAR
    description: "..."
    default: changeme

metadata:
  category: ...
  tags: [...]
```

---

## 🗂️ Autres Fichiers

### Git

| Fichier | Description |
|---------|-------------|
| **.gitignore** | Fichiers ignorés (secrets.env, node_modules, etc.) |
| **.git/** | Dépôt Git (historique) |

### IDE

| Fichier | Description |
|---------|-------------|
| **.idea/** | Configuration IntelliJ/PyCharm |

---

## 📊 Arborescence Complète

```
Dev.Local.2.0/
│
├── 📜 SCRIPTS POWERSHELL
│   ├── menu.ps1                         (256 lignes)
│   ├── manage-profiles.ps1              (773 lignes)
│   └── launch.ps1                       (210 lignes)
│
├── 📜 SCRIPTS BASH
│   ├── menu.sh                          (~190 lignes)
│   ├── manage-profiles.sh               (~850 lignes)
│   ├── launch.sh                        (~220 lignes)
│   └── test-bash-scripts.sh             (~200 lignes)
│
├── 📚 DOCUMENTATION
│   ├── README.md                        (Documentation principale)
│   ├── QUICKSTART.md                    (Démarrage rapide)
│   ├── SUMMARY.md                       (Vue d'ensemble)
│   ├── CHEATSHEET.md                    (Aide-mémoire)
│   ├── BASH_README.md                   (Guide bash)
│   ├── BASH_CONVERSION_REPORT.md        (Rapport technique)
│   ├── BASH_COMPLETION.md               (Résumé conversion)
│   └── MIGRATION_GUIDE.md               (Migration guide)
│
├── ⚙️ CONFIGURATION
│   ├── config.yml                       (Config Dozzle)
│   ├── .sops.yaml                       (Config SOPS)
│   ├── docker-compose.yml               (Généré automatiquement)
│   ├── secrets.env                      (Chiffré SOPS)
│   └── secrets.env.example              (Template)
│
├── 📋 PROFILS
│   └── profiles/
│       ├── ui.yml                       (Service UI)
│       ├── emp.yml                      (Service EMP)
│       ├── andoc.yml                    (Service ANDOC)
│       ├── recpro.yml                   (Service RECPRO)
│       └── example.yml                  (Exemple désactivé)
│
├── 🌐 TRAEFIK
│   └── traefik/
│       ├── traefik.yml                  (Config statique)
│       └── dynamic.yml                  (Généré - routes)
│
└── 🗂️ AUTRES
    ├── .gitignore
    ├── .git/
    └── .idea/
```

---

## 🎯 Fichiers par Catégorie

### 🚀 Exécutables (7)

- ✅ `menu.ps1` - Windows
- ✅ `manage-profiles.ps1` - Windows
- ✅ `launch.ps1` - Windows
- ✅ `menu.sh` - Linux/macOS
- ✅ `manage-profiles.sh` - Linux/macOS
- ✅ `launch.sh` - Linux/macOS
- ✅ `test-bash-scripts.sh` - Validation

### 📖 Documentation (8)

- 📘 `README.md`
- 📘 `QUICKSTART.md`
- 📘 `SUMMARY.md`
- 📘 `CHEATSHEET.md`
- 📘 `BASH_README.md`
- 📘 `BASH_CONVERSION_REPORT.md`
- 📘 `BASH_COMPLETION.md`
- 📘 `MIGRATION_GUIDE.md`

### ⚙️ Configuration (5)

- ⚙️ `config.yml`
- ⚙️ `.sops.yaml`
- ⚙️ `docker-compose.yml` (généré)
- ⚙️ `traefik/traefik.yml`
- ⚙️ `traefik/dynamic.yml` (généré)

### 🔐 Secrets (2)

- 🔐 `secrets.env` (chiffré)
- 🔐 `secrets.env.example`

### 📋 Profils (5+)

- 📋 `profiles/ui.yml`
- 📋 `profiles/emp.yml`
- 📋 `profiles/andoc.yml`
- 📋 `profiles/recpro.yml`
- 📋 `profiles/example.yml`
- 📋 `profiles/*.yml` (à créer)

---

## 📝 Fichiers à NE PAS Éditer Manuellement

| Fichier | Raison | Commande pour Regénérer |
|---------|--------|------------------------|
| **docker-compose.yml** | Généré automatiquement | `./manage-profiles.sh generate` |
| **traefik/dynamic.yml** | Généré automatiquement | `./manage-profiles.sh generate` |
| **secrets.env** | Chiffré SOPS | `sops secrets.env` |

---

## ✏️ Fichiers Éditables

### Configuration Globale

- ✅ `config.yml` - Activer/désactiver Dozzle, changer port
- ✅ `.sops.yaml` - Configurer clés KMS/Age
- ✅ `traefik/traefik.yml` - Config Traefik statique

### Profils

- ✅ `profiles/*.yml` - Tous les profils sont éditables
  - Après modification : `./manage-profiles.sh generate`

### Secrets

- ✅ `secrets.env` - Via SOPS : `sops secrets.env`
- ✅ `secrets.env.example` - Template en clair

---

## 🔍 Trouver un Fichier

### Par Fonction

| Fonction | Fichier |
|----------|---------|
| **Lancer le menu** | `menu.ps1` ou `menu.sh` |
| **Créer un profil** | `manage-profiles.ps1/.sh add` |
| **Démarrer services** | `launch.ps1/.sh` |
| **Config Dozzle** | `config.yml` |
| **Config SOPS** | `.sops.yaml` |
| **Éditer secrets** | `sops secrets.env` |
| **Profil UI** | `profiles/ui.yml` |
| **Routes Traefik** | `traefik/dynamic.yml` (généré) |
| **Aide démarrage** | `QUICKSTART.md` |
| **Aide bash** | `BASH_README.md` |
| **Migration** | `MIGRATION_GUIDE.md` |
| **Aide-mémoire** | `CHEATSHEET.md` |

### Par Extension

| Extension | Nombre | Usage |
|-----------|--------|-------|
| **.ps1** | 3 | Scripts PowerShell (Windows) |
| **.sh** | 4 | Scripts Bash (Linux/macOS) |
| **.md** | 8 | Documentation Markdown |
| **.yml / .yaml** | 10+ | Configuration YAML |
| **.env** | 2 | Secrets (chiffré + exemple) |

---

## 📦 Dépendances Externes

### Requis

- **Docker** v20.10+
- **Docker Compose** v2.0+
- **SOPS** v3.7+

### Optionnel

- **AWS CLI** v2+ (pour ECR, SSO)
- **Age** v1.0+ (alternative à KMS pour SOPS)
- **ShellCheck** (validation scripts bash)
- **Git** (versioning)

---

## 🎓 Comment Naviguer le Projet

### 1. Premier Contact

1. Lire `README.md`
2. Suivre `QUICKSTART.md`
3. Consulter `CHEATSHEET.md` pour les commandes

### 2. Utilisation Quotidienne

- **Windows** : `.\menu.ps1`
- **Linux** : `./menu.sh`
- Aide : `CHEATSHEET.md`

### 3. Configuration Avancée

1. Éditer `profiles/*.yml`
2. Modifier `config.yml` (Dozzle)
3. Configurer `.sops.yaml` (clés)
4. Regénérer : `./manage-profiles.sh generate`

### 4. Migration

- Windows → Linux : `MIGRATION_GUIDE.md`
- Voir aussi : `BASH_README.md`

### 5. Développement

- Conversion technique : `BASH_CONVERSION_REPORT.md`
- Vue d'ensemble : `SUMMARY.md`

---

## 🔢 Statistiques du Projet

| Métrique | Valeur |
|----------|--------|
| **Total fichiers** | ~25 |
| **Scripts PowerShell** | 3 (1239 lignes) |
| **Scripts Bash** | 4 (1460 lignes) |
| **Documentation** | 8 (3600+ lignes) |
| **Configuration** | 7 fichiers |
| **Profils** | 5+ fichiers |
| **Langages** | 4 (PowerShell, Bash, YAML, Markdown) |
| **Plateformes** | 3 (Windows, Linux, macOS) |
| **Fonctionnalités** | 100% portées |

---

## ✅ Checklist Nouveaux Fichiers

Quand vous créez un nouveau profil :

- [ ] Créer `profiles/nom-service.yml`
- [ ] Regénérer : `./manage-profiles.sh generate`
- [ ] Valider : `docker compose config --quiet`
- [ ] Synchroniser secrets : `./manage-profiles.sh sync-secrets`
- [ ] Éditer secrets : `sops secrets.env`
- [ ] Tester : `./launch.sh --profile nom-service start`
- [ ] Documenter (si nécessaire)
- [ ] Commit Git

---

## 📞 Support et Ressources

| Type | Fichier |
|------|---------|
| **Démarrage rapide** | `QUICKSTART.md` |
| **Commandes** | `CHEATSHEET.md` |
| **Bash/Linux** | `BASH_README.md` |
| **Migration** | `MIGRATION_GUIDE.md` |
| **Technique** | `BASH_CONVERSION_REPORT.md` |
| **Vue globale** | `SUMMARY.md` |
| **Index** | Ce fichier |

---

**Version** : 2.0.0  
**Dernière mise à jour** : 2024  
**Maintenance** : Tous les fichiers générés sont synchronisés  
