# CI Scripts

The ci-scripts library developed by Project Catalysts provides a set of core functions and settings used for creating CI scripts using bash.  This ci-scripts library delivers the capability for builds to be developed and tested on a developer's workstation without the requirement to deploy a local 'runner', or repeat continuous rounds of 'change -> check-in -> test -> change'.

## By Why?

We're striving to take the pain our of CI/CD.  Getting software built reliably, consistenty, and securely shouldn't be hard or take huge amounts of effort, but unfortunately it does, especially when you're building with containers.

There's a mountain of great information available on the internet, though we haven't found something that cohesively 'joins the dots' and demonstrates how to pull it all together.  Project Catalysts have built this library to meet our own needs, though believe there may be some benefit to others.  If this library helps you we'd love to know!

## Security
Project Catalysts strive to deliver secure development practices that align to the security found in typical production deployments.  We believe security considerations should be part of a developer's day-to-day design decisions, and it really irks us when we see poor security practices used on a daily basis (for example, docker's use of an insecure JSON file to store docker login passwords).

Configuring development and CI environments that operate in a secure manner isn't easy - there's a lot to learn.  This library has been developed to incorporate our learnings in a way that can be leveraged by others.

Project Catalysts give no warranty that these practices will mitigate all risks associated with compromise of a developer's workstation, though as we learn more and better tools become available, we will strive to incorporate them into this library.  If you have any recommendations please reach out.

## Why Bash?

We don't love Bash but it is a universal capability for all Linux environments.  Bash scripting enables these scripts to be used accross different CI tools, so we're not tied to functionality of a specific CI tool.  Bash scripting does come with it's own complexity, and there are nuances within the language, however we believe that the examples provided within will help developers with their understanding of this language.  In many instances we have incorporated comments to referenced articles that explain what the code means.

## How it works

Please refer to the [design](./docs/design.md) document.

## Environments Tested / Used

These scripts have been tested on Debian linux (versions 10/11) and integrated into GitLab CI pipelines using a 'Shell' runner on Debian Linux.  Integration with GitHub or other CI environments that support bash should also work, though may require minor tweaks.

## Issue Management / Contributions

If you discover any issues with this library, or identify changes that would benefit others, please reach out to us by raising an issue.

## Licence

These scripts are released under the [MIT licence](./licence.txt).  Inspiration for this library has come from countless articles and questions - thank you to all that publish their knowledge for the benefit of others.

## Dependencies

These CI scripts are dependant on the following software being installed:
- [git](https://git-scm.com/download/linux)
- [jq](https://jqlang.github.io/jq/download/)
- [docker](https://docs.docker.com/engine/install/debian/)
- [gpg](./docs/install_gpg.md) and pass are used to store docker credentials, required for pulling packages from / writing images to private registries.

## Getting Started

Confirm installation of these dependencies, then read the [docs](./docs/getting_started.md)!