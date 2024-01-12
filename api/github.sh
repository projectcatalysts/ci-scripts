#!/bin/bash -eu

GITHUB_API_VERSION="2022-11-28"

# ---------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------

#
# github_api_url
#
function github_api_url {
	printf "https://api.github.com"
}

#
# github_repo_uri
#
function github_repo_uri {
	local _owner=${1}
	local _repo=${2}
	local _project_uri_suffix=${3:-}
	if [ -z $_project_uri_suffix ]; then
		printf "/repos/${_owner}/${_repo}"
	else
		printf "/repos/${_owner}/${_repo}/${_project_uri_suffix}"
	fi
}

# ---------------------------------------------------------------------
# Repository functions
# ---------------------------------------------------------------------

#
# github_get_repo
#
function github_get_repo {
	local _token=${1}
	local _owner=${2}
	local _repo=${3}

	local _uri=$(github_repo_uri ${_owner} ${_repo})
	local _response=$(github_get ${_uri} ${_token})
	github_handle_error "Failed to get the repo: ${_owner}/${_repo}" "${_response}"
	jq . <<< ${_response}
}


# ---------------------------------------------------------------------
# Common helpers
# ---------------------------------------------------------------------

#
# github_get
#
function github_get {
	local _github_http_action=GET
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_payload_filepath=-
	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_payload_filepath} ${@:3}
}

#
# gitlab_list
#
function gitlab_list {
	local _github_http_action=LIST
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_payload_filepath=-
	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_payload_filepath} ${@:3}
}

#
# gitlab_post
#
function gitlab_post {
	local _github_http_action=POST
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_payload_filepath=${3:--}
	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_payload_filepath} ${@:4}
}

#
# gitlab_put
#
function gitlab_put {
	local _github_http_action=PUT
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_payload_filepath=${3:--}
	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_payload_filepath} ${@:4}
}

#
# gitlab_patch
#
function gitlab_patch {
	local _github_http_action=PATCH
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_payload_filepath=${3:--}
	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_payload_filepath} ${@:4}
}


#
# gitlab_delete
#
function gitlab_delete {
	local _github_http_action=DELETE
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_payload_filepath=${3:--}
	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_payload_filepath} ${@:4}
}


# ---------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------

#
# github_exec
#
function github_exec {
	local _silent='--silent --show-error'
	local _github_http_action=${1}
	local _github_http_uri=${2}
	local _github_http_token=${3:--}
	local _github_payload_filepath=${4:--}

	local _accept='application/vnd.github+json'
	local _content_type='application/json'

	if [ ${_github_http_action} == PATCH ]; then
		_content_type='application/merge-patch+json'
	fi

	# Check the pre-requisite environment variables have been set
	if [ -z ${_github_api_url+x} ]; then
	    pc_log_fatal "ERROR: The environment variable _github_api_url must be configured prior to calling github_exec!"
	fi

	set -x

	# For some reason -o isn't working, so using redirects instead
	if [[ ${_github_http_token} == "-" ]]; then
		if [[ ${_github_payload_filepath} == "-" ]]; then
			pc_log "  github_exec ${_github_http_action} ${_github_http_uri}"
			curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_content_type}" \
     		-H "Accept: ${_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			${_github_api_url}${_github_http_uri} \
			${@:5} \
			2>&1
		else
			pc_log "  github_exec ${_github_http_action} ${_github_http_uri} '${_github_payload_filepath}'"
			curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_content_type}" \
     		-H "Accept: ${_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			${_github_api_url}${_github_http_uri} \
			${@:5} \
			-d @${_github_payload_filepath} \
			2>&1
		fi
	else
		if [[ ${_github_payload_filepath} == "-" ]]; then
			pc_log "  github_exec ${_github_http_action} ${_github_http_uri}"
			curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_content_type}" \
     		-H "Accept: ${_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			${_github_api_url}${_github_http_uri} \
			${@:5} \
			2>&1
		else
			pc_log "  github_exec ${_github_http_action} ${_github_http_uri} '${_github_payload_filepath}'"
			curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_content_type}" \
     		-H "Accept: ${_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			${_github_api_url}${_github_http_uri} \
			${@:5} \
			-d @${_github_payload_filepath} \
			2>&1
		fi
	fi

	set +x
}

# ---------------------------------------------------------------------
# Errors
# ---------------------------------------------------------------------

# function: github_handle_error
# desc:     Checks a response from a github API call
function github_handle_error {
	local _msg=${1}
	local _response=${2:-}

	if [[ ${_response} == '' ]]; then
		pc_log_fatal "ERROR: ${_msg}, unknown error (no response)"
	fi
	if [[ ${_response:0:1} == "{" ]]; then
		_error=$(jq -r '.message // empty' <<< ${_response})
		if [[ ! -z "${_error}" ]]; then
			pc_log_fatal "ERROR: ${_msg}, error = ${_error}"
		fi	
	elif [[ ${_response:0:1} != "[" ]]; then
		pc_log_fatal "ERROR: ${_msg}, response = ${_response}"
	fi
}