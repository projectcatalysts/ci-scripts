#!/bin/bash

# procat_ci_read_user_environment_variables
# NOTE: We cannot use logging functions here because when this function
#       is called the logging library has not yet been loaded.
function procat_ci_read_user_environment_variables {
    local readonly _missing_env_varname=${1}
    local readonly _procat_ci_env_filename='~/.procat_ci_env.sh'
    
    echo "WARNING : Project Catalysts CI environment setting not found       : ${_missing_env_varname}"
    echo "          Attempting to load CI environment settings from          : ${_procat_ci_env_filename}"
    
    # Try to load the user specific the CI environment settings
    # in case .bashrc or .profile wasn't updated to include them.

    # This step replaces the tilde in the path with the name of the home directory
    local readonly _file_name="${_procat_ci_env_filename/#\~/$HOME}"
    if [ ! -f ${_file_name} ]; then
        echo "ERROR   : Project Catalysts CI environment settings file not found : ${_file_name}"
        return 1
    fi
    source ${_file_name}
    echo "Listing define Project Catalysts CI defined environment variables..."
    env | grep "PROCAT_CI"
}

# procat_ci_set_environment
function procat_ci_set_environment {
    # NOTE: We cannot use logging functions here because when this function
    #       is called the logging library has not yet been loaded.

    #
    # Check the pre-requisite environment variables have been set
    #
    if [ -z ${PROCAT_CI_SCRIPTS_PATH+x} ]; then
        procat_ci_read_user_environment_variables "PROCAT_CI_SCRIPTS_PATH" || return $?

        if [ -z ${PROCAT_CI_SCRIPTS_PATH+x} ]; then
	        local _this_script=${BASH_SOURCE[0]}
            # export not required - we just need this in the context of this script
            PROCAT_CI_SCRIPTS_PATH="$(dirname "$(realpath "${_this_script}")" )"
            pc_log "Setting environment default      : PROCAT_CI_SCRIPTS_PATH    = ${PROCAT_CI_SCRIPTS_PATH}"
        fi
    fi
    if [ -z ${EXEC_CI_SCRIPT_NAME+x} ]; then
        # Set the name and path of the script that is being executed (for diagnostic purposes)
	    local _bash_source_len=${#BASH_SOURCE[@]}
	    local _first_script=${BASH_SOURCE[${_bash_source_len}-1]}
        # export not required - we just need this in the context of this script
        EXEC_CI_SCRIPT_NAME="${_first_script}"
    fi
    if [ -z ${EXEC_CI_SCRIPT_PATH+x} ]; then
        EXEC_CI_SCRIPT_PATH="$(dirname "$(realpath "${EXEC_CI_SCRIPT_NAME}")" )"
    fi

    #
    # Check for the presence of the Project Catalysts CI environment file that holds environment specific settings
    #
    if [ -z ${PROCAT_CI_DOMAIN+x} ]; then
        procat_ci_read_user_environment_variables "PROCAT_CI_DOMAIN" || return $?
    fi

    #
    # Bring the common CI script functions into scope.
    #
    # NOTE: This must be the first ci-script file sourced as all others depend on the functions
    #       defined within it (e.g. pc_log).  lib.sh will also install trap handlers for exit
    #       and fatal error handling.
    echo  "Sourcing CI library functions..."
    source ${PROCAT_CI_SCRIPTS_PATH}/lib.sh

    # NOTE: Logging functions are now available for use
    # Configure the traps for bash exit and fatal errors (SIGUSR1 = a user defined signal = 10)
    pc_log "procat_ci_set_environment()      : Setting traps for logout / shell exit / fatal error..."
    trap pc_exit_trap_handler EXIT
    trap pc_fatal_error_trap_handler 10

    # Bring the common build environment variables into scope
    pc_log "procat_ci_set_environment()      : Defining CI environment variables..."
    source ${PROCAT_CI_SCRIPTS_PATH}/env.sh
    
    # Check that required exports have been defined
    procat_ci_env_check_required_exports || return $?

    # procat_ci_env_create_default_exports creates exported variables with default values
    # for any that have not been defined explictly.  Key CI variables are also logged for
    # diagnostic purposed.  The download path is also verified and created if it doesn't
    # exist.
    procat_ci_env_create_default_exports || return $?

    # Load the SSH agent used for the build
    if [ -z "${PROCAT_CI_SSH_AUTH_SOCK:-}" ]; then

        procat_ci_ssh_create_agent || return $?

        pc_log "procat_ci_set_environment()      : Adding private keys (you may be prompted for passwords)."
        # Preserve SSH_AUTH_SOCK and restore after adding keys
        local readonly _ssh_auth_sock_backup=${SSH_AUTH_SOCK-}
        export SSH_AUTH_SOCK=${PROCAT_CI_SSH_AUTH_SOCK}
        ssh-add ~/.ssh/${PROCAT_CI_SSH_PRIVATE_KEY_FILENAME}
        export SSH_AUTH_SOCK=${_ssh_auth_sock_backup}

    else

        pc_log "procat_ci_set_environment()      : The build ssh agent is already loaded, here's the list of identifies...."
        # Preserve SSH_AUTH_SOCK and restore after adding keys
        local readonly _ssh_auth_sock_backup=${SSH_AUTH_SOCK-}
        export SSH_AUTH_SOCK=${PROCAT_CI_SSH_AUTH_SOCK}
        ssh-add -l
        export SSH_AUTH_SOCK=${_ssh_auth_sock_backup}

    fi

    pc_log "procat_ci_set_environment()      : Complete."
    pc_log " "
}

# Call the function, but first check to ensure that the script is being sourced, otherwise
# the exit trap handler will fire as soon as the script has finished.
#
# Reference:
#
#     https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
#
if (return 0 2>/dev/null) then
    procat_ci_set_environment || return $?
else
    echo "ERROR : The script has not been sourced!"
    echo "Execute this script with the following syntax:"
    echo ""
    echo "   source ./set_ci_env.sh"
    echo ""
fi