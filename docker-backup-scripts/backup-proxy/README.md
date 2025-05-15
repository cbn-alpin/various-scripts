# Sauvegarde proxy

Script Bash de sauvegarde de la stack `proxy` (nginx-proxy / docker-gen / acme-companion)  
Fonctionne depuis l’hôte, sans modification des conteneurs existants.

Le script effectue :
- une copie complète des répertoires montés des trois conteneurs (certificats, configuration Nginx, templates, ACME, etc.)
- une copie des fichiers locaux montés dans les conteneurs (`./docker-gen/`, `./nginx/`)
- une archive gzip unique de l’ensemble
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Aucune base de données n’est présente, aucun conteneur éphémère n’est utilisé.  
La sauvegarde repose sur des appels `docker cp` pour extraire les données internes aux conteneurs, et des copies classiques pour les fichiers locaux.  
Les noms des conteneurs et chemins sont définis en haut du script.

## Structure de sortie

Un dossier : `YYYY-MM-DD_proxy`

Contenu :
- `proxy.tar.gz` (archive unique contenant tous les fichiers extraits des conteneurs et des montages locaux)

## Prérequis

- Docker installé sur l’hôte  
- Conteneurs cibles en fonctionnement (`nginx-proxy`, `nginx-proxy-gen`, `nginx-proxy-letsencrypt`)  
- Droits suffisants pour exécuter `docker cp`
