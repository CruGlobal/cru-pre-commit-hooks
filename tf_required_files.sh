#!/bin/bash

# Enforce that every directory containing .tf files also has:
#   - terraform.tf (main terraform configuration)
#   - README.md (documentation)
# Pre-commit passes .tf filenames as arguments.

set -e

# Directories excluded from the README.md requirement (matched as prefix)
EXCLUDED_README_DIRS=(
  "aws/route53"
)

missing=()

# Collect unique directories from the changed .tf files
dirs=$(for file in "$@"; do dirname "$file"; done | sort -u)

for dir in $dirs; do
  [ -d "$dir" ] || continue

  if [ ! -f "$dir/terraform.tf" ]; then
    missing+=("$dir/terraform.tf")
  fi

  # Check README.md unless directory is excluded
  skip_readme=false
  for excluded in "${EXCLUDED_README_DIRS[@]}"; do
    if [[ "$dir" == "$excluded" || "$dir" == "$excluded"/* ]]; then
      skip_readme=true
      break
    fi
  done

  if [ "$skip_readme" = false ] && [ ! -f "$dir/README.md" ]; then
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
