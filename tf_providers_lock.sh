#!/bin/bash

# terraform .14 introduced a dependency lock files for providers
# since local development is typically on MacOS, there's a provider hash mismatch when compared to Atlantis (linux)
# this pre-commit hook generates the necessary hashes for both platforms
# https://www.hashicorp.com/blog/terraform-0-14-introduces-a-dependency-lock-file-for-providers

set -e

tf_lock_file=".terraform.lock.hcl"
retval=0

# --- Discover changed files ---
# CI mode: pre-commit sets PRE_COMMIT_FROM_REF and PRE_COMMIT_TO_REF with --source/--origin
# Local mode: use git diff --cached for staged files
if [ -n "$PRE_COMMIT_FROM_REF" ] && [ -n "$PRE_COMMIT_TO_REF" ]; then
  changed_files=$(git diff --name-only --diff-filter=ACMR "$PRE_COMMIT_FROM_REF...$PRE_COMMIT_TO_REF" 2>/dev/null || true)
else
  changed_files=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
fi

[ -z "$changed_files" ] && exit 0

changed_dirs=$(echo "$changed_files" | xargs -I{} dirname "{}" | sort -u)

for dir in $changed_dirs; do
  [ -f "$dir/terraform.tf" ] || continue

  if [ ! -f "$dir/$tf_lock_file" ]; then
    echo "Creating missing lock file in the directory $dir"
    (
      cd "$dir"
      terraform init -backend=false
      terraform providers lock -platform=darwin_arm64 -platform=linux_amd64
    )
  elif [ -z "$(git ls-files "$dir/$tf_lock_file")" ] && ! git diff --name-only --staged | grep -qx "$dir/$tf_lock_file"; then
    echo "Provider dependency lock file exists in the directory $dir but is not tracked in git or staged for commit. Run 'git add \"$dir/$tf_lock_file\"'"
    retval=1
  fi
done

exit $retval
