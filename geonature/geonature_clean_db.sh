 #!/usr/bin/env bash
# Encoding : UTF-8
# Script to clean GeoNature DB before re-install DB. Use for development.
# Usage: geonature_clean_db.sh [<path-to-geonature>] [<config-dir-name>]
# Ex.: geonature_clean_db.sh . flore-sentinelle
set -euo pipefail

#+----------------------------------------------------------------------------------------------------------+
# Load utils
script_path=$(realpath "${BASH_SOURCE[0]}")
source "$(realpath "${script_path%/*}")/lib_utils.bash"

function main() {
	local readonly gn_dir=$(realpath ${1:-"${HOME}/workspace/geonature/web/geonature"})
	echo "Path used: ${gn_dir}"
	local readonly cfg_name="${2:-current}"
	echo "Config name used: ${cfg_name}"

	local readonly cfg_dir="${gn_dir}/config"
	local readonly current_gn_cfg_dir="${HOME}/Applications/geonature/configs/${cfg_name}"
	local readonly version=$(cat "${gn_dir}/VERSION")
	echo "GeoNature version: ${version}"


	echo "Are you sure to clean GeoNature local DB (y/n) ?"
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
    readonly actual_db_name=$(grep db_name "${current_gn_cfg_dir}/geonature/settings.ini"|  awk -F= '{print $2}')
	echo "Actual config: ${actual_config}. DB name: ${actual_db_name}. Continue (y/n) ?"
	read -r -n 1 key
	echo # Move to a new line
	if [[ ! "${key}" =~ ^[Yy]$ ]];then
		[[ "${0}" = "${BASH_SOURCE}" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	fi


    cd "${gn_dir}/"

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

		echo "Run create DB"
		./02_create_db.sh

		echo "Run install GN modules"
		./03_install_gn_modules.sh
	else
		cd "${gn_dir}/install/"
		echo "Run install_db.sh"
		./install_db.sh
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
