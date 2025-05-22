#!/bin/bash
# Auteur : Arnaud Ungaro
# Structure : CBNA (Conservatoire Botanique National Alpin)
# Année : 2025
# Script de sauvegarde de l’instance Authentik

set -e
set -o pipefail

cd "$(dirname "$0")"

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# nom logique de la sauvegarde
nom_sauvegarde="authentik"

# répertoire de travail
repertoire_sauvegarde="/home/admin/docker/authentik/backups"
date_du_jour=$(date +%F)
dossier_cible="${repertoire_sauvegarde}/${date_du_jour}_${nom_sauvegarde}"
dossier_temporaire="${dossier_cible}/tmp"
retenue_jours=2

# conteneurs utilisés
conteneur_bdd="authentik-postgresql"
conteneur_data="authentik-server"

# image contenant pg_dump
image_dump="postgres:16-alpine"
port_bdd=5432

echo "----------------------------------------"
echo "DÉMARRAGE DE LA SAUVEGARDE : ${date_du_jour}"
echo "Nom logique : ${nom_sauvegarde}"
echo "Répertoire de travail : ${dossier_cible}"
echo "Conteneur base de données : ${conteneur_bdd}"
echo "Conteneur pour les fichiers : ${conteneur_data}"
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

# récupération des identifiants DB
echo "Extraction des identifiants depuis le conteneur base de données..."
nom_base=$(docker exec "${conteneur_bdd}" printenv POSTGRES_DB)
utilisateur_bdd=$(docker exec "${conteneur_bdd}" printenv POSTGRES_USER)
motdepasse_bdd=$(docker exec "${conteneur_bdd}" printenv POSTGRES_PASSWORD)

# vérification des identifiants
if [[ -z "${nom_base}" || -z "${utilisateur_bdd}" || -z "${motdepasse_bdd}" ]]; then
    echo "Erreur : identifiants DB incomplets ou introuvables."
    exit 1
fi
echo ""

# dump SQL avec conteneur temporaire postgres
echo "Export de la base de données '${nom_base}' via pg_dump (conteneur éphémère)..."
docker run --rm \
  --network container:"${conteneur_bdd}" \
  -e PGPASSWORD="${motdepasse_bdd}" \
  "${image_dump}" \
  pg_dump -h 127.0.0.1 -p "${port_bdd}" -U "${utilisateur_bdd}" -d "${nom_base}" \
  | gzip > "${dossier_cible}/${nom_sauvegarde}.dump.sql.gz"
echo "Dump SQL terminé : ${nom_sauvegarde}.dump.sql.gz"
echo "Conteneur éphémère postgres utilisé pour le dump supprimé automatiquement (--rm)."
echo ""

# copie des fichiers media et templates
echo "Copie des fichiers media et templates Authentik..."
docker cp "${conteneur_data}:/media" "${dossier_temporaire}/media"
docker cp "${conteneur_data}:/templates" "${dossier_temporaire}/templates"
echo ""

echo "Archivage des fichiers media et templates..."
if ! tar czf "${dossier_cible}/${nom_sauvegarde}.media-templates.tar.gz" -C "${dossier_temporaire}" media templates; then
    echo "Erreur : Archivage échoué."
    exit 1
fi
echo "Archive créée : ${nom_sauvegarde}.media-templates.tar.gz"
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

# DEBUG : réactivation du mode strict après la rotation
set -e

echo ""
echo "Sauvegarde terminée avec succès."
exit 0
