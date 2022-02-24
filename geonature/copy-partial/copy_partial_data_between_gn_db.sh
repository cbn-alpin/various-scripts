#!/bin/bash
# Encoding : UTF-8
# Script to copy Synthese Data between two GN database.
set -euo pipefail

#+-------------------------------------------------------------------------------------------------+
# Config
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
pg_admin_name="jpmilcent"
src_db_name="gn2_default_big"
dest_db_name="gn2_default"
area_code="05004"

#+-------------------------------------------------------------------------------------------------+
# Load utils
script_path=$(realpath "${BASH_SOURCE[0]}")
source "$(realpath "${script_path%/*}")/lib_utils.bash"

checkSuperuser

#+-------------------------------------------------------------------------------------------------+
# Configure PSQL
if [[ -f "~/.psqlrc" ]]; then
    mv "~/.psqlrc" "~/.psqlrc.saved"
fi

#+-------------------------------------------------------------------------------------------------+
# PREPARE DESTINATION DB

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c \
    'DROP TABLE IF EXISTS gn_imports.synthese;'

# TODO: manage id_dataset, id_module, id_digitizer
sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c \
    "CREATE TABLE gn_imports.synthese AS
        SELECT
            NULL::INT AS gid,
            unique_id_sinp,
            unique_id_sinp_grp,
            NULL AS id_source,
            NULL AS id_module,
            entity_source_pk_value,
            NULL AS id_dataset,
            NULL::VARCHAR(25) AS cd_nomenclature_geo_object_nature,
            NULL::VARCHAR(25) AS cd_nomenclature_grp_typ,
            grp_method,
            NULL::VARCHAR(25) AS cd_nomenclature_obs_technique,
            NULL::VARCHAR(25) AS cd_nomenclature_bio_status,
            NULL::VARCHAR(25) AS cd_nomenclature_bio_condition,
            NULL::VARCHAR(25) AS cd_nomenclature_naturalness,
            NULL::VARCHAR(25) AS cd_nomenclature_exist_proof,
            NULL::VARCHAR(25) AS cd_nomenclature_valid_status,
            NULL::VARCHAR(25) AS cd_nomenclature_diffusion_level,
            NULL::VARCHAR(25) AS cd_nomenclature_life_stage,
            NULL::VARCHAR(25) AS cd_nomenclature_sex,
            NULL::VARCHAR(25) AS cd_nomenclature_obj_count,
            NULL::VARCHAR(25) AS cd_nomenclature_type_count,
            NULL::VARCHAR(25) AS cd_nomenclature_sensitivity,
            NULL::VARCHAR(25) AS cd_nomenclature_observation_status,
            NULL::VARCHAR(25) AS cd_nomenclature_blurring,
            NULL::VARCHAR(25) AS cd_nomenclature_source_status,
            NULL::VARCHAR(25) AS cd_nomenclature_info_geo_type,
            NULL::VARCHAR(25) AS cd_nomenclature_behaviour,
            NULL::VARCHAR(25) AS cd_nomenclature_biogeo_status,
            reference_biblio,
            count_min,
            count_max,
            cd_nom,
            cd_hab,
            nom_cite,
            meta_v_taxref,
            sample_number_proof,
            digital_proof,
            non_digital_proof,
            altitude_min,
            altitude_max,
            depth_min,
            depth_max,
            place_name,
            the_geom_4326,
            the_geom_point,
            the_geom_local,
            precision,
            id_area_attachment,
            date_min,
            date_max,
            validator,
            validation_comment,
            observers,
            determiner,
            NULL AS id_digitiser,
            NULL::VARCHAR(25) AS cd_nomenclature_determination_method,
            comment_context,
            comment_description,
            additional_data,
            meta_validation_date,
            meta_create_date,
            meta_update_date,
            last_action
        FROM gn_synthese.synthese
    WITH NO DATA ;"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c \
    "ALTER TABLE gn_imports.synthese
	    ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	    ADD CONSTRAINT pk_import_synthese_${area_code} PRIMARY KEY(gid);"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${src_db_name}" -c "COPY (
        SELECT
            s.unique_id_sinp,
            s.unique_id_sinp_grp,
            NULL AS id_source,
            NULL AS id_module,
            s.entity_source_pk_value,
            NULL AS id_dataset,
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_geo_object_nature),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_grp_typ),
            s.grp_method,
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_obs_technique),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_status),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_condition),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_naturalness),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_exist_proof),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_valid_status),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_diffusion_level),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_life_stage),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_sex),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_obj_count),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_type_count),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_sensitivity),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_observation_status),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_blurring),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_source_status),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_info_geo_type),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_behaviour),
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_biogeo_status),
            s.reference_biblio,
            s.count_min,
            s.count_max,
            s.cd_nom,
            s.cd_hab,
            s.nom_cite,
            s.meta_v_taxref,
            s.sample_number_proof,
            s.digital_proof,
            s.non_digital_proof,
            s.altitude_min,
            s.altitude_max,
            s.depth_min,
            s.depth_max,
            s.place_name,
            s.the_geom_4326,
            s.the_geom_point,
            s.the_geom_local,
            s.precision,
            s.id_area_attachment,
            s.date_min,
            s.date_max,
            s.validator,
            s.validation_comment,
            s.observers,
            s.determiner,
            NULL AS id_digitiser,
            ref_nomenclatures.get_cd_nomenclature(id_nomenclature_determination_method),
            s.comment_context,
            s.comment_description,
            s.additional_data,
            s.meta_validation_date,
            s.meta_create_date,
            s.meta_update_date,
            s.last_action
        FROM gn_synthese.synthese AS s
            JOIN gn_synthese.cor_area_synthese AS cas
                ON (s.id_synthese = cas.id_synthese)
            JOIN ref_geo.l_areas AS la
                ON (cas.id_area = la.id_area)
        WHERE la.area_code = '${area_code}'
            AND ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_info_geo_type) != '2'
    ) TO stdout WITH csv null AS E'\\\\N'" |
    psql -d "${dest_db_name}" -c \
    "COPY gn_imports.synthese (
        unique_id_sinp,
        unique_id_sinp_grp,
        id_source,
        id_module,
        entity_source_pk_value,
        id_dataset,
        cd_nomenclature_geo_object_nature,
        cd_nomenclature_grp_typ,
        grp_method,
        cd_nomenclature_obs_technique,
        cd_nomenclature_bio_status,
        cd_nomenclature_bio_condition,
        cd_nomenclature_naturalness,
        cd_nomenclature_exist_proof,
        cd_nomenclature_valid_status,
        cd_nomenclature_diffusion_level,
        cd_nomenclature_life_stage,
        cd_nomenclature_sex,
        cd_nomenclature_obj_count,
        cd_nomenclature_type_count,
        cd_nomenclature_sensitivity,
        cd_nomenclature_observation_status,
        cd_nomenclature_blurring,
        cd_nomenclature_source_status,
        cd_nomenclature_info_geo_type,
        cd_nomenclature_behaviour,
        cd_nomenclature_biogeo_status,
        reference_biblio,
        count_min,
        count_max,
        cd_nom,
        cd_hab,
        nom_cite,
        meta_v_taxref,
        sample_number_proof,
        digital_proof,
        non_digital_proof,
        altitude_min,
        altitude_max,
        depth_min,
        depth_max,
        place_name,
        the_geom_4326,
        the_geom_point,
        the_geom_local,
        precision,
        id_area_attachment,
        date_min,
        date_max,
        validator,
        validation_comment,
        observers,
        determiner,
        id_digitiser,
        cd_nomenclature_determination_method,
        comment_context,
        comment_description,
        additional_data,
        meta_validation_date,
        meta_create_date,
        meta_update_date,
        last_action
    ) FROM stdin csv null AS E'\\\\N'"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c \
    "DELETE FROM gn_synthese.synthese WHERE id_source IN (
        SELECT id_source FROM gn_synthese.t_sources WHERE name_source = 'IMPORT-PARTIAL-${area_code}'
    );"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c \
    "DELETE FROM gn_synthese.t_sources WHERE name_source = 'IMPORT-PARTIAL-${area_code}';"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c \
    "
    LOCK TABLE gn_synthese.synthese IN EXCLUSIVE MODE;
    SELECT setval('gn_synthese.synthese_id_synthese_seq', COALESCE((SELECT MAX(id_synthese)+1 FROM gn_synthese.synthese), 1), false);
    "

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c \
    "
    LOCK TABLE gn_synthese.t_sources IN EXCLUSIVE MODE;
    SELECT setval('gn_synthese.t_sources_id_source_seq', COALESCE((SELECT MAX(id_source)+1 FROM gn_synthese.t_sources), 1), false);
    "

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -f "./add_helpers_functions.sql"

sudo -n -u "${pg_admin_name}" -s \
    cat ./default_test_metadata.sql | \
    sed "s/\${src_db_name}/${src_db_name}/g" | \
    sed "s/\${area_code}/${area_code}/g" | \
    psql -q -d "${dest_db_name}"

sudo -n -u "${pg_admin_name}" -s \
    psql -d "${dest_db_name}" -c \
    "INSERT INTO gn_synthese.synthese (
        unique_id_sinp,
        unique_id_sinp_grp,
        id_source,
        entity_source_pk_value,
        id_dataset,
        id_nomenclature_geo_object_nature,
        id_nomenclature_grp_typ,
        grp_method,
        id_nomenclature_obs_technique,
        id_nomenclature_bio_status,
        id_nomenclature_bio_condition,
        id_nomenclature_naturalness,
        id_nomenclature_exist_proof,
        id_nomenclature_valid_status,
        id_nomenclature_diffusion_level,
        id_nomenclature_life_stage,
        id_nomenclature_sex,
        id_nomenclature_obj_count,
        id_nomenclature_type_count,
        id_nomenclature_sensitivity,
        id_nomenclature_observation_status,
        id_nomenclature_blurring,
        id_nomenclature_source_status,
        id_nomenclature_info_geo_type,
        id_nomenclature_behaviour,
        id_nomenclature_biogeo_status,
        reference_biblio,
        count_min,
        count_max,
        cd_nom,
        cd_hab,
        nom_cite,
        meta_v_taxref,
        sample_number_proof,
        digital_proof,
        non_digital_proof,
        altitude_min,
        altitude_max,
        depth_min,
        depth_max,
        place_name,
        the_geom_4326,
        the_geom_point,
        the_geom_local,
        precision,
        id_area_attachment,
        date_min,
        date_max,
        validator,
        validation_comment,
        observers,
        determiner,
        id_nomenclature_determination_method,
        comment_context,
        comment_description,
        additional_data,
        meta_validation_date,
        meta_create_date,
        meta_update_date,
        last_action
    )
        SELECT
            unique_id_sinp,
            unique_id_sinp_grp,
            (SELECT id_source FROM gn_synthese.t_sources WHERE name_source = 'IMPORT-PARTIAL-${area_code}') AS id_source,
            entity_source_pk_value,
            gn_meta.get_id_dataset('b3988db2-2c94-4e1f-86f3-3a7184fc5f71'),
            ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', cd_nomenclature_geo_object_nature),
            ref_nomenclatures.get_id_nomenclature('TYP_GRP', cd_nomenclature_grp_typ),
            grp_method,
            ref_nomenclatures.get_id_nomenclature('METH_OBS', cd_nomenclature_obs_technique),
            ref_nomenclatures.get_id_nomenclature('STATUT_BIO', cd_nomenclature_bio_status),
            ref_nomenclatures.get_id_nomenclature('ETA_BIO', cd_nomenclature_bio_condition),
            ref_nomenclatures.get_id_nomenclature('NATURALITE', cd_nomenclature_naturalness),
            ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', cd_nomenclature_exist_proof),
            ref_nomenclatures.get_id_nomenclature('STATUT_VALID', cd_nomenclature_valid_status),
            ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', cd_nomenclature_diffusion_level),
            ref_nomenclatures.get_id_nomenclature('STADE_VIE', cd_nomenclature_life_stage),
            ref_nomenclatures.get_id_nomenclature('SEXE', cd_nomenclature_sex),
            ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', cd_nomenclature_obj_count),
            ref_nomenclatures.get_id_nomenclature('TYP_DENBR', cd_nomenclature_type_count),
            ref_nomenclatures.get_id_nomenclature('SENSIBILITE', cd_nomenclature_sensitivity),
            ref_nomenclatures.get_id_nomenclature('STATUT_OBS', cd_nomenclature_observation_status),
            ref_nomenclatures.get_id_nomenclature('DEE_FLOU', cd_nomenclature_blurring),
            ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', cd_nomenclature_source_status),
            ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', cd_nomenclature_info_geo_type),
            ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', cd_nomenclature_behaviour),
            ref_nomenclatures.get_id_nomenclature('STAT_BIOGEO', cd_nomenclature_biogeo_status),
            reference_biblio,
            count_min,
            count_max,
            cd_nom,
            cd_hab,
            nom_cite,
            meta_v_taxref,
            sample_number_proof,
            digital_proof,
            non_digital_proof,
            altitude_min,
            altitude_max,
            depth_min,
            depth_max,
            place_name,
            the_geom_4326,
            the_geom_point,
            the_geom_local,
            precision,
            id_area_attachment,
            date_min,
            date_max,
            validator,
            validation_comment,
            observers,
            determiner,
            ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', cd_nomenclature_determination_method),
            comment_context,
            comment_description,
            additional_data,
            meta_validation_date,
            meta_create_date,
            meta_update_date,
            last_action
        FROM gn_imports.synthese
    ;"

#+-------------------------------------------------------------------------------------------------+
# Configure PSQL
if [[ -f "~/.psqlrc.saved" ]]; then
    mv "~/.psqlrc.saved" "~/.psqlrc"
fi
