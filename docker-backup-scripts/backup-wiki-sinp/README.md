# Sauvegarde wiki-sinp

Script Bash de sauvegarde de l'instance `wiki-sinp` (DokuWiki)  
Fonctionne depuis l’hôte, sans modification des conteneurs.

Le script effectue :
- une copie des volumes montés (via `docker cp`) depuis le conteneur `wiki-sinp-dokuwiki`, notamment :
  - `/var/www/html` (structure complète du wiki)
  - `/var/www/html/conf` (fichiers de configuration)
  - `/var/www/html/data` (contenus, pages, historiques)
  - `/var/www/html/lib/plugins` (plugins installés)
  - `/var/www/html/lib/tpl` (templates personnalisés)
- une copie intégrale des dossiers de configuration locaux :
  - `./nginx/`
  - `./dokuwiki/`
  - le fichier `.env` s’il est présent
- une archive gzip de l’ensemble
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Aucune base de données n’est utilisée par ce wiki.  
Les données sont stockées directement dans les volumes montés.

## Structure de sortie

Un dossier : `YYYY-MM-DD_wiki-sinp`

Contenu :
- `wiki-sinp.tar.gz` (archive complète du site et de sa configuration)
