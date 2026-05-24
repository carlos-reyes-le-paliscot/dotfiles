#!/usr/bin/env bash
# Configure ~/.npmrc for private npm packages.
# Pick ONE of the patterns below, uncomment, and adjust SCOPE / REGISTRY.
# NEVER commit ~/.npmrc or any token to this repo.

set -euo pipefail

# --- Pattern A: GitHub Packages (uses your existing gh auth, no separate token) ---
# TOKEN=$(gh auth token)
# SCOPE="@your-scope"
# REGISTRY_HOST="npm.pkg.github.com"
# REGISTRY_URL="https://${REGISTRY_HOST}"

# --- Pattern B: 1Password CLI (works with any private registry) ---
# op signin
# TOKEN=$(op read "op://Personal/npm-private/token")
# SCOPE="@your-scope"
# REGISTRY_HOST="your.registry.example"
# REGISTRY_URL="https://${REGISTRY_HOST}"

# --- Pattern C: prompt interactively (no secrets manager) ---
# read -srp "Private npm token: " TOKEN; echo
# SCOPE="@your-scope"
# REGISTRY_HOST="your.registry.example"
# REGISTRY_URL="https://${REGISTRY_HOST}"

if [ -z "${TOKEN:-}" ]; then
  echo "→ scripts/setup-npmrc.sh: no pattern enabled — skipping ~/.npmrc setup."
  echo "  Edit this script and uncomment one of the patterns to configure private packages."
  exit 0
fi

cat > "$HOME/.npmrc" <<EOF
${SCOPE}:registry=${REGISTRY_URL}
//${REGISTRY_HOST}/:_authToken=${TOKEN}
EOF
chmod 600 "$HOME/.npmrc"
echo "→ ~/.npmrc configured (${SCOPE} → ${REGISTRY_URL})"
