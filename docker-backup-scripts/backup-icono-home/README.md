# Sauvegarde icono-home

Script Bash de sauvegarde de l’instance `icono-home`  
Fonctionne depuis l’hôte, sans modification des conteneurs.

Le script effectue :
- une copie du contenu statique du site (`/usr/share/nginx/html`) depuis le conteneur `icono-home-nginx`
- une archive gzip de ces fichiers
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Aucune base de données n’est utilisée.  
Le script n’accède qu’à un seul conteneur (NGINX).  
Les fichiers sont copiés via `docker cp`, archivés, puis le répertoire temporaire est supprimé.

## Structure de sortie

Un dossier : `YYYY-MM-DD_icono-home`

Contenu :
- `icono-home.html.tar.gz`

## Prérequis

- Docker installé sur l’hôte  
- Conteneur `icono-home-nginx` actif  
- Droits suffisants pour exécuter `docker cp`  
- Le contenu du site doit se trouver dans `/usr/share/nginx/html` à l’intérieur du conteneur
