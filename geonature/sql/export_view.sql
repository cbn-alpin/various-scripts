CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_tests
AS 
SELECT 
	--s.id_synthese AS "id_synthese",
    s.unique_id_sinp AS "unique_id_sinp",
    s.unique_id_sinp_grp AS "unique_id_sinp_grp",
    CONCAT('gn_synthese.get_id_source(''', sources.name_source, ''')') AS "id_source",
    'gn_commons.get_id_module(''SYNTHESE'')' AS "id_module",
    s.entity_source_pk_value AS "entity_source_pk_value",
    CONCAT('gn_meta.get_id_dataset(''', d.unique_dataset_id, ''')') AS "id_dataset",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''NAT_OBJ_GEO'', ''', n1.label_default, ''')') AS "id_nomenclature_geo_object_nature",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''TYP_GRP'', ''', n2.label_default, ''')') AS "id_nomenclature_grp_typ",
    --s.grp_method AS "grp_method",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''METH_OBS'', ''', n3.label_default, ''')') AS "id_nomenclature_obs_technique",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''STATUT_BIO'', ''', n5.label_default, ''')') AS "id_nomenclature_bio_status",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''ETA_BIO'', ''', n6.label_default, ''')') AS "id_nomenclature_bio_condition",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''NATURALITE'', ''', n7.label_default, ''')') AS "id_nomenclature_naturalness",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''PREUVE_EXIST'', ''', n8.label_default, ''')') AS "id_nomenclature_exist_proof",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''STATUT_VALID'', ''', n21.label_default, ''')') AS "id_nomenclature_valid_status",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''NIV_PRECIS'', ''', n9.label_default, ''')') AS "id_nomenclature_diffusion_level",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''STADE_VIE'', ''', n10.label_default, ''')') AS "id_nomenclature_life_stage",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''SEXE'', ''', n11.label_default, ''')') AS "id_nomenclature_sex",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''OBJ_DENBR'', ''', n12.label_default, ''')') AS "id_nomenclature_obj_count",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''TYP_DENBR'', ''', n13.label_default, ''')') AS "id_nomenclature_type_count",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''SENSIBILITE'', ''', n14.label_default, ''')') AS "id_nomenclature_sensitivity",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''STATUT_OBS'', ''', n15.label_default, ''')') AS "id_nomenclature_observation_status",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''DEE_FLOU'', ''', n16.label_default, ''')') AS "id_nomenclature_blurring",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''STATUT_SOURCE'', ''', n17.label_default, ''')') AS "id_nomenclature_source_status",
    CONCAT('ref_nomenclatures.get_id_nomenclature(''TYP_INF_GEO'', ''', n18.label_default, ''')') AS "id_nomenclature_info_geo_type",
    --CONCAT('ref_nomenclatures.get_id_nomenclature(''OCC_COMPORTEMENT'', ''', n20.label_default, ''')') AS "id_nomenclature_behaviour",
    --CONCAT('ref_nomenclatures.get_id_nomenclature(''STAT_BIOGEO'', ''', n22.label_default, ''')') AS "id_nomenclature_biogeo_status",
    --s.reference_biblio AS "reference_biblio",
    s.count_min AS "count_min",
    s.count_max AS "count_max",
    s.cd_nom AS "cd_nom",
    --s.cd_hab AS "cd_hab",
    s.nom_cite AS "nom_cite",
    --s.meta_v_taxref,
    s.sample_number_proof AS "sample_number_proof",
    s.digital_proof AS "digital_proof",
    s.non_digital_proof AS "non_digital_proof",
    s.altitude_min AS "altitude_min",
    s.altitude_max AS "altitude_max",
    --s.depth_min AS "depth_min",
    --s.depth_max AS "depth_max",
    --s.place_name AS "place_name",
    s.the_geom_4326 AS "the_geom_4326",
    s.the_geom_point AS "the_geom_point",
    s.the_geom_local AS "the_geom_local",
    --s.precision AS "precision",
    --s.id_area_attachment,
    s.date_min AS "date_min",
    s.date_max AS "date_max",
    s.validator AS "validator",
    s.validation_comment AS "validation_comment",
    s.observers AS "observers",
    s.determiner AS "determiner",
    --s.id_digitiser,
    CONCAT('ref_nomenclatures.get_id_nomenclature(''METH_DETERMIN'', ''', n19.label_default, ''')') AS "id_nomenclature_determination_method",
    s.comment_context AS "comment_context",
    s.comment_description AS "comment_description",
    --s.additional_data,
    s.meta_validation_date,
    s.meta_create_date,
    s.meta_update_date,
    s.last_action
    --s.id_nomenclature_obs_meth
FROM gn_synthese.synthese AS s
    JOIN gn_synthese.t_sources AS sources 
        ON (sources.id_source = s.id_source)
    JOIN gn_meta.t_datasets AS d 
        ON (d.id_dataset = s.id_dataset)
    JOIN gn_synthese.cor_area_synthese AS cas
        ON (cas.id_synthese = s.id_synthese)
    LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s.id_nomenclature_grp_typ = n2.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s.id_nomenclature_obs_technique = n3.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n6 ON s.id_nomenclature_bio_condition = n6.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n7 ON s.id_nomenclature_naturalness = n7.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n8 ON s.id_nomenclature_exist_proof = n8.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s.id_nomenclature_sex = n11.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n12 ON s.id_nomenclature_obj_count = n12.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n13 ON s.id_nomenclature_type_count = n13.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n14 ON s.id_nomenclature_sensitivity = n14.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s.id_nomenclature_observation_status = n15.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n16 ON s.id_nomenclature_blurring = n16.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n18 ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n19 ON s.id_nomenclature_determination_method = n19.id_nomenclature
    --LEFT JOIN ref_nomenclatures.t_nomenclatures n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n21 ON s.id_nomenclature_valid_status = n21.id_nomenclature
    --LEFT JOIN ref_nomenclatures.t_nomenclatures n22 ON s.id_nomenclature_biogeo_status = n22.id_nomenclature
WHERE id_area IN (26606, 26607) -- Chabottes, Saint-Laurent-du-Cros
;