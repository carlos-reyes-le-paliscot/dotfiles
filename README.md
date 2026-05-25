# dotfiles

Personal macOS bootstrap. Two self-contained scripts, no clone, nothing persistent on disk except shell config.

## Install

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/carlos-reyes-le-paliscot/dotfiles/main/install.sh)"
```

What runs:

1. Homebrew (also installs Xcode CLT, which provides git)
2. Brewfile bundle, inlined into the script via heredoc — CLIs (git, gh, mise, jq, rg, fzf) + apps (Raycast, 1Password, Dia, VS Code, Claude Code, CleanShot, iStat Menus, TablePlus, Displaperture) + fonts
3. `gh auth login` (browser device flow) + `gh-copilot` extension (skipped if `gh copilot` is already a built-in)
4. VS Code extensions
5. Appends a `brew-purge <pkg>` function to `~/.zshrc` (uninstall + autoremove orphans + sweep leftover config dirs in one shot)

Language runtimes (Node, Python, …) are handled per-repo with `mise` — drop a `.mise.toml` in each project.

Then finish the manual steps in [POST-INSTALL.md](./POST-INSTALL.md).

## Uninstall

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/carlos-reyes-le-paliscot/dotfiles/main/uninstall.sh)"
```

Same shape — one curl, no clone. Removes everything `install.sh` added (Brewfile entries with `--zap`, VS Code extensions, `gh-copilot` extension, brew shellenv lines, the `brew-purge` function block), autoremoves orphaned brew dependencies, and sweeps leftover config dirs under `$(brew --prefix)/etc`. Leaves Homebrew itself, Xcode CLT, GitHub auth, and `~/.npmrc` alone — those have system-wide effects beyond this bootstrap; instructions to remove each are printed at the end.

Pass `-- --yes` to skip the confirmation prompt:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/carlos-reyes-le-paliscot/dotfiles/main/uninstall.sh)" -- --yes
```

## Edit it

Everything lives in `install.sh` and `uninstall.sh` — the Brewfile is a heredoc inside step 2, the VS Code extensions are a `for` loop in step 4, the `brew-purge` function is a heredoc in step 6. Keep the lists in `install.sh` and `uninstall.sh` in sync (a quick `diff` shows the divergence).

To regenerate the Brewfile contents from a fully-set-up machine and paste them into `install.sh`:

```sh
brew bundle dump --file=- --describe
```

For VS Code extensions:

```sh
code --list-extensions
```

## Security notes

- No tokens in this repo. `~/.npmrc` and `~/.ssh/` are generated locally only.
- `install.sh` runs via remote shell exec — keep this repo public so you can audit it, and protect your GitHub account with 2FA + hardware key.
