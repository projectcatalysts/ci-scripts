# CI Scripts

The ci-scripts library developed by Project Catalysts provides a set of core functions and settings used for creating CI scripts using bash.

## By Why?

Bash is a universal capability for all Linux environments.  The ci-scripts library delivers the capability for builds to be developed and tested on a developer's workstation without the requirement to deploy a local 'runner', or repeat continuous rounds of 'change -> check-in -> test -> change'.

## Environments Tested / Used

These scripts have been tested on Debian linux and integrated into GitLab CI pipelines.  Integration with GitHub or other CI environments that support bash should also work, though possibly with minor tweaks.

## Issue Management / Contributions

If you discover any issues with this library, or identify changes that would benefit others, please reach out to us by raising an issue.

## Licence

These scripts are released under the MIT licence.  Inspiration for this library has come from countless articles and questions - thank you to all that publish thier knowledge for the benefit of others.

## Dependencies

These CI scripts are dependant on the following software being installed:
- [git](https://git-scm.com/download/linux)
- [jq](https://jqlang.github.io/jq/download/)
- [docker](https://docs.docker.com/engine/install/debian/)
- [gpg](./docs/install_gpg.md) and pass are used to store docker credentials, required for new writing images back to to a registry.

## Getting Started

Confirm installation of these dependencies, then read the [docs](./docs/getting_started.md)!