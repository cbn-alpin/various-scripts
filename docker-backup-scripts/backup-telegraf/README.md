# Sauvegarde telegraf

Script Bash de sauvegarde de l'instance `telegraf`  
Fonctionne depuis l’hôte, sans modification du conteneur.

Le script effectue :
- une copie du fichier de configuration Telegraf (`telegraf.conf`)
- une copie facultative du fichier `telegraf.sample.conf` s’il est présent
- une copie du fichier de statut `status.json` monté dans `/opt/srvstatus/status.json` s’il est présent
- une archive gzip de l’ensemble
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Aucune base de données n’est concernée.  
Le conteneur envoie ses métriques via UDP et se contente de lire les fichiers système via des montages.

## Structure de sortie

Un dossier : `YYYY-MM-DD_telegraf`

Contenu :
- `telegraf.tar.gz` (archive des fichiers `telegraf.conf`, `telegraf.sample.conf`, `status.json` si existant)

