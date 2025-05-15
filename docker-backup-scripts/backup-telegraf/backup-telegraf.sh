#!/bin/bash
# Auteur : Arnaud Ungaro
# Structure : CBNA (Conservatoire Botanique National Alpin)
# Année : 2025
# Script de sauvegarde de l’instance Telegraf (telegraf)

set -e
set -o pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# nom logique de la sauvegarde
nom_sauvegarde="telegraf"

# répertoire de travail
repertoire_sauvegarde="/home/admin/docker/telegraf/backups"
date_du_jour=$(date +%F)
dossier_cible="${repertoire_sauvegarde}/${date_du_jour}_${nom_sauvegarde}"
dossier_temporaire="${dossier_cible}/tmp"
retenue_jours=2

# conteneur utilisé
conteneur="telegraf"

echo "----------------------------------------"
echo "DÉMARRAGE DE LA SAUVEGARDE : ${date_du_jour}"
echo "Nom logique : ${nom_sauvegarde}"
echo "Répertoire de travail : ${dossier_cible}"
echo "Conteneur cible : ${conteneur}"
echo "----------------------------------------"
echo ""

# suppression préalable du répertoire si déjà présent
if [ -d "${dossier_cible}" ]; then
    echo "Le dossier de destination existe déjà, suppression..."
    rm -rf "${dossier_cible}"
fi

# création des répertoires nécessaires
mkdir -p "${dossier_temporaire}"
mkdir -p "${dossier_temporaire}/etc"
mkdir -p "${dossier_temporaire}/opt"
echo "Répertoires temporaires créés."
echo ""

# copie des fichiers de configuration telegraf (hôte)
echo "Copie des fichiers locaux de configuration..."
cp ./telegraf.conf "${dossier_temporaire}/etc/telegraf.conf"
if [ -f ./telegraf.sample.conf ]; then
    cp ./telegraf.sample.conf "${dossier_temporaire}/etc/telegraf.sample.conf"
fi

# copie du status.json si disponible
if [ -f /opt/srvstatus/status.json ]; then
    cp /opt/srvstatus/status.json "${dossier_temporaire}/opt/status.json"
fi

echo ""
echo "Archivage des fichiers..."
if ! tar czf "${dossier_cible}/${nom_sauvegarde}.tar.gz" -C "${dossier_temporaire}" .; then
    echo "Erreur : Archivage échoué."
    exit 1
fi

echo "Archive créée : ${nom_sauvegarde}.tar.gz"
echo ""

# nettoyage
rm -rf "${dossier_temporaire}"
echo "Dossier temporaire supprimé."
echo ""

# réduction des droits d’accès
chmod -R 700 "${dossier_cible}"

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
