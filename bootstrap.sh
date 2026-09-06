#!/usr/bin/env bash
# ==============================================================================
# One-Liner Quick Bootstrap for Omarchy Setup
# ==============================================================================

set -euo pipefail

DEST_DIR="$HOME/Work/acer-aspire14-omarchy"

echo "==> Setting up Acer Aspire 14 / Omarchy environment..."

if ! command -v git >/dev/null 2>&1; then
  echo "--> Installing git..."
  sudo pacman -S --noconfirm git
fi

if [[ -d "$DEST_DIR" ]]; then
  echo "--> Repository already exists in $DEST_DIR. Pulling latest..."
  git -C "$DEST_DIR" pull --rebase
else
  mkdir -p "$HOME/Work"
  echo "--> Cloning bchurch95/acer-aspire14-omarchy..."
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh repo clone bchurch95/acer-aspire14-omarchy "$DEST_DIR"
  else
    git clone https://github.com/bchurch95/acer-aspire14-omarchy.git "$DEST_DIR" || {
      echo "If prompted for authentication, enter your GitHub credentials or PAT."
    }
  fi
fi

echo "--> Launching restore script..."
bash "$DEST_DIR/restore.sh" "${1:---all}"
