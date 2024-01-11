# Project Catalysts CI Environment Variables

| Variable | Defined In | Description | Example  | Default  |
|----------|------------|-------------|----------|----------|
| EXEC_CI_SCRIPT_NAME | set_ci_env.sh | The CI script being executed | ./build.sh | n/a - calculated |
| EXEC_CI_SCRIPT_PATH | set_ci_env.sh | The path to the CI script being executed | . | n/a - calculated |
| PROCAT_CI_GPG_AGENT_PASS | GitLab Environment Variable (protected) | The password to GPG on the build server, used to gain access to other secrets such as docker login credentials | n/a | n/a - required |
| PROCAT_CI_SSH_TEMP_FILEPATH | core/ssh.sh | The temporary file used to hold the path to the the ssh agent created to support CI processes | n/a | n/a - calculated |
| PROCAT_CI_SSH_AGENT_PID | core/ssh.sh | The process ID of the ssh agent created to support CI processes | n/a | n/a - calculated |
| PROCAT_CI_SSH_AUTH_SOCK | set_ci_env.sh | The value to temporarily set to the SSH_AUTH_SOCK variable to when SSH is used within a CI process | n/a | n/a - calculated |
| PROCAT_CI_BUILD_SERVER | ~/.procat_ci_env.sh | The web server that acts as your organisation's build server (the server that hosts common build artefacts that are not stored within git). | build.registry.example.com | n/a - required   |
| PROCAT_CI_DOMAIN | ~/.procat_ci_env.sh | The domain name for the organisation (the domain that the CI services execute within).| example.com | n/a - required   |
| PROCAT_CI_DOWNLOAD_PATH | ~/.procat_ci_env.sh | The path used to cache dependencies / downloads sourced from the internet. | ~/downloads | ~/downloads || PROCAT_CI_GIT_SERVER | ~/.procat_ci_env.sh | The server that hosts the organisation's GIT source code repository. | gitlab.example.com | n/a - required   |
| PROCAT_CI_GPG_USER_ID | ~/.procat_ci_env.sh | The ID of the GPG user that was used to protect docker and registry passwords. | billy | ${USER} |
| PROCAT_CI_REGISTRY_SERVER | ~/.procat_ci_env.sh | The server that hosts the organisation's docker registry. | registry.example.com | n/a - required   |
| PROCAT_CI_SCRIPT_BUILD | .gitlab-common.yml | (.gitlab-ci.yml) The name of the script to execute in the build stage, e.g.<br>build:<br>&nbsp;&nbsp;script:<br>&nbsp;&nbsp;&nbsp;&nbsp;- PROCAT_CI_SCRIPT_BUILD='./mybuild.sh' | ./build.sh | ./build.sh |
| PROCAT_CI_SCRIPT_PUBLISH | .gitlab-common.yml | (.gitlab-ci.yml) The name of the script to execute in the build stage, e.g.<br>publish:<br>&nbsp;&nbsp;script:<br>&nbsp;&nbsp;&nbsp;&nbsp;- PROCAT_CI_SCRIPT_PUBLISH='./mypublish.sh' | ./publish.sh | ./publish.sh |
| PROCAT_CI_SCRIPT_TEST | .gitlab-common.yml |(.gitlab-ci.yml) The name of the script to execute in the test stage, e.g.<br>test:<br>&nbsp;&nbsp;script:<br>&nbsp;&nbsp;&nbsp;&nbsp;- PROCAT_CI_SCRIPT_TEST='./mytest.sh' | ./test.sh | ./test.sh |
| PROCAT_CI_SCRIPTS_REPO | ~/.procat_ci_env.sh | The URL of the repo that holds the Project Catalysts CI scripts. | git@gitlab.example.com:procat/ci-scripts.git | git@${PROCAT_CI_GIT_SERVER}:procat/ci-scripts.git |
| PROCAT_CI_SCRIPTS_PATH | ~/.procat_ci_env.sh | Used for debugging,   the path where Project Catalysts CI scripts are located from. | ~/src/ci-scripts | ~/src/ci-scripts |
| PROCAT_CI_SSH_PRIVATE_KEY_FILENAME | ~/.procat_ci_env.sh | The name of the private key file that will be added to the SSH agent, used for pulling dependent packages from the GIT server. | id_ed25519 | n/a - required |
