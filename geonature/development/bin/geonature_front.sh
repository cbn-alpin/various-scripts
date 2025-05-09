#!/bin/bash
# Encoding : UTF-8
# Run GeoNature Frontend serveur in development mode..

#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE)[options] <current-geonature-fontend-path>
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: name of config file to use with this script
     -p | --port: set Angular development server port. Default: 4200.
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
            "p") ng_serve_port="${OPTARG}" ;;
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

    initializeDefaultVariable
    runGeoNatureFrontendServer "${@}"
}

function initializeDefaultVariable() {
    ng_serve_port=${ng_serve_port-"4200"}
}

function runGeoNatureFrontendServer() {
    local readonly arg_path="${@: -1}"
    local readonly front_dir=$(realpath ${arg_path:-"/home/${USER}/workspace/geonature/web/geonature/frontend"})
    printMsg "Path used: ${front_dir}"
    local readonly version=$(cat "${front_dir}/../VERSION")
    printMsg "GeoNature version: ${version}"

    printVerbose "Go to GeoNature frontend directory"
    cd ${front_dir}

    printVerbose "Enable Nvm"
    source ~/.nvm/nvm.sh
    declare nvm_version=$(<"./.nvmrc")
    declare installed_nvm_version=$(nvm ls --no-colors "${nvm_version}" | command tail -1 | command tr -d '\->*' | command tr -d '[:space:]')
    if [ "${installed_nvm_version}" = 'N/A' ]; then
        nvm install "${nvm_version}";
    else
        nvm use;
    fi

    printMsg "Run GeoNature Angular server in Dev mode"
    if ! isVersionGreaterThan "${version}" "2.8.1"; then
        ./node_modules/.bin/ng serve \
            --port=${ng_serve_port} \
            --poll=2000 \
            --aot=false \
            --optimization=false \
            --progress=true \
            --sourceMap=true
    else
        ./node_modules/.bin/ng serve \
            --configuration=development \
            --open false \
            --ssl false \
            --port=${ng_serve_port} \
            --poll=2000 \
            --live-reload true \
            --open false
    fi
}

main "${@}"
