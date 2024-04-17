function deactivatePyenv() {
    printVerbose "Try to deactivate Pyenv if necessary:"

    if command -v pyenv 1>/dev/null 2>&1; then
        printVerbose "\tPyenv was found: deactivate Pyenv (remove from PATH) => using venv !"
        PATH=`echo $PATH | tr ':' '\n' | sed '/pyenv/d' | tr '\n' ':' | sed -r 's/:$/\n/'`
    else
        printVerbose "\tPyenv not found !"
    fi
}

function activateVenv() {
    local readonly venv_dir="${1}"

    printMsg "Activate Python venv:"
    source "${venv_dir}/bin/activate"

    in_venv=$(python3 -c 'import sys; print ("1" if (hasattr(sys, "real_prefix") or
            (hasattr(sys, "base_prefix") and sys.base_prefix != sys.prefix)) else "0")')
    if [[ "${in_venv}" == "0" ]] && [[ "${VIRTUAL_ENV}" == "${venv_dir}" ]]; then
        printVerbose "\tPython return false but env variable true ! Force true."
        in_venv="1"
    fi
    if [[ "${in_venv}" == "1" ]]; then
        printPretty "\tvenv activated : ${Gre}${VIRTUAL_ENV}"
    else
        printError "\tvenv not activated: ${in_venv}!"
    fi
}

function stopSupervisor() {
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
}

function runFlaskServer() {
    if [[ -f "${bck_dir}/.flaskenv" ]]; then
        printVerbose "Using .flaskenv:"
        flaskenv_content=$(cat "${bck_dir}/.flaskenv" | sed -e "s/^/\t/")
        printVerbose "${flaskenv_content}"
    else
        if [[ -z "${FLASK_APP}" ]] && [[ -z "${FLASK_RUN_PORT}" ]]; then
            exitScript "FLASK_APP and FLASK_RUN_PORT env variable must be defined !" 2
        fi
        exportFlaskEnv
    fi
    printMsg "Run Flask:"
    flask run
}

function runPythonServer() {
    printMsg "Run server in DEV mode with extra options for Gunicorn and Flask:"
    export GUNICORN_CMD_ARGS="--capture-output --log-level debug";
    exportFlaskEnv
    python server.py
}

function exportFlaskEnv() {
    printVerbose "No .flaskenv, use Flask env variables:"

    # FLASK_ENV see: https://flask.palletsprojects.com/en/2.0.x/config/#environment-and-debug-features
    local flask_version="$(flask --version|grep Flask|cut -d' ' -f2)"
    if isVersionGreaterThan "${flask_version}" "2.2.0"; then
        export FLASK_DEBUG=1;
    else
        export FLASK_ENV="development";
    fi
    local flask_env_vars=$(printenv | grep "FLASK")
    printVerbose "\t${flask_env_vars//$'\n'/$'\n'$'\t'}"
}
