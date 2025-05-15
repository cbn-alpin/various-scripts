# Sauvegarde pgadmin

Script Bash de sauvegarde de l'instance `pgadmin`  
Fonctionne depuis l’hôte, sans modification des conteneurs.

Le script effectue :
- une copie du répertoire de données internes (`/var/lib/pgadmin`)
- une copie du fichier de connexions enregistrées (`/pgadmin4/servers.json`)
- une archive gzip de l’ensemble
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Aucune base de données n’est incluse dans cette sauvegarde.  
Le conteneur ne sert que d’interface web à distance pour gérer des PostgreSQL externes.  
Aucune variable d’environnement n’est requise pour la sauvegarde.  
Le dossier `/bkp` n’est **pas sauvegardé**, car il correspond au répertoire local de destination et pourrait créer une boucle récursive.

## Structure de sortie

Un dossier : `YYYY-MM-DD_pgadmin`

Contenu :
- `pgadmin.data.tar.gz`

## Prérequis

- Docker installé sur l’hôte  
- Conteneur `pgadmin-app` actif  
- Droits suffisants pour exécuter `docker cp`  
- Le répertoire de sauvegarde ne doit pas être monté dans le conteneur sous `/bkp`
