# Post-install manual steps

These can't be automated. Knock them out once and you're done.

## 1. Setapp
- Open Setapp → sign in.
- Install **TablePlus** from the Setapp catalog (Setapp has no public CLI to script this).
- Install any other Setapp apps you use.

## 2. 1Password
- Open 1Password → sign in to your account.
- Enable browser extensions (Safari / Dia / Chrome).
- **Turn on the SSH agent**: Settings → Developer → "Use the SSH agent". This lets `git push` use SSH keys stored in 1Password instead of `~/.ssh/`.

## 3. Raycast
- Open Raycast → sign in (optional but recommended for sync).
- Import settings: Raycast → Settings → Advanced → Import → point at `raycast-settings.rayconfig` if you've exported one (consider keeping the export in this repo; no secrets in it).

## 4. Dia
- Sign in.
- (Optional) Set as default browser via System Settings → Desktop & Dock → Default web browser.

## 5. VS Code
- Open VS Code → sign in with your GitHub account.
- Turn on **Settings Sync** (Command Palette → "Settings Sync: Turn On"). This auto-syncs settings, keybindings, and any extensions not already in `vscode-extensions.txt`.

## 6. GitHub
- `gh auth status` to verify the bootstrap signed you in.
- If you use SSH for git remotes, the 1Password SSH agent (step 2) handles it; otherwise add a key with `ssh-keygen -t ed25519 -C "you@example"` and `gh ssh-key add ~/.ssh/id_ed25519.pub`.

## 7. macOS system prefs (optional)
A few `defaults write` snippets you might want in `install.sh` once you've decided your preferences:

```bash
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
killall Dock
```

## 8. Private npm packages
If you skipped this in the bootstrap: edit `scripts/setup-npmrc.sh`, uncomment one of the three patterns, and re-run it.
