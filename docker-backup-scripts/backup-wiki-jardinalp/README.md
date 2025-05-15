# Sauvegarde wiki-jardinalp

Script Bash de sauvegarde de l'instance `wiki-jardinalp`  
Fonctionne depuis l’hôte, sans modification des conteneurs existants.

Le script effectue :
- un dump SQL complet de la base MariaDB via un conteneur éphémère `mariadb:11.1.2-jammy`
- une copie complète du volume `/var/www/html` du conteneur `wiki-jardinalp-php` (contenu applicatif YesWiki)
- une copie complète des dossiers locaux suivants :
  - `./yeswiki` (contenu du build Docker, thèmes, scripts…)
  - `./nginx` (configuration Nginx spécifique au wiki)
  - `./mariadb` (scripts d’initialisation de la base)
- deux archives gzip distinctes :
  - `wiki-jardinalp.html.tar.gz` (contenu du wiki depuis le conteneur)
  - `wiki-jardinalp.localdirs.tar.gz` (dossiers locaux)
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Aucune donnée externe ni volume non explicitement monté n’est inclus.  
Le script se contente de capturer l’état actuel du wiki et de son environnement local tel que configuré dans le dossier `wiki-jardinalp`.

## Structure de sortie

Un dossier : `YYYY-MM-DD_wiki-jardinalp`

Contenu :
- `wiki-jardinalp.dump.sql.gz` (dump de la base MariaDB)
- `wiki-jardinalp.html.tar.gz` (volume applicatif du wiki)
- `wiki-jardinalp.localdirs.tar.gz` (dossiers locaux yeswiki, mariadb, nginx)
