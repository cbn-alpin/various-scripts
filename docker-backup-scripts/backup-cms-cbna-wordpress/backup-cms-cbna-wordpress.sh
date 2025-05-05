#!/bin/bash

set -e
set -o pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# nom logique de la sauvegarde
nom_sauvegarde="cms-cbna-wordpress"

# répertoire de travail
repertoire_sauvegarde="/home/admin/docker/cms-cbna-wordpress-test/backups"
date_du_jour=$(date +%F)
dossier_cible="${repertoire_sauvegarde}/${date_du_jour}_${nom_sauvegarde}"
dossier_temporaire="${dossier_cible}/tmp"
retenue_jours=2

# conteneurs utilisés
conteneur_bdd="cms-cbna-mariadb"
conteneur_site="cms-cbna-wordpress"
conteneur_dump="cms-cbna-backup-cron"

# base de données à sauvegarder
nom_base="wordpress"
port_bdd=3306
options_dump="--single-transaction --quick --lock-tables=false"

echo "----------------------------------------"
echo "DÉMARRAGE DE LA SAUVEGARDE : ${date_du_jour}"
echo "Nom logique : ${nom_sauvegarde}"
echo "Répertoire de travail : ${dossier_cible}"
echo "Conteneur base de données : ${conteneur_bdd}"
echo "Conteneur site web : ${conteneur_site}"
echo "Conteneur pour le dump : ${conteneur_dump}"
echo "----------------------------------------"

# suppression préalable du répertoire si déjà présent
if [ -d "${dossier_cible}" ]; then
    echo "Le dossier de destination existe déjà, suppression..."
    rm -rf "${dossier_cible}"
fi

# création des répertoires
echo "Création du répertoire de sauvegarde..."
mkdir -p "${dossier_temporaire}"

# récupération des identifiants
echo "Extraction des identifiants depuis le conteneur base de données..."
utilisateur_bdd=$(docker exec ${conteneur_bdd} printenv MARIADB_USER)
motdepasse_bdd=$(docker exec ${conteneur_bdd} printenv MARIADB_PASSWORD)

# dump SQL
echo "Export de la base de données '${nom_base}'..."
docker exec ${conteneur_dump} mysqldump --host=${conteneur_bdd} --port=${port_bdd} ${options_dump} -u${utilisateur_bdd} -p${motdepasse_bdd} ${nom_base} | gzip > "${dossier_cible}/${nom_sauvegarde}.dump.sql.gz"
echo "Dump SQL terminé : ${nom_sauvegarde}.dump.sql.gz"

# copie des fichiers applicatifs
echo "Copie des fichiers du site WordPress..."
docker cp ${conteneur_site}:/var/www/html "${dossier_temporaire}/html"

echo "Archivage des fichiers applicatifs..."
tar czf "${dossier_cible}/${nom_sauvegarde}.html.tar.gz" -C "${dossier_temporaire}" html
echo "Archive créée : ${nom_sauvegarde}.html.tar.gz"

# nettoyage
echo "Nettoyage du dossier temporaire..."
rm -rf "${dossier_temporaire}"

# rotation
echo "Suppression des sauvegardes de plus de ${retenue_jours} jours..."
find "${repertoire_sauvegarde}" -mindepth 1 -maxdepth 1 -type d -name "*_${nom_sauvegarde}" -mtime +${retenue_jours} -exec rm -rf {} \;

echo "Sauvegarde terminée avec succès."
exit 0
