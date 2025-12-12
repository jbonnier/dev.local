# 🔐 Guide de Gestion des Secrets avec SOPS et Age

Ce guide explique comment configurer et utiliser SOPS avec Age pour chiffrer les secrets dans ce projet.

## 1. Prérequis

Assurez-vous que `sops` et `age` sont installés sur votre machine (installés par défaut via le script d'initialisation ou manuellement).

## 2. Configuration de la Clé Age

Une clé Age est une paire de clés (privée/publique) utilisée pour chiffrer et déchiffrer les secrets.

### Générer une nouvelle clé

Si vous n'avez pas encore de clé, générez-en une :

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Cela créera un fichier `keys.txt` contenant votre clé privée. **Ne partagez jamais ce fichier.**

### Obtenir votre clé publique

Pour voir votre clé publique (nécessaire pour la configuration) :

```bash
grep "public key" ~/.config/sops/age/keys.txt
```

Exemple de sortie :
`# public key: age1l6gmgtjxjx9jx09j3umljfkren9dy8nmuet5tnqatxfddjkj89js2gn27m`

## 3. Configuration du Projet (.sops.yaml)

Pour que SOPS sache quelle clé utiliser pour chiffrer les fichiers, ouvrez le fichier `.sops.yaml` à la racine du projet et ajoutez votre clé publique dans la section `age`.

```yaml
creation_rules:
  - path_regex: secrets\.env$
    age: 'age1l6gmgtjxjx9jx09j3umljfkren9dy8nmuet5tnqatxfddjkj89js2gn27m' # Remplacez par VOTRE clé publique
    encrypted_regex: '^.*$' # Chiffre tout sauf les commentaires
```

## 4. Utilisation

### Éditer les secrets

Pour modifier ou ajouter des secrets, n'éditez **jamais** `secrets.env` directement avec un éditeur de texte standard. Utilisez toujours la commande suivante :

```bash
./launch.sh edit-secrets
# ou
./launch.ps1 -c edit-secrets
```

Cela ouvrira le fichier déchiffré dans votre éditeur par défaut. À la fermeture, SOPS rechiffrera automatiquement le fichier.

### Voir les secrets

Pour afficher les secrets déchiffrés dans le terminal sans les modifier :

```bash
./launch.sh view-secrets
```

### Initialiser un nouveau fichier de secrets

Si `secrets.env` n'existe pas :

```bash
./manage-profiles.sh init-secrets
```

## 5. Dépannage

- **Erreur "Aucune méthode de chiffrement configurée"** : Vérifiez que `.sops.yaml` contient bien une ligne `age:` ou `kms:` valide et non commentée.
- **Erreur de déchiffrement** : Assurez-vous que votre clé privée est bien dans `~/.config/sops/age/keys.txt` et qu'elle correspond à la clé publique dans `.sops.yaml` qui a été utilisée pour chiffrer le fichier.
