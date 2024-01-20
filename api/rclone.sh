#!/bin/bash -eu

# ---------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------

#
# rclone_create_connection_string_r2
#
function rclone_create_connection_string_r2 {
	local _access_key_id=${1}
	local _secret_access_key=${2}

	if [[ -z "${PROCAT_R2_ENDPOINT}" ]]; then
        pc_log_fatal "Project Catalysts R2 environment setting has not been specified : PROCAT_R2_ENDPOINT"
	fi

	printf ":s3,provider=Cloudflare,endpoint=\"${PROCAT_R2_ENDPOINT}\",access_key_id=${_access_key_id},secret_access_key=${_secret_access_key},acl=private,no_check_bucket=true"
}