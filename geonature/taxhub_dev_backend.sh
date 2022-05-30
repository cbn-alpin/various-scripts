#!/usr/bin/env bash
# Encoding : UTF-8
# Script to run Taxhub Backend in developpement mode.
# Usage: taxhub_dev_backend.sh [<path-to-geonature>]
# Ex.: taxhub_dev_backend.sh .
set -euo pipefail

#+----------------------------------------------------------------------------------------------------------+
# Load utils
script_path=$(realpath "${BASH_SOURCE[0]}")
source "$(realpath "${script_path%/*}")/lib_utils.bash"

function main() {
    local readonly bck_dir=$(realpath ${1:-"/home/${USER}/workspace/geonature/web/taxhub"})
    echo "Path used: ${bck_dir}"
    local readonly venv_dir="${bck_dir}/venv"
    local readonly version=$(cat "${bck_dir}/VERSION")
    echo "TaxHub version: ${version}"

    if version_gt "${version}" "1.8.0"; then
        cd "${bck_dir}"

        export FLASK_ENV=development
        export FLASK_DEBUG=1

        source "${bck_dir}/venv/bin/activate"
        flask run --port=5000
    else
        # Check Supervisor conf and fix it if necessary
        local stop_supervisor=false
        local readonly supervisor_conf_dir="/etc/supervisor/conf.d"
        local readonly confs=("geonature-service.conf" "usershub-service.conf" "taxhub-service.conf")
        if [[ -d $supervisor_conf_dir ]]; then
            for conf in "${confs[@]}"; do
                local readonly supervisor_conf="${supervisor_conf_dir}/${conf}"
                if grep -q "autostart=true" "${supervisor_conf}" ; then
                    checkSuperuser
                    sudo sed -i "s/^\(autostart\)\s*=.*$/\1=false/" "${supervisor_conf}"
                    stop_supervisor=true
                fi
            done
            if [[ ${stop_supervisor} ]]; then
                sudo supervisorctl stop all
            fi
        fi

        # Activate the virtualenv
        source "${venv_dir}/bin/activate"

        # Go to GeoNature backend directory (optional)
        cd ${bck_dir}

        # Run GeoNature in DEV mode with extra options for Gunicorn and Flask
        export GUNICORN_CMD_ARGS="--capture-output --log-level debug";
        export FLASK_ENV="development";
        python server.py
    fi
}

main "${@}"
