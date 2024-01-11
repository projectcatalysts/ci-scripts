# Getting Started

## Configuring your development environment

1. Create a personalised environment file ~/.procat_ci_env.sh and set it's contents to the following, making any adjustments necessary to suit your environment.

```bash
# Project Catalysts CI environment settings
# This file holds the CI environment specific settings for this user

function ci_set_user_environment {
	# Specify the your organisation's domain (this one the CI services execute within)
	export PROCAT_CI_DOMAIN=example.com

	# Specify the server acts as your organisation's GIT source code repository
	export PROCAT_CI_GIT_SERVER=gitlab.${PROCAT_CI_DOMAIN}

	# Specify the server acts as your organisation's docker registry
	export PROCAT_CI_REGISTRY_SERVER=registry.${PROCAT_CI_DOMAIN}

	# Specify the server acts as your organisation's build server
	# (the server that hosts common build artefacts that are not stored within git)
	export PROCAT_CI_BUILD_SERVER=build.${PROCAT_CI_DOMAIN}

	# Specify the name of the private key file that will be added to the SSH agent
    # that is created to support the build process. This file should reside in ~/.ssh/
    export PROCAT_CI_SSH_PRIVATE_KEY_FILENAME="id_ed25519"

	# (Optional)
	# Specify the ID of the GPG user that has been used to protect docker and registry passwords
	# export PROCAT_CI_GPG_USER_ID=${USER}

	# (Optional)
	# Specify the URL of the repo that holds the Project Catalysts CI scripts
	# If not specified, this will default to git@${PROCAT_CI_GIT_SERVER}:procat/ci-scripts.git
	# export PROCAT_CI_SCRIPTS_REPO=git@${PROCAT_CI_GIT_SERVER}:procat/ci-scripts.git

	# (Optional)
	# Specify the path of the CI scripts folder where the Project Catalysts CI scripts are located.
	# This setting is required for local development of CI build scripts.
	export PROCAT_CI_SCRIPTS_PATH=~/src/ci-scripts

	# (Optional)
	# Specify the path of the downloads folder used to cache downloads sourced from the internet
	# If not specified, this will default to ~/downloads
	export PROCAT_CI_DOWNLOAD_PATH=~/downloads
}

#
# Call the function, but first check to ensure that the script is being sourced.
#
if (return 0 2>/dev/null) then
    ci_set_user_environment
else
    echo "ERROR : The script has not been sourced!"
    echo "Execute this script with the following syntax:"
    echo ""
    echo "   source ~/.procat_ci_env.sh"
    echo ""
fi
```
2. Append the following lines to either ~/.bashrc or ~/.profile
```
# Configure the Project Catalysts CI environment variables
source ~/.procat_ci_env.sh
```
3. Open a new command shell, and verify these settings have worked using the following command:
```
env | grep "PROCAT_CI"
```
## Creating your first project
It's probably best to copy one of the examples that Project Catalysts has published on Github.  