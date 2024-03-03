-- Create a schema and view to export the synthese between databases with FDW.
-- This a template with variables to replace with Sed !

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create schema gn2gn_exports'
CREATE SCHEMA IF NOT EXISTS gn2gn_exports AUTHORIZATION ${db_user};


\echo '----------------------------------------------------------------------------'
\echo 'Create synthese view for export'
CREATE OR REPLACE VIEW gn2gn_exports.synthese AS
    SELECT
        s.unique_id_sinp,
        s.unique_id_sinp_grp,
        NULL AS id_source,
        NULL AS id_module,
        s.entity_source_pk_value,
        NULL AS id_dataset,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_geo_object_nature) AS cd_nomenclature_geo_object_nature,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_grp_typ) AS cd_nomenclature_grp_typ,
        s.grp_method,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_obs_technique) AS cd_nomenclature_obs_technique,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_status) AS cd_nomenclature_bio_status,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_condition) AS cd_nomenclature_bio_condition,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_naturalness) AS cd_nomenclature_naturalness,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_exist_proof) AS cd_nomenclature_exist_proof,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_valid_status) AS cd_nomenclature_valid_status,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_diffusion_level) AS cd_nomenclature_diffusion_level,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_life_stage) AS cd_nomenclature_life_stage,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_sex) AS cd_nomenclature_sex,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_obj_count) AS cd_nomenclature_obj_count,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_type_count) AS cd_nomenclature_type_count,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_sensitivity) AS cd_nomenclature_sensitivity,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_observation_status) AS cd_nomenclature_observation_status,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_blurring) AS cd_nomenclature_blurring,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_source_status) AS cd_nomenclature_source_status,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_info_geo_type) AS cd_nomenclature_info_geo_type,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_behaviour) AS cd_nomenclature_behaviour,
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_biogeo_status) AS cd_nomenclature_biogeo_status,
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
        ref_nomenclatures.get_cd_nomenclature(id_nomenclature_determination_method) AS cd_nomenclature_determination_method,
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
    WHERE la.area_code IN (${gn2gn_areas})
        AND ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_info_geo_type) != '2' ;


\echo '----------------------------------------------------------------------------'
\echo 'Set rights on synthese export view'
ALTER VIEW gn2gn_exports.synthese OWNER TO ${db_user};


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
