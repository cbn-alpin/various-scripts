-- Re-insert all meshes (M1, M5, M10, ...), departements (DEP), municipalities (COM)
-- and SINP area in gn_synthese.cor_area_synthese table.
--
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Transfert this script on server this way:
-- rsync -av ./reload_cor_area_synthese.sql geonat@db-paca-sinp:~/data/shared/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/shared/data/sql/reload_cor_area_synthese.sql

\timing

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create subdivided areas temporary table'

\echo 'Drop subdivided areas table'
DROP TABLE IF EXISTS ref_geo.subdivided_areas ;

\echo ' Add subdivided areas table'
-- SINP AURA Preprod: 31 735 rows in 29s 352ms
CREATE TABLE IF NOT EXISTS ref_geo.subdivided_areas AS
    SELECT
        random() AS gid,
        a.id_area AS area_id,
        bat.type_code AS code_type,
        a.area_code,
        st_subdivide(a.geom, 250) AS geom
    FROM ref_geo.l_areas AS a
        JOIN ref_geo.bib_areas_types AS bat
            ON bat.id_type = a.id_type
    WHERE a."enable" = TRUE
        AND bat.type_code NOT IN ('M1', 'M2', 'M5', 'M10', 'M20', 'M50') ;

\echo ' Create index on geom column for subdivided areas table'
CREATE INDEX IF NOT EXISTS idx_subdivided_geom
ON ref_geo.subdivided_areas USING gist(geom);

\echo ' Create index on column id_area for subdivided areas table'
CREATE INDEX IF NOT EXISTS idx_subdivided_area_id
ON ref_geo.subdivided_areas USING btree(area_id) ;


\echo '----------------------------------------------------------------------------'
\echo 'Drop geom_synthese table'
DROP TABLE IF EXISTS gn_synthese.geom_synthese ;

\echo ' Create geom_synthese temporary table with observations ids group by geom'
-- SINP AURA Preprod (29 million obs): 7 213 407 rows in 03mn 12s 407ms
CREATE TABLE IF NOT EXISTS gn_synthese.geom_synthese AS (
    SELECT
        the_geom_local,
        array_agg(id_synthese) AS id_syntheses
    FROM gn_synthese.synthese
    GROUP BY the_geom_local
) ;

\echo ' Create index on geom column for unique geom on synthese table'
-- SINP AURA Preprod: 20s 469ms
CREATE INDEX IF NOT EXISTS idx_geom_synthese_geom
ON gn_synthese.geom_synthese USING gist(the_geom_local);


\echo '----------------------------------------------------------------------------'
\echo 'Drop flatten_meshes table'
DROP TABLE IF EXISTS ref_geo.flatten_meshes ;

\echo ' Create flatten_meshes temporary table with meshes M1, M2, M5, M10, M20, M50'
-- SINP AURA Preprod: 72 230 rows in 1mn 45s 846ms
CREATE TABLE IF NOT EXISTS ref_geo.flatten_meshes AS (
    SELECT
        m1.id_area AS id_m1,
        m2.id_area AS id_m2,
        m5.id_area AS id_m5,
        m10.id_area AS id_m10,
        m20.id_area AS id_m20,
        m50.id_area AS id_m50
    FROM (
            SELECT id_area, geom, centroid
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M1')
        ) AS m1
        LEFT JOIN (
            SELECT id_area, geom
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M2')
        ) AS m2
            ON st_contains(m2.geom, m1.centroid)
        LEFT JOIN (
            SELECT id_area, geom
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M5')
        ) AS m5
            ON st_contains(m5.geom, m1.centroid)
        LEFT JOIN (
            SELECT id_area, geom
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M10')
        ) AS m10
            ON  st_contains(m10.geom, m1.centroid)
        LEFT JOIN (
            SELECT id_area, geom
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M20')
        ) AS m20
            ON st_contains(m20.geom, m1.centroid)
        LEFT JOIN (
            SELECT id_area, geom
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M50')
        ) AS m50
            ON st_contains(m50.geom, m1.centroid)
) ;

\echo ' Create index on column id_m1 for flatten_meshes table'
CREATE INDEX IF NOT EXISTS id_m1_flatten_meshes_idx
ON ref_geo.flatten_meshes USING btree(id_m1);


\echo '----------------------------------------------------------------------------'
\echo 'Drop synthese_geom_dep table'
DROP TABLE IF EXISTS gn_synthese.synthese_geom_dep ;

\echo 'Create synthese_geom_dep temporary table'
CREATE TABLE IF NOT EXISTS gn_synthese.synthese_geom_dep AS (
    SELECT DISTINCT
        s.the_geom_local AS geom,
        s.id_syntheses,
        a.area_id,
        a.area_code
    FROM gn_synthese.geom_synthese AS s
        JOIN ref_geo.subdivided_areas AS a
            ON ( a.code_type = 'DEP' AND st_intersects(s.the_geom_local, a.geom) )
) ;

\echo ' Create index on geom column for synthese_geom_dep table'
CREATE INDEX IF NOT EXISTS idx_synthese_geom_dep_geom
ON gn_synthese.synthese_geom_dep USING gist(geom);

\echo ' Create index on column area_code for synthese_geom_dep table'
CREATE INDEX IF NOT EXISTS idx_synthese_geom_dep_area_code
ON gn_synthese.synthese_geom_dep USING btree(area_code) ;


\echo '----------------------------------------------------------------------------'
\echo 'Drop area_syntheses table'
DROP TABLE IF EXISTS gn_synthese.area_syntheses ;

\echo 'Create area_syntheses temporary table'
CREATE TABLE IF NOT EXISTS gn_synthese.area_syntheses AS (
    SELECT DISTINCT
        s.id_syntheses,
        a.area_id
    FROM gn_synthese.geom_synthese AS s
        JOIN ref_geo.subdivided_areas AS a
            ON st_intersects(s.the_geom_local, a.geom)
    WHERE a.code_type NOT IN ('COM', 'DEP', 'REG', 'M1', 'M2', 'M5', 'M10', 'M20', 'M50', 'TERRITORY', 'SINP')

    UNION ALL

    SELECT DISTINCT
        s.id_syntheses,
        a.area_id
    FROM gn_synthese.synthese_geom_dep AS s
        JOIN ref_geo.subdivided_areas AS a
            ON ( a.code_type = 'COM' AND LEFT(a.area_code, 2) = s.area_code )
    WHERE st_intersects(s.geom, a.geom)

    UNION ALL

    SELECT
        id_syntheses,
        area_id
    FROM gn_synthese.synthese_geom_dep

    -- UNION ALL

    -- SELECT DISTINCT
    --     s.id_syntheses,
    --     a.id_area AS area_id
    -- FROM gn_synthese.synthese_geom_dep AS s
    --     JOIN (
    --         SELECT id_area
    --         FROM ref_geo.l_areas
    --         WHERE id_type = ref_geo.get_id_area_type('REG')
    --     ) AS a ON TRUE
) ;

\echo ' Create index on column area_id for area_syntheses table'
CREATE INDEX IF NOT EXISTS idx_area_syntheses_area_id
ON gn_synthese.area_syntheses USING btree(area_id) ;


\echo '----------------------------------------------------------------------------'
\echo 'Drop synthese_geom_m1 table'
DROP TABLE IF EXISTS gn_synthese.synthese_geom_m1 ;

\echo 'Create synthese_geom_m1 temporary table'
-- SINP AURA Preprod: 7 483 988 rows in 1mn 42s
CREATE TABLE IF NOT EXISTS gn_synthese.synthese_geom_m1 AS (
    SELECT DISTINCT
        s.id_syntheses,
        a.id_area AS id_m1
    FROM gn_synthese.geom_synthese AS s
        INNER JOIN ref_geo.l_areas AS a
            ON (
                a.id_type = ref_geo.get_id_area_type('M1')
                AND st_intersects(s.the_geom_local, a.geom)
            )
) ;

\echo ' Create index on column id_m1 for synthese_geom_m1 table'
-- 6s
CREATE INDEX IF NOT EXISTS idx_synthese_geom_m1_id_m1
ON gn_synthese.synthese_geom_m1 USING btree(id_m1) ;


\echo '----------------------------------------------------------------------------'
\echo 'Drop synthese_geom_meshes table'
DROP TABLE IF EXISTS gn_synthese.synthese_geom_meshes ;

\echo 'Create synthese_geom_meshes temporary table'
-- SINP AURA Preprod: 43 677 186 rows in 7mn 21s
CREATE TABLE IF NOT EXISTS gn_synthese.synthese_geom_meshes AS (
    SELECT
        id_syntheses,
        id_m1 AS id_mesh
    FROM gn_synthese.synthese_geom_m1

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m2 AS id_mesh
    FROM gn_synthese.synthese_geom_m1 AS sgm
        LEFT JOIN ref_geo.flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1
    WHERE fm.id_m2 IS NOT NULL

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m5 AS id_mesh
    FROM gn_synthese.synthese_geom_m1 AS sgm
        LEFT JOIN ref_geo.flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1
    WHERE fm.id_m5 IS NOT NULL

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m10 AS id_mesh
    FROM gn_synthese.synthese_geom_m1 AS sgm
        LEFT JOIN ref_geo.flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1
    WHERE fm.id_m10 IS NOT NULL

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m20 AS id_mesh
    FROM gn_synthese.synthese_geom_m1 AS sgm
        LEFT JOIN ref_geo.flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1
    WHERE fm.id_m20 IS NOT NULL

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m50 AS id_mesh
    FROM gn_synthese.synthese_geom_m1 AS sgm
        LEFT JOIN ref_geo.flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1
    WHERE fm.id_m50 IS NOT NULL
) ;

\echo ' Create index on column id_mesh for synthese_geom_meshes table'
-- 36s
CREATE INDEX IF NOT EXISTS idx_synthese_geom_meshes_id_mesh
ON gn_synthese.synthese_geom_meshes USING btree(id_mesh) ;


\echo '----------------------------------------------------------------------------'
\echo 'Drop synthese_territory table'
DROP TABLE IF EXISTS gn_synthese.synthese_territory ;

\echo 'Create synthese_territory temporary table'
-- SINP AURA Preprod: 29 175 104 rows in 56s
CREATE TABLE IF NOT EXISTS gn_synthese.synthese_territory AS (
    WITH sinp AS (
        SELECT id_area
        FROM ref_geo.l_areas
        WHERE id_type = ref_geo.get_id_area_type('TERRITORY')
        LIMIT 1
    )
    SELECT
        s.id_synthese,
        sinp.id_area
    FROM gn_synthese.synthese AS s, sinp
) ;

\echo ' Create index on column id_synthese for synthese_territory table'
CREATE INDEX IF NOT EXISTS idx_synthese_territory_id_synthese
ON gn_synthese.synthese_territory USING btree(id_synthese) ;


\echo '----------------------------------------------------------------------------'
\echo 'Delete cor_area_synthese indexes and constraints'
-- Don't drop id_area index because it's used by delete queries
-- DROP INDEX IF EXISTS gn_synthese.cor_area_synthese_id_area_idx ;

DROP INDEX IF EXISTS gn_synthese.cor_area_synthese_id_synthese_idx ;

ALTER TABLE gn_synthese.cor_area_synthese
DROP CONSTRAINT IF EXISTS fk_cor_area_synthese_id_area ;

ALTER TABLE gn_synthese.cor_area_synthese
DROP CONSTRAINT IF EXISTS fk_cor_area_synthese_id_synthese ;

ALTER TABLE gn_synthese.cor_area_synthese
DROP CONSTRAINT IF EXISTS pk_cor_area_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'Reinsert all non-orthogonal areas in cor_area_synthese (except TERRITORY)'

\echo ' Clean non-orthogonal areas in table cor_area_synthese'
-- SINP AURA Preprod: 99 824 926 rows in 5mn 04s 582ms
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type IN (
        SELECT id_type
        FROM ref_geo.bib_areas_types
        WHERE type_code NOT IN ('M1', 'M2', 'M5', 'M10', 'M20', 'M50', 'TERRITORY')
    )
) ;

\echo ' Reinsert non-orthogonal areas'
-- SINP AURA Preprod: 100 237 094 rows in 8mn 35s
DO $$
DECLARE
    step INTEGER;
    stopAt INTEGER;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    SELECT COUNT(*) INTO stopAt FROM gn_synthese.area_syntheses ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to insert in "synthese" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to insert % observations from %', step, offsetCnt ;

        WITH admin_zones AS (
            SELECT
                id_syntheses,
                area_id
            FROM gn_synthese.area_syntheses AS a
            ORDER BY a.area_id ASC
            OFFSET offsetCnt
            LIMIT step
        )
        INSERT INTO gn_synthese.cor_area_synthese (
            id_synthese,
            id_area
        )
            SELECT
                UNNEST(id_syntheses) AS id_synthese,
                area_id
            FROM admin_zones ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted cor_area_synthese rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'Reinsert all meshes (M1, M2, M5, M10, M20, M50) in cor_area_synthese'

\echo ' Clean meshes in table cor_area_synthese'
-- SINP AURA Preprod: 375 695 806 in 8mn 20s
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type IN (
        ref_geo.get_id_area_type('M1'),
        ref_geo.get_id_area_type('M2'),
        ref_geo.get_id_area_type('M5'),
        ref_geo.get_id_area_type('M10'),
        ref_geo.get_id_area_type('M20'),
        ref_geo.get_id_area_type('M50')
    )
) ;

\echo ' Reinsert all meshes'
-- SINP AURA Preprod: 336 482 236 rows in ~60mn
DO $$
DECLARE
    step INTEGER;
    stopAt INTEGER;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    SELECT COUNT(*) INTO stopAt FROM gn_synthese.synthese_geom_meshes ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to insert in "synthese" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to insert % observations from %', step, offsetCnt ;

        WITH meshes AS (
            SELECT
                id_syntheses,
                id_mesh
            FROM gn_synthese.synthese_geom_meshes AS sgm
            ORDER BY sgm.id_mesh ASC
            OFFSET offsetCnt
            LIMIT step
        )
        INSERT INTO gn_synthese.cor_area_synthese (
            id_synthese,
            id_area
        )
            SELECT
                UNNEST(id_syntheses) AS id_synthese,
                id_mesh
            FROM meshes ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted cor_area_synthese rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;



\echo '----------------------------------------------------------------------------'
\echo 'Reinsert all observations link to TERRITORY in cor_area_synthese'

\echo ' Clean TERRITORY area in table cor_area_synthese'
-- SINP AURA Preprod: 28 987 775 in 3mn 32s
WITH sinp AS (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type = ref_geo.get_id_area_type('TERRITORY')
    LIMIT 1
)
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM sinp
) ;

\echo ' Reinsert all observations in cor_area_synthese link to TERRITORY area'
-- SINP AURA Preprod: 29 175 104 rows in 2mn 35s
DO $$
DECLARE
    step INTEGER;
    stopAt INTEGER;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    SELECT COUNT(*) INTO stopAt FROM gn_synthese.synthese_territory ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to insert in "synthese" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to insert % observations from %', step, offsetCnt ;

        INSERT INTO gn_synthese.cor_area_synthese (
            id_synthese,
            id_area
        )
            SELECT
                id_synthese,
                id_area
            FROM gn_synthese.synthese_territory AS ss
            ORDER BY ss.id_synthese ASC
            OFFSET offsetCnt
            LIMIT step ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted cor_area_synthese rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'Recreate cor_area_synthese indexes and constraints'
-- 10mn 39s
ALTER TABLE gn_synthese.cor_area_synthese
ADD CONSTRAINT pk_cor_area_synthese PRIMARY KEY (id_synthese, id_area) ;

-- 2mn 57s
ALTER TABLE gn_synthese.cor_area_synthese
ADD CONSTRAINT fk_cor_area_synthese_id_area
FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
ON DELETE CASCADE ON UPDATE CASCADE ;

-- 4mn 25s
ALTER TABLE gn_synthese.cor_area_synthese
ADD CONSTRAINT fk_cor_area_synthese_id_synthese
FOREIGN KEY (id_synthese) REFERENCES gn_synthese.synthese(id_synthese)
ON DELETE CASCADE ON UPDATE CASCADE ;

-- The id_area index was not deleted because delete queries uses it.
-- 7mn
-- CREATE INDEX cor_area_synthese_id_area_idx
-- ON gn_synthese.cor_area_synthese USING btree(id_area);

-- 8mn 11s
CREATE INDEX cor_area_synthese_id_synthese_idx
ON gn_synthese.cor_area_synthese USING btree(id_synthese);


\echo '----------------------------------------------------------------------------'
\echo 'Clean all temporary tables'

\echo ' Drop subdivided non-orthogonal areas table'
DROP TABLE IF EXISTS ref_geo.subdivided_areas ;

\echo ' Drop geom_synthese table'
DROP TABLE IF EXISTS gn_synthese.geom_synthese ;

\echo ' Drop flatten_meshes table'
DROP TABLE IF EXISTS ref_geo.flatten_meshes ;

\echo ' Drop synthese_geom_dep table'
DROP TABLE IF EXISTS gn_synthese.synthese_geom_dep ;

\echo ' Drop area_syntheses table'
DROP TABLE IF EXISTS gn_synthese.area_syntheses ;

\echo ' Drop synthese_geom_m1 table'
DROP TABLE IF EXISTS gn_synthese.synthese_geom_m1 ;

\echo ' Drop synthese_geom_meshes table'
DROP TABLE IF EXISTS gn_synthese.synthese_geom_meshes ;

\echo ' Drop synthese_territory table'
DROP TABLE IF EXISTS gn_synthese.synthese_territory ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
