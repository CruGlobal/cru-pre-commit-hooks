#!/bin/bash

# terraform .14 introduced a dependency lock files for providers
# since local development is typically on MacOS, there's a provider hash mismatch when compared to Atlantis (linux)
# this pre-commit hook generates the necessary hashes for both platforms
# https://www.hashicorp.com/blog/terraform-0-14-introduces-a-dependency-lock-file-for-providers

set -e

TF_LOCK_FILE=".terraform.lock.hcl"
STAGED_FILES=$(git diff --cached --name-only)
STAGED_DIRS=()
UNIQ_STAGED_DIRS=()
RETVAL=0

for i in $STAGED_FILES; do
    STAGED_DIRS+=($(dirname $i))
done

UNIQ_STAGED_DIRS=($(echo "${STAGED_DIRS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

for i in "${UNIQ_STAGED_DIRS[@]}"; do
    if [ -f "$i/terraform.tf" ] && [ ! -f "$i/$TF_LOCK_FILE" ]
    then
        echo "Creating missing lock file in the directory $i"
        cd $i && terraform providers lock -platform=darwin_amd64 -platform=linux_amd64
        RETVAL=1
    elif [ `git ls-files "$i/$TF_LOCK_FILE" | wc -l` -eq 0 ] && [ `git diff --name-only --staged | grep "$i/$TF_LOCK_FILE" | wc -l` -eq 0 ]
    then
        echo "Provider dependency lock file exists in the directory $i but is not tracked in git or staged for commit. Run 'git add "$i/$TF_LOCK_FILE"'"
        RETVAL=1
    fi
done

if [ $RETVAL = 1 ]
then
    exit 1
fi
