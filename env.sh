function procat_ci_env_load_defaults {
    #
    # Check for the presence of the Project Catalysts CI environment file that holds environment specific settings
    #
    local readonly _procat_ci_env_filename="~/.procat_ci_env.sh"
    if [ ! -f ${_procat_ci_env_filename} ]; then
        pc_log_fatal "Project Catalysts CI environment settings file not found : ${_procat_ci_env_filename}"
    fi

    pc_log "Loading Project Catalysts CI environment settings from : ${_procat_ci_env_filename}"
    source ${_procat_ci_env_filename}@

    if [ ! -z ${PROCAT_CI_GIT_SERVER+x} ]; then
        pc_log_fatal "Project Catalysts CI environment setting has not been specified : PROCAT_CI_GIT_SERVER"
    fi

    if [ ! -z ${PROCAT_CI_REGISTRY_SERVER+x} ]; then
        pc_log_fatal "Project Catalysts CI environment setting has not been specified : PROCAT_CI_REGISTRY_SERVER"
    fi
}

function procat_ci_env_create_exports {
    #
    # Load environent default settings for this user / organisation
    #
    procat_ci_env_load_defaults

    if [ -z ${PROCAT_CI_SCRIPTS_REPO+x} ]; then 
        export PROCAT_CI_SCRIPTS_REPO=git@${PROCAT_CI_GIT_SERVER}:procat/ci-scripts.git
        pc_log "Setting PROCAT_CI_SCRIPTS_REPO to default : ${PROCAT_CI_SCRIPTS_REPO}"
    fi

    if [ -z ${PROCAT_CI_DOWNLOAD_PATH+x} ]; then 
        export PROCAT_CI_DOWNLOAD_PATH=~/downloads
        pc_log "Setting PROCAT_CI_DOWNLOAD_PATH to default : ${PROCAT_CI_DOWNLOAD_PATH}"
    fi

    if [ -z ${PROCAT_CI_GPG_USER_ID+x} ]; then 
        export PROCAT_CI_GPG_USER_ID=${USER}
        pc_log "Setting PROCAT_CI_GPG_USER_ID to default : ${PROCAT_CI_GPG_USER_ID}"
    fi

    if [ -z ${GPG_TTY+x} ]; then
        pc_log 'GPG_TTY is not set, setting to $(tty)...'
        export GPG_TTY=$(tty)
    fi

    pc_log ""
    pc_log "PROCAT_CI_SCRIPT_NAME                  : ${PROCAT_CI_SCRIPT_NAME}"
    pc_log "PROCAT_CI_SCRIPT_PATH                  : ${PROCAT_CI_SCRIPT_PATH}"
    pc_log "PROCAT_CI_LIBRARY_PATH                 : ${PROCAT_CI_LIBRARY_PATH}"
    pc_log "PROCAT_CI_GIT_SERVER                   : ${PROCAT_CI_GIT_SERVER}"
    pc_log "PROCAT_CI_REGISTRY_SERVER              : ${PROCAT_CI_REGISTRY_SERVER}"
    pc_log "PROCAT_CI_SCRIPTS_REPO                 : ${PROCAT_CI_SCRIPTS_REPO}"
    pc_log "PROCAT_CI_DOWNLOAD_PATH                : ${PROCAT_CI_DOWNLOAD_PATH}"
    pc_log "PROCAT_CI_GPG_USER_ID                  : ${PROCAT_CI_GPG_USER_ID}"
    pc_log ""

    # Create the download path if it doesn't exist already
    mkdir -p ${PROCAT_CI_DOWNLOAD_PATH}
}

function procat_ci_env_destroy_exports {
    # unset vars if they are currently set
    if [ ! -z ${PROCAT_CI_SCRIPT_NAME+x} ]; then
        unset PROCAT_CI_SCRIPT_NAME
    fi
    if [ ! -z ${PROCAT_CI_SCRIPT_PATH+x} ]; then
        unset PROCAT_CI_LIBRARY_PATH
    fi
    if [ ! -z ${PROCAT_CI_LIBRARY_PATH+x} ]; then
        unset PROCAT_CI_LIBRARY_PATH
    fi
    if [ ! -z ${PROCAT_CI_GIT_SERVER+x} ]; then
        unset PROCAT_CI_GIT_SERVER
    fi
    if [ ! -z ${PROCAT_CI_REGISTRY_SERVER+x} ]; then
        unset PROCAT_CI_REGISTRY_SERVER
    fi
    if [ ! -z ${PROCAT_CI_SCRIPTS_REPO+x} ]; then
        unset PROCAT_CI_SCRIPTS_REPO
    fi
    if [ ! -z ${PROCAT_CI_DOWNLOAD_PATH+x} ]; then 
        unset PROCAT_CI_DOWNLOAD_PATH
    fi
    if [ ! -z ${PROCAT_CI_GPG_USER_ID+x} ]; then 
        unset PROCAT_CI_GPG_USER_ID
    fi
}
