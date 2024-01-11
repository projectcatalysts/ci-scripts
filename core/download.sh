#!/bin/bash

# function: procat_ci_download
# desc:     downloads a file
# usage:    procat_ci_download $no_cache_flag, $src_path, $dst_path $dst_filename, $package_is_latest, $build_args
# notes:    
function procat_ci_download {
	local readonly no_cache_flag=${1}
  	local readonly src_path=${2}
    local readonly dst_path=${3}
    local readonly dst_filename=${4}
    
    # If the destination file is missing, 
    # or the no_cache_flag flag is true,
    # then download the file to the cache.
	local readonly dst_filepath=${dst_path}/${dst_filename}
    local status_code=200
    if [ ! -f ${dst_filepath} ]; then
        pc_log "Downloading                      : ${dst_filename} to ${dst_filepath}"
        status_code=$(curl --silent --write-out "%{http_code}" -o ${dst_filepath} -jksSL ${src_path})
    else
        if [ ${no_cache_flag} == "true" ]; then
            pc_log "Downloading (cache ignored)      : ${dst_filename} to ${dst_filepath}"
            status_code=$(curl --silent --write-out "%{http_code}" -o ${dst_filepath} -z ${dst_filepath} -jksSL ${src_path})
        else
            pc_log "Using cached download            : ${dst_filename}"
        fi
    fi

    if test ${status_code} -ne 200; then
        # If the download failed for any reason (e.g. 404 'Not Found' error) then we want to remove the HTTP response stored in the output file
        if [ -f ${dst_filepath} ]; then
            rm -f ${dst_filepath} > /dev/null
        fi
        pc_log_fatal "Download from ${src_path} failed with HTTP status code ${status_code}"
    fi
}
