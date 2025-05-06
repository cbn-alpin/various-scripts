# Sauvegarde cms-cbna-wordpress

Script Bash de sauvegarde de l'instance `cms-cbna-wordpress`  
Fonctionne depuis l’hôte, sans modification des conteneurs existants.

Le script effectue :
- un dump SQL compressé via `mariadb-dump`, exécuté depuis un conteneur éphémère (`mariadb:11.1-jammy`)
- une archive gzip des fichiers applicatifs WordPress (`/var/www/html`)
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Le conteneur utilisé pour le dump est temporaire et supprimé automatiquement à la fin (`--rm`).  
Les identifiants de la base sont extraits dynamiquement depuis les variables d’environnement du conteneur MariaDB.  
Les noms des conteneurs cibles sont définis en haut du script.

## Structure de sortie

Un dossier : `YYYY-MM-DD_nom-logique`

Contenu :
- `nom-logique.dump.sql.gz`
- `nom-logique.html.tar.gz`

## Prérequis

- Docker installé sur l’hôte  
- Accès à un conteneur MariaDB exposant les variables `MARIADB_USER` et `MARIADB_PASSWORD`  
- Accès réseau entre l’hôte du dump et le conteneur base de données (`--network container:<nom_du_conteneur>`)  
- Droits suffisants pour exécuter `docker exec`, `docker cp` et `docker run --rm`

