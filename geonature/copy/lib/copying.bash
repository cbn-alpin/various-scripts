# DESC: Execute query in destination database.
# ARGS: $1 (required): Query to execute.
# OUTS: None
function executeQueryInDestDb() {
    if [[ $# -lt 1 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local readonly query="${1}"
    sudo -n -u "${gn2gn_pg_admin_name}" -s psql -d "${gn2gn_pg_db_dest}" -c "${query}"
}

# DESC: Execute query in source database.
# ARGS: $1 (required): Query to execute.
# OUTS: None
function executeQueryInSrcDb() {
    if [[ $# -lt 1 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local readonly query="${1}"
    sudo -n -u "${gn2gn_pg_admin_name}" -s psql -d "${gn2gn_pg_db_src}" -c "${query}"
}

# DESC: Execute SQL file in destination database.
# ARGS: $1 (required): sql file path to execute.
# OUTS: None
function executeFileInDestDb() {
    if [[ $# -lt 1 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local readonly sql_file_path="${1}"
    sudo -n -u "${gn2gn_pg_admin_name}" -s psql -d "${gn2gn_pg_db_dest}" -f "${sql_file_path}"
}

# DESC: Execute "COPY ... TO stdout" query in source database then pipe result in
#       "COPY ... FROM stdin" query in  destination database.
# ARGS: $1 (required): part of COPY query between COPY and TO used in source database.
#                      By dfefault, this value is also used in destination database.
# ARGS: $2 (optional): part of COPY query between COPY and FROM used in destination database.
# OUTS: None
function copy() {
    if [[ $# -lt 1 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local readonly src="${1}"
    local readonly dest="${2:-${1}}"
    extractTableName "${src}" "${dest}"
    printVerbose "Copying table '${__table}'"
    sudo -n -u "${gn2gn_pg_admin_name}" -s \
        psql -d "${gn2gn_pg_db_src}" -c "COPY ${src} TO stdout WITH csv null AS E'\\\\N'" |
        psql -d "${gn2gn_pg_db_dest}" -c "COPY ${dest} FROM stdin csv null AS E'\\\\N'"
}

# DESC: Extract table name from copy string.
# ARGS: $1 (required): part of COPY query between COPY and TO used in source database.
# ARGS: $2 (optional): part of COPY query between COPY and FROM used in destination database. If
#                      not present, use $1 as value.
# OUTS: __table: variable with table name.
function extractTableName() {
    __table=""
    local readonly src="${1}"
    local readonly dest="${2:-${1}}"
    if [[ "${src}" =~ [.]([a-zA-Z_]+)($| ) ]]; then
        __table="${BASH_REMATCH[1]}"
    elif [[ "${dest}" =~ [.]([a-zA-Z_]+)($| ) ]]; then
        __table="${BASH_REMATCH[1]}"
    fi
}

# DESC: Print error if gn2gn_pg_db_src or gn2gn_pg_db_dest is empty.
# ARGS: None
# OUTS: None
function runCommonChecks {
    if [[ -z "${gn2gn_pg_db_src-}" ]]; then
        printError "Missing required parameter -i or define gn2gn_pg_db_src in setting.ini !"
        printScriptUsage
    fi
    if [[ -z "${gn2gn_pg_db_dest-}" ]]; then
        printError "Missing required parameter -o or define gn2gn_pg_db_dest in setting.ini !"
        printScriptUsage
    fi
}

# DESC: Prepare gn2gn_pg_verbosity variable with Psql verbosity parameters.
# ARGS: None
# OUTS: None
function prepareParameters() {
    if [[ ${verbose-} == true ]]; then
        gn2gn_pg_verbosity="--echo-all --echo-hidden"
    fi
}

# DESC: Insert utils functions in destination database.
# ARGS: None
# OUTS: None
function setHelpersFunctions() {
    printMsg "Create or replace utils functions in destination database"
    executeFileInDestDb "${sql_shared_dir}/utils_functions.sql"
}

# DESC: Rename .psqlrc to .psqlrc.saved to avoid to used it.
# ARGS: None
# OUTS: None
function prepareEnv {
    if [[ -f "~/.psqlrc" ]]; then
        mv "~/.psqlrc" "~/.psqlrc.saved"
    fi
}

# DESC: Rename .psqlrc.saved to .psqlrc to restore this functionality.
# ARGS: None
# OUTS: None
function restoreEnv() {
    if [[ -f "~/.psqlrc.saved" ]]; then
        mv "~/.psqlrc.saved" "~/.psqlrc"
    fi
}

# DESC: Disable some synthese triggers to speed up the insert.
# ARGS: None
# OUTS: None
function disableSyntheseTriggers() {
    printVerbose "\tDisable trigger 'tri_meta_dates_change_synthese'"
    executeQueryInDestDb "ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;"

    printVerbose "\tDisable trigger 'tri_insert_calculate_sensitivity'"
    executeQueryInDestDb "ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_insert_calculate_sensitivity ;"

    printVerbose "\tDisable trigger 'tri_insert_cor_area_synthese'"
    executeQueryInDestDb "ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_insert_cor_area_synthese ;"
}

# DESC: Restore the synthese triggers that were disabled by disable function.
# ARGS: None
# OUTS: None
function enableSyntheseTriggers() {
    printVerbose "\tEnable trigger 'tri_insert_cor_area_synthese'"
    executeQueryInDestDb "ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_insert_cor_area_synthese ;"

    printVerbose "\tEnable trigger 'tri_meta_dates_change_synthese'"
    executeQueryInDestDb "ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;"

    printVerbose "\tEnable trigger 'tri_insert_calculate_sensitivity'"
    executeQueryInDestDb "ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_insert_calculate_sensitivity ;"
}
