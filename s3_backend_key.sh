#!/bin/bash

# Enforce all terraform s3 backend key paths match folder structure.
# Expected key format: <dirname>/terraform.tfstate
# Pre-commit passes .tf filenames as arguments.

set -e

updated_files=()

for file in "$@"; do
  [ -f "$file" ] || continue

  # Extract the key value from the backend "s3" block only
  actual_key=$(awk '
    /backend[[:space:]]+"s3"[[:space:]]*\{/ { in_backend=1; next }
    in_backend && /\}/ { in_backend=0; next }
    in_backend && /key[[:space:]]*=[[:space:]]*"/ {
      val=$0
      sub(/.*key[[:space:]]*=[[:space:]]*"/, "", val)
      sub(/".*/, "", val)
      print val
      next
    }
  ' "$file")

  [ -z "$actual_key" ] && continue

  expected_key="$(dirname "$file")/terraform.tfstate"

  if [ "$actual_key" != "$expected_key" ]; then
    # Replace the key value only within the backend "s3" block
    awk -v expected="$expected_key" '
      /backend[[:space:]]+"s3"[[:space:]]*\{/ { in_backend=1 }
      in_backend && /\}/ { in_backend=0 }
      in_backend && /key[[:space:]]*=[[:space:]]*"/ {
        sub(/key[[:space:]]*=[[:space:]]*"[^"]*"/, "key            = \"" expected "\"")
      }
      { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    updated_files+=("$file")
  fi
done

if [ ${#updated_files[@]} -eq 0 ]; then
  exit 0
fi

echo "The following files had incorrect S3 backend keys and were updated:"
for file in "${updated_files[@]}"; do
  echo "  - $file"
done
echo "If the state was initialized for any of these modules, you will need to re-run \`terraform init\` to move the state to the correct key."
exit 1
