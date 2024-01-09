echo "This is an example of a Project Catalysts CI environment settings file typically named ~/.procat_ci_env.sh"
echo "This file should be sourced into your environment either within ~/.bashrc or ~/.profile"
echo " "
echo "For example, add the following lines:"
echo "# Configure the Project Catalysts CI environment variables"
echo "source ~/.procat_ci_env.sh"
echo " "
echo "Then remove these 'echo' instructions from this file (~/.procat_ci_env.sh)"

# Project Catalysts CI environment settings
# This file holds the CI environment specific settings for this user

# Specify the server acts as your organisation's GIT source code repository
export PROCAT_CI_GIT_SERVER=gitlab.example.com

# Specify the server acts as your organisation's docker registry
export PROCAT_CI_REGISTRY_SERVER=registry.example.com

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