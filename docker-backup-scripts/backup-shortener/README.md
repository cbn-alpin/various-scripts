# Sauvegarde shortener

Script Bash de sauvegarde de l'instance `shortener`  
Fonctionne depuis l’hôte, sans modification des conteneurs existants.

Le script effectue :
- un dump SQL compressé de la base MariaDB (`shlink`), via `mariadb-dump` exécuté depuis un conteneur éphémère (`mariadb:11.1-jammy`)
- une copie complète du dossier `./mariadb/initdb.d/` (scripts SQL d’initialisation)
- une copie complète du dossier `./shlink/config/` (configuration frontend)
- une archive gzip de l’ensemble
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Les identifiants de la base sont extraits dynamiquement depuis les variables d’environnement du conteneur MariaDB.  
Le conteneur temporaire utilisé pour le dump est supprimé automatiquement à la fin (`--rm`).

## Structure de sortie

Un dossier : `YYYY-MM-DD_shortener`

Contenu :
- `shortener.dump.sql.gz` (dump compressé de la base de données `shlink`)
- `shortener.tar.gz` (archive des fichiers locaux `mariadb/initdb.d/` et `shlink/config/`)

