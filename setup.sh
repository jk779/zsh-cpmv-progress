#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# setup.sh - installer for zsh-cpmv-progress
#
#   curl -fsSL https://raw.githubusercontent.com/jk779/zsh-cpmv-progress/main/setup.sh | bash
#
# Safe to run multiple times (idempotent): re-running just updates the repo
# and won't duplicate the source line in your .zshrc.
# ------------------------------------------------------------------------------

set -euo pipefail

REPO_URL="https://github.com/jk779/zsh-cpmv-progress.git"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
OMZ_CUSTOM_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}"
OMZ_PLUGIN_DIR="$OMZ_CUSTOM_DIR/plugins/zsh-cpmv-progress"
MANUAL_DIR="${ZSH_CPMV_PROGRESS_DIR:-$HOME/.zsh/plugins/zsh-cpmv-progress}"
SKIP_ZSHRC_WIRING=0
USE_OMZ=0

if [[ -d "$OMZ_DIR" ]]; then
  echo "Detected oh-my-zsh at $OMZ_DIR - installing as a custom plugin."
  INSTALL_DIR="$OMZ_PLUGIN_DIR"
  USE_OMZ=1
else
  INSTALL_DIR="$MANUAL_DIR"
fi

PLUGIN_FILE="$INSTALL_DIR/zsh-cpmv-progress.plugin.zsh"
SOURCE_LINE="source \"$PLUGIN_FILE\""

# --- sanity checks -----------------------------------------------------------

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required but not found in PATH." >&2
  exit 1
fi

if ! command -v zsh >/dev/null 2>&1; then
  echo "warning: zsh not found in PATH - this plugin only works in zsh." >&2
fi

# --- clone or update -----------------------------------------------------------

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "zsh-cpmv-progress already installed at $INSTALL_DIR - updating..."
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

NAME="zsh-cpmv-progress"
# word-boundary-ish match: not preceded/followed by another identifier character
NAME_RE='(^|[^a-zA-Z0-9_-])'"$NAME"'([^a-zA-Z0-9_-]|$)'

if [[ "$USE_OMZ" == "1" ]]; then
  if [[ ! -f "$ZSHRC" ]]; then
    echo "warning: $ZSHRC not found - add '$NAME' to your plugins=(...) array manually." >&2
  elif grep -qE "$NAME_RE" "$ZSHRC"; then
    echo "'$NAME' already in plugins=(...) in $ZSHRC - nothing to add."
  elif grep -qE '^\s*plugins=\(.*\)\s*$' "$ZSHRC"; then
    # single-line array, e.g.: plugins=(git docker)
    sed -i.bak -E "s/^(\s*plugins=\([^)]*)\)/\1 $NAME)/" "$ZSHRC"
    rm -f "$ZSHRC.bak"
    echo "Added '$NAME' to plugins=(...) in $ZSHRC"
  elif grep -qE '^\s*plugins=\(\s*$' "$ZSHRC"; then
    # multi-line array - just drop the name onto its own line right after the opener:
    #   plugins=(
    #     zsh-cpmv-progress
    #     git
    #     ...
    line_no=$(grep -nE '^\s*plugins=\(\s*$' "$ZSHRC" | head -1 | cut -d: -f1)
    awk -v n="$line_no" -v name="  $NAME" 'NR==n{print; print name; next}1' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
    echo "Added '$NAME' to the multi-line plugins=(...) array in $ZSHRC"
  else
    echo "" >&2
    echo "warning: couldn't find a plugins=(...) array in $ZSHRC." >&2
    echo "Please add '$NAME' to it manually, e.g.:" >&2
    echo "  plugins=(... $NAME)" >&2
  fi
else
  if [[ -f "$ZSHRC" ]] && grep -qF "$SOURCE_LINE" "$ZSHRC"; then
    echo "Already wired up in $ZSHRC - nothing to add."
  else
    {
      echo ""
      echo "# zsh-cpmv-progress: native progress bars for cp/mv (OSC 9;4)"
      echo "$SOURCE_LINE"
    } >> "$ZSHRC"
    echo "Added source line to $ZSHRC"
  fi
fi

echo ""
echo "Done. Restart your shell or run: source \"$ZSHRC\""
echo "Then try: cpp SRC DEST   or   mvp SRC DEST"