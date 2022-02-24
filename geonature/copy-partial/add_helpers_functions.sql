
-- Rights : SUPER USER
-- Create import table from source table.
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Add get_id_organization()'
CREATE OR REPLACE FUNCTION utilisateurs.get_id_organization(organizationUuid UUID)
 RETURNS int AS
$BODY$
-- Function which return the id_dataset from a dataset UUID
DECLARE idOrganization INTEGER;
BEGIN
  SELECT id_organisme INTO idOrganization
  FROM utilisateurs.bib_organismes
  WHERE uuid_organisme = organizationUuid ;
  RETURN idOrganization ;
END ;
$BODY$
  LANGUAGE plpgsql IMMUTABLE ;


\echo '----------------------------------------------------------------------------'
\echo 'Add get_id_acquisition_framework()'
CREATE OR REPLACE FUNCTION gn_meta.get_id_acquisition_framework(acquisitionFrameworkUuid UUID)
 RETURNS int AS
$BODY$
-- Function which return the id_acquisition_framework from a acquisition framework UUID
DECLARE idAcquisitionFramework INTEGER;
BEGIN
  SELECT id_acquisition_framework INTO idAcquisitionFramework
  FROM gn_meta.t_acquisition_frameworks
  WHERE unique_acquisition_framework_id = acquisitionFrameworkUuid ;
  RETURN idAcquisitionFramework ;
END ;
$BODY$
  LANGUAGE plpgsql IMMUTABLE ;


\echo '----------------------------------------------------------------------------'
\echo 'Add get_id_dataset()'
CREATE OR REPLACE FUNCTION gn_meta.get_id_dataset(datasetUuid UUID)
 RETURNS int AS
$BODY$
-- Function which return the id_dataset from a dataset UUID
DECLARE idDataset INTEGER;
BEGIN
  SELECT id_dataset INTO idDataset
  FROM gn_meta.t_datasets
  WHERE unique_dataset_id = datasetUuid ;
  RETURN idDataset ;
END ;
$BODY$
  LANGUAGE plpgsql IMMUTABLE ;


\echo '----------------------------------------------------------------------------'
\echo 'Add get_id_source()'
CREATE OR REPLACE FUNCTION gn_synthese.get_id_source(sourceName character varying)
 RETURNS int AS
$BODY$
-- Function which return the id_source from a source name
DECLARE idSource INTEGER;
BEGIN
  SELECT id_source INTO idSource
  FROM gn_synthese.t_sources
  WHERE name_source = sourceName ;
  RETURN idSource ;
END ;
$BODY$
  LANGUAGE plpgsql IMMUTABLE ;


\echo '----------------------------------------------------------------------------'
\echo 'Add get_id_module()'
CREATE OR REPLACE FUNCTION gn_commons.get_id_module(moduleCode character varying)
 RETURNS int AS
$BODY$
-- Function which return the id_module from a module code
DECLARE idModule INTEGER;
BEGIN
  SELECT id_module INTO idModule
  FROM gn_commons.t_modules
  WHERE module_code ILIKE moduleCode ;
  RETURN idModule ;
END ;
$BODY$
  LANGUAGE plpgsql IMMUTABLE ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
