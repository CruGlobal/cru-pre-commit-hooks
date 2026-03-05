#!/bin/bash

# Enforce that provider version constraints use pessimistic operator (~>).
# Checks required_providers blocks for version strings that use exact (=),
# minimum (>=), or bare version pinning instead of ~>.
# Pre-commit passes .tf filenames as arguments.

set -e

violations=()

for file in "$@"; do
  [ -f "$file" ] || continue

  # Extract version constraints from required_providers blocks
  # Look for lines like: version = "= 5.0.0" or version = ">= 3.0"
  # but not version = "~> 5.0" (which is correct)
  bad_constraints=$(awk '
    /required_providers[[:space:]]*\{/ { in_rp=1; depth=1; next }
    in_rp && /\{/ { depth++ }
    in_rp && /\}/ { depth--; if (depth==0) in_rp=0; next }
    in_rp && /version[[:space:]]*=[[:space:]]*"/ {
      line=$0
      # Extract the version string
      val=line
      sub(/.*version[[:space:]]*=[[:space:]]*"/, "", val)
      sub(/".*/, "", val)
      # Flag if it does not start with ~>
      if (val !~ /^~>/) {
        # Print file:line_number:constraint for reporting
        printf "%s:%d: version = \"%s\"\n", FILENAME, NR, val
      }
    }
  ' "$file")

  if [ -n "$bad_constraints" ]; then
    while IFS= read -r line; do
      violations+=("$line")
    done <<< "$bad_constraints"
  fi
done

if [ ${#violations[@]} -eq 0 ]; then
  exit 0
fi

echo "Provider version constraints must use the pessimistic operator (~>)."
echo ""
echo "The following violations were found:"
for v in "${violations[@]}"; do
  echo "  $v"
done
echo ""
echo "Example fix: version = \">= 5.0\" -> version = \"~> 5.0\""
exit 1
