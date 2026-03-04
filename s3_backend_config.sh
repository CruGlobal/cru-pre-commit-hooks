#!/bin/bash

# Enforce that all S3 backend blocks use the correct bucket and region:
#   - bucket  = "cru-tf-remote-state"
#   - region  = "us-east-1"
# Auto-corrects incorrect values. Pre-commit passes .tf filenames as arguments.

set -e

EXPECTED_BUCKET="cru-tf-remote-state"
EXPECTED_REGION="us-east-1"

updated_files=()

for file in "$@"; do
  [ -f "$file" ] || continue

  # Check if file has a backend "s3" block
  has_backend=$(awk '/backend[[:space:]]+"s3"[[:space:]]*\{/ { print "yes"; exit }' "$file")
  [ "$has_backend" = "yes" ] || continue

  file_modified=false

  # Extract current bucket value from backend "s3" block
  actual_bucket=$(awk '
    /backend[[:space:]]+"s3"[[:space:]]*\{/ { in_backend=1; next }
    in_backend && /\}/ { in_backend=0; next }
    in_backend && /bucket[[:space:]]*=[[:space:]]*"/ {
      val=$0
      sub(/.*bucket[[:space:]]*=[[:space:]]*"/, "", val)
      sub(/".*/, "", val)
      print val
      exit
    }
  ' "$file")

  if [ -n "$actual_bucket" ] && [ "$actual_bucket" != "$EXPECTED_BUCKET" ]; then
    awk -v expected="$EXPECTED_BUCKET" '
      /backend[[:space:]]+"s3"[[:space:]]*\{/ { in_backend=1 }
      in_backend && /\}/ { in_backend=0 }
      in_backend && /bucket[[:space:]]*=[[:space:]]*"/ {
        sub(/bucket[[:space:]]*=[[:space:]]*"[^"]*"/, "bucket         = \"" expected "\"")
      }
      { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    file_modified=true
  fi

  # Extract current region value from backend "s3" block
  actual_region=$(awk '
    /backend[[:space:]]+"s3"[[:space:]]*\{/ { in_backend=1; next }
    in_backend && /\}/ { in_backend=0; next }
    in_backend && /region[[:space:]]*=[[:space:]]*"/ {
      val=$0
      sub(/.*region[[:space:]]*=[[:space:]]*"/, "", val)
      sub(/".*/, "", val)
      print val
      exit
    }
  ' "$file")

  if [ -n "$actual_region" ] && [ "$actual_region" != "$EXPECTED_REGION" ]; then
    awk -v expected="$EXPECTED_REGION" '
      /backend[[:space:]]+"s3"[[:space:]]*\{/ { in_backend=1 }
      in_backend && /\}/ { in_backend=0 }
      in_backend && /region[[:space:]]*=[[:space:]]*"/ {
        sub(/region[[:space:]]*=[[:space:]]*"[^"]*"/, "region         = \"" expected "\"")
      }
      { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    file_modified=true
  fi

  if [ "$file_modified" = true ]; then
    updated_files+=("$file")
  fi
done

if [ ${#updated_files[@]} -eq 0 ]; then
  exit 0
fi

echo "The following files had incorrect S3 backend configuration and were updated:"
for file in "${updated_files[@]}"; do
  echo "  - $file"
done
echo ""
echo "Expected: bucket = \"$EXPECTED_BUCKET\", region = \"$EXPECTED_REGION\""
echo "Please review the changes, stage them, and re-commit."
exit 1
