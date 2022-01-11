#!/usr/bin/env bash
# Encoding : UTF-8
# Script to run GeoNature in development mode.
set -euo pipefail
#+----------------------------------------------------------------------------------------------------------+
# Load utils
script_path=$(realpath "${BASH_SOURCE[0]}")
source "$(realpath "${script_path%/*}")/lib_utils.bash"

function main() {
    local readonly front_dir=$(realpath ${1:-"/home/${USER}/workspace/geonature/web/geonature/frontend"})
    echo "Path used: ${front_dir}"
    local readonly version=$(cat "${front_dir}/../VERSION")
    echo "GeoNature version: ${version}"

    echo "Go to GeoNature frontend directory"
    cd ${front_dir}

    echo "Enable Nvm"
    . ~/.nvm/nvm.sh;
    nvm use;

    echo "Run GeoNature Angular server in Dev mode"
    # TODO: update version below to 2.10.0
    if ! version_gt "${version}" "2.8.0"; then
        ./node_modules/.bin/ng serve \
            --port=4200 \
            --poll=2000 \
            --aot=false \
            --optimization=false \
            --progress=true \
            --sourceMap=false
    else
        ./node_modules/.bin/ng serve \
            --port=4200 \
            --poll=2000
    fi
}

main "${@}"
