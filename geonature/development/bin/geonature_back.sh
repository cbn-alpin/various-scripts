#!/bin/bash
# Encoding : UTF-8
# Run GeoNature Backend serveur in development mode..

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
     -p | --port: set Flask development server port. Default: 8000.
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
            "--port") set -- "${@}" "-p" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:p:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            "p") flask_port="${OPTARG}" ;;
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
    gdsr_script_path=$(realpath "${BASH_SOURCE[0]}")
    gdsr_current_dir=$(realpath "${gdsr_script_path%/*}")
    source "${gdsr_current_dir}/../../../shared/lib/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    source "${lib_dir}/development.bash"

    initializeDefaultVariables
    runGeoNatureBackendServer
}

function initializeDefaultVariables() {
    flask_port="${flask_port-8000}"
}

function runGeoNatureBackendServer() {
    local readonly bck_dir=$(realpath ${1:-"/home/${USER}/workspace/geonature/web/geonature/backend"})
    printMsg "Path used: ${bck_dir}"
    local readonly venv_dir="${bck_dir}/venv"
    local readonly version=$(cat "${bck_dir}/../VERSION")
    printMsg "GeoNature version: ${version}"

    if ! isVersionGreaterThan "${version}" "2.7.5"; then
        stopSupervisor
    fi

    printVerbose "Go to backend directory (optional)"
    cd ${bck_dir}

    deactivatePyenv

    activateVenv

    # Run GeoNature in DEV mode with extra options for Gunicorn and Flask
    export GUNICORN_CMD_ARGS="--capture-output --log-level debug";
    exportFlaskEnv
    # To avoid GDAL debug message. Not necessary anymore (?).
    #export GDAL_DATA="${venv_dir}/lib/python3.7/site-packages/fiona/gdal_data"
    geonature dev-back --port=${flask_port}
}


main "${@}"
