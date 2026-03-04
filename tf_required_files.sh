#!/bin/bash

# Enforce that every directory containing .tf files also has:
#   - terraform.tf (main terraform configuration)
#   - README.md (documentation)
# Pre-commit passes .tf filenames as arguments.

set -e

missing=()

# Collect unique directories from the changed .tf files
dirs=$(for file in "$@"; do dirname "$file"; done | sort -u)

for dir in $dirs; do
  [ -d "$dir" ] || continue

  if [ ! -f "$dir/terraform.tf" ]; then
    missing+=("$dir/terraform.tf")
  fi

  if [ ! -f "$dir/README.md" ]; then
    missing+=("$dir/README.md")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  exit 0
fi

echo "The following required files are missing:"
for file in "${missing[@]}"; do
  echo "  - $file"
done
echo ""
echo "Every directory containing .tf files must have both terraform.tf and README.md."
exit 1
