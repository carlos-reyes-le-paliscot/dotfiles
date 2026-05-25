#!/usr/bin/env bash
# Reverse install.sh on this machine.
# Doesn't uninstall Homebrew itself, Xcode CLT, or sign you out of GitHub —
# those are system-wide and not specific to this dotfiles bootstrap.
#
# Usage:
#   ./uninstall.sh          # prompts for confirmation
#   ./uninstall.sh --yes    # no prompt

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]:-./}")"

CONFIRM=1
if [ "${1:-}" = "--yes" ] || [ "${1:-}" = "-y" ]; then
  CONFIRM=0
fi

if [ "$CONFIRM" = "1" ]; then
  cat <<'EOF'
⚠ This will remove everything install.sh added:
  - VS Code extensions from vscode-extensions.txt
  - gh-copilot extension
  - every formula and cask in Brewfile (casks via --zap, so app prefs go too)
  - leftover config dirs under $(brew --prefix)/etc that brew itself never deletes
  - autoremoved dependency leftovers (e.g. openssl@3, ca-certificates configs)
  - "eval brew shellenv" lines from ~/.zprofile and ~/.bash_profile
  - the clone at ~/.dotfiles (or $DOTFILES_DIR if set)

It will NOT:
  - uninstall Homebrew, Xcode CLT, or sign you out of GitHub
  - touch ~/.npmrc (might have unrelated config)
  - remove 1Password / iCloud / etc. account data
EOF
  read -rp "Continue? [y/N] " ans
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
if command -v code >/dev/null 2>&1 && [ -f vscode-extensions.txt ]; then
  echo "→ Removing VS Code extensions…"
  xargs -n1 code --uninstall-extension < vscode-extensions.txt || true
fi

# 2. gh extensions
if command -v gh >/dev/null 2>&1; then
  echo "→ Removing gh-copilot extension…"
  gh extension remove github/gh-copilot 2>/dev/null || true
fi

# 3. Brewfile contents — casks first (some depend on formulae), then formulae.
if command -v brew >/dev/null 2>&1 && [ -f Brewfile ]; then
  echo "→ Uninstalling casks from Brewfile…"
  grep -E '^[[:space:]]*cask[[:space:]]+"' Brewfile \
    | sed -E 's/.*cask[[:space:]]+"([^"]+)".*/\1/' \
    | while read -r c; do
        echo "  · $c"
        brew uninstall --cask --zap "$c" 2>/dev/null || true
      done

  echo "→ Uninstalling formulae from Brewfile…"
  grep -E '^[[:space:]]*brew[[:space:]]+"' Brewfile \
    | sed -E 's/.*brew[[:space:]]+"([^"]+)".*/\1/' \
    | while read -r f; do
        echo "  · $f"
        brew uninstall --ignore-dependencies "$f" 2>/dev/null || true
      done

  # Sweep orphaned dependencies that brew pulled in transitively.
  echo "→ Autoremoving orphaned dependencies…"
  brew autoremove 2>/dev/null || true

  # brew uninstall preserves /opt/homebrew/etc/<name> by design ("might contain
  # user customizations"). For a clean teardown we don't want that — wipe any
  # config dir whose corresponding Cellar dir is gone.
  BREW_PREFIX="$(brew --prefix)"
  if [ -d "$BREW_PREFIX/etc" ]; then
    echo "→ Removing leftover config dirs under $BREW_PREFIX/etc…"
    find "$BREW_PREFIX/etc" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r d; do
      name="$(basename "$d")"
      if [ ! -d "$BREW_PREFIX/Cellar/$name" ]; then
        echo "  · $d"
        rm -rf "$d"
      fi
    done
  fi
fi

# 4. Strip brew shellenv lines from shell profiles.
for profile in "$HOME/.zprofile" "$HOME/.bash_profile"; do
  [ -f "$profile" ] || continue
  if grep -q 'brew shellenv' "$profile"; then
    echo "→ Removing brew shellenv line from ${profile/#$HOME/~}"
    sed -i.bak '/brew shellenv/d' "$profile"
  fi
done

# 5. Clone directory.
CLONE_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
if [ -d "$CLONE_DIR" ]; then
  echo "→ Removing clone at $CLONE_DIR"
  rm -rf "$CLONE_DIR"
fi

cat <<'EOF'

✓ Uninstall complete.

Still present (intentionally):
  - Homebrew itself  →  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  - Xcode CLT        →  sudo rm -rf /Library/Developer/CommandLineTools
  - GitHub auth      →  gh auth logout
  - ~/.npmrc         →  rm ~/.npmrc  (if you set up a private registry)
EOF
