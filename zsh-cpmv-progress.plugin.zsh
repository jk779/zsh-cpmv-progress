#!/usr/bin/env zsh
# ------------------------------------------------------------------------------
# FILE: zsh-cpmv-progress.plugin.zsh
# DESCRIPTION: Native terminal progress bars (OSC 9;4) for cp/mv, backed by rsync.
#              Supported by iTerm2 (>= 3.6.6), Windows Terminal, Ghostty, WezTerm.
#              On unsupported terminals the escape sequences are simply ignored.
# ------------------------------------------------------------------------------

# Disable this plugin entirely by setting: CPMV_PROGRESS_DISABLE=1
if [[ "${CPMV_PROGRESS_DISABLE:-0}" == "1" ]]; then
  return 0
fi

# Make sure required tools exist. If not, warn once and skip loading cpp/mvp.
if ! command -v rsync >/dev/null 2>&1; then
  echo "zsh-cpmv-progress: 'rsync' not found — cpp/mvp will not be available." >&2
  return 0
fi
if ! command -v awk >/dev/null 2>&1; then
  echo "zsh-cpmv-progress: 'awk' not found — cpp/mvp will not be available." >&2
  return 0
fi

# Internal: emit OSC 9;4 progress sequences from rsync's --info=progress2 output.
# $1: extra rsync flags (e.g. --remove-source-files), remaining args: rsync args
_cpmv_progress_run_rsync() {
  local extra_flags="$1"; shift
  printf '\e]9;4;3;0\a'  # indeterminate while rsync scans the file list

  rsync -ah --outbuf=L ${=extra_flags} --info=progress2 "$@" 2>&1 | \
    awk 'BEGIN{RS="[\r\n]"} match($0,/[0-9]+%/){printf "\033]9;4;1;%s\a", substr($0,RSTART,RLENGTH-1); fflush()}'

  local status=$?
  printf '\e]9;4;0;0\a'  # hide the bar when done
  return $status
}

# cpp: cp with a native progress bar (always uses rsync)
cpp() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: cpp SRC... DEST" >&2
    return 1
  fi
  _cpmv_progress_run_rsync "" "$@"
}

# --- mvp

# Internal: portable "device ID of path" across macOS/BSD (stat -f) and Linux/GNU (stat -c).
# We only ever trust a command's stdout once its exit code is actually 0.
_cpmv_progress_dev_id() {
  local result
  if result=$(stat -f '%d' "$1" 2>/dev/null); then
    print -r -- "$result"
    return 0
  fi
  if result=$(stat -c '%d' "$1" 2>/dev/null); then
    print -r -- "$result"
    return 0
  fi
  return 1
}

# mvp: instant rename() on the same volume (no bar needed),
#      falls back to rsync + progress bar when crossing volumes/disks.
mvp() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: mvp SRC... DEST" >&2
    return 1
  fi

  local dest="${@: -1}"
  local srcs=("${@:1:$#-1}")

  local dest_check="$dest"
  [[ -d "$dest" ]] && dest_check="$dest/."
  [[ -e "$dest_check" ]] || dest_check="$(dirname -- "$dest")"

  local dest_dev same_volume=1
  dest_dev=$(_cpmv_progress_dev_id "$dest_check")

  local s
  for s in "${srcs[@]}"; do
    [[ "$(_cpmv_progress_dev_id "$s")" != "$dest_dev" ]] && same_volume=0
  done

  if (( same_volume )); then
    command mv "$@"
    return $?
  fi

  _cpmv_progress_run_rsync "--remove-source-files" "$@"
  local status=$?

  # clean up empty directories left behind by --remove-source-files
  for s in "${srcs[@]}"; do
    [[ -d "$s" ]] && find "$s" -type d -empty -delete 2>/dev/null
  done

  return $status
}

# --- reminder

# Friendly reminder when using plain cp/mv, so you remember cpp/mvp exist.
# Disable with: CPMV_PROGRESS_NO_HINT=1
if [[ "${CPMV_PROGRESS_NO_HINT:-0}" != "1" ]]; then
  autoload -Uz add-zsh-hook
  _cpmv_progress_suggest() {
    case "$1" in
      cp\ * | mv\ *)
        echo "💡 Tip: use cpp/mvp for a native progress bar on large transfers" >&2
        ;;
    esac
  }
  add-zsh-hook preexec _cpmv_progress_suggest
fi