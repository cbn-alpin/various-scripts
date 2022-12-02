#!/usr/bin/env bash
# Encoding : UTF-8
# Script to run GeoNature Backend in developpement mode.

set -euo pipefail

#+----------------------------------------------------------------------------------------------------------+
# Load utils
script_path=$(realpath "${BASH_SOURCE[0]}")
source "$(realpath "${script_path%/*}")/lib_utils.bash"

function main() {
    local readonly bck_dir=$(realpath ${1:-"/home/${USER}/workspace/geonature/web/geonature/backend"})
    echo "Path used: ${bck_dir}"
    local readonly venv_dir="${bck_dir}/venv"
    local readonly version=$(cat "${bck_dir}/../VERSION")
    echo "GeoNature version: ${version}"

    if ! version_gt "${version}" "2.7.5"; then
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
    fi

    # Go to GeoNature backend directory (optional)
    cd "${bck_dir}"

    # Activate the virtualenv
    . "${venv_dir}/bin/activate"

    # Run GeoNature in DEV mode with extra options for Gunicorn and Flask
    export GUNICORN_CMD_ARGS="--capture-output --log-level debug";
    # FLASK_ENV see: https://flask.palletsprojects.com/en/2.0.x/config/#environment-and-debug-features
    flask_version="$(flask --version|grep Flask|cut -d' ' -f2)"
    if version_gt "${flask_version}" "2.2.0"; then
        export FLASK_DEBUG=1;
    else
        export FLASK_ENV="development";
    fi
    # To avoid GDAL debug message. Not necessary anymore (?).
    #export GDAL_DATA="${venv_dir}/lib/python3.7/site-packages/fiona/gdal_data"
    geonature dev_back
}

main "${@}"
