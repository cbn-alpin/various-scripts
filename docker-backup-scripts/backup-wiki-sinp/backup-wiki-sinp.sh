#!/bin/bash
# Auteur : Arnaud Ungaro
# Structure : CBNA (Conservatoire Botanique National Alpin)
# Année : 2025
# Script de sauvegarde de l’instance Dokuwiki SINP (wiki-sinp)

set -e
set -o pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# nom logique de la sauvegarde
nom_sauvegarde="wiki-sinp"

# répertoire de travail
repertoire_sauvegarde="/home/admin/docker/wiki-sinp/backups"
date_du_jour=$(date +%F)
dossier_cible="${repertoire_sauvegarde}/${date_du_jour}_${nom_sauvegarde}"
dossier_temporaire="${dossier_cible}/tmp"
retenue_jours=2

# conteneur principal utilisé
conteneur_site="wiki-sinp-dokuwiki"
conteneur_proxy="wiki-sinp-nginx"

echo "----------------------------------------"
echo "DÉMARRAGE DE LA SAUVEGARDE : ${date_du_jour}"
echo "Nom logique : ${nom_sauvegarde}"
echo "Répertoire de travail : ${dossier_cible}"
echo "Conteneur site : ${conteneur_site}"
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

# Copie des volumes montés depuis le conteneur
for chemin in \
    "/var/www/html" \
    "/var/www/html/conf" \
    "/var/www/html/data" \
    "/var/www/html/lib/plugins" \
    "/var/www/html/lib/tpl" \
    "/etc/oauth"; do
    echo "Copie depuis le conteneur (${conteneur_site}) : ${chemin}"
    dossier_nom=$(basename "${chemin}")
    docker cp "${conteneur_site}:${chemin}" "${dossier_temporaire}/${dossier_nom}"
    echo "OK"
    echo ""
done

# Copie des fichiers locaux (intégralité des répertoires de config)
echo "Copie des fichiers locaux..."
cp -r ./nginx "${dossier_temporaire}/nginx"
cp -r ./dokuwiki "${dossier_temporaire}/dokuwiki"
cp ./.env "${dossier_temporaire}/.env"
echo ""

echo "Archivage de la sauvegarde..."
if ! tar czf "${dossier_cible}/${nom_sauvegarde}.tar.gz" -C "${dossier_temporaire}" .; then
    echo "Erreur : Archivage échoué."
    exit 1
fi

echo "Archive créée : ${nom_sauvegarde}.tar.gz"
echo ""

# nettoyage
echo "Nettoyage du dossier temporaire..."
rm -rf "${dossier_temporaire}"
echo ""

# réduction des droits d’accès
chmod -R 700 "${dossier_cible}"

# rotation sécurisée basée sur la nomenclature des dossiers
echo "Rotation des sauvegardes : conservation de ${retenue_jours} jours..."
date_limite=$(date -d "-${retenue_jours} days" +%Y-%m-%d)
date_limite_ts=$(date -d "${date_limite}" +%s)
echo "Date limite pour conservation : ${date_limite}"
echo ""

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
set -e

echo ""
echo "Sauvegarde terminée avec succès."
exit 0
