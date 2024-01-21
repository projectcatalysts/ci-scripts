#!/bin/bash -eu

# git_delete_repo_folder is used to delete a folder that has been cloned from a repo
function git_delete_repo_folder {
    local readonly repo=${1}
    cd "${repo}"
    # remove hidden git folder
    rm -rf .git
    # remove regular files
    rm -rf *
    # remove .files
    # https://unix.stackexchange.com/questions/77127/rm-rf-all-files-and-all-hidden-files-without-error
    find . -name . -o -prune -exec rm -rf -- {} +
    cd ..
    rmdir "${repo}"
}