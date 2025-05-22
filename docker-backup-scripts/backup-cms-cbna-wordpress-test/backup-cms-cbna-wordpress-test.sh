#!/bin/bash
# Auteur : Arnaud Ungaro
# Structure : CBNA (Conservatoire Botanique National Alpin)
# Année : 2025
# Script de sauvegarde de l’instance WordPress de test (cms-cbna-wordpress-test)

set -e
set -o pipefail

cd "$(dirname "$0")"

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# nom logique de la sauvegarde
nom_sauvegarde="cms-cbna-wordpress-test"

# répertoire de travail
repertoire_sauvegarde="/home/admin/docker/cms-cbna-wordpress-test/backups"
date_du_jour=$(date +%F)
dossier_cible="${repertoire_sauvegarde}/${date_du_jour}_${nom_sauvegarde}"
dossier_temporaire="${dossier_cible}/tmp"
retenue_jours=2

# conteneurs utilisés
conteneur_bdd="cms-cbna-test-mariadb"
conteneur_site="cms-cbna-test-wordpress"

# base de données à sauvegarder
nom_base="wordpress"
port_bdd=3306
options_dump="--single-transaction --quick --lock-tables=false"

# image contenant mariadb-dump
image_dump="mariadb:11.1-jammy"

echo "----------------------------------------"
echo "DÉMARRAGE DE LA SAUVEGARDE : ${date_du_jour}"
echo "Nom logique : ${nom_sauvegarde}"
echo "Répertoire de travail : ${dossier_cible}"
echo "Conteneur base de données : ${conteneur_bdd}"
echo "Conteneur site web : ${conteneur_site}"
echo "Image utilisée pour le dump : ${image_dump}"
echo "----------------------------------------"
echo ""

# suppression préalable du répertoire si déjà présent
if [ -d "${dossier_cible}" ]; then
    echo "Le dossier de destination existe déjà, suppression..."
    rm -rf "${dossier_cible}"
fi

# création des répertoires
echo "Création du répertoire de sauvegarde..."
mkdir -p "${dossier_temporaire}"
echo ""

# récupération des identifiants
echo "Extraction des identifiants depuis le conteneur base de données..."
utilisateur_bdd=$(docker exec "${conteneur_bdd}" printenv MARIADB_USER)
motdepasse_bdd=$(docker exec "${conteneur_bdd}" printenv MARIADB_PASSWORD)

# vérification des identifiants
if [[ -z "${utilisateur_bdd}" || -z "${motdepasse_bdd}" ]]; then
    echo "Erreur : identifiants DB incomplets ou introuvables."
    exit 1
fi
echo ""

# dump SQL avec image temporaire mariadb
echo "Export de la base de données '${nom_base}' via mariadb-dump (conteneur éphémère)..."
docker run --rm \
  --network container:"${conteneur_bdd}" \
  "${image_dump}" \
  mariadb-dump \
  --host=127.0.0.1 \
  --port="${port_bdd}" \
  ${options_dump} \
  -u"${utilisateur_bdd}" -p"${motdepasse_bdd}" "${nom_base}" \
  | gzip > "${dossier_cible}/${nom_sauvegarde}.dump.sql.gz"
echo "Dump SQL terminé : ${nom_sauvegarde}.dump.sql.gz"
echo "Conteneur éphémère mariadb utilisé pour le dump supprimé automatiquement (--rm)."
echo ""

# copie des fichiers applicatifs
echo "Copie des fichiers du site WordPress..."
docker cp "${conteneur_site}:/var/www/html" "${dossier_temporaire}/html"
echo ""

echo "Archivage des fichiers applicatifs..."
if ! tar czf "${dossier_cible}/${nom_sauvegarde}.html.tar.gz" -C "${dossier_temporaire}" html; then
    echo "Erreur : Archivage échoué."
    exit 1
fi
echo "Archive créée : ${nom_sauvegarde}.html.tar.gz"
echo ""

# nettoyage
echo "Nettoyage du dossier temporaire..."
rm -rf "${dossier_temporaire}"

# réduction des droits d’accès
chmod -R 700 "${dossier_cible}"

# rotation sécurisée basée sur la nomenclature des dossiers
echo "Rotation des sauvegardes : conservation de ${retenue_jours} jours..."
date_limite=$(date -d "-${retenue_jours} days" +%Y-%m-%d)
date_limite_ts=$(date -d "${date_limite}" +%s)

echo "Date limite pour conservation : ${date_limite}"
echo ""

# DEBUG : désactivation temporaire du mode "exit on error" pour éviter les arrêts silencieux
set +e

for dossier in "${repertoire_sauvegarde}/"*_"${nom_sauvegarde}"; do
    if [ -d "${dossier}" ]; then
        dossier_base=$(basename "${dossier}")
        dossier_date=$(echo "${dossier_base}" | grep -Eo '^[0-9]{4}-[0-9]{2}-[0-9]{2}')

        if [[ ! "${dossier_date}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "IGNORÉ (format non conforme) : ${dossier}"
            continue
        fi

        dossier_date_ts=$(date -d "${dossier_date}" +%s)

        if [ "${dossier_date_ts}" -lt "${date_limite_ts}" ]; then
            echo "SUPPRESSION programmée : ${dossier}"
            if rm -rfv "${dossier}"; then
                echo "SUPPRESSION RÉUSSIE : ${dossier}"
            else
                echo "ÉCHEC DE LA SUPPRESSION : ${dossier}"
            fi
        else
            echo "CONSERVÉ : ${dossier}"
        fi
    fi
done

# DEBUG : réactivation du mode strict après la rotation
set -e

echo ""
echo "Sauvegarde terminée avec succès."
exit 0
