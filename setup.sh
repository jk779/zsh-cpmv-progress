#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# setup.sh -- installer for zsh-cpmv-progress
#
#   curl -fsSL https://github.com/jk779/zsh-cpmv-progress/raw/branch/main/setup.sh | bash
#
# Safe to run multiple times (idempotent): re-running just updates the repo
# and won't duplicate the source line in your .zshrc.
# ------------------------------------------------------------------------------

set -euo pipefail

REPO_URL="https://github.com/jk779/zsh-cpmv-progress.git"
INSTALL_DIR="${ZSH_CPMV_PROGRESS_DIR:-$HOME/.zsh/plugins/zsh-cpmv-progress}"
PLUGIN_FILE="$INSTALL_DIR/zsh-cpmv-progress.plugin.zsh"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
SOURCE_LINE="source \"$PLUGIN_FILE\""

# --- sanity checks -----------------------------------------------------------

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required but not found in PATH." >&2
  exit 1
fi

if ! command -v zsh >/dev/null 2>&1; then
  echo "warning: zsh not found in PATH — this plugin only works in zsh." >&2
fi

# --- clone or update -----------------------------------------------------------

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "zsh-cpmv-progress already installed at $INSTALL_DIR — updating..."
  if [[ "${FORCE:-0}" == "1" ]]; then
    git -C "$INSTALL_DIR" fetch --depth 1 origin
    git -C "$INSTALL_DIR" reset --hard origin/HEAD
  elif ! git -C "$INSTALL_DIR" pull --ff-only; then
    echo "" >&2
    echo "error: update failed (local changes or diverged history)." >&2
    echo "Re-run with FORCE=1 to discard local changes and hard-reset to the latest version:" >&2
    echo "  curl -fsSL <url-to-setup.sh> | FORCE=1 bash" >&2
    exit 1
  fi
else
  echo "Cloning zsh-cpmv-progress into $INSTALL_DIR ..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

# --- wire it up into .zshrc -----------------------------------------------------------

if [[ -f "$ZSHRC" ]] && grep -qF "$SOURCE_LINE" "$ZSHRC"; then
  echo "Already wired up in $ZSHRC — nothing to add."
else
  {
    echo ""
    echo "# zsh-cpmv-progress: native progress bars for cp/mv (OSC 9;4)"
    echo "$SOURCE_LINE"
  } >> "$ZSHRC"
  echo "Added source line to $ZSHRC"
fi

echo ""
echo "Done. Restart your shell or run: source \"$ZSHRC\""
echo "Then try: cpp SRC DEST   or   mvp SRC DEST"