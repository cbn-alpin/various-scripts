#!/bin/bash
# Encoding : UTF-8
# Migrate Database between 2 Postgresql major versions.

#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE) [options]
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: path to config file to use (default : config/settings.ini)
EOF
    exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "${@}"; do
        shift
        case "${arg}" in
            "--help") set -- "${@}" "-h" ;;
            "--verbose") set -- "${@}" "-v" ;;
            "--debug") set -- "${@}" "-x" ;;
            "--config") set -- "${@}" "-c" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    source "$(dirname "${BASH_SOURCE[0]}")/../../../shared/lib/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${log_file}"
    checkSuperuser

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${script_name} script started at: ${fmt_time_start}"

    stepToNext addPostgresDebianRepo
    stepToNext installPostgresOldVersion
    stepToNext installPostgresNewVersion
    stepToNext checkPostgresqlStatus
    stepToNext backupOldPostgresDb
    stepToNext copyPostgresConf
    stepToNext upgradePostgresData
    stepToNext removeOldPostgres

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function addPostgresDebianRepo() {
    printMsg "Adding Postgres Debian repo..."
    pg_source_list_file="/etc/apt/sources.list.d/postgresql.list"
    if [[ ! -f "${pg_source_list_file}" ]]; then
        sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > "${pg_source_list_file}"'
        sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update
    else
        printVerbose "Postgresql Debian repo file already installed in ${pg_source_list_file}"
    fi
}

function installPostgresNewVersion() {
    printMsg "Installing Postgres ${pg_new_version} ..."
    sudo apt-get install -y "postgresql-${pg_new_version}" "postgresql-${pg_new_version}-postgis-${pg_new_postgis_version}"
}

function installPostgresOldVersion() {
    printMsg "Installing Postgres ${pg_old_version} ..."
    sudo apt-get install -y "postgresql-${pg_old_version}" "postgresql-${pg_old_version}-postgis-${pg_old_postgis_version}"
}

function checkPostgresqlStatus() {
    printMsg "You shoud see Postgres ${pg_old_version} & ${pg_new_version} running (if not, script exit):"

    printPretty "Stoping all Postgres services..." ${Gra}
    sudo systemctl stop postgresql "postgresql@${pg_old_version}-main" "postgresql@${pg_new_version}-main"

    printPretty "Reseting port and data directory for Postgres ${pg_new_version} (=5433) & ${pg_old_version} (=5432), if this script already runned" ${Gra}
    if [[ -f "/etc/postgresql/${pg_new_version}/main/postgresql.conf" ]]; then
        sudo sed -e "s/^\(port =\) .*$/\1 5433 # (change requires restart)/" -i "/etc/postgresql/${pg_new_version}/main/postgresql.conf"
        sudo sed -e "s/^\(data_directory =\) .*$/\1 '${pg_new_data_dir//\//\\/}' # use data in another directory/" -i "/etc/postgresql/${pg_new_version}/main/postgresql.conf"
    fi
    if [[ -f "/etc/postgresql/${pg_old_version}/main/postgresql.conf" ]]; then
        sudo sed -e "s/^\(port =\) .*$/\1 5432 # (change requires restart)/" -i "/etc/postgresql/${pg_old_version}/main/postgresql.conf"
        sudo sed -e "s/^\(data_directory =\) .*$/\1 '${pg_old_data_dir//\//\\/}' # use data in another directory/" -i "/etc/postgresql/${pg_old_version}/main/postgresql.conf"
    fi

    # printPretty "Moving new postgresql data dir..."
    # if [[ -d "/var/lib/postgresql/${pg_new_version}" ]]; then
    #     rsync -av "/var/lib/postgresql/${pg_new_version}" "${pg_new_data_dir//main/}"
    #     mv "/var/lib/postgresql/${pg_new_version}" "/var/lib/postgresql/${pg_new_version}.Save"
    # else
    #     printVerbose "New Postgresql data dir aleady moved."
    # fi

    printPretty "Reloading systemd daemon..." ${Gra}
    sudo systemctl daemon-reload

    printPretty "Restarting all Postgres services..." ${Gra}
    sudo systemctl restart postgresql

    printPretty "Showing all Postgres services status..." ${Gra}
    sudo systemctl status postgresql
}

function backupOldPostgresDb() {
    printMsg "Backuping Postgres DB from old version (can take several minutes)..."
    local dumpfile="${raw_dir}/$(date +'%F')_dumpall_pg-${pg_old_version}.dump"
    if [[ ! -f "${dumpfile}" ]]; then
        sudo -u postgres pg_dumpall --port 5432 > "${dumpfile}"
    else
        printVerbose "Postgresql old version already dumped in ${dumpfile}"
    fi
    printInfo "Dumpfile size: $(du -hs ${dumpfile})"
    printInfo "If needed, restore Postgres DB with : psql -f \"${dumpfile}\" postgres"
}

function copyPostgresConf() {
    printPretty "Now, transfert manually your conf from /etc/postgresql/${pg_old_version}/* to /etc/postgresql/${pg_new_version}/*. After that, go to the next step (y/n) ?" ${Red}
    read -r -n 1 key
    echo # Move to a new line
    if [[ ! "${key}" =~ ^[Yy]$ ]];then
        [[ "${0}" = "${BASH_SOURCE}" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    fi
    sudo sed -e "s/datestyle =.*$/datestyle = 'iso, dmy'/g" -i /etc/postgresql/${pg_new_version}/main/postgresql.conf
}

function upgradePostgresData() {
    local new_service="postgresql@${pg_new_version}-main"
    local old_service="postgresql@${pg_old_version}-main"
    local old_data_size=$(sudo du -hs "${pg_old_data_dir}")

    printMsg "Upgrading Postgresql data (size: ${old_data_size})..."

    printPretty "Stoping service ${new_service}..." ${Gra}
    sudo systemctl stop "${new_service}"

    printPretty "Droping cluster ${pg_new_version} main..." ${Gra}
    if [[ -d "/etc/postgresql/${pg_new_version}/" ]]; then
        sudo -u postgres pg_dropcluster "${pg_new_version}" main
        sudo systemctl daemon-reload
    fi

    printPretty "Upgrading data from old cluster ${pg_old_version} main to new cluster ${pg_new_version} main..." ${Gra}
    sudo pg_upgradecluster -v "${pg_new_version}" -m upgrade "${pg_old_version}" main --no-start "${pg_new_data_dir}"
    sudo systemctl daemon-reload

    printPretty "Stoping old cluster ${pg_old_version} main..." ${Gra}
    sudo systemctl stop "${old_service}"

    printPretty "Change new Postgres server port to default (=5432)..." ${Gra}
    sudo sed -e "s/^\(port =\) .*$/\1 5432 # (change requires restart)/" -i "/etc/postgresql/${pg_new_version}/main/postgresql.conf"

    printPretty "Starting service ${new_service}..." ${Gra}
    sudo systemctl start "${new_service}"

    printPretty "Show service ${new_service} status (exit script if not started)..." ${Gra}
    sudo systemctl status "${new_service}"

    local new_data_size=$(sudo du -hs "${pg_new_data_dir}")
    printInfo "Check data size (old/new): ${old_data_size} / ${new_data_size}"
}

function removeOldPostgres() {
    printMsg "Removing old Postgresql ${pg_old_version} server..."
    local cmd="sudo apt-get remove --purge postgresql-${pg_old_version}"
    printInfo "When you are sure about new data upgrading, remode old Postgres with: ${cmd}"
}

main "${@}"