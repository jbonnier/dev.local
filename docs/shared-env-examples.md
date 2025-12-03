# 🧪 Exemples Pratiques - Variables Partagées

Ce document contient des exemples concrets d'utilisation des variables d'environnement partagées.

## 📋 Table des matières

1. [Configuration initiale](#configuration-initiale)
2. [Exemple 1 : Microservices avec service discovery](#exemple-1--microservices-avec-service-discovery)
3. [Exemple 2 : APIs externes communes](#exemple-2--apis-externes-communes)
4. [Exemple 3 : Configuration multi-environnement](#exemple-3--configuration-multi-environnement)
5. [Exemple 4 : Variables spécifiques par service](#exemple-4--variables-spécifiques-par-service)

---

## Configuration initiale

### config.yml de base

```yaml
shared_env:
  global:
    - LOG_LEVEL=info
    - NODE_ENV=development
    - TZ=America/Toronto

shared_env_config:
  enabled: true
  auto_inject:
    - global
```

---

## Exemple 1 : Microservices avec service discovery

### Contexte
Vous avez plusieurs microservices qui doivent communiquer entre eux via leurs URLs internes.

### config.yml

```yaml
shared_env:
  global:
    - LOG_LEVEL=info
    - NODE_ENV=development
    - TZ=America/Toronto
  
  # URLs internes entre services
  service_discovery:
    - SERVICE_USER_URL=http://user-service:3000
    - SERVICE_PRODUCT_URL=http://product-service:3000
    - SERVICE_ORDER_URL=http://order-service:3000
    - SERVICE_PAYMENT_URL=http://payment-service:3000
    - SERVICE_NOTIFICATION_URL=http://notification-service:3000

shared_env_config:
  enabled: true
  auto_inject:
    - global
    - service_discovery
```

### Résultat

Tous vos services auront automatiquement accès aux URLs de tous les autres services :

```yaml
# docker-compose.yml (généré)
services:
  order-service:
    environment:
      # Variables partagées (depuis config.yml)
      - LOG_LEVEL=info
      - NODE_ENV=development
      - TZ=America/Toronto
      - SERVICE_USER_URL=http://user-service:3000
      - SERVICE_PRODUCT_URL=http://product-service:3000
      - SERVICE_PAYMENT_URL=http://payment-service:3000
      # ... autres variables du service
```

### Dans votre code

```javascript
// order-service/index.js
const userServiceUrl = process.env.SERVICE_USER_URL;
const paymentServiceUrl = process.env.SERVICE_PAYMENT_URL;

async function createOrder(userId, items) {
  // Appeler le service utilisateur
  const user = await fetch(`${userServiceUrl}/users/${userId}`);
  
  // Appeler le service paiement
  const payment = await fetch(`${paymentServiceUrl}/charge`, {...});
}
```

---

## Exemple 2 : APIs externes communes

### Contexte
Plusieurs de vos services utilisent les mêmes APIs externes (authentification, stockage, etc.).

### config.yml

```yaml
shared_env:
  global:
    - LOG_LEVEL=info
    - NODE_ENV=development
  
  external_apis:
    # Authentification
    - AUTH0_DOMAIN=myapp.auth0.com
    - AUTH0_AUDIENCE=https://api.myapp.com
    
    # AWS Services
    - AWS_REGION=ca-central-1
    - S3_BUCKET=myapp-uploads
    
    # APIs tierces
    - STRIPE_API_URL=https://api.stripe.com/v1
    - SENDGRID_API_URL=https://api.sendgrid.com/v3
    - TWILIO_API_URL=https://api.twilio.com/2010-04-01

shared_env_config:
  auto_inject:
    - global
    - external_apis
```

### profiles/api-backend.yml

```yaml
name: api-backend
docker-compose:
  image: myapp/backend:latest
  environment:
    # Variables partagées injectées automatiquement :
    # - AUTH0_DOMAIN, AWS_REGION, STRIPE_API_URL, etc.
    
    # Variables spécifiques au backend
    - PORT=3000
    - DB_HOST=postgres
    - DB_NAME=myapp
```

### profiles/worker.yml

```yaml
name: worker
docker-compose:
  image: myapp/worker:latest
  environment:
    # Mêmes variables partagées disponibles !
    # - AWS_REGION, S3_BUCKET, SENDGRID_API_URL, etc.
    
    # Variables spécifiques au worker
    - QUEUE_NAME=background-jobs
    - CONCURRENCY=5
```

---

## Exemple 3 : Configuration multi-environnement

### Contexte
Basculer facilement entre dev, staging et prod.

### config.yml

```yaml
shared_env:
  common:
    - TZ=America/Toronto
    - LOG_FORMAT=json
  
  # Environnement de développement
  dev:
    - NODE_ENV=development
    - LOG_LEVEL=debug
    - API_URL=http://localhost:8080
    - DB_HOST=localhost
    - REDIS_HOST=localhost
    - ENABLE_DEBUG_TOOLBAR=true
  
  # Environnement de staging
  staging:
    - NODE_ENV=staging
    - LOG_LEVEL=info
    - API_URL=https://staging-api.myapp.com
    - DB_HOST=staging-db.myapp.com
    - REDIS_HOST=staging-redis.myapp.com
    - ENABLE_DEBUG_TOOLBAR=false
  
  # Environnement de production
  prod:
    - NODE_ENV=production
    - LOG_LEVEL=error
    - API_URL=https://api.myapp.com
    - DB_HOST=prod-db.myapp.com
    - REDIS_HOST=prod-redis.myapp.com
    - ENABLE_DEBUG_TOOLBAR=false

shared_env_config:
  auto_inject:
    - common
    - dev  # ⚡ CHANGER ICI : dev, staging, ou prod
```

### Utilisation

```powershell
# Développement local (par défaut)
.\manage-profiles.ps1 -Action generate
.\launch.ps1

# Basculer vers staging
# 1. Éditer config.yml, changer "dev" en "staging"
# 2. Regénérer
.\manage-profiles.ps1 -Action generate
.\launch.ps1 -c recreate
```

---

## Exemple 4 : Variables spécifiques par service

### Contexte
Certains services ont besoin de variables supplémentaires que d'autres n'utilisent pas.

### config.yml

```yaml
shared_env:
  global:
    - LOG_LEVEL=info
    - NODE_ENV=development
  
  # Variables pour les services qui utilisent une DB
  database:
    - DB_POOL_MIN=5
    - DB_POOL_MAX=20
    - DB_CONNECTION_TIMEOUT=30000
    - DB_STATEMENT_TIMEOUT=60000
  
  # Variables pour les services avec cache
  caching:
    - CACHE_TTL=3600
    - CACHE_PREFIX=myapp
    - CACHE_COMPRESSION=true
  
  # Variables pour les services de messaging
  messaging:
    - MESSAGE_QUEUE_PREFIX=myapp
    - MESSAGE_RETRY_COUNT=3
    - MESSAGE_RETRY_DELAY=5000

shared_env_config:
  auto_inject:
    - global
  
  # Configuration spécifique par service
  service_specific:
    # API backend a besoin de DB et cache
    api-backend:
      - database
      - caching
    
    # Worker a besoin de DB et messaging
    worker:
      - database
      - messaging
    
    # Frontend n'a besoin que du global (rien d'autre)
    frontend: []
    
    # Service analytics a besoin de tout
    analytics:
      - database
      - caching
      - messaging
```

### Résultat

```yaml
# docker-compose.yml

services:
  api-backend:
    environment:
      # Variables globales
      - LOG_LEVEL=info
      - NODE_ENV=development
      # Variables database (service_specific)
      - DB_POOL_MIN=5
      - DB_POOL_MAX=20
      # Variables caching (service_specific)
      - CACHE_TTL=3600
      - CACHE_PREFIX=myapp

  frontend:
    environment:
      # Seulement les variables globales
      - LOG_LEVEL=info
      - NODE_ENV=development
      # Pas de DB, cache ou messaging

  worker:
    environment:
      # Variables globales
      - LOG_LEVEL=info
      - NODE_ENV=development
      # Variables database (service_specific)
      - DB_POOL_MIN=5
      - DB_POOL_MAX=20
      # Variables messaging (service_specific)
      - MESSAGE_QUEUE_PREFIX=myapp
      - MESSAGE_RETRY_COUNT=3
```

---

## Exemple 5 : Exclure certains services

### Contexte
Certains services (Traefik, Dozzle, Redis) n'ont pas besoin des variables métier.

### config.yml

```yaml
shared_env:
  global:
    - LOG_LEVEL=info
    - NODE_ENV=development
  
  business:
    - COMPANY_NAME=MyCompany
    - COMPANY_DOMAIN=mycompany.com
    - SUPPORT_EMAIL=support@mycompany.com

shared_env_config:
  auto_inject:
    - global
    - business
  
  # Services système qui n'ont pas besoin des variables métier
  exclude_services:
    - traefik
    - dozzle
    - redis
    - postgres
    - mongodb
```

### Résultat

```yaml
# docker-compose.yml

services:
  api-backend:
    environment:
      # Reçoit toutes les variables
      - LOG_LEVEL=info
      - NODE_ENV=development
      - COMPANY_NAME=MyCompany
      - COMPANY_DOMAIN=mycompany.com
      - SUPPORT_EMAIL=support@mycompany.com

  redis:
    environment:
      # Aucune variable partagée (exclu)
      # Seulement les variables du profil redis.yml
```

---

## 🎯 Bonnes pratiques

### ✅ Recommandé

1. **Grouper par fonction**
   ```yaml
   shared_env:
     auth:
       - AUTH_URL=...
       - AUTH_TIMEOUT=...
     
     storage:
       - S3_BUCKET=...
       - S3_REGION=...
   ```

2. **Nommer clairement**
   ```yaml
   # ✅ Bon
   - API_GATEWAY_URL=...
   - AUTH_SERVICE_URL=...
   
   # ❌ Mauvais
   - URL1=...
   - SVC=...
   ```

3. **Utiliser des valeurs par défaut raisonnables**
   ```yaml
   # Pour dev local
   - LOG_LEVEL=debug
   - ENABLE_CORS=true
   ```

### ❌ À éviter

1. **Secrets en clair**
   ```yaml
   # ❌ JAMAIS de secrets ici
   shared_env:
     bad:
       - DATABASE_PASSWORD=secret123  # Utiliser secrets.env !
   ```

2. **Trop de variables globales**
   ```yaml
   # ❌ Trop de variables dans global
   global:
     - VAR1=...
     - VAR2=...
     # ... 50 variables ...
   
   # ✅ Mieux : grouper
   database:
     - DB_VAR1=...
     - DB_VAR2=...
   ```

---

## 🔍 Debugging

### Voir les variables injectées

```powershell
# Générer avec affichage détaillé
.\manage-profiles.ps1 -Action generate

# Vérifier dans docker-compose.yml
Get-Content docker-compose.yml | Select-String "Variables partagées" -Context 0,10

# Tester dans un conteneur
docker compose exec mon-service env | grep API_URL
```

### Vérifier l'ordre de priorité

Les variables sont appliquées dans cet ordre (dernière gagne) :

1. Variables partagées (config.yml)
2. Variables du profil (profiles/service.yml)
3. Variables d'environnement du shell (au runtime)

```bash
# Ordre de priorité :
# 1. config.yml shared_env → LOG_LEVEL=info
# 2. profiles/api.yml → LOG_LEVEL=debug (écrase)
# 3. Shell env → LOG_LEVEL=error (écrase)

LOG_LEVEL=error docker compose up api
# Résultat final : LOG_LEVEL=error
```

---

## 📚 Ressources

- [Guide complet](shared-env-guide.md)
- [README.md](../README.md)
- [CHEATSHEET.md](../CHEATSHEET.md)

