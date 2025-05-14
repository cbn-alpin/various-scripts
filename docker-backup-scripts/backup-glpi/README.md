# Sauvegarde GLPI

Script Bash de sauvegarde de l'instance `GLPI`  
Fonctionne depuis l’hôte, sans modification des conteneurs.

Le script effectue :
- un **dump SQL compressé** via `mariadb-dump`, exécuté dans un conteneur éphémère (`mariadb:11.1-jammy`)
- une **archive gzip** des répertoires applicatifs :
  - `/app/config`
  - `/app/data`
  - `/app/glpi` (incluant les plugins, la marketplace, les templates, etc.)
- une **rotation automatique** des sauvegardes basée sur la date (suppression des dossiers trop anciens)

Les identifiants de connexion à la base de données sont extraits dynamiquement depuis les variables d’environnement du conteneur MariaDB.  
Le conteneur temporaire utilisé pour le dump est automatiquement supprimé après exécution (`--rm`).  
Les noms des conteneurs (`glpi` et `glpi-mariadb`) sont définis en haut du script.

## Structure de sortie

Un dossier par sauvegarde, nommé :  
`YYYY-MM-DD_glpi`

Contenu :
- `glpi.dump.sql.gz` → dump SQL compressé
- `glpi.files.tar.gz` → archive complète de la configuration, des données et du code GLPI

## Prérequis

- Docker installé sur l’hôte  
- Accès à un conteneur MariaDB exposant les variables `MARIADB_USER` et `MARIADB_PASSWORD`  
- Accès réseau entre l’hôte du dump et le conteneur base de données (`--network container:<nom_du_conteneur>`)  
- Droits suffisants pour exécuter `docker exec`, `docker cp` et `docker run --rm`
