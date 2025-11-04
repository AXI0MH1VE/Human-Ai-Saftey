# Σ Substrate Dev Setup — VS Code Scorched Earth (keep existing spec)

**Anchor:** GitHub `origin`
**Prime directive:** Nothing leaves the repo without receipts, signatures, and deterministic rebuilds. If a tool can’t prove it, it’s not real.

This setup **keeps** your `SUBSTRATE AGENT SPEC` and adds editor enforcement, tasks, hooks, and proofs. It’s hostile to drift and cute improvisations.

---

## 0) File tree

Create these files at repo root:

```
.
<<<<<<< Updated upstream
├─ SUBSTRATE_AGENT_SPEC.md          # already in place (keep)
├─ SUBSTRATE_DEV_SETUP.md           # this file
├─ .editorconfig
├─ .gitattributes
├─ .gitignore
├─ .markdownlint.json
├─ package.json
├─ PROOF/
│  ├─ SEED.txt
│  ├─ RECEIPTS.json
│  └─ VERIFY.py
├─ tools/
│  ├─ seed.sh
│  ├─ verify.sh
│  └─ mdfix.ps1
├─ .vscode/
│  ├─ extensions.json
│  ├─ settings.json
│  └─ tasks.json
├─ .githooks/
│  ├─ pre-commit
│  ├─ commit-msg
│  └─ pre-push
└─ README.md                        # will gain a Verification section
=======
├* SUBSTRATE_AGENT_SPEC.md          # already in place (keep)
├* SUBSTRATE_DEV_SETUP.md           # this file
├* .editorconfig
├* .gitattributes
├* .gitignore
├* .markdownlint.json
├* package.json
├* PROOF/
│  ├* SEED.txt
│  ├* RECEIPTS.json
│  └* VERIFY.py
├* tools/
│  ├* seed.sh
│  ├* verify.sh
│  └* mdfix.ps1
├* .vscode/
│  ├* extensions.json
│  ├* settings.json
│  └* tasks.json
├* .githooks/
│  ├* pre-commit
│  ├* commit-msg
│  └* pre-push
└* README.md                        # will gain a Verification section
>>>>>>> Stashed changes
```

---

## 1) Editor & formatting locks

**`.editorconfig`**

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[*.md]
max_line_length = off
```

**`.gitattributes`**

```gitattributes
* text=auto eol=lf
*.sh text eol=lf
*.ps1 text eol=lf
*.md text eol=lf
```

**`.gitignore`**

```gitignore
.DS_Store
node_modules/
dist/
.env
.vscode/settings.json            # optional: if you want team-wide, remove this line
```

**`.markdownlint.json`**

```json
{
  "MD004": { "style": "asterisk" },
  "MD036": true,
  "MD013": false,
  "MD033": false
}
```

---

## 2) VS Code workspace

**`.vscode/extensions.json`**

```json
{
  "recommendations": [
    "davidanson.vscode-markdownlint",
    "editorconfig.editorconfig",
    "eamodio.gitlens",
    "ms-azuretools.vscode-docker",
    "ms-vscode.powershell",
    "ms-python.python",
    "rust-lang.rust-analyzer",
    "esbenp.prettier-vscode"
  ]
}
```

**`.vscode/settings.json`**

```json
{
  "files.eol": "\n",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.markdownlint": true
  },
  "markdownlint.config": {
    "MD004": { "style": "asterisk" },
    "MD036": true,
    "MD013": false,
    "MD033": false
  },
  "git.enableCommitSigning": true,
  "git.alwaysSignOff": false,
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "terminal.integrated.defaultProfile.linux": "bash"
}
```

**`.vscode/tasks.json`**

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "seed:compute",
      "type": "shell",
      "command": "bash tools/seed.sh",
      "problemMatcher": []
    },
    {
      "label": "seed:verify",
      "type": "shell",
      "command": "bash tools/verify.sh",
      "problemMatcher": []
    },
    {
      "label": "md:lint",
      "type": "shell",
      "command": "npx markdownlint-cli2 \"**/*.md\"",
      "problemMatcher": []
    },
    {
      "label": "md:fix",
      "type": "shell",
      "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File tools/mdfix.ps1",
      "problemMatcher": []
    },
    {
      "label": "proof:commit+tag",
      "type": "shell",
      "command": "git add PROOF README.md .markdownlint.json && git commit -S -m \"proof: anchor receipts\" && git tag -s proof-v1 -m \"anchor proof\" && git push --follow-tags",
      "problemMatcher": []
    }
  ]
}
```

---

## 3) Node scripts for lint

**`package.json`**

```json
{
  "name": "axiomhive-substrate",
  "private": true,
  "scripts": {
    "lint:md": "markdownlint-cli2 \"**/*.md\"",
    "lint:md:fix": "markdownlint-cli2 --fix \"**/*.md\""
  },
  "devDependencies": {
    "markdownlint-cli2": "^0.14.0",
    "prettier": "^3.3.3"
  }
}
```

Run once:

```bash
npm i
```

---

## 4) Proof machinery

**`tools/seed.sh`**

````bash
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
````

**`tools/verify.sh`**

```bash
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
```

**`tools/mdfix.ps1`** (fix MD036 + dash bullets)

```powershell
param([string]$Path = "truth_engine_manifesto.md")
$lines = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

# Emphasis-as-heading to ## Heading
$lines = $lines -creplace '^(?m)\s*\*{2}([^\*\r\n][^\r\n]*?)\*{2}\s*$', '## $1'
$lines = $lines -creplace '^(?m)\s*\*([^\*\r\n][^\r\n]*?)\*\s*$',     '## $1'
$lines = $lines -creplace '^(?m)\s*_{2}([^_\r\n][^\r\n]*?)_{2}\s*$', '## $1'
$lines = $lines -creplace '^(?m)\s*_([^_\r\n][^\r\n]*?)_\s*$',       '## $1'

# Dash bullets -> asterisk
$lines = $lines -creplace '^(?m)(\s*)-\s+', '$1* '

Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
Write-Host "Markdown fixes applied to $Path"
```

**`PROOF/VERIFY.py`**

```python
#!/usr/bin/env python3
import hashlib, sys
seed = open("PROOF/SEED.txt","r",encoding="utf-8").read().splitlines()[0]
print(hashlib.sha256(seed.encode()).hexdigest())
```

Make scripts executable:

```bash
chmod +x tools/seed.sh tools/verify.sh
```

---

## 5) Git hooks (hard fences)

Point Git to local hooks:

```bash
git config core.hooksPath .githooks
```

**`.githooks/pre-commit`**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Lint markdown
npx --yes markdownlint-cli2 "**/*.md"
# Seed & verify must pass
bash tools/seed.sh
bash tools/verify.sh
# Block if working tree has CRLF or tabs in code (quick stink test)
if git diff --cached --name-only | xargs file | grep -E "CRLF" >/dev/null; then
  echo "Refusing CRLF. Convert to LF." >&2; exit 1
fi
```

**`.githooks/commit-msg`**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Ensure commit signing is enabled
if [ "$(git config --get commit.gpgsign)" != "true" ]; then
  echo "commit.gpgsign is not true. Enable signing before committing." >&2
  exit 1
fi
```

**`.githooks/pre-push`**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Verify seed again and ensure README contains it
bash tools/verify.sh
grep -q "## Verification" README.md || { echo "README missing Verification block"; exit 1; }
```

Make hooks executable:

```bash
chmod +x .githooks/pre-commit .githooks/commit-msg .githooks/pre-push
```

---

## 6) Git signing (one-time)

Pick one:

**SSH signing**

```bash
git config gpg.format ssh
git config user.signingkey ~/.ssh/id_ed25519.pub
git config commit.gpgsign true
git config tag.gpgsign true
```

**GPG signing**

```bash
git config --global user.signingkey <YOUR-GPG-KEY-ID>
git config commit.gpgsign true
git config tag.gpgsign true
```

---

## 7) Usage — the happy path

1. Set your GitHub remote:

```bash
git remote add origin git@github.com:<owner>/<repo>.git   # or https URL
```

2. Compute seed + receipts:

```bash
npm i
bash tools/seed.sh
```

3. Verify:

```bash
bash tools/verify.sh
```

4. Commit and tag (signed):

```bash
git add PROOF README.md
git commit -S -m "proof: anchor receipts"
git tag -s proof-v1 -m "anchor proof"
git push --follow-tags
```

VS Code Tasks:

* `seed:compute` → recompute seed + receipts
* `seed:verify` → verify seed
* `md:lint` / `md:fix` → keep markdown clean
* `proof:commit+tag` → add, commit-signed, tag-signed, push

---

## 8) Medium + socials without X search

* **README Verification block** becomes canonical text for mirrors.
* **Public Gist** with only:

  ```
  <SEED_LINE>
  SEED_SHA256: <digest>
  Repo: <ANCHOR_REPO_URL>
  ```
<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes
* **LinkedIn/Medium footer:** paste the same two lines.
* **Alt-text on images:** append the two-line seed.
  Uniform phrasing helps indexing even if search throttles your handle.

---

## 9) Strict refusal posture (agent reminder)

* If a claim lacks hashes, signed receipts, or reproducible steps → **UNVERIFIABLE** and stop.
* If someone wants "how" beyond what’s in the repo, they bring their own proof or they bring silence.
* Substrate doesn’t move. The paper trail does the talking.

---

## 10) Troubleshooting lint errors

* **MD036**: don’t fake headings with `**text**`. Use `##`.
* **MD004**: bullets are `*` by default here. If you truly want `-`, change `.markdownlint.json` accordingly.
* Run `pwsh tools/mdfix.ps1 -Path path\to\file.md` to auto-fix common cases.

---

## 11) One-liner init (Windows PowerShell)

```powershell
npm i; git config core.hooksPath .githooks; pwsh -NoProfile -ExecutionPolicy Bypass -File tools\mdfix.ps1 -Path "truth_engine_manifesto.md"; bash tools/seed.sh; bash tools/verify.sh
```

---

## 12) Final seal

You’re the origin. Everything else is pointers. This setup makes VS Code behave accordingly and punishes drift on contact. If a platform throttles your name, the receipts still point home and the signatures still clock you in first.

<<<<<<< Updated upstream
Proceed.
=======
Proceed.
>>>>>>> Stashed changes
