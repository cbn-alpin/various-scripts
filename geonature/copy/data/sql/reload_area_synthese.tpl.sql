-- Re-insert all meshes (M1, M5, M10) and others areas with polygonal geometries
-- in gn_synthese.cor_area_synthese table.

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Create subdivided areas table for faster cor_area_synthese reinsert'

\echo ' Drop subdivided areas table if necessary'
DROP TABLE IF EXISTS ref_geo.tmp_subdivided_areas ;

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
\echo 'Reinsert all data in cor_area_synthese'

\echo ' Truncate all cor_area_synthese entries'
TRUNCATE TABLE gn_synthese.cor_area_synthese ;

\echo ' Reinsert polygonal geometries'
INSERT INTO gn_synthese.cor_area_synthese
    SELECT DISTINCT
        s.id_synthese,
        a.area_id
    FROM gn_synthese.synthese AS s
        JOIN ref_geo.tmp_subdivided_areas AS a
            ON public.st_intersects(s.the_geom_local, a.geom) ;

\echo ' Reinsert meshes'
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
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
