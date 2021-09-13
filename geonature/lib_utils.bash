
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

# DESC: Return true if first argument is greater than second.
# ARGS: $1 (required): first version string
# ARGS: $2 (required): second version string
# OUTS: None
# SOURCE: 
function version_gt() {
	test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}