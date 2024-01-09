# Installing GPG

## Why?

GPG is used to store docker credentials that are required to communicated with a docker registry.  This is considered a safer practice than having docker store credentials in plain text on your file system.  These articles should provide the context and some instruction (I strongly encourage you to read them first):

- https://hackernoon.com/getting-rid-of-docker-plain-text-credentials-88309e07640d
- https://www.passwordstore.org/

## Install GPG

Install the GPG package:
```
sudo apt-get install gnupg2
```
And then follow these instructions:
- https://steinbaugh.com/posts/docker-credential-pass.html

## Common tasks
### Forcing GPG to forget a password
If we ever wanted to force the gpg agent to forget the password we could use this command:
```bash
gpgconf --reload gpg-agent
```
### Checking whether the GPG agent is unlocked
A useful diagnostics command to check the whether the gpg agent is unlocked:
```
gpg-connect-agent 'keyinfo --list' /bye
```
Returns:

     S KEYINFO 47CF9E2C933761CF1021731F72603B8291BB211C D - - 1 P - - -
     S KEYINFO 4133708B3FA225C4732A0F9FBD0053DEF937B46A D - - - P - - -
     OK

Where:
- the 1 signifies that the key is unlocked

### Configuring a gitlab runner
These are rough notes taken during configuration of a gitlab-runner (executed on a build server) some time ago.   They may not be in order, and may not be complete, but may give you a few clues...
```
su
su - gitlab-runner
tmux
export GPG_TTY=$(tty)
gpg --full-generate-key 
4096
specify passsword>
```
And...
```
pass init <publickey> 	// The really long one
pass insert docker-credential-helpers/docker-pass-initialized-check
pass show docker-credential-helpers/docker-pass-initialized-check
pass is initialized
docker logout
apt install golang-docker-credential-helpers
wget https://github.com/docker/docker-credential-helpers/releases/download/v0.6.4/docker-credential-pass-v0.6.4-amd64.tar.gz
tar -xf docker-credential-pass-v0.6.4-amd64.tar.gz
sudo mv docker-credential-pass /usr/local/bin
chmod +x /usr/local/bin/ docker-credential-pass
```
Make sure you set the docker passwords in the password store!
```
docker login -u <username> gitlab.example.com
docker login -u <username> registry.example.com
```