#!/usr/bin/env bash
# Encoding : UTF-8
# Script to run GeoNature Backend in developpement mode.

set -euo pipefail

#+----------------------------------------------------------------------------------------------------------+
# Load utils
script_path=$(realpath "${BASH_SOURCE[0]}")
source "$(realpath "${script_path%/*}")/lib_utils.bash"

function main() {
	local readonly bck_dir="/home/${USER}/workspace/geonature/web/geonature/backend"
	local readonly venv_dir="${bck_dir}/venv"
	local readonly version=$(cat "${bck_dir}/../VERSION")
	echo "GeoNature version: ${version}"

	if ! version_gt "${version}" "2.7.5"; then
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
	fi
	
	# Go to GeoNature backend directory (optional)
	cd "${bck_dir}"

	# Activate the virtualenv
	. "${venv_dir}/bin/activate"

	# Run GeoNature in DEV mode with extra options for Gunicorn and Flask
	export GUNICORN_CMD_ARGS="--capture-output --log-level debug";
	export FLASK_ENV="development";
	export GDAL_DATA="${venv_dir}/lib/python3.7/site-packages/fiona/gdal_data"
	geonature dev_back
}

main "${@}"
