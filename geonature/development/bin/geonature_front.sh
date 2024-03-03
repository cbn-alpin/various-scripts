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
Usage: ./$(basename $BASH_SOURCE)[options]
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: name of config file to use with this script
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
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
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

    runGeoNatureFrontendServer
}

function runGeoNatureFrontendServer() {
    local readonly front_dir=$(realpath ${1:-"/home/${USER}/workspace/geonature/web/geonature/frontend"})
    printMsg "Path used: ${front_dir}"
    local readonly version=$(cat "${front_dir}/../VERSION")
    printMsg "GeoNature version: ${version}"

    printVerbose "Go to GeoNature frontend directory"
    cd ${front_dir}

    printVerbose "Enable Nvm"
    . ~/.nvm/nvm.sh;
    nvm use;

    printMsg "Run GeoNature Angular server in Dev mode"
    if ! isVersionGreaterThan "${version}" "2.8.1"; then
        ./node_modules/.bin/ng serve \
            --port=4200 \
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
            --port=4200 \
            --poll=2000 \
            --live-reload true \
            --open false
    fi
}

main "${@}"
