#!/usr/bin/env bash
set -euo pipefail
SEED=$(head -n1 PROOF/SEED.txt)
if command -v shasum >/dev/null 2>&1; then
  DIG=$(printf "%s" "$SEED" | shasum -a 256 | awk '{print $1}')
else
  DIG=$(printf "%s" "$SEED" | sha256sum | awk '{print $1}')
fi
echo "Computed: $DIG"
grep -q "$DIG" PROOF/SEED.txt && echo "OK" || { echo "MISMATCH"; exit 1; }