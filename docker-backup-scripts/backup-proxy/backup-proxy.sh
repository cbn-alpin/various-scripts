#!/bin/bash
# Auteur : Arnaud Ungaro
# Structure : CBNA (Conservatoire Botanique National Alpin)
# Année : 2025
# Script de sauvegarde de la stack NGINX-Proxy (nginx-proxy)

set -e
set -o pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# nom logique de la sauvegarde
nom_sauvegarde="proxy"

# répertoire de travail
repertoire_sauvegarde="/home/admin/docker/proxy/backups"
date_du_jour=$(date +%F)
dossier_cible="${repertoire_sauvegarde}/${date_du_jour}_${nom_sauvegarde}"
dossier_temporaire="${dossier_cible}/tmp"
retenue_jours=2

# conteneurs à cibler
conteneur_proxy="nginx-proxy"
conteneur_gen="nginx-proxy-gen"
conteneur_letsencrypt="nginx-proxy-letsencrypt"

echo "----------------------------------------"
echo "DÉMARRAGE DE LA SAUVEGARDE : ${date_du_jour}"
echo "Nom logique : ${nom_sauvegarde}"
echo "Répertoire de travail : ${dossier_cible}"
echo "----------------------------------------"
echo ""

# suppression préalable du répertoire si déjà présent
if [ -d "${dossier_cible}" ]; then
    echo "Le dossier de destination existe déjà, suppression..."
    rm -rf "${dossier_cible}"
fi

# création des répertoires
mkdir -p "${dossier_temporaire}"
echo "Création du répertoire de sauvegarde..."
echo ""

# copies des volumes montés via docker cp
echo "Copie des répertoires internes des conteneurs..."
docker cp "${conteneur_proxy}:/etc/nginx" "${dossier_temporaire}/nginx"
docker cp "${conteneur_proxy}:/usr/share/nginx/html" "${dossier_temporaire}/html"
docker cp "${conteneur_gen}:/etc/docker-gen" "${dossier_temporaire}/docker-gen"
docker cp "${conteneur_letsencrypt}:/etc/acme.sh" "${dossier_temporaire}/acme.sh"
echo ""

# copie des fichiers montés locaux (configurations)
echo "Ajout des fichiers locaux montés dans les conteneurs..."
mkdir -p "${dossier_temporaire}/local"
cp -r ./docker-gen "${dossier_temporaire}/local/docker-gen"
cp -r ./nginx "${dossier_temporaire}/local/nginx"
echo ""

# archivage final
echo "Archivage des fichiers de configuration et des volumes..."
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

# droits
chmod -R 700 "${dossier_cible}"

# rotation sécurisée
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
