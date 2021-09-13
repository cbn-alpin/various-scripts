 #!/usr/bin/env bash
# Encoding : UTF-8
# Script to clean GeoNature before re-install all. Use for development.

set -euo pipefail

#+----------------------------------------------------------------------------------------------------------+
# Load utils
script_path=$(realpath "${BASH_SOURCE[0]}")
source "$(realpath "${script_path%/*}")/lib_utils.bash"

function main() {
	local readonly gn_dir="${HOME}/workspace/geonature/web/geonature"
	local readonly cfg_dir="${gn_dir}/config"
	local readonly em_dir="${gn_dir}/external_modules"
	local readonly bke_dir="${gn_dir}/backend"
	local readonly venv_dir="${bke_dir}/venv"
	local readonly fte_dir="${gn_dir}/frontend"
	local readonly node_dir="${fte_dir}/node_modules"
	local readonly tmp_dir="${gn_dir}/tmp"
	local readonly var_dir="${gn_dir}/var"
	local readonly current_gn_cfg_dir="${HOME}/Applications/geonature/configs/current"
	local readonly version=$(cat "${gn_dir}/VERSION")
	echo "GeoNature version: ${version}"

	
	echo "Are you sure to clean GeoNature local install (y/n) ?"
	read -r -n 1 key
	echo # Move to a new line
	if [[ ! "${key}" =~ ^[Yy]$ ]];then
		[[ "${0}" = "${BASH_SOURCE}" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	fi

	echo "Restore GeoNature 'settings.ini' link if necessary"
	if [[ ! -L "${cfg_dir}/settings.ini" ]]; then
		echo "...restoring settings.ini link !"
		mv "${cfg_dir}/settings.ini" "${cfg_dir}/settings.ini.save-$(date +%FT%T)"
		ln -s "${current_gn_cfg_dir}/geonature/settings.ini" "${cfg_dir}/settings.ini"
	fi

	echo "Restore GeoNature 'geonature_config.toml' link if necessary"
	if [[ ! -L "${cfg_dir}/geonature_config.toml" ]]; then
		echo "...restoring geonature_config.toml link !"
		mv "${cfg_dir}/geonature_config.toml" "${cfg_dir}/geonature_config.toml.save-$(date +%FT%T)"
		ln -s "${current_gn_cfg_dir}/geonature/geonature_config.toml" "${cfg_dir}/geonature_config.toml"
	fi

	readonly actual_config="$(basename "$(readlink -f "${current_gn_cfg_dir}")")"
	echo "Actual config: ${actual_config}. Continue (y/n) ?"
	read -r -n 1 key
	echo # Move to a new line
	if [[ ! "${key}" =~ ^[Yy]$ ]];then
		[[ "${0}" = "${BASH_SOURCE}" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	fi
	
	
	echo "Remove ${em_dir}/*"
	cd "${em_dir}/"
	rm -fR *
	
	cd "${gn_dir}/"

	echo "Remove ${bke_dir}/static/node_modules"
	rm -f "${bke_dir}/static/node_modules"

	echo "Remove ${fte_dir}/src/external_assets"
	rm -f "${fte_dir}/src/external_assets/*"

	echo "Remove ${venv_dir}"
	rm -fR "${venv_dir}"
	
	echo "Remove ${node_dir}"
	rm -fR "${node_dir}"
	
	echo "Remove ${tmp_dir}"
	rm -fR "${tmp_dir}"
	
	echo "Remove ${var_dir}"
	rm -fR "${var_dir}"
	
	echo "Update GeoNature 'drop_apps_db' parameter to 'true'"
	sed -i --follow-symlinks "s/^\(drop_apps_db\)=.*$/\1=true/" "${gn_dir}/config/settings.ini"

	echo "Load GeoNature 'settings.ini' file"
	. "${gn_dir}/config/settings.ini"

	echo "Get super user rights"
	checkSuperuser

	echo "Create GeoNature role admin in database if necessary"
	if psql -t -c '\du' | cut -d \| -f 1 | grep -qw "${user_pg}"; then
		echo -e "\tRole '${user_pg}' already exists !"
	else
		sudo -n -u 'postgres' -s \
			psql -c "CREATE ROLE ${user_pg} WITH LOGIN PASSWORD '${user_pg_pass}';"
	fi

	echo "Create GeoNature database if necessary"
	if psql -lqt | cut -d \| -f 1 | grep -qw "${db_name}"; then
    	echo -e "\tDatabase '${db_name}' already exists !"
	else
		sudo -n -u 'postgres' -s \
			psql -c "CREATE DATABASE ${db_name};"
		sudo -n -u 'postgres' -s \
			psql -c "GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${user_pg};"
	fi

	echo "Close all Postgresql conection on GeoNature DB"
	local query=("SELECT pg_terminate_backend(pg_stat_activity.pid) "
		"FROM pg_stat_activity "
		"WHERE pg_stat_activity.datname = '${db_name}' "
		"AND pid <> pg_backend_pid();")
	sudo -n -u 'postgres' -s \
        psql -d 'postgres' -c "${query[*]}"
	
	if version_gt "${version}" "2.7.5" ; then
		cd "${gn_dir}/install/"

		echo "Run install backend"
		./01_install_backend.sh --dev

		echo "Run create DB"
		./02_create_db.sh

		echo "Run install frontend"
		./04_install_frontend.sh --dev
	else
		cd "${gn_dir}/install/"
		echo "Run install_db.sh"
		./install_db.sh
		
		echo "Run install_app.sh in DEV mode !"
		./install_app.sh --dev
	fi

	echo "GeoNature install_app.sh remove geonature_config.toml => restore link !"
	echo "Restore GeoNature 'geonature_config.toml' link"
	if [[ ! -L "${cfg_dir}/geonature_config.toml" ]]; then
		echo "...restoring geonature_config.toml link !"
		mv "${cfg_dir}/geonature_config.toml" "${cfg_dir}/geonature_config.toml.save-$(date +%FT%T)"
		ln -s "${current_gn_cfg_dir}/geonature/geonature_config.toml" "${cfg_dir}/geonature_config.toml"
	fi
}

main "${@}"
