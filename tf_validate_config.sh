#!/bin/bash

# Pre-commit hook to enforce:
# 1. Terraform version matches what the repo defines in .tool-versions
# 2. S3 backend blocks use "use_lockfile = true" instead of "dynamodb_table = "terraform-state-lock""
# 3. required_version constraint is updated to "~> <version>" from .tool-versions
# This hook auto-corrects issues it finds, then exits 1 so the user can review and re-commit.
# Pre-commit passes .tf filenames as arguments.

set -e

retval=0
modified_files=()

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

# --- Check .tf files passed by pre-commit ---
for file in "$@"; do
  [ -f "$file" ] || continue
  file_modified=false

  # --- Check 2: S3 backend should use use_lockfile instead of dynamodb_table ---
  if grep -q 'dynamodb_table[[:space:]]*=[[:space:]]*"terraform-state-lock"' "$file" 2>/dev/null; then
    echo "Replacing 'dynamodb_table = \"terraform-state-lock\"' with 'use_lockfile = true' in $file"
    if sed --version >/dev/null 2>&1; then
      sed -i 's/dynamodb_table[[:space:]]*=[[:space:]]*"terraform-state-lock"/use_lockfile = true/' "$file"
    else
      sed -i '' 's/dynamodb_table[[:space:]]*=[[:space:]]*"terraform-state-lock"/use_lockfile = true/' "$file"
    fi
    file_modified=true
  fi

  # --- Check 3: required_version in terraform {} block should be "~> <version>" from .tool-versions ---
  if [ -n "$required_version" ]; then
    # Use awk to only match required_version inside the top-level terraform {} block (depth 1)
    in_terraform_block=$(awk '
      /^terraform[[:space:]]*\{/ { in_tf=1; depth=1; next }
      in_tf && /\{/ { depth++ }
      in_tf && /\}/ { depth--; if (depth==0) in_tf=0 }
      in_tf && depth==1 && /required_version[[:space:]]*=/ { print; exit }
    ' "$file")

    if [ -n "$in_terraform_block" ]; then
      expected='required_version = "~> '"$required_version"'"'
      # Trim whitespace for comparison
      current_trimmed=$(echo "$in_terraform_block" | sed 's/^[[:space:]]*//')
      if [ "$current_trimmed" != "$expected" ]; then
        echo "Updating required_version in $file to \"~> $required_version\""
        # Replace only within the terraform {} block using awk
        awk -v new_ver="$required_version" '
          /^terraform[[:space:]]*\{/ { in_tf=1; depth=1; print; next }
          in_tf && /\{/ { depth++ }
          in_tf && /\}/ { depth--; if (depth==0) in_tf=0 }
          in_tf && depth==1 && /required_version[[:space:]]*=/ {
            sub(/required_version[[:space:]]*=[[:space:]]*"[^"]*"/, "required_version = \"~> " new_ver "\"")
          }
          { print }
        ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        file_modified=true
      fi
    fi
  fi

  if [ "$file_modified" = true ]; then
    modified_files+=("$file")
    retval=1
  fi
done

# Run terraform fmt on modified files to fix indentation/alignment
for file in "${modified_files[@]}"; do
  echo "Formatting $file"
  terraform fmt "$file" 2>/dev/null || true
done

if [ $retval = 1 ]; then
  echo ""
  echo "Files were updated. Please review the changes, stage them, and re-commit."
  exit 1
fi
