# dotfiles

Personal macOS bootstrap. Fresh machine → ready to code in ~20 minutes, mostly hands-off.

## Use it

```sh
curl -fsSL https://raw.githubusercontent.com/<you>/dotfiles/main/install.sh | bash
```

What runs:

1. Homebrew (also installs Xcode CLT)
2. Everything in `Brewfile` — CLIs (git, gh, mise, jq, rg, fzf) + apps (Raycast, Setapp, 1Password, Dia, VS Code) + fonts
3. `gh auth login` (browser device flow) + `gh-copilot` extension
4. VS Code extensions from `vscode-extensions.txt`
5. `scripts/setup-npmrc.sh` (no-op until you configure a private registry pattern)
6. Global npm packages from `npm-globals.txt` (Claude Code, Copilot CLI)

Then finish the manual steps in [POST-INSTALL.md](./POST-INSTALL.md).

## Refresh the snapshot

After installing or removing apps:

```sh
brew bundle dump --file=Brewfile --force --describe
code --list-extensions > vscode-extensions.txt
npm ls -g --depth=0 --json | jq -r '.dependencies | keys[]' > npm-globals.txt
git commit -am "refresh snapshot"
```

## Security notes

- No tokens in this repo. `~/.npmrc` and `~/.ssh/` are generated locally only.
- `install.sh` runs via `curl | bash` — keep this repo public so you can audit it, and protect your GitHub account with 2FA + hardware key.
