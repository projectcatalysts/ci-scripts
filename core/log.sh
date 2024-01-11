#!/bin/bash

#
# Capture the PID for this bash process in case we need to notify it (via SIGUSR1)
# to terminate due to a fatal error.
#
_procat_ci_script_pid=$$

# usage: log 'Message to log'
function pc_log {
	# Determine the name of the script
	_bash_source_len=${#BASH_SOURCE[@]}
	_first_script=${BASH_SOURCE[${_bash_source_len}-1]}

	# log to stderr ensures log messages are not sent to calling function that captures output
    >&2 echo '['$(date +'%a %Y-%m-%d %H:%M:%S %z')']' "${_first_script}  :  $1"
}

# function: pc_log_fatal
# desc:     log a message and exit
function pc_log_fatal {
	local readonly _msg=${1}
	local _exit_code=${2:-}
	if [ -z "${_exit_code}" ]; then
		_exit_code=1
	fi
	# using >&2 to echo to STDERR in case STDOUT has been redirected as part of a function call used to capture return values
	>&2 echo " "
    pc_log "$_msg"

	pc_print_call_stack

	>&2 echo "Stopping script due to fatal error...."
	>&2 echo " "
	# refer to pc_fatal_error_trap_handler in set_ci_env.sh
    kill -10 ${_procat_ci_script_pid}
	exit ${_exit_code}
}

# function: pc_print_call_stack
# usage:    pc_print_call_stack
function pc_print_call_stack {
	>&2 echo " "
	>&2 echo "call stack:"
	>&2 echo "-----------"
	slen=${#BASH_SOURCE[@]}
	for (( i=${slen}-1; i>1; i-- )); do
		_scriptName=${BASH_SOURCE[$i]}
		_funcName=${FUNCNAME[$i]}
		if [[ ${_funcName} == "source" ]]; then
			>&2 echo "${_scriptName}"
		else
			>&2 echo "${_scriptName}::${_funcName}()"
		fi
	done
	>&2 echo "-----------"
}

# function: pc_eval
# desc:     log a single-line command to the console and then execute it
# usage:    pc_eval 'docker ps'
function pc_eval {
    local cmd=${1}
	>&2 echo "    ${cmd}"
	eval "${cmd}"
}

# function: pc_exec
# desc:     log a command to the console and then execute it
# usage:    pc_exec 'docker ps'
function pc_exec {
	pc_log ""
	pc_log "    $1"
	pc_log ""
	${1}
}