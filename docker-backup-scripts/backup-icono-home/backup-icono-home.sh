#!/bin/bash
# Auteur : Arnaud Ungaro
# Structure : CBNA (Conservatoire Botanique National Alpin)
# Année : 2025
# Script de sauvegarde de l’instance ICONO-HOME 

set -e
set -o pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# nom logique de la sauvegarde
nom_sauvegarde="icono-home"

# répertoire de travail
repertoire_sauvegarde="/home/admin/docker/icono-home/backups"
date_du_jour=$(date +%F)
dossier_cible="${repertoire_sauvegarde}/${date_du_jour}_${nom_sauvegarde}"
dossier_temporaire="${dossier_cible}/tmp"
retenue_jours=2

# conteneur utilisé
conteneur_nginx="icono-home-nginx"

echo "----------------------------------------"
echo "DÉMARRAGE DE LA SAUVEGARDE : ${date_du_jour}"
echo "Nom logique : ${nom_sauvegarde}"
echo "Répertoire de travail : ${dossier_cible}"
echo "Conteneur ciblé : ${conteneur_nginx}"
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

# copie des fichiers du site statique
echo "Copie des fichiers statiques depuis le conteneur NGINX..."
docker cp "${conteneur_nginx}:/usr/share/nginx/html" "${dossier_temporaire}/html"
echo ""

echo "Archivage des fichiers statiques..."
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

# désactivation temporaire du mode strict pour la rotation
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

# réactivation du mode strict
set -e

echo ""
echo "Sauvegarde terminée avec succès."
exit 0
