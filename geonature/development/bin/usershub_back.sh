#!/bin/bash
# Encoding : UTF-8
# Run UsersHub Backend serveur in development mode..

#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE)[options] <current-usershub-path>
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: name of config file to use with this script
     -p | --port: set Flask development server port. Default: 5001.
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
    runBackendServer "${@}"
}

function initializeDefaultVariables() {
    flask_port="${flask_port-5001}"
}

function runBackendServer() {
    local readonly arg_path="${@: -1}"
    local readonly bck_dir=$(realpath ${arg_path:-"/home/${USER}/workspace/geonature/web/usershub"})
    printMsg "Path used: ${bck_dir}"
    local readonly venv_dir="${bck_dir}/venv"
    local readonly version=$(cat "${bck_dir}/VERSION")
    printMsg "UsersHub version: ${version}"

    printVerbose "Go to backend directory (optional)"
    cd ${bck_dir}

    deactivatePyenv

    activateVenv "${venv_dir}"

    if isVersionGreaterThan "${version}" "2.1.3"; then
        export FLASK_APP="app.app:create_app"
        export FLASK_RUN_PORT="${flask_port}"
        runFlaskServer
    else
        stopSupervisor
        runPythonServer
    fi
}

main "${@}"
