# Scripts de sauvegarde Docker

Ce répertoire regroupe une série de scripts Bash conçus pour automatiser les sauvegardes de conteneurs Docker  
dans des environnements de production ou de pré-production.

## Objectifs

- Permettre la sauvegarde de services conteneurisés (bases de données, fichiers applicatifs, etc.)
- Conserver une approche non intrusive (aucune modification des images Docker en production)
- Externaliser les opérations de dump et de copie, en utilisant des conteneurs utilitaires existants
- Garantir des sauvegardes exploitables indépendamment du système de gestion de conteneurs
- Faciliter l'intégration dans des tâches `cron`

## Fonctionnement général

Chaque sous-dossier contient :
- Un script principal (`backup.sh`)
- Un `README.md` spécifique décrivant le périmètre et les prérequis
- Éventuellement un fichier `cron`, un Dockerfile d'utilitaire ou des exemples

Les scripts utilisent les commandes standard de Docker (`docker exec`, `docker cp`) pour :
- Identifier dynamiquement les informations d'accès à la base
- Réaliser les dumps avec compression
- Archiver les fichiers applicatifs
- Gérer une rotation automatique des sauvegardes (basée sur l'âge)

## Avertissement

Aucune donnée confidentielle n'est présente dans ce dépôt.  
Les mots de passe et autres secrets sont récupérés dynamiquement depuis les variables d'environnement des conteneurs concernés.
