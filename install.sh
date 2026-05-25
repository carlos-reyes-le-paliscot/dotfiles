#!/usr/bin/env bash
# Bootstrap a fresh macOS machine. Single self-contained script — no clone,
# no companion files, nothing persistent on disk except shell config.
#
# Usage (on a new Mac):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/carlos-reyes-le-paliscot/dotfiles/main/install.sh)"

set -euo pipefail

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

# Persist brew on PATH for future login shells.
BREW_SHELLENV_LINE="eval \"\$($BREW_BIN shellenv)\""
for profile in "$HOME/.zprofile" "$HOME/.bash_profile"; do
  if ! grep -qsF "$BREW_SHELLENV_LINE" "$profile"; then
    echo "$BREW_SHELLENV_LINE" >> "$profile"
    echo "→ Added brew shellenv to ${profile/#$HOME/~}"
  fi
done

# 2. Brewfile (piped to brew bundle via stdin)
echo "→ Installing Brewfile bundle…"
brew bundle --file=- --verbose <<'BREWFILE'
# --- CLIs ---
brew "git"
brew "gh"
brew "mise"
brew "jq"
brew "ripgrep"
brew "fzf"

# --- Apps ---
cask "raycast"
cask "thebrowsercompany-dia"
cask "1password"
cask "1password-cli"
cask "visual-studio-code"
cask "claude-code"

# Previously via Setapp — now standalone (separate licenses):
cask "displaperture"
cask "istat-menus"
cask "cleanshot"
cask "tableplus"

# --- Fonts ---
cask "font-jetbrains-mono-nerd-font"
BREWFILE

# 3. GitHub auth (browser device flow — no tokens in this repo)
if ! gh auth status >/dev/null 2>&1; then
  echo "→ Signing in to GitHub…"
  gh auth login --web -h github.com
fi

# 4. gh-copilot — skip if already a built-in/alias/extension.
if gh copilot --help >/dev/null 2>&1 || gh extension list 2>/dev/null | grep -q gh-copilot; then
  : # already available
else
  echo "→ Installing gh-copilot extension…"
  gh extension install github/gh-copilot || echo "⚠ gh-copilot install failed; continuing."
fi

# 5. VS Code extensions
if command -v code >/dev/null 2>&1; then
  echo "→ Installing VS Code extensions…"
  for ext in \
    anthropic.claude-code \
    dbaeumer.vscode-eslint \
    esbenp.prettier-vscode \
    Prisma.prisma \
    bradlc.vscode-tailwindcss \
    ms-azuretools.vscode-docker; do
    code --force --install-extension "$ext" || echo "⚠ Failed: $ext (continuing)"
  done
else
  echo "⚠ VS Code 'code' CLI not on PATH. Open VS Code once, run 'Shell Command: Install code command in PATH', then re-run this script."
fi

# 6. Append brew-purge function directly to ~/.zshrc (idempotent via marker).
BREW_PURGE_MARKER="# dotfiles:brew-purge"
if ! grep -qsF "$BREW_PURGE_MARKER" "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" <<'ZSHRC'

# dotfiles:brew-purge
# Uninstall a brew formula and clean up what brew leaves behind:
#   - autoremove orphaned deps
#   - sweep $(brew --prefix)/etc/<name> dirs whose Cellar dir is gone
# Usage: brew-purge node
brew-purge() {
  brew uninstall "$@" && brew autoremove
  local P
  P=$(brew --prefix)
  local swept=""
  local count=0
  for d in "$P"/etc/*/; do
    [ -d "$d" ] || continue
    if [ ! -d "$P/Cellar/$(basename "$d")" ]; then
      rm -rf "$d"
      swept="$swept $(basename "$d")"
      count=$((count + 1))
    fi
  done
  if [ "$count" -gt 0 ]; then
    echo
    echo "→ brew-purge: removed $count leftover config dir(s) under $P/etc/:$swept"
    echo "  (brew's earlier 'configuration files have not been removed' warnings are resolved.)"
  else
    echo
    echo "→ brew-purge: no leftover config dirs to clean."
  fi
}
ZSHRC
  echo "→ Added brew-purge function to ~/.zshrc"
fi

# 7. Clean up legacy clone from earlier multi-file design, if present.
if [ -d "$HOME/.dotfiles" ]; then
  echo "→ Removing legacy clone at ~/.dotfiles (no longer needed)…"
  rm -rf "$HOME/.dotfiles"
fi

cat <<'EOF'

✓ Bootstrap complete.

This terminal still has the OLD shell config loaded — Unix can't push env
changes from a child process up into the parent shell. To pick up brew on
PATH and brew-purge in THIS terminal, run:

    source ~/.zprofile && source ~/.zshrc

Or just open a new terminal tab/window — new shells pick everything up
automatically.

To uninstall everything later:
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/carlos-reyes-le-paliscot/dotfiles/main/uninstall.sh)"
EOF
