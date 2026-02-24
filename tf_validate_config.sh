#!/bin/bash

# Pre-commit hook to enforce:
# 1. Terraform version matches what the repo defines in .tool-versions
# 2. S3 backend blocks use "use_lockfile = true" instead of "dynamodb_table = "terraform-state-lock""
# This hook auto-corrects issues it finds, then exits 1 so the user can review and re-commit.
# Works both locally (staged files) and in CI (--all-files mode).

set -e

retval=0

# --- Check 1: Terraform version ---
tool_versions_file=".tool-versions"
if [ -f "$tool_versions_file" ]; then
  required_version=$(grep '^terraform ' "$tool_versions_file" | awk '{print $2}')
  if [ -n "$required_version" ]; then
    installed_version=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
    if [ -z "$installed_version" ]; then
      installed_version=$(terraform version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    fi

    if [ -z "$installed_version" ]; then
      echo "ERROR: Could not determine installed terraform version. Is terraform installed?"
      retval=1
    elif [ "$installed_version" != "$required_version" ]; then
      echo "Terraform version mismatch (installed: $installed_version, required: $required_version)"
      echo "Installing terraform $required_version via asdf..."
      if asdf install terraform "$required_version" && asdf set terraform "$required_version"; then
        echo "Terraform $required_version installed and set successfully"
      else
        echo "ERROR: Failed to install terraform $required_version"
        echo "  Please install manually: asdf install terraform $required_version"
      fi
      retval=1
    fi
  fi
else
  echo "WARNING: No .tool-versions file found, skipping terraform version check"
fi

# --- Check 2: S3 backend should use use_lockfile instead of dynamodb_table ---
# Use staged files locally, fall back to finding all .tf files for CI (--all-files mode)
staged_files=$(git diff --cached --name-only --diff-filter=ACM -- '*.tf' 2>/dev/null || true)
if [ -z "$staged_files" ]; then
  staged_files=$(git ls-files -- '*.tf' 2>/dev/null || true)
fi

for file in $staged_files; do
  [ -f "$file" ] || continue
  if grep -q 'dynamodb_table\s*=\s*"terraform-state-lock"' "$file" 2>/dev/null; then
    echo "Replacing 'dynamodb_table = \"terraform-state-lock\"' with 'use_lockfile = true' in $file"
    # Use portable sed syntax (works on both macOS and Linux)
    if sed --version >/dev/null 2>&1; then
      # GNU sed (Linux)
      sed -i 's/dynamodb_table\s*=\s*"terraform-state-lock"/use_lockfile = true/' "$file"
    else
      # BSD sed (macOS)
      sed -i '' 's/dynamodb_table[[:space:]]*=[[:space:]]*"terraform-state-lock"/use_lockfile = true/' "$file"
    fi
    retval=1
  fi
done

if [ $retval = 1 ]; then
  echo ""
  echo "Files were updated. Please review the changes, stage them, and re-commit."
  exit 1
fi
