# dotfiles

Personal macOS bootstrap. Fresh machine → ready to code in ~20 minutes, mostly hands-off.

## Use it

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/carlos-reyes-le-paliscot/dotfiles/main/install.sh)"
```

What runs:

1. Homebrew (also installs Xcode CLT)
2. Everything in `Brewfile` — CLIs (git, gh, mise, jq, rg, fzf) + apps (Raycast, 1Password, Dia, VS Code, Claude Code, CleanShot, iStat Menus, TablePlus, Displaperture) + fonts
3. `gh auth login` (browser device flow) + `gh-copilot` extension
4. VS Code extensions from `vscode-extensions.txt`

Language runtimes (Node, Python, …) are handled per-repo with `mise` — drop a `.mise.toml` in each project. `scripts/setup-npmrc.sh` is left as a manual helper if you ever need a private npm registry.

Then finish the manual steps in [POST-INSTALL.md](./POST-INSTALL.md).

## Undo it

From inside the clone (`~/.dotfiles` by default):

```sh
./uninstall.sh          # prompts before doing anything
./uninstall.sh --yes    # skip the prompt
```

Removes every Brewfile entry (casks via `--zap`, wiping app prefs), VS Code extensions, the `gh-copilot` extension, autoremoves orphaned brew dependencies, sweeps leftover config dirs under `$(brew --prefix)/etc` (so you don't have to `rm -rf /opt/homebrew/etc/openssl@3` and friends by hand), and strips the brew shellenv lines from `~/.zprofile` / `~/.bash_profile`. Leaves Homebrew, Xcode CLT, GitHub auth, and `~/.npmrc` alone — those have system-wide effects beyond this bootstrap; instructions to remove each are printed at the end.

## Refresh the snapshot

After installing or removing apps:

```sh
brew bundle dump --file=Brewfile --force --describe
code --list-extensions > vscode-extensions.txt
git commit -am "refresh snapshot"
```

## Security notes

- No tokens in this repo. `~/.npmrc` and `~/.ssh/` are generated locally only.
- `install.sh` runs via remote shell exec — keep this repo public so you can audit it, and protect your GitHub account with 2FA + hardware key.
