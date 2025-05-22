#!/bin/bash
# Auteur : Arnaud Ungaro
# Structure : CBNA (Conservatoire Botanique National Alpin)
# Année : 2025
# Script de sauvegarde de l’instance Saisie-Flore (saisie-flore)

set -e
set -o pipefail

cd "$(dirname "$0")"

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# nom logique de la sauvegarde
nom_sauvegarde="saisie-flore"

# répertoire de travail
repertoire_sauvegarde="/home/admin/docker/saisie-flore/backups"
date_du_jour=$(date +%F)
dossier_cible="${repertoire_sauvegarde}/${date_du_jour}_${nom_sauvegarde}"
dossier_temporaire="${dossier_cible}/tmp"
retenue_jours=2

# conteneurs utilisés
conteneur_php="saisie-flore-php"
conteneur_db="saisie-flore-postgres"

# base de données
nom_base="saisie_flore"
port_bdd=5432
image_dump="postgres:15.3-bookworm"

echo "----------------------------------------"
echo "DÉMARRAGE DE LA SAUVEGARDE : ${date_du_jour}"
echo "Nom logique : ${nom_sauvegarde}"
echo "Répertoire de travail : ${dossier_cible}"
echo "Conteneur base de données : ${conteneur_db}"
echo "Conteneur applicatif : ${conteneur_php}"
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
utilisateur_bdd=$(docker exec "${conteneur_db}" printenv POSTGRES_USER)
motdepasse_bdd=$(docker exec "${conteneur_db}" printenv POSTGRES_PASSWORD)

if [[ -z "${utilisateur_bdd}" || -z "${motdepasse_bdd}" ]]; then
    echo "Erreur : identifiants DB incomplets ou introuvables."
    exit 1
fi

# dump PostgreSQL compressé
echo "Export de la base de données '${nom_base}' via pg_dump (compressé)..."
docker run --rm \
  --network container:"${conteneur_db}" \
  -e PGPASSWORD="${motdepasse_bdd}" \
  "${image_dump}" \
  pg_dump -h 127.0.0.1 -U "${utilisateur_bdd}" -d "${nom_base}" -Fc \
  | gzip > "${dossier_cible}/${nom_sauvegarde}.dump.pgsql.gz"
echo "Dump SQL compressé terminé : ${nom_sauvegarde}.dump.pgsql.gz"
echo ""

# copie du code applicatif
echo "Copie des fichiers applicatifs PHP..."
docker cp "${conteneur_php}:/var/www/html" "${dossier_temporaire}/html"
echo ""

# copie des fichiers locaux montés
echo "Ajout des fichiers locaux de configuration..."
mkdir -p "${dossier_temporaire}/local"
cp -r ./nginx "${dossier_temporaire}/local/nginx"
cp -r ./postgres "${dossier_temporaire}/local/postgres"
cp -r ./php "${dossier_temporaire}/local/php"
echo ""

# archivage
echo "Archivage des fichiers..."
if ! tar czf "${dossier_cible}/${nom_sauvegarde}.tar.gz" -C "${dossier_temporaire}" .; then
    echo "Erreur : Archivage échoué."
    exit 1
fi
echo "Archive créée : ${nom_sauvegarde}.tar.gz"
echo ""

# nettoyage
rm -rf "${dossier_temporaire}"
echo "Nettoyage du dossier temporaire terminé."
echo ""

chmod -R 700 "${dossier_cible}"

# rotation des anciennes sauvegardes
set +e
echo "Rotation des sauvegardes : conservation de ${retenue_jours} jours..."
date_limite=$(date -d "-${retenue_jours} days" +%Y-%m-%d)
date_limite_ts=$(date -d "${date_limite}" +%s)

for dossier in "${repertoire_sauvegarde}/"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_"${nom_sauvegarde}"; do
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

set -e
echo ""
echo "Sauvegarde terminée avec succès."
exit 0
