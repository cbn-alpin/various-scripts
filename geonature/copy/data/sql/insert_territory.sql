-- Add TERRITORY area for Atlas

\timing

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Disable trigger tri_insert_cor_area_synthese on l_areas table'
ALTER TABLE ref_geo.l_areas DISABLE TRIGGER tri_insert_cor_area_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert TERRITORY area type'
INSERT INTO ref_geo.bib_areas_types (
    type_name,
    type_code,
    type_desc,
    ref_name,
    ref_version
)
    SELECT
        'Territoire',
        'TERRITORY',
        'Zone concernée par toutes les observations de la base GeoNature.',
        'GeoNature',
        date_part('year', NOW())
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM ref_geo.bib_areas_types AS bat
        WHERE bat.type_code = 'TERRITORY'
    ) ;

\echo '----------------------------------------------------------------------------'
\echo 'Disable REG, SINP area if necessary'
UPDATE ref_geo.l_areas
SET "enable" = FALSE
WHERE id_type IN (
    ref_geo.get_id_area_type('SINP'),
    ref_geo.get_id_area_type('REG')
) ;

\echo '----------------------------------------------------------------------------'
\echo 'Remove previous TERRITORY area if necessary'
DELETE FROM ref_geo.l_areas
WHERE id_type = ref_geo.get_id_area_type('TERRITORY')
    AND area_code = 'TERRITORY' ;

\echo '----------------------------------------------------------------------------'
\echo 'Insert TERRITORY area'
INSERT INTO ref_geo.l_areas (
    id_type,
    area_name,
    area_code,
    geom,
    geom_4326,
    "enable"
)
	SELECT
        ref_geo.get_id_area_type('TERRITORY'),
        'Territoire',
        'TERRITORY',
        st_convexhull(st_union(st_makevalid(s.the_geom_local))) AS geom,
        st_convexhull(st_union(st_makevalid(s.the_geom_4326))) AS geom_4326,
        TRUE
    FROM gn_synthese.synthese AS s
ON CONFLICT (id_type, area_code)
DO UPDATE SET geom = EXCLUDED.geom, geom_4326 = EXCLUDED.geom_4326 ;


\echo '----------------------------------------------------------------------------'
\echo 'Disable trigger tri_insert_cor_area_synthese on l_areas table'
ALTER TABLE ref_geo.l_areas ENABLE TRIGGER tri_insert_cor_area_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
