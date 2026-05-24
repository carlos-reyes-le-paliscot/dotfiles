#!/usr/bin/env bash
# Bootstrap a fresh macOS machine.
# Usage (on a new Mac):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/carlos-reyes-le-paliscot/dotfiles/main/install.sh)"

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/carlos-reyes-le-paliscot/dotfiles.git}"
CLONE_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# 1. Homebrew (also installs Xcode Command Line Tools, which provides git)
if ! command -v brew >/dev/null 2>&1; then
  echo "→ Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ -x /opt/homebrew/bin/brew ]; then
  BREW_BIN=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
  BREW_BIN=/usr/local/bin/brew
else
  echo "✗ brew not found after install" >&2
  exit 1
fi
eval "$("$BREW_BIN" shellenv)"

# Persist brew on PATH for future shells.
BREW_SHELLENV_LINE="eval \"\$($BREW_BIN shellenv)\""
for profile in "$HOME/.zprofile" "$HOME/.bash_profile"; do
  if ! grep -qsF "$BREW_SHELLENV_LINE" "$profile"; then
    echo "$BREW_SHELLENV_LINE" >> "$profile"
    echo "→ Added brew shellenv to ${profile/#$HOME/~}"
  fi
done

# 2. If we were piped via curl|bash, BASH_SOURCE is empty and Brewfile isn't local.
#    Clone the repo and re-exec from inside it.
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [ -z "$SCRIPT_PATH" ] || [ ! -f "$(dirname "$SCRIPT_PATH")/Brewfile" ]; then
  if [ ! -d "$CLONE_DIR/.git" ]; then
    echo "→ Cloning $REPO_URL to ${CLONE_DIR}…"
    git clone "$REPO_URL" "$CLONE_DIR"
  fi
  echo "→ Re-running from clone at ${CLONE_DIR}…"
  exec bash "$CLONE_DIR/install.sh" "$@"
fi
cd "$(dirname "$SCRIPT_PATH")"

# 3. CLIs and apps from Brewfile
echo "→ Installing Brewfile bundle…"
brew bundle --file=Brewfile --verbose

# 4. GitHub auth (browser device flow — no tokens in this repo)
if ! gh auth status >/dev/null 2>&1; then
  echo "→ Signing in to GitHub…"
  gh auth login --web -h github.com
fi

# 5. gh extensions (Copilot CLI)
if ! gh extension list 2>/dev/null | grep -q gh-copilot; then
  echo "→ Installing gh-copilot extension…"
  gh extension install github/gh-copilot
fi

# 6. VS Code extensions
if command -v code >/dev/null 2>&1; then
  echo "→ Installing VS Code extensions…"
  xargs -n1 code --install-extension --force < vscode-extensions.txt
else
  echo "⚠ VS Code 'code' CLI not on PATH. Open VS Code once, run 'Shell Command: Install code command in PATH', then re-run this script."
fi

# 7. Private npm registry auth + global packages
./scripts/setup-npmrc.sh
if command -v npm >/dev/null 2>&1; then
  echo "→ Installing global npm packages…"
  xargs -n1 npm install -g < npm-globals.txt
else
  echo "⚠ npm not found. Install Node first (e.g. 'brew install node' or via mise) and re-run."
fi

cat <<'EOF'

✓ Bootstrap complete.

Next, finish the manual steps in POST-INSTALL.md (1Password sign-in,
Raycast import, VS Code Settings Sync, …).
EOF
