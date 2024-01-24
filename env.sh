# procat_ci_env_check_required_exports checks that required exports have been specified
# for this user / organisation.
function procat_ci_env_check_required_exports {
    if [ -z ${PROCAT_CI_DOMAIN+x} ]; then
        pc_log_fatal "Project Catalysts CI environment setting has not been specified : PROCAT_CI_DOMAIN"
    fi

    if [ -z ${PROCAT_CI_GIT_SERVER+x} ]; then
        pc_log_fatal "Project Catalysts CI environment setting has not been specified : PROCAT_CI_GIT_SERVER"
    fi

    if [ -z ${PROCAT_CI_REGISTRY_SERVER+x} ]; then
        pc_log_fatal "Project Catalysts CI environment setting has not been specified : PROCAT_CI_REGISTRY_SERVER"
    fi

    if [ -z ${PROCAT_CI_BUILD_SERVER+x} ]; then
        pc_log_fatal "Project Catalysts CI environment setting has not been specified : PROCAT_CI_BUILD_SERVER"
    fi

    if [ -z ${PROCAT_CI_SSH_PRIVATE_KEY_FILENAME+x} ]; then
        pc_log_fatal "Project Catalysts CI environment setting has not been specified : PROCAT_CI_SSH_PRIVATE_KEY_FILENAME"
    fi
}

# procat_ci_env_create_default_exports creates exported variables with default values
# for any that have not been defined explictly.  Key CI variables are also logged for
# diagnostic purposed.  The download path is also verified and created if it doesn't
# exist.
function procat_ci_env_create_default_exports {
    if [ -z ${PROCAT_CI_GPG_USER_ID+x} ]; then 
        export PROCAT_CI_GPG_USER_ID=${USER}
        pc_log "Setting environment default      : PROCAT_CI_GPG_USER_ID     = ${PROCAT_CI_GPG_USER_ID}"
    fi

    if [ -z ${PROCAT_CI_SCRIPTS_REPO+x} ]; then 
        export PROCAT_CI_SCRIPTS_REPO=git@${PROCAT_CI_GIT_SERVER}:procat/ci-scripts.git
        pc_log "Setting environment default      : PROCAT_CI_SCRIPTS_REPO    = ${PROCAT_CI_SCRIPTS_REPO}"
    fi

    # There is no default setting for PROCAT_CI_SCRIPTS_PATH

    if [ -z ${PROCAT_CI_DOWNLOAD_PATH+x} ]; then 
        export PROCAT_CI_DOWNLOAD_PATH=~/downloads
        pc_log "Setting environment default      : PROCAT_CI_DOWNLOAD_PATH   = ${PROCAT_CI_DOWNLOAD_PATH}"
    fi

    if [ -z ${PROCAT_CI_SSH_GITHUB_PRIVATE_KEY_FILENAME+x} ]; then 
        export PROCAT_CI_SSH_GITHUB_PRIVATE_KEY_FILENAME="${PROCAT_CI_SSH_PRIVATE_KEY_FILENAME}"
        pc_log "Setting environment default      : PROCAT_CI_SSH_GITHUB_PRIVATE_KEY_FILENAME = ${PROCAT_CI_SSH_GITHUB_PRIVATE_KEY_FILENAME}"
    fi

    if [ -z ${GPG_TTY+x} ]; then
        export GPG_TTY=$(tty)
        pc_log "Setting environment default      : GPG_TTY                   = \$(tty)"
    fi

    pc_log ""
    pc_log "EXEC_CI_SCRIPT_NAME              : ${EXEC_CI_SCRIPT_NAME}"
    pc_log "EXEC_CI_SCRIPT_PATH              : ${EXEC_CI_SCRIPT_PATH}"
    pc_log "PROCAT_CI_DOMAIN                 : ${PROCAT_CI_DOMAIN}"
    pc_log "PROCAT_CI_GIT_SERVER             : ${PROCAT_CI_GIT_SERVER}"
    pc_log "PROCAT_CI_REGISTRY_SERVER        : ${PROCAT_CI_REGISTRY_SERVER}"
    pc_log "PROCAT_CI_BUILD_SERVER           : ${PROCAT_CI_BUILD_SERVER}"
    pc_log "PROCAT_CI_SCRIPTS_REPO           : ${PROCAT_CI_SCRIPTS_REPO}"
    pc_log "PROCAT_CI_SCRIPTS_PATH           : ${PROCAT_CI_SCRIPTS_PATH}"
    pc_log "PROCAT_CI_DOWNLOAD_PATH          : ${PROCAT_CI_DOWNLOAD_PATH}"
    pc_log "PROCAT_CI_GPG_USER_ID            : ${PROCAT_CI_GPG_USER_ID}"
    pc_log ""

    # Create the download path if it doesn't exist already
    mkdir -p ${PROCAT_CI_DOWNLOAD_PATH}
}

function procat_ci_env_destroy_exports {
    # unset vars if they are currently set
    if [ ! -z ${EXEC_CI_SCRIPT_NAME+x} ]; then
        unset EXEC_CI_SCRIPT_NAME
    fi
    if [ ! -z ${EXEC_CI_SCRIPT_PATH+x} ]; then
        unset EXEC_CI_SCRIPT_PATH
    fi
}
