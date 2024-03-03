-- Re-insert all meshes (M1, M5, M10) and others areas with polygonal geometries
-- in gn_synthese.cor_area_synthese table.

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Create subdivided areas table for faster cor_area_synthese reinsert'

\echo ' Add subdivided areas table'
CREATE TABLE IF NOT EXISTS ref_geo.tmp_subdivided_areas AS
    SELECT
        random() AS gid,
        a.id_area AS area_id,
        st_subdivide(a.geom, 250) AS geom
    FROM ref_geo.l_areas AS a
    WHERE a."enable" = TRUE
        AND a.id_type NOT IN (
            ref_geo.get_id_area_type('M10'),
            ref_geo.get_id_area_type('M5'),
            ref_geo.get_id_area_type('M1')
        ) ;

\echo ' Create index on geom column for subdivided areas table'
CREATE INDEX IF NOT EXISTS idx_tmp_subdivided_geom ON ref_geo.tmp_subdivided_areas USING gist (geom);

\echo ' Create index on column id_area for subdivided areas table'
CREATE INDEX IF NOT EXISTS idx_tmp_subdivided_area_id ON ref_geo.tmp_subdivided_areas USING btree(area_id) ;

\echo 'Set rights on subdivided areas table'
ALTER TABLE ref_geo.tmp_subdivided_areas OWNER TO ${db_user};

\echo '----------------------------------------------------------------------------'
\echo 'Reinsert data in cor_area_synthese for source: ${gn2gn_source}'

-- TRUNCATE TABLE cor_area_synthese ;
-- TO AVOID TRUNCATE : add condition on id_source or id_dataset to reduce synthese table entries in below inserts

\echo ' Clean observations in table cor_area_synthese'
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_synthese IN (
    SELECT id_synthese
    FROM gn_synthese.synthese
    WHERE id_source = gn_synthese.get_id_source_by_name('${gn2gn_source}')
) ;

\echo ' Reinsert polygonal geometries'
-- ~35mn for ~1,000 areas and ~6,000,000 of rows in synthese table on SSD NVME disk
INSERT INTO gn_synthese.cor_area_synthese
    SELECT DISTINCT
        s.id_synthese,
        a.area_id
    FROM gn_synthese.synthese AS s
        JOIN ref_geo.tmp_subdivided_areas AS a
            ON public.st_intersects(s.the_geom_local, a.geom)
    WHERE s.id_source = gn_synthese.get_id_source_by_name('${gn2gn_source}') ;

\echo ' Reinsert meshes'
-- ~3mn for ~35,000 areas and ~6,000,000 of rows in synthese table on SSD NVME disk
INSERT INTO gn_synthese.cor_area_synthese
    SELECT
        s.id_synthese,
        a.id_area
    FROM ref_geo.l_areas AS a
        JOIN gn_synthese.synthese AS s
            ON (a.geom && s.the_geom_local) -- Postgis operator && : https://postgis.net/docs/geometry_overlaps.html
    WHERE a.id_type IN (
            ref_geo.get_id_area_type('M10'), -- Mailles 10*10
            ref_geo.get_id_area_type('M5'), -- Mailles 5*5
            ref_geo.get_id_area_type('M1') -- Mailles 1*1
        )
        AND s.id_source = gn_synthese.get_id_source_by_name('${gn2gn_source}') ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
