# zsh-cpmv-progress

Native terminal progress bars for `cp`/`mv` using the [OSC 9;4](https://conemu.github.io/en/AnsiEscapeCodes.html#ConEmu_specific_OSC) escape sequence - the same mechanism used by Claude Code, `uv`, and other modern CLI tools.

Supported by **iTerm2 (3.6.6+)**, Windows Terminal, Ghostty, and WezTerm. On unsupported terminals the sequences are simply ignored.

![demo](cpmv-demo.gif)

## Why

`cp` and `mv` don't show progress on their own. This plugin adds two new commands, `cpp` and `mvp`, that show a real progress bar rendered natively by your terminal (not ASCII art in stdout), visible even if you switch tabs.

- **`cpp`**: copy via `rsync`, always shows a progress bar.
- **`mvp`**: moves files. If source and destination are on the **same volume**, it falls back to an instant `mv` (no bar needed since it's already instant via `rename()`). If they're on **different volumes/disks**, it uses `rsync --remove-source-files` with a live progress bar.

`cp`/`mv` are left completely untouched. `cpp`/`mvp` are additive.

## Requirements

- `zsh`
- `rsync` (pre-installed on macOS and most Linux distros)
- `awk` (pre-installed everywhere)
- A terminal that supports OSC 9;4 for the actual bar to render (otherwise the commands still works, just pointlessly without the visual bar)

## Installation

### Quick install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/jk779/zsh-cpmv-progress/main/setup.sh | bash
```

This clones the repo to `~/.zsh/plugins/zsh-cpmv-progress` and adds a `source` line to your `.zshrc`. Safe to re-run anytime — it'll just `git pull` and won't duplicate the source line.

To re-run for updates later, just run the same command again. If the update fails due to local changes (e.g. you edited the plugin file by hand), force a hard reset to the latest version: `...main/setup.sh | FORCE=1 bash`

As always with `curl | bash`: [inspect the script](setup.sh) first before piping it to bash.

### Manual

```bash
git clone https://github.com/jk779/zsh-cpmv-progress.git ~/.zsh/plugins/zsh-cpmv-progress
echo 'source ~/.zsh/plugins/zsh-cpmv-progress/zsh-cpmv-progress.plugin.zsh' >> ~/.zshrc
```

### oh-my-zsh

```bash
git clone https://github.com/jk779/zsh-cpmv-progress.git ~/.oh-my-zsh/custom/plugins/zsh-cpmv-progress
```

Then add `zsh-cpmv-progress` to the `plugins=(...)` array in your `.zshrc`.

### zinit

```bash
zinit load jk779/zsh-cpmv-progress
```

## Usage

```bash
cpp large_file.iso /Volumes/Backup/
cpp -r some_folder/ /Volumes/Backup/

mvp some_folder/ ./elsewhere/        # same volume -> instant mv, no bar
mvp some_folder/ /Volumes/OtherDisk/ # cross-volume -> rsync + progress bar
```

## Configuration

| Variable                    | Effect                                              |
| ---------------------------- | ---------------------------------------------------- |
| `CPMV_PROGRESS_DISABLE=1`    | Disables the whole plugin (no functions, no hook)    |
| `CPMV_PROGRESS_NO_HINT=1`    | Disables the reminder hint on plain `cp`/`mv` calls  |

Set these *before* the plugin is sourced, e.g. at the top of your `.zshrc`.

## Known caveats

- `cpp`/`mvp` use `rsync` under the hood. For very large file trees on the same machine/volume, `cpp` is a touch slower than a raw filesystem `cp` since it goes through rsync's file-by-file comparison logic.
- These are shell **functions**, only active in interactive zsh sessions that load this plugin. Scripts, other shells, or subprocesses calling `mv`/`cp` directly are unaffected (by design — your real `cp`/`mv` binaries are never touched).

## License

MIT
