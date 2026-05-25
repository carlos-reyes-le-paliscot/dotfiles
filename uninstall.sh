#!/usr/bin/env bash
# Reverse install.sh. Single self-contained script — fetch via curl|bash too.
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/carlos-reyes-le-paliscot/dotfiles/main/uninstall.sh)"
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/carlos-reyes-le-paliscot/dotfiles/main/uninstall.sh)" -- --yes

set -euo pipefail

CONFIRM=1
if [ "${1:-}" = "--yes" ] || [ "${1:-}" = "-y" ]; then
  CONFIRM=0
fi

# Keep these lists in sync with install.sh.
FORMULAE=(git gh mise jq ripgrep fzf)
CASKS=(
  raycast
  thebrowsercompany-dia
  1password
  1password-cli
  visual-studio-code
  claude-code
  displaperture
  istat-menus
  cleanshot
  tableplus
  font-jetbrains-mono-nerd-font
)
VSCODE_EXTS=(
  anthropic.claude-code
  dbaeumer.vscode-eslint
  esbenp.prettier-vscode
  Prisma.prisma
  bradlc.vscode-tailwindcss
  ms-azuretools.vscode-docker
)

if [ "$CONFIRM" = "1" ]; then
  cat <<EOF
⚠ This will remove everything install.sh added:
  - VS Code extensions: ${VSCODE_EXTS[*]}
  - gh-copilot extension (if installed as extension)
  - Brewfile casks via --zap (so app prefs go too): ${CASKS[*]}
  - Brewfile formulae: ${FORMULAE[*]}
  - autoremoved orphaned dependencies + leftover config dirs under \$(brew --prefix)/etc
  - "eval brew shellenv" lines from ~/.zprofile and ~/.bash_profile
  - the brew-purge function block from ~/.zshrc

It will NOT:
  - uninstall Homebrew, Xcode CLT, or sign you out of GitHub
  - touch ~/.npmrc or other unrelated config
  - remove 1Password / iCloud / etc. account data

EOF
  read -rp "Continue? [y/N] " ans </dev/tty
  case "${ans:-}" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

# Put brew on PATH for this run if it isn't already.
if ! command -v brew >/dev/null 2>&1; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# 1. VS Code extensions
if command -v code >/dev/null 2>&1; then
  echo "→ Removing VS Code extensions…"
  for ext in "${VSCODE_EXTS[@]}"; do
    code --uninstall-extension "$ext" 2>/dev/null || true
  done
fi

# 2. gh-copilot extension (if it was installed as an extension)
if command -v gh >/dev/null 2>&1 && gh extension list 2>/dev/null | grep -q gh-copilot; then
  echo "→ Removing gh-copilot extension…"
  gh extension remove github/gh-copilot 2>/dev/null || true
fi

# 3. Brewfile contents — casks first (some depend on formulae), then formulae.
if command -v brew >/dev/null 2>&1; then
  echo "→ Uninstalling casks…"
  for c in "${CASKS[@]}"; do
    echo "  · $c"
    brew uninstall --cask --zap "$c" 2>/dev/null || true
  done

  echo "→ Uninstalling formulae…"
  for f in "${FORMULAE[@]}"; do
    echo "  · $f"
    brew uninstall --ignore-dependencies "$f" 2>/dev/null || true
  done

  echo "→ Autoremoving orphaned dependencies…"
  brew autoremove 2>/dev/null || true

  echo "→ Sweeping leftover config dirs under $(brew --prefix)/etc…"
  P=$(brew --prefix)
  swept=0
  for d in "$P"/etc/*/; do
    [ -d "$d" ] || continue
    if [ ! -d "$P/Cellar/$(basename "$d")" ]; then
      rm -rf "$d"
      swept=$((swept + 1))
    fi
  done
  echo "  Removed $swept leftover dir(s)."
fi

# 4. Strip brew shellenv lines from login profiles.
for profile in "$HOME/.zprofile" "$HOME/.bash_profile"; do
  [ -f "$profile" ] || continue
  if grep -q 'brew shellenv' "$profile"; then
    echo "→ Removing brew shellenv line from ${profile/#$HOME/~}"
    sed -i.bak '/brew shellenv/d' "$profile"
  fi
done

# 5. Strip brew-purge function block from ~/.zshrc.
if [ -f "$HOME/.zshrc" ] && grep -q 'dotfiles:brew-purge' "$HOME/.zshrc"; then
  echo "→ Removing brew-purge function block from ~/.zshrc"
  # Delete from the marker comment through the closing brace of brew-purge().
  sed -i.bak '/# dotfiles:brew-purge/,/^}$/d' "$HOME/.zshrc"
fi

# 6. Clean up legacy clone from earlier multi-file design, if present.
if [ -d "$HOME/.dotfiles" ]; then
  echo "→ Removing legacy clone at ~/.dotfiles…"
  rm -rf "$HOME/.dotfiles"
fi

cat <<'EOF'

✓ Uninstall complete.

Still present (intentionally):
  - Homebrew itself  →  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  - Xcode CLT        →  sudo rm -rf /Library/Developer/CommandLineTools
  - GitHub auth      →  gh auth logout
  - ~/.npmrc         →  rm ~/.npmrc  (if you set one up)
EOF
