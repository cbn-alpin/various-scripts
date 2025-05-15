# Sauvegarde saisie-flore

Script Bash de sauvegarde de l'instance `saisie-flore`  
Fonctionne depuis l’hôte, sans modification des conteneurs.

Le script effectue :
- un dump PostgreSQL compressé (format `pg_dump -Fc | gzip`) via un conteneur éphémère `postgres:15.3-bookworm`
- une copie du code applicatif PHP situé dans `/var/www/html` via `docker cp`
- une archive complète des dossiers locaux de configuration : `./nginx`, `./php` et `./postgres`
- une archive gzip de l’ensemble
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Les identifiants de la base sont récupérés dynamiquement depuis les variables d’environnement du conteneur PostgreSQL.  
Aucun composant n’est modifié, aucun script n’est injecté à l’intérieur des conteneurs.  
Le conteneur utilisé pour le dump est supprimé automatiquement après exécution (`--rm`).

## Structure de sortie

Un dossier : `YYYY-MM-DD_saisie-flore`

Contenu :
- `saisie-flore.dump.pgsql.gz` (dump PostgreSQL compressé)
- `saisie-flore.tar.gz` (archive contenant `/var/www/html` et les trois dossiers locaux)

## Prérequis

- Docker installé sur l’hôte
- Conteneurs suivants actifs :
  - `saisie-flore-postgres`
  - `saisie-flore-php`
- Variables `POSTGRES_USER` et `POSTGRES_PASSWORD` définies dans le conteneur PostgreSQL
- Droits suffisants pour exécuter `docker exec`, `docker cp`, `docker run`
- Accès réseau entre le conteneur éphémère de dump et le conteneur PostgreSQL (`--network container:<nom_du_conteneur>`)
