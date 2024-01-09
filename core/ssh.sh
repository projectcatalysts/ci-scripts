#!/bin/bash

# function: procat_ci_ssh_create_agent
# desc:     starts an SSH agent used specifically for CI
# usage:    procat_ci_ssh_create_agent
function procat_ci_ssh_create_agent {
	if [ -z "${PROCAT_CI_SSH_AUTH_SOCK-}" ]; then
		pc_log "ssh_create_ci_agent()            : Creating a new ssh agent for the build...."
		export PROCAT_CI_SSH_TEMP_FILEPATH=$(mktemp -t build_ssh_agent.XXXXXXXXXX)
		# umask changes the permissions of the newly created file
		(umask 066; ssh-agent > ${PROCAT_CI_SSH_TEMP_FILEPATH})
		export PROCAT_CI_SSH_AUTH_SOCK=$(awk '/^SSH_AUTH_SOCK=/{ split($0,p1,";"); split(p1[1],p2,"="); print p2[2] }\' ${PROCAT_CI_SSH_TEMP_FILEPATH})
		export PROCAT_CI_SSH_AGENT_PID=$(awk '/^SSH_AGENT_PID=/{ split($0,p1,";"); split(p1[1],p2,"="); print p2[2] }\' ${PROCAT_CI_SSH_TEMP_FILEPATH})

		pc_log "procat_ci_ssh_create_agent()     : Setting trap exit to cleanup after build completes...."
		trap procat_ci_ssh_destroy_agent EXIT
	else
		pc_log "procat_ci_ssh_create_agent()     : The build ssh agent is already loaded."
	fi
	pc_log "PROCAT_CI_SSH_TEMP_FILEPATH      : ${PROCAT_CI_SSH_TEMP_FILEPATH}"
	pc_log "PROCAT_CI_SSH_AUTH_SOCK          : ${PROCAT_CI_SSH_AUTH_SOCK}"
	pc_log "PROCAT_CI_SSH_AGENT_PID          : ${PROCAT_CI_SSH_AGENT_PID}"
	pc_log " "
}

# function: procat_ci_ssh_destroy_agent
# desc:     stops an SSH agent used specifically for CI
# usage:    procat_ci_ssh_destroy_agent
function procat_ci_ssh_destroy_agent {
	if [ "${PROCAT_CI_SSH_AUTH_SOCK-}" ]; then
		pc_log "procat_ci_ssh_destroy_agent()    : Stopping the ssh agent used for the build...."
		kill ${PROCAT_CI_SSH_AGENT_PID}
		rm ${PROCAT_CI_SSH_TEMP_FILEPATH}
		unset PROCAT_CI_SSH_TEMP_FILEPATH
		unset PROCAT_CI_SSH_AUTH_SOCK
		unset PROCAT_CI_SSH_AGENT_PID
		pc_log "PROCAT_CI_SSH_TEMP_FILEPATH      : ${PROCAT_CI_SSH_TEMP_FILEPATH}"
		pc_log "PROCAT_CI_SSH_AUTH_SOCK          : ${PROCAT_CI_SSH_AUTH_SOCK}"
		pc_log "PROCAT_CI_SSH_AGENT_PID          : ${PROCAT_CI_SSH_AGENT_PID}"
	else
		pc_log "procat_ci_ssh_destroy_agent()    : A build ssh agent is not configured."
	fi
}
