#!/usr/bin/env bash
# Bootstrap a fresh macOS machine.
# Usage (on a new Mac):
#   curl -fsSL https://raw.githubusercontent.com/<you>/dotfiles/main/install.sh | bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# 1. Homebrew (also installs Xcode Command Line Tools)
if ! command -v brew >/dev/null 2>&1; then
  echo "→ Installing Homebrew…"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 2. CLIs and apps from Brewfile
echo "→ Installing Brewfile bundle…"
brew bundle --file=Brewfile

# 3. GitHub auth (browser device flow — no tokens in this repo)
if ! gh auth status >/dev/null 2>&1; then
  echo "→ Signing in to GitHub…"
  gh auth login --web -h github.com
fi

# 4. gh extensions (Copilot CLI)
if ! gh extension list 2>/dev/null | grep -q gh-copilot; then
  echo "→ Installing gh-copilot extension…"
  gh extension install github/gh-copilot
fi

# 5. VS Code extensions
if command -v code >/dev/null 2>&1; then
  echo "→ Installing VS Code extensions…"
  xargs -n1 code --install-extension --force < vscode-extensions.txt
else
  echo "⚠ VS Code 'code' CLI not on PATH. Open VS Code once, run 'Shell Command: Install code command in PATH', then re-run this script."
fi

# 6. Private npm registry auth + global packages
./scripts/setup-npmrc.sh
if command -v npm >/dev/null 2>&1; then
  echo "→ Installing global npm packages…"
  xargs -n1 npm install -g < npm-globals.txt
else
  echo "⚠ npm not found. Install Node first (e.g. 'brew install node' or via mise) and re-run."
fi

cat <<'EOF'

✓ Bootstrap complete.

Next, finish the manual steps in POST-INSTALL.md (Setapp + TablePlus,
1Password sign-in, Raycast import, VS Code Settings Sync, …).
EOF
