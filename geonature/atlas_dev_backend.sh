#!/usr/bin/env bash
# Encoding : UTF-8
# Script to run GeoNature Atlas Backend in developpement mode.
# Usage: atlas_dev_backend.sh [<path-to-atlas>]
# Ex.: atlas_dev_backend.sh .
set -euo pipefail

#+----------------------------------------------------------------------------------------------------------+
# Load utils
script_path=$(realpath "${BASH_SOURCE[0]}")
source "$(realpath "${script_path%/*}")/lib_utils.bash"

function main() {
    local readonly bck_dir=$(realpath ${1:-"/home/${USER}/workspace/geonature/web/atlas"})
    echo "Path used: ${bck_dir}"
    local readonly venv_dir="${bck_dir}/venv"
    local readonly version=$(cat "${bck_dir}/VERSION")
    echo "Atlas version: ${version}"

    # Deactivate Pyenv
    if command -v pyenv 1>/dev/null 2>&1; then
        echo "Deactivate Pyenv (remove from PATH) => using venv !"
        PATH=`echo $PATH | tr ':' '\n' | sed '/pyenv/d' | tr '\n' ':' | sed -r 's/:$/\n/'`
    fi

    # Activate venv
    source "${venv_dir}/bin/activate"

    in_venv=$(python3 -c 'import sys; print ("1" if (hasattr(sys, "real_prefix") or
            (hasattr(sys, "base_prefix") and sys.base_prefix != sys.prefix)) else "0")')
    if [[ "${in_venv}" == "0" ]] && [[ "${VIRTUAL_ENV}" == "${venv_dir}" ]]; then
        echo "Python return false but env variable true ! Force true."
        in_venv="1"
    fi
    if [[ "${in_venv}" == "1" ]]; then
        echo "Python venv activated : ${VIRTUAL_ENV}"
    else
        echo "Python venv not activated: ${in_venv}!"
    fi

    cd "${bck_dir}"

    if version_gt "${version}" "1.5.0"; then
        if [[ -f "${bck_dir}/.flaskenv" ]]; then
            echo "Using .flaskenv:"
            cat "${bck_dir}/.flaskenv" | sed -e "s/^/\t/"
        else
            echo "No .flaskenv, use env variables..."
            export FLASK_ENV=development
            export FLASK_RUN_PORT=8081
            export FLASK_DEBUG=1
            export FLASK_APP=atlas.app
        fi
        echo "Run Flask:"
        flask run
    else
        echo "Not implemented for Atlas ${version} !"
    fi
}

main "${@}"
