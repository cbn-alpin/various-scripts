#!/usr/bin/env bash
# Encoding : UTF-8
# Script to run Taxhub Backend in developpement mode.

function main() {
	local readonly bck_dir="/home/${USER}/workspace/geonature/web/taxhub"
	local readonly venv_dir="${bck_dir}/venv"
	local readonly version=$(cat "${bck_dir}/VERSION")
	echo "TaxHub version: ${version}"

	if version_gt "${version}" "1.8.0" ]]; then
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

# DESC: Validate we have superuser access as root (via sudo if requested)
# ARGS: $1 (optional): Set to any value to not attempt root access via sudo
# OUTS: None
# SOURCE: https://github.com/ralish/bash-script-template/blob/stable/source.sh
function checkSuperuser() {
    local superuser
    if [[ ${EUID} -eq 0 ]]; then
        superuser=true
    elif [[ -z ${1-} ]]; then
        if command -v "sudo" > /dev/null 2>&1; then
            echo 'Sudo: Updating cached credentials ...'
            if ! sudo -v; then
                echo "Sudo: Couldn't acquire credentials ..."
            else
                local test_euid
                test_euid="$(sudo -H -- "${BASH}" -c 'printf "%s" "${EUID}"')"
                if [[ ${test_euid} -eq 0 ]]; then
                    superuser=true
                fi
            fi
        else
			echo "Missing dependency: sudo"
        fi
    fi

    if [[ -z ${superuser-} ]]; then
        echo 'Unable to acquire superuser credentials.'
        return 1
    fi

    echo 'Successfully acquired superuser credentials.'
    return 0
}

function version_gt() {
	test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

main "${@}"
