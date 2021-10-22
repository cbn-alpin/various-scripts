 #!/usr/bin/env bash
# Encoding : UTF-8
# Script to clean GeoNature App before re-install. Use for development.
# Usage: geonature_clean_app.sh [<path-to-geonature>] [<config-dir-name>]
# Ex.: geonature_clean_app.sh . flore-sentinelle

set -euo pipefail

#+----------------------------------------------------------------------------------------------------------+
# Load utils
script_path=$(realpath "${BASH_SOURCE[0]}")
source "$(realpath "${script_path%/*}")/lib_utils.bash"

function main() {
	local readonly gn_dir=$(realpath ${1:-"${HOME}/workspace/geonature/web/geonature"})
	echo "Path used: ${main_dir}"
	local readonly cfg_name="${2:-'current'}"
	echo "Config name used: ${cfg_name}"

	local readonly cfg_dir="${gn_dir}/config"
	local readonly em_dir="${gn_dir}/external_modules"
	local readonly bke_dir="${gn_dir}/backend"
	local readonly venv_dir="${bke_dir}/venv"
	local readonly fte_dir="${gn_dir}/frontend"
	local readonly node_dir="${fte_dir}/node_modules"
	local readonly tmp_dir="${gn_dir}/tmp"
	local readonly var_dir="${gn_dir}/var"
	local readonly current_gn_cfg_dir="${HOME}/Applications/geonature/configs/${cfg_name}"
	local readonly version=$(cat "${gn_dir}/VERSION")
	echo "GeoNature version: ${version}"

	echo "Are you sure to clean GeoNature local APP install (y/n) ?"
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
	
	echo "Load GeoNature 'settings.ini' file"
	. "${gn_dir}/config/settings.ini"

	echo "Get super user rights"
	checkSuperuser
	
	cd "${gn_dir}/install/"
	if version_gt "${version}" "2.7.5"; then
		echo "Run install frontend"
		./04_install_frontend.sh --dev
	else
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
