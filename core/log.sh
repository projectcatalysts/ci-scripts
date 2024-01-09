#!/bin/bash

#
# Include the library functions
#


#
# Determine the script directory
#
_script_filepath=$(realpath $0)
_script_filename=$(basename ${_script_filepath})
_script_path=$(dirname ${_script_filepath})
_script_pid=$$

# usage: log 'Message to log'
function pc_log {
	# log to stderr ensures log messages are not sent to calling function that captures output
    >&2 echo '['$(date +'%a %Y-%m-%d %H:%M:%S %z')']' "${_script_filename}  :  $1"
}

# function: pc_log_fatal
# desc:     log a message and exit
function pc_log_fatal {
	local readonly _msg={$1}
	local _exit_code={$2:-}
	if [ ! -z "${_exit_code}" ]; then
		_exit_code=1
	fi
	# using >&2 to echo to STDERR in case STDOUT has been redirected as part of a function call used to capture return values
	>&2 echo " "	
    pc_log "_msg"
	>&2 echo "Stopping script due to fatal error...."
	>&2 echo " "
	# refer to fatal_error_trap_handler in set_build_env.sh
    kill -10 $_script_pid
	exit ${_exit_code}
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
	pc_log "    " $1
	${1}
}