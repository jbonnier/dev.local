# 🔄 Variables d'Environnement Partagées

## 📋 Vue d'ensemble

Le système de variables d'environnement partagées permet de définir des variables communes qui seront automatiquement injectées dans tous vos services Docker. Ceci est particulièrement utile pour :

- 🌐 **URLs de services externes** - APIs, services d'authentification, passerelles
- 🔧 **Configuration commune** - Log level, timezone, environnement
- 📊 **Paramètres partagés** - Taille de pool, timeouts, limites
- 🔗 **Référencement de variables** - Renommer ou adapter des variables existantes pour un service spécifique

## 🎯 Configuration

### Fichier `config.yml`

Les variables partagées sont définies dans `config.yml` sous la section `shared_env` :

```yaml
shared_env:
  # Variables globales pour tous les services
  global:
    - LOG_LEVEL=info
    - NODE_ENV=development
    - TZ=America/Toronto
  
  # Variables pour des services externes
  external_services:
    - API_GATEWAY_URL=https://api.example.com
    - AUTH_SERVICE_URL=https://auth.example.com
    - MESSAGING_SERVICE_URL=https://messaging.example.com
  
  # Variables personnalisées
  custom:
    - DATABASE_POOL_SIZE=10
    - CACHE_TTL=3600
```

### Configuration de l'injection

```yaml
shared_env_config:
  # Activer/désactiver l'injection automatique
  enabled: true
  
  # Groupes injectés automatiquement dans TOUS les services
  auto_inject:
    - global
    - external_services
  
  # Exclure certains services de l'injection automatique
  exclude_services:
    - traefik
    - dozzle
  
  # Groupes spécifiques pour certains services
  service_specific:
    mon-api:
      - custom
    mon-frontend:
      - custom
```

## 🔗 Référencement de variables existantes

### Utiliser une variable déjà définie

Vous pouvez référencer une variable partagée existante pour la renommer ou l'adapter à un service spécifique. Docker Compose résoudra automatiquement la référence au runtime.

#### Exemple : Renommer une variable pour un service

```yaml
shared_env:
  # Variables globales
  external_services:
    - API_GATEWAY_URL=https://api.example.com
    - AUTH_SERVICE_URL=https://auth.example.com
  
  # Variables spécifiques au service 'demo'
  demo_only:
    - DEMO_ONLY_VAR=demo-only-value
    # Référencer une variable existante sous un autre nom
    - DEMO_API_GATEWAY_URL=${API_GATEWAY_URL}
    # Ou avec une valeur de fallback
    - DEMO_AUTH_URL=${AUTH_SERVICE_URL:-https://auth.fallback.com}

shared_env_config:
  auto_inject:
    - external_services
  
  service_specific:
    demo:
      - demo_only
```

**Résultat dans docker-compose.yml :**

```yaml
services:
  demo:
    environment:
      # Variables partagées (depuis config.yml)
      - API_GATEWAY_URL=https://api.example.com
      - AUTH_SERVICE_URL=https://auth.example.com
      - DEMO_ONLY_VAR=demo-only-value
      - DEMO_API_GATEWAY_URL=${API_GATEWAY_URL}
      # Variables du service (profil)
      - ENVIRONMENT=docker-compose
```

Docker Compose remplacera `${API_GATEWAY_URL}` par `https://api.example.com` au démarrage du conteneur.

#### Cas d'usage typiques

**1. Adaptation d'URL pour un service legacy :**
```yaml
shared_env:
  legacy_adapter:
    # Le service legacy attend LEGACY_API_URL au lieu de API_GATEWAY_URL
    - LEGACY_API_URL=${API_GATEWAY_URL}
    - LEGACY_DB_HOST=${DATABASE_HOST}
```

**2. Préfixage pour isolation :**
```yaml
shared_env:
  service_a_config:
    # Préfixer toutes les variables pour ce service
    - SERVICE_A_API=${API_GATEWAY_URL}
    - SERVICE_A_AUTH=${AUTH_SERVICE_URL}
```

**3. Override conditionnel avec fallback :**
```yaml
shared_env:
  dev_overrides:
    # Utiliser une variable d'environnement système si définie, sinon la valeur partagée
    - MY_API_URL=${OVERRIDE_API_URL:-${API_GATEWAY_URL}}
```

**4. Composition de valeurs :**
```yaml
shared_env:
  composed:
    # Créer une nouvelle variable à partir d'une existante
    - FULL_API_URL=${API_GATEWAY_URL}/v1/api
    - HEALTH_CHECK_URL=${API_GATEWAY_URL}/health
```

### ⚠️ Notes importantes

1. **Ordre d'injection** : Les variables partagées sont injectées AVANT les variables du profil
2. **Résolution Docker Compose** : La substitution `${VAR}` est effectuée par Docker Compose au runtime
3. **Variables disponibles** : Seules les variables déjà définies plus haut dans la liste peuvent être référencées
4. **Commentaires** : Les commentaires entre items de liste sont supportés et ignorés lors du parsing

### 💡 Astuce : Voir les valeurs résolues

Pour voir les valeurs finales après substitution :

```bash
# Afficher la configuration résolue d'un service
docker compose config demo

# Ou voir toutes les variables d'environnement dans le conteneur
docker compose exec demo env | sort
```

## 🚀 Utilisation

### 1. Définir des variables partagées

Éditez `config.yml` et ajoutez vos variables dans un groupe :

```yaml
shared_env:
  mon_groupe:
    - MA_VARIABLE=ma_valeur
    - AUTRE_VARIABLE=autre_valeur
```

### 2. Configurer l'injection automatique

Ajoutez votre groupe aux `auto_inject` pour l'appliquer à tous les services :

```yaml
shared_env_config:
  auto_inject:
    - global
    - mon_groupe
```

### 3. Regénérer docker-compose.yml

```powershell
.\manage-profiles.ps1 -Action generate
```

Le script affichera le nombre de variables partagées injectées dans chaque service.

## 📝 Exemples d'utilisation

### Exemple 1 : URLs de services externes

```yaml
shared_env:
  external_services:
    - API_GATEWAY_URL=https://api.mycompany.com
    - AUTH_SERVICE_URL=https://auth.mycompany.com
    - STORAGE_SERVICE_URL=https://storage.mycompany.com

shared_env_config:
  auto_inject:
    - external_services
```

**Résultat :** Tous vos services auront accès à ces 3 URLs sans les redéfinir.

### Exemple 2 : Configuration par environnement

```yaml
shared_env:
  development:
    - NODE_ENV=development
    - LOG_LEVEL=debug
    - ENABLE_DEBUG=true
  
  production:
    - NODE_ENV=production
    - LOG_LEVEL=error
    - ENABLE_DEBUG=false

shared_env_config:
  auto_inject:
    - development  # Changer en 'production' pour prod
```

### Exemple 3 : Variables spécifiques à certains services

```yaml
shared_env:
  database_config:
    - DB_POOL_MIN=5
    - DB_POOL_MAX=20
    - DB_TIMEOUT=30000

shared_env_config:
  # Ne pas injecter automatiquement
  auto_inject: []
  
  # Seulement pour les services qui ont besoin de DB
  service_specific:
    api-backend:
      - database_config
    worker-service:
      - database_config
```

### Exemple 4 : Exclure certains services

```yaml
shared_env_config:
  auto_inject:
    - global
  
  # Traefik et Dozzle n'ont pas besoin des variables métier
  exclude_services:
    - traefik
    - dozzle
    - redis
```

## 🔍 Vérification

### Voir les variables injectées

Après génération, vérifiez `docker-compose.yml` :

```yaml
services:
  mon-service:
    image: mon-image
    environment:
      # Variables partagées (depuis config.yml)
      - LOG_LEVEL=info
      - NODE_ENV=development
      - API_GATEWAY_URL=https://api.example.com
      # Variables spécifiques au service
      - SERVICE_PORT=8000
```

### Tester dans le conteneur

```bash
docker compose exec mon-service env | grep API_GATEWAY_URL
```

## 🎨 Bonnes pratiques

### ✅ À faire

1. **Grouper logiquement** - Créez des groupes cohérents (auth, database, logging, etc.)
2. **Documenter** - Ajoutez des commentaires dans `config.yml`
3. **Utiliser des valeurs par défaut** - Pour les environnements de développement
4. **Centraliser** - Toutes les URLs externes dans un seul groupe
5. **Versionner** - `config.yml` doit être dans Git

### ❌ À éviter

1. **Secrets** - NE JAMAIS mettre de secrets ici ! Utilisez `secrets.env` avec SOPS
2. **Mélanger** - Ne pas mélanger config dev et prod dans le même groupe
3. **Trop de variables** - Si > 20 variables, créer des sous-groupes
4. **Hardcoder les IPs** - Utiliser des noms DNS ou des variables d'environnement

## 🔐 Secrets vs Variables partagées

| Type | Utilisation | Fichier | Chiffré |
|------|-------------|---------|---------|
| **Variables partagées** | Configuration non-sensible | `config.yml` | ❌ Non |
| **Secrets** | Mots de passe, tokens, clés | `secrets.env` | ✅ Oui (SOPS) |

### Exemple

```yaml
# ✅ BON - config.yml (variables partagées)
shared_env:
  services:
    - AUTH_SERVICE_URL=https://auth.example.com
    - LOG_LEVEL=info

# ❌ MAUVAIS - NE PAS mettre de secrets ici !
shared_env:
  bad_practice:
    - DATABASE_PASSWORD=supersecret123  # ❌ Utiliser secrets.env !
```

## 🔧 Cas d'usage avancés

### Cas 1 : Multi-environnement

Créez des groupes par environnement et changez `auto_inject` selon le besoin :

```yaml
shared_env:
  common:
    - TZ=America/Toronto
  
  dev:
    - API_URL=http://localhost:8000
    - DEBUG=true
  
  staging:
    - API_URL=https://staging.example.com
    - DEBUG=false
  
  prod:
    - API_URL=https://api.example.com
    - DEBUG=false

shared_env_config:
  auto_inject:
    - common
    - dev  # Changer selon l'environnement
```

### Cas 2 : Feature flags

```yaml
shared_env:
  feature_flags:
    - FEATURE_NEW_UI=true
    - FEATURE_BETA_API=false
    - FEATURE_ANALYTICS=true

shared_env_config:
  auto_inject:
    - feature_flags
```

### Cas 3 : Microservices discovery

```yaml
shared_env:
  service_discovery:
    - SERVICE_USER_URL=http://user-service:3000
    - SERVICE_PRODUCT_URL=http://product-service:3000
    - SERVICE_ORDER_URL=http://order-service:3000
    - SERVICE_PAYMENT_URL=http://payment-service:3000

shared_env_config:
  auto_inject:
    - service_discovery
```

## 📊 Workflow complet

```powershell
# 1. Éditer la configuration
notepad config.yml

# 2. Ajouter des variables partagées
# shared_env:
#   mon_groupe:
#     - MA_VAR=valeur

# 3. Regénérer docker-compose.yml
.\manage-profiles.ps1 -Action generate

# 4. Vérifier le résultat
Get-Content docker-compose.yml | Select-String "MA_VAR"

# 5. Relancer les services
.\launch.ps1 -c recreate
```

## ❓ FAQ

### Q: Les variables partagées écrasent-elles les variables spécifiques ?

**R:** Non ! Les variables du profil sont ajoutées APRÈS les variables partagées. Si une variable existe dans les deux, la version du profil prend la priorité.

### Q: Puis-je désactiver temporairement l'injection ?

**R:** Oui, mettez `enabled: false` dans `shared_env_config`.

### Q: Comment voir quelles variables sont injectées ?

**R:** Lors de la génération, le script affiche : `📌 X variable(s) partagée(s)` pour chaque service.

### Q: Puis-je utiliser des variables dans les valeurs ?

**R:** Non directement dans `config.yml`, mais vous pouvez utiliser `${VAR:-default}` dans les profils qui référencent des variables de `secrets.env`.

### Q: Les variables partagées sont-elles disponibles au build ?

**R:** Non, seulement au runtime. Pour le build, utilisez `args:` dans votre profil.

## 🔗 Ressources

- [Docker Compose - Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [12 Factor App - Config](https://12factor.net/config)
- [Documentation Dev.Local - README.md](../README.md)

## 📝 Historique

- 2025-01-03 : Création de la fonctionnalité de variables partagées
- Support de groupes multiples
- Support d'injection sélective par service
- Support d'exclusion de services
