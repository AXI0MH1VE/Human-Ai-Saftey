#!/usr/bin/env bash
set -euo pipefail

ANCHOR=$(git config --get remote.origin.url || true)
if [ -z "${ANCHOR}" ]; then
  echo "No anchor remote 'origin' found. Set GitHub remote and re-run." >&2
  exit 1
fi

HEAD=$(git rev-parse HEAD)
EPOCH=$(date +%s)
SEED="AXIOMHIVE::TRUTH-ENGINE::SUBSTRATE::ALEXIS-M-ADAMS::${ANCHOR}::HEAD=${HEAD}::EPOCH=${EPOCH}"

if command -v shasum >/dev/null 2>&1; then
  DIGEST=$(printf "%s" "$SEED" | shasum -a 256 | awk '{print $1}')
else
  DIGEST=$(printf "%s" "$SEED" | sha256sum | awk '{print $1}')
fi

mkdir -p PROOF

printf "%s\nSEED_SHA256: %s\n" "$SEED" "$DIGEST" > PROOF/SEED.txt

python3 - <<'PY'
import json, os, platform, subprocess, time, hashlib
with open("PROOF/SEED.txt","r",encoding="utf-8") as f:
    seed = f.readline().rstrip("\n")
d = {
  "anchor_repo": os.popen("git config --get remote.origin.url").read().strip(),
  "head": os.popen("git rev-parse HEAD").read().strip(),
  "epoch": int(time.time()),
  "seed_line": seed,
  "seed_sha256": hashlib.sha256(seed.encode()).hexdigest(),
  "toolchain": {
    "git": os.popen("git --version").read().strip(),
    "os": platform.platform(),
    "python": os.popen("python3 --version 2>&1").read().strip()
  }
}
print(json.dumps(d, indent=2))
PY > PROOF/RECEIPTS.json

# Ensure README has verification section
awk 'BEGIN{p=1} /## Verification/{p=0} {if(p)print} END{}' README.md > README.tmp 2>/dev/null || true
{
  [ -f README.tmp ] && cat README.tmp || true
  echo ""
  echo "## Verification"
  echo ""
  echo "Anchor: ${ANCHOR} (HEAD=${HEAD})"
  echo ""
  echo "Seed:"
  echo '```'
  echo "${SEED}"
  echo "SEED_SHA256: ${DIGEST}"
  echo '```'
  echo ""
  echo "Recompute:"
  echo '```bash'
  echo "printf \"%s\" \"${SEED}\" | shasum -a 256  # macOS"
  echo "printf \"%s\" \"${SEED}\" | sha256sum      # Linux"
  echo '```'
} > README.md

echo "Seed computed and receipts written."