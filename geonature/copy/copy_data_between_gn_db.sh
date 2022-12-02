#!/bin/bash
# Encoding : UTF-8
# Script to copy Synthese Data between two GN database.
set -euo pipefail

#+-------------------------------------------------------------------------------------------------+
# Config
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
pg_admin_name="${USER}"
src_db_name="${1-gn2_sinp_paca}"
dest_db_name="${2-gn2_default}"

#+-------------------------------------------------------------------------------------------------+
# Load utils
source "${SCRIPT_DIR}/../../shared/lib/utils.bash"

checkSuperuser

#+-------------------------------------------------------------------------------------------------+
# Configure PSQL
if [[ -f "~/.psqlrc" ]]; then
    mv "~/.psqlrc" "~/.psqlrc.saved"
fi

#+-------------------------------------------------------------------------------------------------+
# TRUNCATES

# NOMENCLATURES
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c 'TRUNCATE
        taxonomie.bib_noms,
        ref_geo.bib_areas_types,
        ref_geo.l_areas,
        ref_nomenclatures.bib_nomenclatures_types,
        utilisateurs.t_applications,
        utilisateurs.bib_organismes,
        utilisateurs.t_roles,
        utilisateurs.cor_profil_for_app,
        gn_meta.t_acquisition_frameworks,
        gn_meta.t_datasets,
        gn_synthese.t_sources,
        gn_synthese.synthese,
        gn_synthese.cor_area_synthese
        CASCADE ;'

#+-------------------------------------------------------------------------------------------------+
# SOURCES
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_synthese.t_sources TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_synthese.t_sources FROM stdin csv null AS E'\\\\N'"

#+-------------------------------------------------------------------------------------------------+
# ORGANISMS
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY utilisateurs.bib_organismes (
        id_organisme, uuid_organisme, nom_organisme, adresse_organisme, cp_organisme,
        ville_organisme, tel_organisme, fax_organisme, email_organisme, url_organisme,
        url_logo, id_parent) TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY utilisateurs.bib_organismes (
        id_organisme, uuid_organisme, nom_organisme, adresse_organisme, cp_organisme,
        ville_organisme, tel_organisme, fax_organisme, email_organisme, url_organisme,
        url_logo, id_parent) FROM stdin csv null AS E'\\\\N'"

#+-------------------------------------------------------------------------------------------------+
# NOMENCLATURES
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY ref_nomenclatures.bib_nomenclatures_types TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY ref_nomenclatures.bib_nomenclatures_types FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY ref_nomenclatures.t_nomenclatures TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY ref_nomenclatures.t_nomenclatures FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY ref_nomenclatures.defaults_nomenclatures_value TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY ref_nomenclatures.defaults_nomenclatures_value FROM stdin csv null AS E'\\\\N'"

#+-------------------------------------------------------------------------------------------------+
# TAXONOMIE
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY taxonomie.bib_noms (
        id_nom, cd_nom, cd_ref, nom_francais, comments
    ) TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY taxonomie.bib_noms FROM stdin csv null AS E'\\\\N'"

#+-------------------------------------------------------------------------------------------------+
# GEOGRAPHY
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY ref_geo.bib_areas_types (
        id_type, type_name, type_code, type_desc, ref_name, ref_version, num_version
    ) TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY ref_geo.bib_areas_types FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY ref_geo.l_areas TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY ref_geo.l_areas FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY ref_geo.li_grids TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY ref_geo.li_grids FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY ref_geo.li_municipalities TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY ref_geo.li_municipalities FROM stdin csv null AS E'\\\\N'"

#+-------------------------------------------------------------------------------------------------+
# USERS (role)
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY utilisateurs.t_roles TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY utilisateurs.t_roles FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY utilisateurs.cor_roles TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY utilisateurs.cor_roles FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY utilisateurs.cor_role_token TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY utilisateurs.cor_role_token FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY utilisateurs.t_applications TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY utilisateurs.t_applications FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY utilisateurs.cor_role_app_profil TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY utilisateurs.cor_role_app_profil FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY utilisateurs.cor_profil_for_app TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY utilisateurs.cor_profil_for_app FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s psql -d "${dest_db_name}" -f "${SCRIPT_DIR}/../sql/default_permissions_sinp.sql"

#+-------------------------------------------------------------------------------------------------+
# ACQUISITION FRAMEWORKS
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.t_acquisition_frameworks TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.t_acquisition_frameworks FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.sinp_datatype_publications TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.sinp_datatype_publications FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.t_bibliographical_references TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.t_bibliographical_references FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.cor_acquisition_framework_voletsinp TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.cor_acquisition_framework_voletsinp FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.cor_acquisition_framework_territory TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.cor_acquisition_framework_territory FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.cor_acquisition_framework_publication TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.cor_acquisition_framework_publication FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.cor_acquisition_framework_objectif TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.cor_acquisition_framework_objectif FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.cor_acquisition_framework_actor TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.cor_acquisition_framework_actor FROM stdin csv null AS E'\\\\N'"

#+-------------------------------------------------------------------------------------------------+
# DATASETS
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.t_datasets (
        id_dataset, unique_dataset_id, id_acquisition_framework, dataset_name, dataset_shortname,
        dataset_desc, id_nomenclature_data_type, keywords, marine_domain, terrestrial_domain,
        id_nomenclature_dataset_objectif, bbox_west, bbox_east, bbox_south, bbox_north,
		id_nomenclature_collecting_method, id_nomenclature_data_origin, id_nomenclature_source_status,
		id_nomenclature_resource_type, active, validable, id_digitizer, id_taxa_list,
        meta_create_date, meta_update_date) TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.t_datasets FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.sinp_datatype_protocols TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.sinp_datatype_protocols FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.cor_dataset_territory TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.cor_dataset_territory FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.cor_dataset_protocol TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.cor_dataset_protocol FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_meta.cor_dataset_actor TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_meta.cor_dataset_actor FROM stdin csv null AS E'\\\\N'"

#+-------------------------------------------------------------------------------------------------+
# SYNTHESE

# TODO: Add id_area_attachement to 1,5 millions observations with
# id_nomenclature_info_geo_type code = 2 and id_area_attachment IS NULL.
# For now, remove constaint.
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c "ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS check_synthese_info_geo_type_id_area_attachment ;"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_synthese.defaults_nomenclatures_value TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_synthese.defaults_nomenclatures_value FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_synthese.synthese TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_synthese.synthese FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "
        DELETE FROM gn_synthese.cor_area_synthese AS cas
        WHERE NOT EXISTS (
            SELECT FROM gn_synthese.synthese AS s
            WHERE s.id_synthese = cas.id_synthese
        ) ; "

# sudo -n -u "${pg_admin_name}" -s \
#     psql -d "${src_db_name}" -c "COPY gn_synthese.cor_area_synthese TO stdout WITH csv null AS E'\\\\N'" |
#     psql -d "${dest_db_name}" -c "COPY gn_synthese.cor_area_synthese FROM stdin csv null AS E'\\\\N'"

# Reset all sequences in destination database
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c "
CREATE OR REPLACE FUNCTION reset_sequence(table_schema text, tablename text, columnname text, sequence_name text)
    RETURNS \"pg_catalog\".\"void\" AS
    '
      DECLARE
      BEGIN

      EXECUTE ''SELECT setval( '''''' || sequence_name  || '''''', '' || ''(SELECT MAX('' || columnname ||
          '') FROM '' || table_schema || ''.''|| tablename || '')'' || ''+1)'';

      END;
    ' LANGUAGE 'plpgsql';"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c "
SELECT substring(column_default, '''(.*)'''),
    reset_sequence(table_schema, table_name, column_name, substring(column_default, '''(.*)'''))
FROM information_schema.columns WHERE column_default LIKE 'nextval%' ; "

#+-------------------------------------------------------------------------------------------------+
# COMMONS
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_commons.t_parameters TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_commons.t_parameters FROM stdin csv null AS E'\\\\N'"

# TODO: see how to copy t_modules

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY gn_commons.cor_module_dataset TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c "COPY gn_commons.cor_module_dataset FROM stdin csv null AS E'\\\\N'"

#+-------------------------------------------------------------------------------------------------+
# Configure PSQL
if [[ -f "~/.psqlrc.saved" ]]; then
    mv "~/.psqlrc.saved" "~/.psqlrc"
fi
