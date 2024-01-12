#!/bin/bash -eu

# ---------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------

#
# gitlab_api_url
#
function gitlab_api_url {
	local _server=${1:-}
	printf "https://${_server}/api/v4"
}

#
# gitlab_project_uri
#
function gitlab_project_uri {
	local _project_id=${1}
	local _project_uri_suffix=${2:-}
	printf "/projects/${_project_id}${_project_uri_suffix}"
}

# ---------------------------------------------------------------------
# Projects
# ---------------------------------------------------------------------

#
# gitlab_list_projects
#
function gitlab_list_projects {
	local _token=${1}

	local _response=$(gitlab_get /projects ${_token})
	gitlab_handle_error 'Failed to list the projects' "${_response}"
	jq . <<< ${_response}
}

#
# gitlab_get_project
#
function gitlab_get_project {
	local _token=${1}
	local _project_id=${2}

	local _uri=$(gitlab_project_uri ${_project_id})
	local _response=$(gitlab_get ${_uri} ${_token})
	gitlab_handle_error "Failed to get the project: ${_project_id}" "${_response}"
	jq . <<< ${_response}
}

#
# gitlab_get_project_latest_pipeline
#
function gitlab_get_project_latest_pipeline {
	local _token=${1}
	local _project_id=${2}
	local _branch=${3}
	local _status=${4}

	local _uri=$(gitlab_project_uri ${_project_id} /pipelines?ref=${_branch}\&status=${_status}\&per_page=1\&page=1)
	local _response=$(gitlab_get ${_uri} ${_token})
	gitlab_handle_error "Failed to get the project pipeline: ${_project_id}" "${_response}"
	jq . <<< ${_response}
}

#
# gitlab_get_project_pipeline_jobs
#
function gitlab_get_project_pipeline_jobs {
	local _token=${1}
	local _project_id=${2}
	local _pipeline_id=${3}

	local _uri=$(gitlab_project_uri ${_project_id} /pipelines/${_pipeline_id}/jobs)
	local _response=$(gitlab_get ${_uri} ${_token})
	gitlab_handle_error "Failed to get the pipeline jobs for project: ${_project_id}" "${_response}"
	jq . <<< ${_response}
}

#
# gitlab_get_project_latest_release_tag
#
function gitlab_get_project_latest_release_tag {
	local _token=${1}
	local _project_id=${2}

	local _uri=$(gitlab_project_uri ${_project_id}/releases/ )
	local _response=$(gitlab_get ${_uri} ${_token})
	gitlab_handle_error "Failed to get the project's latest release tag: ${_project_id}" "${_response}"
	jq '.[0].tag_name' -r <<< ${_response}
}

#
# gitlab_get_project_latest_branch_tag
#
function gitlab_get_project_latest_branch_tag {
	local _token=${1}
	local _project_id=${2}
	local _branch_name=${3}

	# Get the latest commit on the specified branch
	local _uri=$(gitlab_project_uri ${_project_id}/repository/branches )
	local _response=$(gitlab_get ${_uri} ${_token})
	gitlab_handle_error "Failed to get the project's branch : ${_project_id} / ${_branch_name}" "${_response}"
	# >&2 jq . <<< ${_response}
	local _commit_id=$(
		jq --arg branchName "${_branch_name}" '.[] | select( .name == $branchName ) | .commit.id' -r <<< ${_response}
	) exit_code="$?"
	[ $exit_code != 0 ] && pc_log_fatal "jq exited with code : $exit_code"

	# Get the tag associated with the latest commit
	local _uri=$(gitlab_project_uri ${_project_id}/repository/tags )
	local _response=$(gitlab_get ${_uri} ${_token})
	gitlab_handle_error "Failed to get the project's tags : ${_project_id} / ${_branch_name}" "${_response}"
	local _tag_name=$(
		jq --arg commitId "${_commit_id}" '.[] | select( .target == $commitId ) | .name' -r <<< ${_response}
	) exit_code="$?"
	[ $exit_code != 0 ] && pc_log_fatal "jq exited with code : $exit_code"

	printf "${_tag_name}"
}


#
# gitlab_trigger_project_pipeline_api1
# - uses the /trigger/pipeline API
# - variables is expected to be passed as a JSON object, e.g.  '{ "myVar": "myValue" }'
#
function gitlab_trigger_project_pipeline_api1 {
	local _token=${1}
	local _project_id=${2}
	local _ref=${3}
	local _variables=${4:-}

	local _uri=$(gitlab_project_uri ${_project_id} "/trigger/pipeline" )
	
	if [[ ${_variables} == "" ]]; then
		pc_log "variables: nil${_variables}"
		local _response=$(gitlab_post ${_uri} ${_token} <(jq --null-input \
			--arg ref "${_ref}" \
			--arg token "${_token}" \
			'{
				"ref": $ref,
				"token": $token
			}' \
		))
		gitlab_handle_error "Failed to trigger the pileline for project : ${_project_id}" "${_response}"
	else
		local _response=$(gitlab_post ${_uri} ${_token} <(jq \
			--arg ref "${_ref}" \
			--arg token "${_token}" \
			'{
			    "ref": $ref,
			    "token": $token,
				"variables": .
			}' \
			<${_variables} \
		))
		gitlab_handle_error "Failed to trigger the pileline for project : ${_project_id}" "${_response}"
	fi
	
	if [ "$( jq 'has("message")' <<< ${_response} )" == "true" ]; then
		local readonly _message=$( jq '.message' <<< ${_response} )
		pc_log_fatal "ERROR: ${_message}"
	fi

	jq . <<< ${_response}
}

#
# gitlab_trigger_project_pipeline_api2
# - uses the /pipeline API
# - variables is expected to be passed as a JSON object, e.g.  '{ "myVar": "myValue" }'
#
function gitlab_trigger_project_pipeline_api2 {
	local _token=${1}
	local _project_id=${2}
	local _ref=${3}
	local _variables=${4:-}

	local _uri=$(gitlab_project_uri ${_project_id} "/pipeline" )
	
	if [[ ${_variables} == "" ]]; then
		local _response=$(gitlab_post ${_uri} ${_token} <(jq --null-input \
			--arg ref "${_ref}" \
			'{
				"ref": $ref
			}' \
		))
		gitlab_handle_error "Failed to trigger the pileline for project : ${_project_id}" "${_response}"
	else
		local _response=$(gitlab_post ${_uri} ${_token} <(jq \
			--arg ref "${_ref}" \
			'{
				"ref": $ref,
				"variables": . | to_entries
			}' \
			<${_variables} \
		))
		gitlab_handle_error "Failed to trigger the pileline for project : ${_project_id}" "${_response}"
	fi
	
	if [ "$( jq 'has("message")' <<< ${_response} )" == "true" ]; then
		local readonly _message=$( jq '.message' <<< ${_response} )
		pc_log_fatal "ERROR: ${_message}"
	fi

	jq . <<< ${_response}
}

# ---------------------------------------------------------------------
# Common helpers
# ---------------------------------------------------------------------

#
# gitlab_get
#
function gitlab_get {
	local _gitlab_http_action=GET
	local _gitlab_http_uri=${1}
	local _gitlab_http_token=${2:--}
	local _gitlab_payload_filepath=-
	gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri} ${_gitlab_http_token} ${_gitlab_payload_filepath} ${@:3}
}

#
# gitlab_list
#
function gitlab_list {
	local _gitlab_http_action=LIST
	local _gitlab_http_uri=${1}
	local _gitlab_http_token=${2:--}
	local _gitlab_payload_filepath=-
	gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri} ${_gitlab_http_token} ${_gitlab_payload_filepath} ${@:3}
}

#
# gitlab_post
#
function gitlab_post {
	local _gitlab_http_action=POST
	local _gitlab_http_uri=${1}
	local _gitlab_http_token=${2:--}
	local _gitlab_payload_filepath=${3:--}
	gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri} ${_gitlab_http_token} ${_gitlab_payload_filepath} ${@:4}
}

#
# gitlab_put
#
function gitlab_put {
	local _gitlab_http_action=PUT
	local _gitlab_http_uri=${1}
	local _gitlab_http_token=${2:--}
	local _gitlab_payload_filepath=${3:--}
	gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri} ${_gitlab_http_token} ${_gitlab_payload_filepath} ${@:4}
}

#
# gitlab_patch
#
function gitlab_patch {
	local _gitlab_http_action=PATCH
	local _gitlab_http_uri=${1}
	local _gitlab_http_token=${2:--}
	local _gitlab_payload_filepath=${3:--}
	gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri} ${_gitlab_http_token} ${_gitlab_payload_filepath} ${@:4}
}


#
# gitlab_delete
#
function gitlab_delete {
	local _gitlab_http_action=DELETE
	local _gitlab_http_uri=${1}
	local _gitlab_http_token=${2:--}
	local _gitlab_payload_filepath=${3:--}
	gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri} ${_gitlab_http_token} ${_gitlab_payload_filepath} ${@:4}
}


# ---------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------

#
# gitlab_exec
#
function gitlab_exec {
	local _silent='--silent --show-error'
	local _gitlab_http_action=${1}
	local _gitlab_http_uri=${2}
	local _gitlab_http_token=${3:--}
	local _gitlab_payload_filepath=${4:--}

	local _accept='application/json'
	local _content_type='application/json'

	if [ ${_gitlab_http_action} == PATCH ]; then
		_content_type='application/merge-patch+json'
	fi

	# Check the pre-requisite environment variables have been set
	if [ -z ${_gitlab_api_url+x} ]; then
	    pc_log_fatal "ERROR: The environment variable _gitlab_api_url must be configured prior to calling gitlab_exec!"
	fi

	# set -x

	# For some reason -o isn't working, so using redirects instead
	if [[ ${_gitlab_http_token} == "-" ]]; then
		if [[ ${_gitlab_payload_filepath} == "-" ]]; then
			pc_log "  gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri}"
			curl ${_silent} \
			-X ${_gitlab_http_action} \
			-H "Content-Type: ${_content_type}" \
     		-H "Accept: ${_accept}" \
			-H "Authorization: Bearer ${_gitlab_http_token}" \
			-H "PRIVATE-TOKEN: ${_gitlab_http_token}" \
			${_gitlab_api_url}${_gitlab_http_uri} \
			${@:5} \
			2>&1
		else
			pc_log "  gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri} '${_gitlab_payload_filepath}'"
			curl ${_silent} \
			-X ${_gitlab_http_action} \
			-H "Content-Type: ${_content_type}" \
     		-H "Accept: ${_accept}" \
			-H "Authorization: Bearer ${_gitlab_http_token}" \
			-H "PRIVATE-TOKEN: ${_gitlab_http_token}" \
			${_gitlab_api_url}${_gitlab_http_uri} \
			${@:5} \
			-d @${_gitlab_payload_filepath} \
			2>&1
		fi
	else
		if [[ ${_gitlab_payload_filepath} == "-" ]]; then
			pc_log "  gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri}"
			curl ${_silent} \
			-X ${_gitlab_http_action} \
			-H "Content-Type: ${_content_type}" \
     		-H "Accept: ${_accept}" \
			-H "Authorization: Bearer ${_gitlab_http_token}" \
			-H "PRIVATE-TOKEN: ${_gitlab_http_token}" \
			${_gitlab_api_url}${_gitlab_http_uri} \
			${@:5} \
			2>&1
		else
			pc_log "  gitlab_exec ${_gitlab_http_action} ${_gitlab_http_uri} '${_gitlab_payload_filepath}'"
			curl ${_silent} \
			-X ${_gitlab_http_action} \
			-H "Content-Type: ${_content_type}" \
     		-H "Accept: ${_accept}" \
			-H "Authorization: Bearer ${_gitlab_http_token}" \
			-H "PRIVATE-TOKEN: ${_gitlab_http_token}" \
			${_gitlab_api_url}${_gitlab_http_uri} \
			${@:5} \
			-d @${_gitlab_payload_filepath} \
			2>&1
		fi
	fi

	# set +x
}

# ---------------------------------------------------------------------
# Errors
# ---------------------------------------------------------------------

# function: gitlab_handle_error
# desc:     Checks a response from a gitlab API call
function gitlab_handle_error {
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