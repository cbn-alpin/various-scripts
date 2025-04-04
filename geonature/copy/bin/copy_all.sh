#!/bin/bash
# Encoding : UTF-8
# Copy data between a SINP GeoNature database and a development GeoNature database (v2.13.3+).

#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE)[options]
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: name of config file to use with this script
     -i | --in: name of source database
     -o | --out: name of destination database
EOF
    exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "${@}"; do
        shift
        case "${arg}" in
            "--help") set -- "${@}" "-h" ;;
            "--verbose") set -- "${@}" "-v" ;;
            "--debug") set -- "${@}" "-x" ;;
            "--config") set -- "${@}" "-c" ;;
            "--input") set -- "${@}" "-i" ;;
            "--output") set -- "${@}" "-o" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:i:o:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "i") gn2gn_pg_db_src="${OPTARG}" ;;
            "o") gn2gn_pg_db_dest="${OPTARG}" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    current_dir=$(dirname "${BASH_SOURCE[0]}")
    source "${current_dir}/../../../shared/lib/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${gn2gn_log}"
    checkSuperuser

    # Prepare Gn2Gn running
    source "${lib_dir}/copying.bash"
    runCommonChecks
    prepareEnv
    prepareParameters

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} started at: ${fmt_time_start}"

    setHelpersFunctions
    truncateDestTables
    resetSequences
    copySources
    copyOrganims
    copyNomenclatures
    copyTaxonomy
    copyGeography
    copyUsers
    copyPermissions
    copyAcquisitionFrameworks
    copyDatasets
    copySynthese
    enableSyntheseTriggers
    resetSequences
    copyCommons
    createTerritory
    reloadAllAreasObservationsLinks

    # Finalize Gn2Gn run
    restoreEnv

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function truncateDestTables() {
    printMsg "Tuncate destination tables"
    executeQueryInDestDb 'TRUNCATE
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
}

function copySources() {
    printMsg "Copy sources"
    copy "gn_synthese.t_sources (
        id_source, name_source, desc_source, entity_source_pk_field, url_source,
        meta_create_date, meta_update_date
    )"
}

function copyOrganims() {
    printMsg "Copy organisms"
    copy "utilisateurs.bib_organismes (
        id_organisme, uuid_organisme, nom_organisme, adresse_organisme, cp_organisme,
        ville_organisme, tel_organisme, fax_organisme, email_organisme, url_organisme,
        url_logo, id_parent
    )"
}

function copyNomenclatures() {
    printMsg "Copy nomenclatures"
    copy "ref_nomenclatures.bib_nomenclatures_types"
    copy "ref_nomenclatures.t_nomenclatures"
    copy "ref_nomenclatures.defaults_nomenclatures_value"
}

function copyTaxonomy() {
    printMsg "Copy taxonomy"
    copy "taxonomie.bib_noms (id_nom, cd_nom, cd_ref, nom_francais, comments)" "taxonomie.bib_noms"
}

function copyGeography() {
    printMsg "Copy geography"
    copy "ref_geo.bib_areas_types"
    copy "( SELECT
            id_area, id_type, area_name, area_code, geom, st_transform(geom, 4326) AS geom_4326,
            centroid, source, comment, enable, additional_data, meta_create_date, meta_update_date
            FROM ref_geo.l_areas
        )" \
        "ref_geo.l_areas (
            id_area, id_type, area_name, area_code, geom, geom_4326,
            centroid, source, comment, enable, additional_data, meta_create_date, meta_update_date
        )"
    copy "ref_geo.li_grids"
    copy "ref_geo.li_municipalities"
}

function copyUsers() {
    printMsg "Copy users"

    copy "utilisateurs.t_roles"
    copy "utilisateurs.cor_roles"
    copy "utilisateurs.cor_role_token"
    copy "utilisateurs.t_applications"
    copy "utilisateurs.cor_role_app_profil"
    copy "utilisateurs.cor_profil_for_app"
}

function copyPermissions() {
    printMsg "Copy permissions"

    executeFileInDestDb "${sql_dir}/default_permissions.sql"
}

function copyAcquisitionFrameworks() {
    printMsg "Copy acquisition frameworks"
    copy "gn_meta.t_acquisition_frameworks"
    copy "gn_meta.sinp_datatype_publications"
    copy "gn_meta.t_bibliographical_references"
    copy "gn_meta.cor_acquisition_framework_voletsinp"
    copy "gn_meta.cor_acquisition_framework_territory"
    copy "gn_meta.cor_acquisition_framework_publication"
    copy "gn_meta.cor_acquisition_framework_objectif"
    copy "gn_meta.cor_acquisition_framework_actor"
}

function copyDatasets() {
    printMsg "Copy datasets"
    copy "gn_meta.t_datasets (
            id_dataset, unique_dataset_id, id_acquisition_framework, dataset_name, dataset_shortname,
            dataset_desc, id_nomenclature_data_type, keywords, marine_domain, terrestrial_domain,
            id_nomenclature_dataset_objectif, bbox_west, bbox_east, bbox_south, bbox_north,
            id_nomenclature_collecting_method, id_nomenclature_data_origin, id_nomenclature_source_status,
            id_nomenclature_resource_type, active, validable, id_digitizer, id_taxa_list,
            meta_create_date, meta_update_date
        )" \
        "gn_meta.t_datasets"
    copy "gn_meta.sinp_datatype_protocols"
    copy "gn_meta.cor_dataset_territory"
    copy "gn_meta.cor_dataset_protocol"
    copy "gn_meta.cor_dataset_actor"
}

function copySynthese() {
    printMsg "Copy synthese"

    disableSyntheseTriggers

    # TODO: Add id_area_attachement to 1,5 millions observations with
    # id_nomenclature_info_geo_type code = 2 and id_area_attachment IS NULL.
    # For now, remove constraint.
    executeQueryInDestDb "ALTER TABLE gn_synthese.synthese
        DROP CONSTRAINT IF EXISTS check_synthese_info_geo_type_id_area_attachment ;"

    # Remove temporary Taxref constraint
    executeQueryInDestDb "ALTER TABLE gn_synthese.synthese
        DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom ;"

    copy "gn_synthese.defaults_nomenclatures_value"
    copy "gn_synthese.synthese"

    # Restore TaxRef constraint
    executeQueryInDestDb "UPDATE gn_synthese.synthese AS s
        SET cd_nom = NULL
        WHERE NOT EXISTS (
            SELECT 'X' FROM taxonomie.taxref AS t WHERE t.cd_nom = s.cd_nom
        ) ;"
    executeQueryInDestDb "ALTER TABLE gn_synthese.synthese
        ADD CONSTRAINT fk_synthese_cd_nom
        FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom)
        ON UPDATE CASCADE ;"

    checkSuperuser
    enableSyntheseTriggers
}

function resetSequences() {
    printMsg "Resets sequences"

    executeQueryInDestDb "SELECT
            substring(column_default, '''(.*)'''),
            reset_sequence(table_schema, table_name, column_name, substring(column_default, '''(.*)'''))
        FROM information_schema.columns
        WHERE column_default LIKE 'nextval%' ;"
}

function copyCommons() {
    printMsg "Copy commons"

    copy "gn_commons.t_parameters"
    copy "gn_commons.cor_module_dataset"
}

function createTerritory() {
    printMsg "Create territory area entry if necessary"

    executeFileInDestDb "${sql_dir}/insert_territory.sql"
}

function reloadAllAreasObservationsLinks() {
    printMsg "Create all areas observations links"

    cat "${sql_dir}/reload_area_synthese.tpl.sql" | \
        sed "s/\${db_user}/${db_user}/g" \
        > "${raw_dir}/reload_area_synthese.sql"
    executeFileInDestDb "${raw_dir}/reload_area_synthese.sql"
}

main "${@}"
