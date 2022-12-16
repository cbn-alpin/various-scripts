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

    # Go to backend directory (optional)
    cd ${bck_dir}

    if version_gt "${version}" "1.8.0"; then
        if [[ -f "${bck_dir}/.flaskenv" ]]; then
            echo "Using .flaskenv:"
            cat "${bck_dir}/.flaskenv" | sed -e "s/^/\t/"
        else
            echo "No .flaskenv, use env variables..."
            export FLASK_ENV=development
            export FLASK_DEBUG=1
        fi
        echo "Run Flask:"
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

        # Run GeoNature in DEV mode with extra options for Gunicorn and Flask
        export GUNICORN_CMD_ARGS="--capture-output --log-level debug";
        export FLASK_ENV="development";
        python server.py
    fi
}

main "${@}"
