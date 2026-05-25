# Functions sourced into interactive shells by the dotfiles bootstrap.

# brew-purge: uninstall a formula and clean up what brew leaves behind.
# `brew uninstall` preserves $(brew --prefix)/etc/<pkg>/ by design (configs
# might be customized) and doesn't touch orphaned dependencies. This wraps:
#   brew uninstall "$@" && brew autoremove
#   + sweep any etc/<name> dir whose Cellar dir is gone
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
