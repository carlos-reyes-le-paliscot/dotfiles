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
  for d in "$P"/etc/*/; do
    [ -d "$d" ] || continue
    [ -d "$P/Cellar/$(basename "$d")" ] || rm -rf "$d"
  done
}
