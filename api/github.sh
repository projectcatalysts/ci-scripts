#!/bin/bash -eu
GITHUB_URL="https://github.com"
GITHUB_URL_API="https://api.github.com"
GITHUB_URL_UPLOAD="https://uploads.github.com"
GITHUB_API_VERSION="2022-11-28"
GITHUB_DEFAULT_PAGE_COUNT=30
GITHUB_DEFAULT_ACCEPT='application/vnd.github+json'
GITHUB_DEFAULT_CONTENT_TYPE='application/json'
# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
GITHUB_SSH_HOST_PUBLIC_KEY='|1|euws6XaVD4eb5bQ3anIOgExRTio=|ML1fwJrFCz1oUj166czbxXMWxxY= ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'

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
# github_repo_get
#
function github_repo_get {
	local _token=${1}
	local _owner=${2}
	local _repo=${3}

	local _uri=$(github_repo_uri ${_owner} ${_repo})
	local _response=$(github_get ${_uri} ${_token})
	github_handle_error "Failed to get the repo: ${_owner}/${_repo}" "${_response}"
	jq . <<< ${_response}
}

# ---------------------------------------------------------------------
# Release functions
# ---------------------------------------------------------------------

#
# github_release_get
#
function github_release_get {
	local _token=${1}
	local _owner=${2}
	local _repo=${3}
	local _tag_name=${4}
	local _must_exist=${5:-true}

	# We can't use the releases/tags/${_tag_name} API because that only looks for published releases
	local _uri=$(github_repo_uri ${_owner} ${_repo} "releases")

	# the releases API could return paged results, so
	# determine how many pages or results there are
	local _page_count=$(github_get_page_count ${_uri} ${_token}) || return $?
	pc_log "  github_release_get: page_count = ${_page_count}"

	local _curl_exit_code=0
	for (( _page = 1; ${_page} <= ${_page_count}; _page++ )); do
		local _response=$(github_get_page ${_page} ${_uri} ${_token}) || return $?
		github_handle_error_ex "Not Found" "Failed to get the release: ${_owner}/${_repo}:${_tag_name}" "${_response}"

		# Show the response
		# >&2 jq . <<< ${_response}
		# >&2 jq '.[]' <<< ${_response}

		# Search for the release in this page
		local _release=$(jq --arg tagName "${_tag_name}" '.[] | select( .tag_name==$tagName )' <<< ${_response} )

		if [[ -n "${_release}" ]]; then
			# We have found a matching release - return it
			# Return the release
			jq . <<< ${_release}
			return 0
		fi
	done

	if [[ "${_must_exist}" == "true" ]]; then
		pc_log_fatal "ERROR: Failed to get the release: ${_owner}/${_repo}:${_tag_name}, error = 'Not Found'"
	fi
	return 0
}

#
# github_release_create
#
function github_release_create {
	local _token=${1}
	local _owner=${2}
	local _repo=${3}
	local _branch=${4}
	local _tag_name=${5}
	local _is_draft=${6:-true}
	local _is_pre_release=${6:-true}

	local _uri=$(github_repo_uri ${_owner} ${_repo} "releases" )
	local _response=$(github_post ${_uri} ${_token} ${GITHUB_DEFAULT_CONTENT_TYPE} <(jq --null-input \
		--arg branch "${_branch}" \
		--arg tagName "${_tag_name}" \
		--argjson isDraft ${_is_draft} \
		--argjson isPreRelease ${_is_pre_release} \
		'{
			"tag_name": $tagName,
			"target_commitish": $branch,
			"name": $tagName,
			"body": ("Description of " + $tagName),
			"draft": $isDraft,
			"prerelease": $isPreRelease,
			"generate_release_notes": false
		}' \
	))
	github_handle_error "Failed to create the release: ${_owner}/${_repo}:${_tag_name}" "${_response}"
	jq . <<< ${_response}
}

#
# github_release_assets_list
#
function github_release_assets_list {
	local _token=${1}
	local _owner=${2}
	local _repo=${3}
	local _release_id=${4}

	local _uri=$(github_repo_uri ${_owner} ${_repo} "releases/${_release_id}/assets")
	local _response=$(github_get ${_uri} ${_token})
	github_handle_error "Failed to list the release assets: ${_owner}/${_repo}/${_release_id}" "${_response}"
	jq . <<< ${_response}
}

#
# github_release_asset_create
#
function github_release_asset_create {
	local _token=${1}
	local _owner=${2}
	local _repo=${3}
	local _release_id=${4}
	local _content_type=${5}
	local _file_name=${6}
	local _file_path=${7}

	local _uri=$(github_repo_uri ${_owner} ${_repo} "releases/${_release_id}/assets?name=${_file_name}")
	local _silent='--silent --show-error'

	pc_log "  github_release_asset_create ${_uri} '${_file_path}'"
	local _response=$(curl ${_silent} \
		-X POST \
		-H "Content-Type: ${_content_type}" \
		-H "Accept: ${GITHUB_DEFAULT_ACCEPT}" \
		-H "Authorization: Bearer ${_token}" \
		-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
		${GITHUB_URL_UPLOAD}${_uri} \
		-d "@${_file_path}" \
		2>&1 \
	)
	_curl_exit_code=$?

	# Log the request payload if curl returned an error
	# If we discover any requests that contain sensitive information we'll need to revist this approach!
	if [ $_curl_exit_code != 0 ]; then
		pc_log "  curl returned an error exit code: ${_curl_exit_code}"
		return ${_curl_exit_code}
	fi
	github_handle_error "Failed to create the release asset: ${_owner}/${_repo}/${_release_id}/${_file_name}" "${_response}"
	jq . <<< ${_response}
}

#
# github_release_asset_delete
#
function github_release_asset_delete {
	local _token=${1}
	local _owner=${2}
	local _repo=${3}
	local _asset_id=${4}

	local _uri=$(github_repo_uri ${_owner} ${_repo} "releases/assets/${_asset_id}")
	local _silent='--silent --show-error'

	pc_log "  github_release_asset_delete ${_uri}"
	local _response=$(curl ${_silent} \
		-X DELETE \
		-H "Accept: ${GITHUB_DEFAULT_ACCEPT}" \
		-H "Authorization: Bearer ${_token}" \
		-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
		${_github_api_url}${_uri} \
		2>&1 \
	)
	_curl_exit_code=$?

	# Log the request payload if curl returned an error
	# If we discover any requests that contain sensitive information we'll need to revist this approach!
	if [ $_curl_exit_code != 0 ]; then
		pc_log "  curl returned an error exit code: ${_curl_exit_code}"
		return ${_curl_exit_code}
	fi
	# A blank response indicates success
	if [[ ! -z "${_response}" ]]; then
		github_handle_error "Failed to delete the release asset: ${_owner}/${_repo}/${_asset_id}" "${_response}"
		jq . <<< ${_response}
	fi
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
	local _github_content_type=${3:--}
	local _github_payload_filepath=${4:--}

	local _github_content_type
	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_content_type} ${_github_payload_filepath} ${@:5}
}

#
# github_list
#
function github_list {
	local _github_http_action=LIST
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_content_type=${3:--}
	local _github_payload_filepath=${4:--}

	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_content_type} ${_github_payload_filepath} ${@:5}
}

#
# github_post
#
function github_post {
	local _github_http_action=POST
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_content_type=${3:--}
	local _github_payload_filepath=${4:--}

	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_content_type} ${_github_payload_filepath} ${@:5}
}

#
# github_put
#
function github_put {
	local _github_http_action=PUT
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_content_type=${3:--}
	local _github_payload_filepath=${4:--}

	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_content_type} ${_github_payload_filepath} ${@:5}
}

#
# github_patch
#
function github_patch {
	local _github_http_action=PATCH
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_content_type=${3:--}
	local _github_payload_filepath=${4:--}

	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_content_type} ${_github_payload_filepath} ${@:5}
}


#
# github_delete
#
function github_delete {
	local _github_http_action=DELETE
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_content_type=${3:--}
	local _github_payload_filepath=${4:--}

	github_exec ${_github_http_action} ${_github_http_uri} ${_github_http_token} ${_github_content_type} ${_github_payload_filepath} ${@:5}
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
	local _github_content_type=${4:--}
	local _github_payload_filepath=${5:--}

	local _github_accept=${GITHUB_DEFAULT_ACCEPT}
	if [[ ${_github_content_type} == "-" ]]; then
		_github_content_type=${GITHUB_DEFAULT_CONTENT_TYPE}
	fi

	# Check the pre-requisite environment variables have been set
	if [ -z ${_github_api_url+x} ]; then
	    pc_log_fatal "ERROR: The environment variable _github_api_url must be configured prior to calling github_exec!"
	fi

	# For some reason -o isn't working, so using redirects instead
	if [[ ${_github_payload_filepath} == "-" ]]; then
		pc_log "  github_exec ${_github_http_action} ${_github_http_uri}"
		curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_github_content_type}" \
			-H "Accept: ${_github_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			${_github_api_url}${_github_http_uri} \
			${@:6} \
			2>&1
		_curl_exit_code=$?
	else
		pc_log "  github_exec ${_github_http_action} ${_github_http_uri} '${_github_payload_filepath}'"
		curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_github_content_type}" \
			-H "Accept: ${_github_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			${_github_api_url}${_github_http_uri} \
			${@:6} \
			-d @${_github_payload_filepath} \
			2>&1
		_curl_exit_code=$?

		# Log the request payload if curl returned an error
		# If we discover any requests that contain sensitive information we'll need to revist this approach!
		if [ $_curl_exit_code != 0 ]; then
			pc_log "  curl returned an error exit code: ${_curl_exit_code}, logging request payload..."
			>&2 jq . <${_github_payload_filepath}
		fi
	fi
	# set +x
	return ${_curl_exit_code}
}

#
# github_get_page_count
#
function github_get_page_count {
	local _silent='--silent --show-error'
	local _github_http_uri=${1}
	local _github_http_token=${2:--}
	local _github_payload_filepath=${3:--}

	local _github_http_action="GET"
	local _github_accept=${GITHUB_DEFAULT_ACCEPT}
	local _github_content_type=${GITHUB_DEFAULT_CONTENT_TYPE}
	local _page_count=1

	# Check the pre-requisite environment variables have been set
	if [ -z ${_github_api_url+x} ]; then
	    pc_log_fatal "ERROR: The environment variable _github_api_url must be configured prior to calling github_get_page_count!"
	fi

	local _response_headers=""

	# Specify the number of results per page if not already set
	if [[ ! ${_github_http_uri} = *'pages='* ]]; then
		_github_http_uri="${_github_http_uri}?per_page=${GITHUB_DEFAULT_PAGE_COUNT}"
	fi

	# Execute get with -I flag to list returned headers
	# which are then parsed to determine the number of pages
	if [[ ${_github_payload_filepath} == "-" ]]; then
		_response_headers=$(curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_github_content_type}" \
			-H "Accept: ${_github_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			-I ${_github_api_url}${_github_http_uri} \
			${@:5} \
			2>&1 \
		); _curl_exit_code=$?

		if [ $_curl_exit_code != 0 ]; then
			pc_log "  github_get_page_count ${_github_http_action} ${_github_http_uri}"
			pc_log "  curl returned an error exit code: ${_curl_exit_code}"
			return $_curl_exit_code
		fi
	else
		_response_headers=$(curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_github_content_type}" \
			-H "Accept: ${_github_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			-I ${_github_api_url}${_github_http_uri} \
			${@:5} \
			-d @${_github_payload_filepath} \
			2>&1 \
		); _curl_exit_code=$?
		
		if [ $_curl_exit_code != 0 ]; then
			pc_log "  github_get_page_count ${_github_http_action} ${_github_http_uri} '${_github_payload_filepath}'"
			pc_log "  curl returned an error exit code: ${_curl_exit_code}, logging request..."
			>&2 jq . <${_github_payload_filepath}
			return $_curl_exit_code
		fi
	fi

	# Parse the respose headers looking for the page count
	# Single page results (no pagination) have no 'link:' header and the grep result is empty
	local readonly _link_header=$(echo "${_response_headers}" | grep '^link:')
	if [[ ! -z "${_link_header}" ]]; then
		_page_count=$(echo ${_link_header} | sed -e 's/^link:.*page=//g' -e 's/>.*$//g' )
	fi

	# Return the page count to the caller
	echo "${_page_count}"

	return 0
}


#
# github_get_page
#
function github_get_page {
	local _silent='--silent --show-error'
	local _page=${1}
	local _github_http_uri=${2}
	local _github_http_token=${3:--}
	local _github_payload_filepath=${4:--}

	local _github_http_action='GET'
	local _github_accept=${GITHUB_DEFAULT_ACCEPT}
	local _gitgub_content_type=${GITHUB_DEFAULT_CONTENT_TYPE}

	# Check the pre-requisite environment variables have been set
	if [ -z ${_github_api_url+x} ]; then
	    pc_log_fatal "ERROR: The environment variable _github_api_url must be configured prior to calling github_get_page!"
	fi

	# Specify the number of results per page if not already set
	if [[ ! ${_github_http_uri} = *'pages='* ]]; then
		_github_http_uri="${_github_http_uri}?per_page=${GITHUB_DEFAULT_PAGE_COUNT}"
	fi

	# For some reason -o isn't working, so using redirects instead
	if [[ ${_github_payload_filepath} == "-" ]]; then
		pc_log "  github_get_page ${_github_http_action} ${_github_http_uri}&page=${_page}"
		curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_gitgub_content_type}" \
			-H "Accept: ${_github_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			"${_github_api_url}${_github_http_uri}&page=${_page}" \
			${@:5} \
			2>&1
		_curl_exit_code=$?
	else
		pc_log "  github_get_page ${_github_http_action} ${_github_http_uri} '${_github_payload_filepath}&page=${_page}'"
		curl ${_silent} \
			-X ${_github_http_action} \
			-H "Content-Type: ${_gitgub_content_type}" \
			-H "Accept: ${_github_accept}" \
			-H "Authorization: Bearer ${_github_http_token}" \
			-H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
			"${_github_api_url}${_github_http_uri}&page=${_page}" \
			${@:5} \
			-d @${_github_payload_filepath} \
			2>&1
		_curl_exit_code=$?

		# Log the request payload if curl returned an error
		# If we discover any requests that contain sensitive information we'll need to revist this approach!
		if [ $_curl_exit_code != 0 ]; then
			pc_log "  curl returned an error exit code: ${_curl_exit_code}, logging request payload..."
			>&2 jq . <${_github_payload_filepath}
		fi
	fi

	return ${_curl_exit_code}
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
		_message=$(jq -r '.message // empty' <<< ${_response})
		if [[ ! -z "${_message}" ]]; then
			>&2 jq . <<< ${_response} 
			pc_log_fatal "ERROR: ${_msg}, error = ${_message}"
		fi	
	elif [[ ${_response:0:1} != "[" ]]; then
		pc_log_fatal "ERROR: ${_msg}, response = ${_response}"
	fi
}

# function: github_handle_error_ex
# desc:     Checks a response from a github API call, treat responses with the specified message as ok.
function github_handle_error_ex {
	local _ok=${1}
	local _msg=${2}
	local _response=${3:-}

	if [[ ${_response} == '' ]]; then
		pc_log_fatal "ERROR: ${_msg}, unknown error (no response)"
	fi
	if [[ ${_response:0:1} == "{" ]]; then
		_message=$(jq -r '.message // empty' <<< ${_response})
		if [[ ! -z "${_message}" ]]; then
			if [[ "${_message}" == "${_ok}" ]]; then
				return 1
			else
				>&2 jq . <<< ${_response} 
				pc_log_fatal "ERROR: ${_msg}, error = ${_message}"
			fi
		fi
	elif [[ ${_response:0:1} != "[" ]]; then
		pc_log_fatal "ERROR: ${_msg}, response = ${_response}"
	fi
}