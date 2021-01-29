 #!/usr/bin/env bash
# Encoding : UTF-8
# Script to clean Taxhub before re-install all. Use for development.


function main() {
	local readonly main_dir="${HOME}/workspace/geonature/web/taxhub"
	local readonly venv_dir="${main_dir}/venv"
	local readonly var_dir="${main_dir}/var"
	local readonly log_dir="${var_dir}/log"
	
	echo "Are you sure to clean Taxhub local install (y/n) ?"
	read -r -n 1 key
	echo # Move to a new line
	if [[ ! "${key}" =~ ^[Yy]$ ]];then
		[[ "${0}" = "${BASH_SOURCE}" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	fi

	cd "${main_dir}/"

	echo "Remove ${venv_dir}"
	rm -fR "${venv_dir}"

	echo "Remove ${var_dir}"
	rm -fR "${var_dir}"

	echo "Run install_db.sh"
	./install_db.sh

	echo "Run install_app.sh"
	./install_app.sh

	echo "Add log dir"
	mkdir -p "${log_dir}"
	
	echo "Add log file"
	touch "${log_dir}/taxhub-errors.log"
}

main "${@}"
