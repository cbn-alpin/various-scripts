# Sauvegarde borgmatic

Script Bash de sauvegarde de l'instance `borgmatic`  
Fonctionne depuis l’hôte, sans modification des conteneurs existants.

Le script effectue :
- une copie complète des fichiers de configuration utilisés par le conteneur :
  - `/root/.config/borg`
  - `/root/.config/ntfy`
  - `/etc/borgmatic.d`
  - `/etc/aliases`
  - `/root/.ssh`
  - `/root/.cache/borg`
- une copie complète des dossiers locaux du dépôt :
  - `./config/` (fichiers de configuration borgmatic, ntfy, aliases)
  - `./build/` (scripts utilisés dans l’image Docker)
  - `./msmtp.env` (variables de messagerie)
- une archive gzip de l’ensemble
- une rotation automatique des sauvegardes (suppression des sauvegardes trop anciennes)

Aucune donnée du dépôt Borg lui-même n’est incluse dans cette sauvegarde (il est considéré comme cible de la sauvegarde, pas source).  
Le script se contente d’archiver l’ensemble des configurations et clés nécessaires pour restaurer l’outil ou reconstruire le conteneur.

## Structure de sortie

Un dossier : `YYYY-MM-DD_borgmatic`

Contenu :
- `borgmatic.tar.gz` (archive de tous les fichiers mentionnés ci-dessus)

