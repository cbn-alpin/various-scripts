# Sauvegarde cms-cbna-wordpress

Script Bash de sauvegarde de l'instance cms-cbna-wordpress
Fonctionne depuis l’hôte, sans modification des conteneurs.

Le script effectue :
- un dump SQL compressé via mysqldump exécuté depuis un conteneur externe
- une archive gzip des fichiers applicatifs WordPress (/var/www/html)
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Les identifiants de la base sont récupérés dynamiquement depuis les variables d’environnement du conteneur base de données.
Les conteneurs à cibler sont définis en haut du script.

## Structure de sortie

Un dossier : YYYY-MM-DD_nom-logique

Avec les fichiers suivants :
- nom-logique.dump.sql.gz
- nom-logique.html.tar.gz

## Prérequis

- Docker installé sur l’hôte
- Accès à un conteneur MariaDB/MySQL exposant les variables MARIADB_USER et MARIADB_PASSWORD
- Conteneur externe disposant de mysqldump
- Droits suffisants pour exécuter docker exec et docker cp
