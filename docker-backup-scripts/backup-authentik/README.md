# Sauvegarde authentik

Script Bash de sauvegarde de l'instance `authentik`  
Fonctionne depuis l’hôte, sans modification des conteneurs.

Le script effectue :
- un dump SQL compressé via `pg_dump`, exécuté dans un conteneur éphémère (`postgres:16-alpine`)
- une archive gzip des répertoires `media` et `templates` de l'instance Authentik (`/media` et `/templates`)
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Le conteneur temporaire utilisé pour le dump est automatiquement supprimé après exécution (`--rm`).  
Les identifiants de la base sont récupérés dynamiquement depuis les variables d’environnement du conteneur PostgreSQL.  
Les noms des conteneurs à cibler sont définis en haut du script.

## Structure de sortie

Un dossier : `YYYY-MM-DD_nom-logique`

Contenu :
- `nom-logique.dump.sql.gz`
- `nom-logique.media-templates.tar.gz`

## Prérequis

- Docker installé sur l’hôte  
- Accès à un conteneur PostgreSQL exposant les variables `POSTGRES_USER` et `POSTGRES_PASSWORD`  
- Accès réseau entre l’hôte du dump et le conteneur base de données (`--network container:<nom_du_conteneur>`)  
- Droits suffisants pour exécuter `docker exec`, `docker cp` et `docker run --rm`
