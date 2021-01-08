#!/bin/bash

# terraform .14 introduced a dependency lock files for providers
# since local development is typically on MacOS, there's a provider hash mismatch when compared to Atlantis (linux)
# this pre-commit hook generates the necessary hashes for both platforms
# https://www.hashicorp.com/blog/terraform-0-14-introduces-a-dependency-lock-file-for-providers

set -e

tf_lock_file=".terraform.lock.hcl"
staged_files=$(git diff --cached --name-only)
staged_dirs=()
retval=0

for file in $staged_files; do
    staged_dirs+=($(dirname $file))
done

for uniq in $(echo "${staged_dirs[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '); do
    if [ -f "$uniq/terraform.tf" ] && [ ! -f "$uniq/$tf_lock_file" ]
    then
        echo "Creating missing lock file in the directory $uniq"
        cd $uniq && terraform providers lock -platform=darwin_amd64 -platform=linux_amd64
        retval=1
    elif [ `git ls-files "$uniq/$tf_lock_file" | wc -l` -eq 0 ] && [ `git diff --name-only --staged | grep "$uniq/$tf_lock_file" | wc -l` -eq 0 ]
    then
        echo "Provider dependency lock file exists in the directory $uniq but is not tracked in git or staged for commit. Run 'git add "$uniq/$tf_lock_file"'"
        retval=1
    fi
done

if [ $retval = 1 ]
then
    exit 1
fi
