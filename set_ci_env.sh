#!/bin/bash

# procat_ci_set_environment
function procat_ci_set_environment {
    #
    # Check the pre-requisite environment variables have been set
    # - these are typically defined in ~/.procat_ci_env.sh which is sourced into ~/.bashrc or ~/.profile
    #
    if [ -z ${PROCAT_CI_SCRIPT_NAME+x} ]; then
        echo "ERROR: PROCAT_CI_SCRIPT_NAME has not been set!"
        return 2
    fi
    if [ -z ${PROCAT_CI_SCRIPT_PATH+x} ]; then
        echo "ERROR: PROCAT_CI_SCRIPT_PATH has not been set!"
        return 2
    fi
    if [ -z ${PROCAT_CI_LIBRARY_PATH+x} ]; then
        echo "ERROR: PROCAT_CI_LIBRARY_PATH has not been set!"
        return 2
    fi
    if [ -z ${PROCAT_CI_GPG_USER_ID+x} ]; then
        echo "ERROR: PROCAT_CI_GPG_USER_ID has not been set!"
        return 2
    fi

    # Bring the common CI script functions into scope.
    #
    # NOTE: This must be the first ci-script file sourced as all others depend on the functions
    #       defined within it (e.g. pc_log).
    #
    echo  "procat_ci_set_environment() : Sourcing library functions..."
    source ${PROCAT_CI_LIBRARY_PATH}/lib.sh

    # Bring the common build environment variables into scope
    pc_log "procat_ci_set_environment() : Defining build environment variables..."
    source ${PROCAT_CI_LIBRARY_PATH}/env.sh
    procat_ci_env_create_exports

    # Load the SSH agent used for the build
    if [ -z "${PROCAT_CI_SSH_AUTH_SOCK:-}" ]; then

        procat_ci_ssh_create_agent

        pc_log "procat_ci_set_environment() : Adding private keys (you may be prompted for passwords)."
        # Preserve SSH_AUTH_SOCK and restore after adding keys
        local readonly _ssh_auth_sock_backup=${SSH_AUTH_SOCK-}
        export SSH_AUTH_SOCK=${PROCAT_CI_SSH_AUTH_SOCK}
        ssh-add ~/.ssh/${PROCAT_CI_SSH_PRIVATE_KEY}
        export SSH_AUTH_SOCK=${_ssh_auth_sock_backup}

        pc_log "procat_ci_set_environment() : Setting traps for logout / shell exit / fatal error..."
        trap pc_exit_trap_handler EXIT
        # SIGUSR1 = a user defined signal = 10
        trap pc_fatal_error_trap_handler 10

    else

        pc_log "procat_ci_set_environment() : The build ssh agent is already loaded, here's the list of identifies...."
        # Preserve SSH_AUTH_SOCK and restore after adding keys
        local readonly _ssh_auth_sock_backup=${SSH_AUTH_SOCK-}
        export SSH_AUTH_SOCK=${PROCAT_CI_SSH_AUTH_SOCK}
        ssh-add -l
        export SSH_AUTH_SOCK=${_ssh_auth_sock_backup}

    fi

    pc_log "procat_ci_set_environment() : Complete."
}

# Call the function, but first check to ensure that the script is being sourced, otherwise
# the exit trap handler will fire as soon as the script has finished.
#
# Reference:
#
#     https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
#
if (return 0 2>/dev/null) then
    procat_ci_set_environment
else
    echo "ERROR : The script has not been sourced!"
    echo "Execute this script with the following syntax:"
    echo ""
    echo "   source ./set_ci_env.sh"
    echo ""
fi