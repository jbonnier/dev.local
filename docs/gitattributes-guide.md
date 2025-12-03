# Guide .gitattributes - Dev.Local

## 📋 Vue d'ensemble

Le fichier `.gitattributes` garantit que tous les développeurs, quel que soit leur système d'exploitation, travaillent avec les bonnes fins de ligne pour chaque type de fichier.

## 🎯 Règles appliquées

### Scripts Shell (*.sh)
- **Format :** LF (Line Feed - Unix)
- **Raison :** Les scripts Bash doivent utiliser LF pour fonctionner sur Linux/macOS
- **Impact :** Même sur Windows, les fichiers `.sh` auront LF

### Scripts PowerShell (*.ps1)
- **Format :** CRLF (Windows)
- **Raison :** Convention Windows standard
- **Impact :** Cohérence sur tous les environnements Windows

### Fichiers YAML (*.yml, *.yaml)
- **Format :** LF
- **Raison :** Docker Compose, CI/CD, outils Linux
- **Fichiers concernés :** `docker-compose.yml`, `config.yml`, `profiles/*.yml`

### Documentation (*.md, *.txt)
- **Format :** LF
- **Raison :** Convention GitHub/GitLab, compatibilité multi-plateforme
- **Fichiers concernés :** `README.md`, `QUICKSTART.md`, etc.

### Images (*.png, *.jpg, *.gif)
- **Format :** Binary (aucune conversion)
- **Raison :** Éviter la corruption des fichiers binaires

## 🔍 Vérification

### Vérifier les attributs d'un fichier

```powershell
git check-attr -a launch.sh
```

Résultat attendu :
```
launch.sh: text: set
launch.sh: eol: lf
```

### Vérifier tous les fichiers .sh

```powershell
git check-attr -a *.sh
```

## 🛠️ Que faire après modification de .gitattributes ?

Si vous modifiez `.gitattributes`, les fichiers existants ne sont pas automatiquement re-normalisés. Pour appliquer les nouvelles règles :

```powershell
# 1. Supprimer l'index (ne touche pas aux fichiers locaux)
git rm --cached -r .

# 2. Re-normaliser tous les fichiers
git reset --hard

# 3. Vérifier les changements
git status
```

**⚠️ Attention :** Faites cela sur une branche propre (sans modifications non commitées) !

## ❓ FAQ

### Pourquoi mes fichiers .sh utilisent-ils LF même sur Windows ?

C'est voulu ! Les scripts shell **doivent** utiliser LF pour fonctionner sur Linux/macOS. `.gitattributes` force ce comportement.

### Est-ce que cela affecte mes commits ?

Oui, mais positivement ! Git convertit automatiquement les fins de ligne avant de commiter selon les règles définies. Vous n'avez rien à faire manuellement.

### Que se passe-t-il si j'utilise un éditeur qui force CRLF ?

Git corrigera automatiquement au moment du commit. Le fichier stocké dans le dépôt aura toujours les bonnes fins de ligne.

### Puis-je désactiver ce comportement ?

Techniquement oui, mais **ce n'est pas recommandé** pour un projet multi-plateforme. Cela causerait des bugs sur Linux/macOS.

## 🔗 Ressources

- [Documentation Git Attributes](https://git-scm.com/docs/gitattributes)
- [Guide GitHub fins de ligne](https://docs.github.com/en/get-started/getting-started-with-git/configuring-git-to-handle-line-endings)

## 📝 Historique

- 2025-01-03 : Création initiale du fichier `.gitattributes`
  - Configuration des fins de ligne pour .sh, .ps1, .yml, .md
  - Protection des fichiers binaires

