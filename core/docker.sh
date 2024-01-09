#!/bin/bash

# function: procat_ci_docker_init
# desc:     procat_ci_docker_init is used to initialise the CI environment for using docker
# usage:    procat_ci_docker_init
function procat_ci_docker_init {
	#
	# GPG on the build agent is expected to be configured in the following way:
	#
	# ~/.gnupg/gpg-agent.conf
	#
	#       // Set to the maximum expected duration of a build job, specified in seconds
	#       // This determines how long the agent caches the password.  When this expires
	#       // pass would prompt for password entry when running as a terminal
	# 		default-cache-ttl 600
	#
	#       // Allow loopback pinentry to be used.  We use loopback in preference to
	#       // gpg-preset-passphrase because the ttl is respected whereas with the use of 
	#       // gpg-preset-passphrase the password remains unlocked until the agent is restarted
	#       allow-preset-passphrase
    #       allow-loopback-pinentry
	#
	# We force pinentry by requesting a signature that is subsequently ignored.  This command unlocks the gpg
	# agent for the duration of the ttl.  This is necessary becasuse docker has been configured to use the
	# 'pass' credentials store.
	#
	# ~/.docker/config.json
	#
	# {
    #    "auths": {
    #            "gitlab.example.com": {},
    #            "registry.example.com": {}
    #    },
    #    "credsStore": "pass"
	# }
	#
	local readonly this_script="$0"
	if [ -n "${CI_JOB_ID-}" ]; then
		pc_log "procat_ci_docker_init() : Triggering pinentry for docker login from the PROCAT_CI_GPG_AGENT_PASS environment variable..."
		if [ -z "${PROCAT_CI_GPG_AGENT_PASS-}" ]; then
			pc_log_fatal "procat_ci_docker_init() : the PROCAT_CI_GPG_AGENT_PASS environment variable has not been set"		
		fi
		echo ${PROCAT_CI_GPG_AGENT_PASS} | gpg --pinentry-mode loopback --passphrase-fd 0 --yes --clearsign -o /dev/null ${this_script}
	else
		# Force pinentry if needed only when not running as a gitlab build job
		pc_log "procat_ci_docker_init() : Triggering pinentry for docker login from the local console..."
		export GPG_TTY=$(tty)
		pass show docker-credential-helpers/docker-pass-initialized-check > /dev/null
	fi
	log "procat_ci_docker_init() : Listing gpg info and status...."
	gpg-connect-agent 'keyinfo --list' /bye	
	#
	# If we ever wanted to force the gpg agent to forget the password we could use this command:
	# 
	#     gpgconf --reload gpg-agent
	#
    # A useful diagnostics command to check the whether the gpg agent is unlocked:
	#
	#     gpg-connect-agent 'keyinfo --list' /bye
	#
	# Returns:
	#
	#     S KEYINFO 47CF9E2C933761CF1021731F72603B8291BB211C D - - 1 P - - -
	#     S KEYINFO 4133708B3FA225C4732A0F9FBD0053DEF937B46A D - - - P - - -
    #     OK
	#
	# Where the '1' signifies that the key is unlocked
	#
	# Commands to configure gitlab-runner (executed on the build server).   These are random notes (not in order)
	# 
	#     su
	#     su - gitlab-runner
	#     tmux
	#     export GPG_TTY=$(tty)
	#     gpg --full-generate-key 
	#     4096
	#     <specify passsword>
	# 
	#     pass init <publickey> 	// The really long one
	#     pass insert docker-credential-helpers/docker-pass-initialized-check
    #     pass show docker-credential-helpers/docker-pass-initialized-check
    #     pass is initialized
    #     docker logout
    #     apt install golang-docker-credential-helpers
	#     wget https://github.com/docker/docker-credential-helpers/releases/download/v0.6.4/docker-credential-pass-v0.6.4-amd64.tar.gz
    #     tar -xf docker-credential-pass-v0.6.4-amd64.tar.gz
    #     sudo mv docker-credential-pass /usr/local/bin
    #     chmod +x /usr/local/bin/ docker-credential-pass
	#
	# Make sure you set the docker passwords in the password store!
	#
	#     docker login -u <username> gitlab.example.com
	#     docker login -u <username> registry.example.com
}

# function: procat_ci_docker_stop
# desc:     stops a named container if it is running
# usage:    procat_ci_docker_stop $containerName
function procat_ci_docker_stop {
	local readonly _container_name=${1}

	local container_id="$(docker ps --quiet --filter name=^/${_container_name}$)"
	if [ -n "${container_id}" ]; then
		pc_log "Stopping container : ${1}"
		docker stop ${1}
	fi
}

# function: procat_ci_docker_remove
# desc:     removes a named container if it exists
# usage:    procat_ci_docker_remove $containerName
function procat_ci_docker_remove {
	local readonly _container_name=${1}

	local container_id="$(docker ps --all --quiet --filter name=^/${_container_name}$)"
	if [ -n "${container_id}" ]; then
		pc_log "Removing container : ${_container_name}"
		docker rm ${_container_name}
	fi
}

# function: procat_ci_docker_build_image
# desc:     builds a docker image
# usage:    procat_ci_docker_build_image $no_cache_flag, $package_name, $package_push $package_version, $package_is_latest, $build_args
# notes:    If $package_is_latest is set to "latest" the image will be tagged as the latest version of this package within the docker registry
#           If build arguments are not needed use - as a placeholder
function procat_ci_docker_build_image {
	local no_cache_flag=${1}
	local package_name=${2}
	local package_push=${3}
	local package_version=${4:-}
	local package_is_latest=${5:-}
	local build_args=${6:-}

	pc_log "-----------------------------------------------------------------"

	if [ -z "${build_args}" ]; then
		build_args=""
	fi

	if [ "${build_args}" == "-" ]; then
		build_args=""
	fi

	if [ -z "${package_version}" ]; then
	
		#
		# No package version specified
		#
		pc_log "Building image : ${package_name}"
		pc_log "Build args     : ${build_args}"
		pc_exec "docker build --pull --no-cache=${no_cache_flag} -t ${package_name}:latest ${build_args} ."
		package_version="latest" 
	else
        build_args="--build-arg package_version=${package_version} ${build_args}"

		pc_log "Building image : ${package_name}, version ${package_version}"
		pc_log "Build args     : ${build_args}"
		pc_exec "docker build --pull --no-cache=${no_cache_flag} -t ${package_name}:${package_version} ${build_args} ."
		
		if [ ! -z "${package_is_latest}" ]; then
			if [ ${package_is_latest} == "latest" ]; then
				#
				# This version has been nominated as the latest version of this package
				#
				pc_log "Tagging image: ${package_name}:${package_version} as latest"
				pc_exec "docker tag ${package_name}:${package_version} ${package_name}:latest"
			fi
		fi
	fi

	if [ ! -z "${package_push}" ]; then
		if [ ${package_push} == "push" ]; then
			#
			# This version has been nominated as the latest version of this package
			#
			pc_log "Pushing image: ${package_name}:${package_version}"
			pc_exec "docker push --all-tags ${package_name}"
		fi
	fi	
}