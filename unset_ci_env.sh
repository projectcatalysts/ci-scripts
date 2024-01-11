#!/bin/bash

# Define the function to unset the CI environment
function procat_ci_unset_environment {
    source ${PROCAT_CI_SCRIPTS_PATH}/lib.sh
    pc_log "procat_ci_unset_environment()    : Cleaning up..."
    procat_ci_ssh_destroy_agent

    source ${PROCAT_CI_SCRIPTS_PATH}/env.sh
    procat_ci_env_destroy_exports
}

# Call the function we've just defined
if [ -z "${PROCAT_CI_SCRIPTS_PATH}" ]; then
    echo "procat_ci_unset_environment()    : set_ci_env wasn't run"
    exit 1
else
    procat_ci_unset_environment
fi