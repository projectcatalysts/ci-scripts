#!/bin/bash

# pc_exit_trap_handler
function pc_exit_trap_handler {
    local readonly _exit_code=$?

    # Reset the exit trap handler
    # https://stackoverflow.com/questions/8122779/is-it-necessary-to-specify-traps-other-than-exit
    trap - EXIT

    # Get the path to this script (${BASH_SOURCE[0]} is always the current source file)
    pc_get_script_path ${BASH_SOURCE[0]} tmp
    readonly lib_path=$tmp

	# Execute the unset script from the same directory that this script lives in
    "${lib_path}/unset_ci_env.sh"
    local readonly _unset_ci_env_exit_code=$?
    if [ ${_unset_ci_env_exit_code} != 0 ]; then
        # An error occurred cleaning up the environment
        pc_log "pc_exit_trap_handler() : An error occurred cleaning up the environment, exiting with exit code ${_unset_ci_env_exit_code}"
        exit ${_unset_ci_env_exit_code}
    fi

    # Exit without changing the exit code
    pc_log "pc_exit_trap_handler() : Complete, exiting with exit code ${_exit_code}"
    exit ${_exit_code}
}

# pc_fatal_error_trap_handler
function pc_fatal_error_trap_handler {
    local readonly _exit_code=$?
    if [ ${_exit_code} == 0 ]; then
        pc_log "pc_fatal_error_trap_handler() : Complete, exiting with default exit code 1"
        exit 1
    fi
    pc_log "pc_fatal_error_trap_handler() : Complete, exiting with exit code ${_exit_code}"
    exit ${_exit_code}
}

# function: pc_get_script_path returns the path to a script, following symbolic links as necessary
# usage:    pc_get_script_path ${BASH_SOURCE[0]} returnVariableName
# example:  pc_get_script_path ${BASH_SOURCE[0]} tmp
function pc_get_script_path {
    local source=$1
    local __resultvar=$2
    local dir=''
    while [ -h "$source" ]; do # resolve $SOURCE until the file is no longer a symlink
        dir="$( cd -P "$( dirname "$source" )" && pwd )"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    dir="$( cd -P "$( dirname "$source" )" && pwd )"
    eval $__resultvar="'$dir'"
}

#
# Determine where this file resides
#
pc_get_script_path ${BASH_SOURCE[0]} tmp
readonly _procat_ci_library_path=${tmp}

#
# Include the core library functions (i.e. the functions typically required by all CI scripts)
#
if [ ! -f "${_procat_ci_library_path}/core/log.sh" ]; then
    echo "ERROR: Project Catalysts CI core library file not found : ${_procat_ci_library_path}/core/log.sh"
    return 1
fi
if [ ! -f "${_procat_ci_library_path}/core/docker.sh" ]; then
    echo "ERROR: Project Catalysts CI core library file not found : ${_procat_ci_library_path}/core/docker.sh"
    return 1
fi
if [ ! -f "${_procat_ci_library_path}/core/download.sh" ]; then
    echo "ERROR: Project Catalysts CI core library file not found : ${_procat_ci_library_path}/core/download.sh"
    return 1
fi
if [ ! -f "${_procat_ci_library_path}/core/semver.sh" ]; then
    echo "ERROR: Project Catalysts CI core library file not found : ${_procat_ci_library_path}/core/semver.sh"
    return 1
fi
if [ ! -f "${_procat_ci_library_path}/core/ssh.sh" ]; then
    echo "ERROR: Project Catalysts CI core library file not found : ${_procat_ci_library_path}/core/ssh.sh"
    return 1
fi

# Load the logging library first (just in case sourcing of
# the other library functions causes an error).
source ${_procat_ci_library_path}/core/log.sh
source ${_procat_ci_library_path}/core/docker.sh
source ${_procat_ci_library_path}/core/download.sh
source ${_procat_ci_library_path}/core/semver.sh
source ${_procat_ci_library_path}/core/ssh.sh

#
# If the library path export hasn't been set, we can set it now
# since we know where the library resides!
#
if [ -z ${PROCAT_CI_SCRIPTS_PATH+x} ]; then
    export PROCAT_CI_SCRIPTS_PATH=${_procat_ci_library_path}
fi