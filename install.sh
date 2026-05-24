#!/usr/bin/env bash
set -euo pipefail

REPO="collymoore/hermes-secrets-vault"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/main"
INSTALL_DIR="/usr/local/bin"
VAULT_BIN="${INSTALL_DIR}/vault"

echo "==> Hermes Secrets Vault — Installing..."

# Ensure we have curl
if ! command -v curl &>/dev/null; then
  echo "ERROR: curl is required but not installed. Install curl first."
  exit 1
fi

# Download the vault CLI
echo "==> Downloading vault CLI from ${RAW_BASE}/bin/vault..."
curl -fsSL "${RAW_BASE}/bin/vault" -o "${VAULT_BIN}" || {
  echo "ERROR: Failed to download vault CLI."
  exit 1
}

# Make executable
chmod +x "${VAULT_BIN}"

echo "==> Installed vault CLI to ${VAULT_BIN}"
echo ""
echo "  ____  _   _ ____  _   _ ____  "
echo " / ___|| | | |  _ \| | | / ___| "
echo " \___ \| |_| | |_) | | | \___ \ "
echo "  ___) |  _  |  __/| |_| |___) |"
echo " |____/|_| |_|_|    \___/|____/ "
echo ""
echo "Hermes Secrets Vault installed successfully!"
echo ""
echo "Quick start:"
echo "  cd /path/to/your/project"
echo "  vault init         # Create a new vault (you'll be prompted for a password)"
echo "  vault set my-key   # Store a secret"
echo "  vault get my-key   # Retrieve a secret"
echo ""
echo "Run 'vault --help' for full usage."
