#!/bin/bash

# Script de sauvegarde du wiki intranet du CBNA

# PRÉ-REQUIS : 
# 1. Installer Anacron : `aptitude install anacron`
# 2. copier sa clé SSH sur l'espace d'hébergement : `ssh-copy-id -i /home/$USER/.ssh/id_rsa.pub cbnalpin@ssh.cluster005.hosting.ovh.net`
# 3. créer un lien vers ce script dans /etc/cron.daily/ sans l'extenssion "".sh"
# ATTENTION : si le script porte l'extenssion ".sh" dans le dossier /etc/cron.daily le script ne se lance pas.
# Pour voir les script qui vont se lancer, utiliser : `run-parts --test /etc/cron.daily`

LOCAL_USER="jpm"
LOCAL_DIR="/home/jpm/Documents/Stockage/backups/wiki-intranet"
ADMIN_EMAIL="jp.milcent@cbn-alpin.fr"
DATE=$(date '+%Y-%m-%d')
DATE_DIR="$LOCAL_DIR/$DATE"
USER="cbnalpin"
HOST="ssh.cluster005.hosting.ovh.net"
DIST_DIR="/homez.342/cbnalpin/wiki-intranet"

sudo -u $LOCAL_USER bash -l -c "rm -fR $DATE_DIR"
sudo -u $LOCAL_USER bash -l -c "mkdir -p $DATE_DIR/conf"
sudo -u $LOCAL_USER bash -l -c "mkdir -p $DATE_DIR/data"
sudo -u $LOCAL_USER bash -l -c "scp -r $USER@$HOST:$DIST_DIR/conf $DATE_DIR/conf"
sudo -u $LOCAL_USER bash -l -c "scp -r $USER@$HOST:$DIST_DIR/data/attic $DATE_DIR/data/attic"
sudo -u $LOCAL_USER bash -l -c "scp -r $USER@$HOST:$DIST_DIR/data/media $DATE_DIR/data/media"
sudo -u $LOCAL_USER bash -l -c "scp -r $USER@$HOST:$DIST_DIR/data/media_attic $DATE_DIR/data/media_attic"
sudo -u $LOCAL_USER bash -l -c "scp -r $USER@$HOST:$DIST_DIR/data/media_meta $DATE_DIR/data/media_meta"
sudo -u $LOCAL_USER bash -l -c "scp -r $USER@$HOST:$DIST_DIR/data/meta $DATE_DIR/data/meta"
sudo -u $LOCAL_USER bash -l -c "scp -r $USER@$HOST:$DIST_DIR/data/pages $DATE_DIR/data/pages"

subject="Wiki Intranet - Sauvegarde subject"
message="Sauvegarde du wiki Intranet terminée à $(date '+%Y-%m-%d %T')."
echo "${message}" | mail -s "${subject}" "${ADMIN_EMAIL}"