BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Add CBNA as organism'
INSERT INTO utilisateurs.bib_organismes (
    uuid_organisme,
    nom_organisme,
    adresse_organisme,
    cp_organisme,
    ville_organisme,
    tel_organisme,
    fax_organisme,
    email_organisme,
    url_organisme,
    url_logo
)
SELECT
    'f80af199-2873-499a-b4e1-99078873fb47',
    'Conservatoire Botanique National Alpin',
    'Domaine de Charance',
    '05000',
    'Gap',
    '04 92 53 56 82',
    '04 92 51 94 58',
    'accueil@cbn-alpin.fr',
    'http://www.cbn-alpin.fr',
    'http://www.cbn-alpin.fr/images/stories/habillage/logo-cbna.jpg'
WHERE NOT EXISTS (
    SELECT 'X'
    FROM utilisateurs.bib_organismes AS bo
    WHERE bo.uuid_organisme = 'f80af199-2873-499a-b4e1-99078873fb47'
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Create acquisition framework for CBNA'
INSERT INTO gn_meta.t_acquisition_frameworks (
    unique_acquisition_framework_id,
    acquisition_framework_name,
    acquisition_framework_desc,
    id_nomenclature_territorial_level,
    territory_desc,
    keywords,
    id_nomenclature_financing_type,
    target_description,
    ecologic_or_geologic_target,
    acquisition_framework_parent_id,
    is_parent,
    acquisition_framework_start_date,
    acquisition_framework_end_date
)
SELECT
    '54d26761-2859-49d2-bb87-ef97448c8a27',
    'Observations Flore (CBNA)',
    'Ensemble desobservations Faune transmises par le CBNA dans le cadre du SINP régional.',
    ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '5'),-- Régional
    'Région Sud (Provence-Alpes-Côte d''Azur).',
    'Observations, Flore, Région, Sud, PACA, Provence, Alpes, Côte d''Azur.',
    ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '3'),-- Mélange public et privé
    'Silene est la plateforme de la région Sud (PACA) du Système d’Information de l’iNventaire du Patrimoine naturel (SINP).',
    'Flore',
    NULL,
    false,
    '1988-01-01',
    NULL
WHERE NOT EXISTS(
    SELECT 'X'
    FROM gn_meta.t_acquisition_frameworks AS tafe
    WHERE tafe.unique_acquisition_framework_id = '54d26761-2859-49d2-bb87-ef97448c8a27'
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and actor'
INSERT INTO gn_meta.cor_acquisition_framework_actor (
    id_acquisition_framework,
    id_organism,
    id_nomenclature_actor_role
) VALUES (
    gn_meta.get_id_acquisition_framework_by_uuid('54d26761-2859-49d2-bb87-ef97448c8a27'), -- Observations Flore (CBNA)
    utilisateurs.get_id_organism_by_uuid('f80af199-2873-499a-b4e1-99078873fb47'), -- CBNA
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1') -- Contact principal
)
ON CONFLICT ON CONSTRAINT check_is_unique_cor_acquisition_framework_actor_organism DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and objectifs'
INSERT INTO gn_meta.cor_acquisition_framework_objectif (
    id_acquisition_framework,
    id_nomenclature_objectif
) VALUES
    (
        gn_meta.get_id_acquisition_framework_by_uuid('54d26761-2859-49d2-bb87-ef97448c8a27'), -- Observations Flore (CBNA)
        ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '8') -- Inventaire espèce
    ),
    (
        gn_meta.get_id_acquisition_framework_by_uuid('54d26761-2859-49d2-bb87-ef97448c8a27'), -- Observations Flore (CBNA)
        ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '11') -- Multiples ou autres
    )
ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_objectif DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and SINP "volet"'
INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (
    id_acquisition_framework,
    id_nomenclature_voletsinp
) VALUES
    (
        gn_meta.get_id_acquisition_framework_by_uuid('54d26761-2859-49d2-bb87-ef97448c8a27'), -- Observations Flore (CBNA)
        ref_nomenclatures.get_id_nomenclature('VOLET_SINP', '1') -- Terre
    )
ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_voletsinp DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Create CBNA datasets in acquisition framework'
INSERT INTO gn_meta.t_datasets (
    unique_dataset_id,
    id_acquisition_framework,
    dataset_name,
    dataset_shortname,
    dataset_desc,
    id_nomenclature_data_type,
    keywords,
    marine_domain,
    terrestrial_domain,
    id_nomenclature_dataset_objectif,
    bbox_west,
    bbox_east,
    bbox_south,
    bbox_north,
    id_nomenclature_collecting_method,
    id_nomenclature_data_origin,
    id_nomenclature_source_status,
    id_nomenclature_resource_type,
    active,
    validable
)
SELECT
    '${gn2gn_dataset_uuid}',
    gn_meta.get_id_acquisition_framework_by_uuid('54d26761-2859-49d2-bb87-ef97448c8a27'), -- Observations Flore (CBNA)
    'Données flore du CBNA',
    'DFCBNA',
    'Ensemble des données flore du CBNA pour test.',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'), -- Occurrences de Taxons
    'Flore, test, CBNA.',
    false,
    true,
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '7.1'), -- Regroupement de données
    NULL,
    NULL,
    NULL,
    NULL,
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'), -- Observation directe
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'NSP'), -- Ne sait pas
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'NSP'), -- Ne sait pas
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'), -- Dataset
    true,
    true
WHERE NOT EXISTS(
    SELECT 'X'
    FROM gn_meta.t_datasets AS td
    WHERE td.unique_dataset_id = '${gn2gn_dataset_uuid}'
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between datasets and actors'
INSERT INTO gn_meta.cor_dataset_actor (
    id_dataset,
    id_organism,
    id_nomenclature_actor_role
) VALUES
    (
        gn_meta.get_id_dataset_by_uuid('b3988db2-2c94-4e1f-86f3-3a7184fc5f71'), -- DFCBNA
        utilisateurs.get_id_organism_by_uuid('f80af199-2873-499a-b4e1-99078873fb47'), -- CBNA
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1') -- Contact principal
    )
ON CONFLICT ON CONSTRAINT check_is_unique_cor_dataset_actor_organism DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between datasets and modules'
INSERT INTO gn_commons.cor_module_dataset (
    id_module,
    id_dataset
) VALUES
    (
        gn_commons.get_id_module_by_code('SYNTHESE'),
        gn_meta.get_id_dataset_by_uuid('b3988db2-2c94-4e1f-86f3-3a7184fc5f71') -- DFCBNA
    )
ON CONFLICT ON CONSTRAINT pk_cor_module_dataset DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert source import infos'
INSERT INTO gn_synthese.t_sources (
    name_source,
    desc_source,
    entity_source_pk_field
)
SELECT
    '${gn2gn_source}',
    'Partial import from ${gn2gn_pg_db_src} for area_code ${gn2gn_areas_protected}.',
    'id_synthese'
WHERE NOT EXISTS(
    SELECT 'X'
    FROM gn_synthese.t_sources AS ts
    WHERE ts.name_source = '${gn2gn_source}'
) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
