#!/bin/bash
# Encoding : UTF-8
# Copy partial data between a SINP GeoNature database and a development GeoNature database (v2.13.3+).

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
     -a | --areas: list of comma separated areas code of type 'COM'
     -s | --source: name of the source use for data copy.
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
            "--areas") set -- "${@}" "-a" ;;
            "--source") set -- "${@}" "-s" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:i:o:a:d:s:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            "i") gn2gn_pg_db_src="${OPTARG}" ;;
            "o") gn2gn_pg_db_dest="${OPTARG}" ;;
            "a") gn2gn_areas="${OPTARG}" ;;
            "s") gn2gn_source="${OPTARG}" ;;
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
    runCopyPartialChecks
    prepareEnv
    prepareParameters

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} started at: ${fmt_time_start}"

    setHelpersFunctions
    createSyntheseExport
    cleanForeignDataWrapper
    createForeignDataWrapper
    cleanPreviousData
    createMetadata
    insertSyntheseObservations
    createTerritory
    reloadAreasObservationsLinks

    # Finalize Gn2Gn run
    restoreEnv

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function runCopyPartialChecks {
    if [[ -z "${gn2gn_areas-}" ]]; then
        printError "Missing required parameter -a or define gn2gn_areas in setting.ini !"
        printScriptUsage
    fi
    if [[ -z "${gn2gn_areas_hash-}" ]]; then
        gn2gn_areas_hash=$(crc32 <(echo -n "${gn2gn_areas}"))
        printVerbose "Auto generated gn2gn_areas_hash value: ${gn2gn_areas_hash}"
    fi
    if [[ -z "${gn2gn_source-}" ]]; then
        gn2gn_source="IMPORT-PARTIAL-${gn2gn_areas_hash}"
        printVerbose "Auto generated gn2gn_source value: ${gn2gn_source}"
    fi
}

function createSyntheseExport() {
    printMsg "Create synthese exports in source database"

    cat "${sql_dir}/create_synthese_view_for_export.tpl.sql" | \
        sed "s/\${gn2gn_areas}/${gn2gn_areas}/g" | \
        sed "s/\${db_user}/${db_user}/g" \
        > "${raw_dir}/create_synthese_view_for_export.sql"
    executeFileInDestDb "${raw_dir}/create_synthese_view_for_export.sql"
}

function cleanForeignDataWrapper() {
    local fdw_server_name="server_${gn2gn_pg_db_src,,}"
    printMsg "Clean Foreign Data Wrapper: ${fdw_server_name}"

    executeQueryInDestDb "DROP SERVER IF EXISTS ${fdw_server_name} CASCADE ;"
}

function createForeignDataWrapper() {
    local fdw_server_name="server_${gn2gn_pg_db_src,,}"
    printMsg "Create Foreign Data Server: ${fdw_server_name}"

    executeQueryInDestDb "CREATE EXTENSION IF NOT EXISTS postgres_fdw ;"

    executeQueryInDestDb "CREATE SERVER IF NOT EXISTS ${fdw_server_name}
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (
            host '${db_host}', dbname '${gn2gn_pg_db_src}', port '${db_port}',
            fetch_size '${gn2gn_pg_fetch_size}',
            use_remote_estimate 'on'
        );"''
    executeQueryInDestDb "CREATE USER MAPPING IF NOT EXISTS
        FOR CURRENT_USER
        SERVER ${fdw_server_name}
        OPTIONS (user '${db_user}', password '${db_pass}');"
    executeQueryInDestDb "CREATE USER MAPPING IF NOT EXISTS
        FOR ${db_user}
        SERVER ${fdw_server_name}
        OPTIONS (user '${db_user}', password '${db_pass}');"

    executeQueryInDestDb "CREATE SCHEMA IF NOT EXISTS gn2gn_imports AUTHORIZATION ${db_user} ;"
    executeQueryInDestDb "IMPORT FOREIGN SCHEMA gn2gn_exports
        FROM SERVER ${fdw_server_name}
        INTO gn2gn_imports;"
    executeQueryInDestDb "ALTER FOREIGN TABLE gn2gn_imports.synthese OWNER TO ${db_user};"
}

function cleanPreviousData() {
    printMsg "Clean '${gn2gn_source}' previous data"

    executeQueryInDestDb "DELETE FROM gn_synthese.synthese WHERE id_source IN (
        SELECT id_source FROM gn_synthese.t_sources WHERE name_source = '${gn2gn_source}'
    );"
    executeQueryInDestDb "DELETE FROM gn_synthese.t_sources WHERE name_source = '${gn2gn_source}';"
}

function resetSequences() {
    printMsg "Resets sequences"

    resetSequence "gn_synthese" "synthese" "id_synthese" "synthese_id_synthese_seq"
    resetSequence "gn_synthese" "t_sources" "id_source" "t_sources_id_source_seq"
    resetSequence "gn_meta" "t_acquisition_frameworks" "id_acquisition_framework" \
        "t_acquisition_frameworks_id_acquisition_framework_seq"
    resetSequence "gn_meta" "t_datasets" "id_dataset" "t_datasets_id_dataset_seq"
    resetSequence "gn_meta" "cor_acquisition_framework_actor" "id_cafa" \
        "cor_acquisition_framework_actor_id_cafa_seq"
}

# DESC: Execute select query to call reset_sequence() SQL function.
# ARGS: $1 (required): the schema name.
# ARGS: $2 (required): the table name.
# ARGS: $3 (required): the column name to use to determine the max id.
# ARGS: $4 (required): the sequence name to reset.
# OUTS: None
function resetSequence() {
    if [[ $# -lt 4 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local readonly schema="${1}"
    local readonly table="${2}"
    local readonly column="${3}"
    local readonly sequence="${4}"
    executeQueryInDestDb "SELECT reset_sequence(${schema}, ${table}, ${column}, ${sequence});"
}

function createMetadata() {
    printMsg "Create metadata entry if necessary"

    cat "${sql_dir}/default_metadata.tpl.sql" | \
        sed "s/\${gn2gn_pg_db_src}/${gn2gn_pg_db_src}/g" | \
        sed "s/\${gn2gn_areas_protected}/${gn2gn_areas//\'/}/g" | \
        sed "s/\${gn2gn_source}/${gn2gn_source}/g" | \
        sed "s/\${gn2gn_dataset_uuid}/${gn2gn_dataset_uuid}/g" \
        > "${raw_dir}/metadata.sql"
    executeFileInDestDb "${raw_dir}/metadata.sql"
}

function createTerritory() {
    printMsg "Create territory area entry if necessary"

    executeFileInDestDb "${sql_dir}/insert_territory.sql"
}

function insertSyntheseObservations() {
    printMsg "Insert observations in synthese destination table"

    disableSyntheseTriggers

    printVerbose "\tInsert observbations 'gn_synthese.synthese'"
    cat "${sql_dir}/insert_synthese_from_import.tpl.sql" | \
        sed "s/\${gn2gn_source}/${gn2gn_source}/g" | \
        sed "s/\${gn2gn_dataset_uuid}/${gn2gn_dataset_uuid}/g" \
        > "${raw_dir}/insert_synthese_from_import.sql"
    executeFileInDestDb "${raw_dir}/insert_synthese_from_import.sql"

    enableSyntheseTriggers
}

function reloadAreasObservationsLinks() {
    printMsg "Create areas observations links"

    cat "${sql_dir}/reload_area_synthese_by_source.tpl.sql" | \
        sed "s/\${gn2gn_source}/${gn2gn_source}/g" | \
        sed "s/\${db_user}/${db_user}/g" \
        > "${raw_dir}/reload_area_synthese_by_source.sql"
    executeFileInDestDb "${raw_dir}/reload_area_synthese_by_source.sql"
}

main "${@}"
