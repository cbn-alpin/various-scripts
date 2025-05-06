# Sauvegarde cms-cbna-joomla

Script Bash de sauvegarde de l'instance `cms-cbna-joomla`  
Fonctionne depuis l’hôte, sans modification des conteneurs.

Le script effectue :
- un dump SQL compressé via `mariadb-dump`, exécuté dans un conteneur éphémère (`mariadb:11.1-jammy`)
- une archive gzip des fichiers applicatifs Joomla (`/var/www/html`)
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Le conteneur temporaire utilisé pour le dump est automatiquement supprimé après exécution (`--rm`).  
Les identifiants de la base sont récupérés dynamiquement depuis les variables d’environnement du conteneur MariaDB.  
Les noms des conteneurs à cibler sont définis en haut du script.

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

