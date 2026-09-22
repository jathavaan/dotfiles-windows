# dotfiles-windows

Windows terminal setup: Alacritty + psmux + PowerShell 7, with Neovim-style
keybindings across every layer.

The pieces are deliberately coupled. `Alt+hjkl` moves between Neovim splits and
psmux panes without you thinking about which is which, and the colour scheme
follows a single light/dark toggle from the terminal down to the status bar and
the prompt.

Neovim lives in its own repo: [jathavaan/nvim](https://github.com/jathavaan/nvim).

## What's in here

| Package       | Installs to            | Contents                                                |
| ------------- | ---------------------- | ------------------------------------------------------- |
| `alacritty/`  | `%APPDATA%\alacritty`  | Terminal config, light/dark themes, theme toggle script |
| `powershell/` | `Documents\PowerShell` | `$PROFILE`: prompt, completions, psmux autostart        |
| `psmux/`      | `~`                    | `.psmux.conf`, `.psmux-picker.ps1` (fzf session picker) |
| `oh-my-posh/` | `~`                    | `.omp.json` — prompt theme                              |

## Install

```powershell
git clone https://github.com/jathavaan/dotfiles-windows "$HOME\Code\Misc\dotfiles-windows"
cd "$HOME\Code\Misc\dotfiles-windows"
.\install.ps1
```

`install.ps1` symlinks every file in a package folder to its destination. A
package's destination comes from its `.target` file (a single line holding a
base path); packages without one go to `~`. Symlinks require Developer Mode, or
an elevated shell.

### Dependencies

```powershell
winget install marlocarlo.psmux
winget install Alacritty.Alacritty
winget install Microsoft.PowerShell
winget install JanDeDobbeleer.OhMyPosh
winget install ajeetdsouza.zoxide
winget install junegunn.fzf
```

PowerShell modules go on local disk rather than OneDrive, because OneDrive's
Files On-Demand can hand PowerShell a placeholder file and break module loading:

```powershell
New-Item -ItemType Directory -Force "$HOME\.local\pwsh\Modules"
Save-Module PSFzf -Path "$HOME\.local\pwsh\Modules"
Save-Module Terminal-Icons -Path "$HOME\.local\pwsh\Modules"
```

A Nerd Font is required (JetBrainsMono Nerd Font here) for icons and prompt
glyphs.

## Keybindings

Prefix is `Ctrl+a`.

### Panes and splits

| Keys                | Action                                     |
| ------------------- | ------------------------------------------ |
| `Alt+h/j/k/l`       | Move between Neovim splits and psmux panes |
| `Shift+Alt+h/j/k/l` | Resize the split or pane                   |
| `prefix` `h/j/k/l`  | Move between panes (fallback, repeatable)  |
| `prefix` `H/J/K/L`  | Resize pane (repeatable)                   |
| `prefix` `v`        | Split side by side                         |
| `prefix` `s`        | Split stacked                              |
| `prefix` `q`        | Close pane                                 |
| `prefix` `o`        | Close all other panes                      |
| `prefix` `m`        | Maximize / restore                         |
| `prefix` `e`        | Equalize layout                            |
| `prefix` `x`        | Swap with next pane                        |

### Sessions and windows

| Keys                         | Action                                       |
| ---------------------------- | -------------------------------------------- |
| `prefix` `w`                 | Session picker (fzf in a popup)              |
| `prefix` `T`                 | psmux's own chooser (sessions/windows/panes) |
| `prefix` `c`                 | New window                                   |
| `prefix` `Tab` / `Shift+Tab` | Next / previous window                       |
| `prefix` `d`                 | Detach                                       |
| `prefix` `r`                 | Reload `.psmux.conf`                         |

### Shell

| Keys           | Action                             |
| -------------- | ---------------------------------- |
| `Ctrl+r`       | Fuzzy history search (PSFzf)       |
| `Ctrl+t`       | Fuzzy file search (PSFzf)          |
| `Tab`          | Menu completion                    |
| `→`            | Accept one word of the suggestion  |
| `Ctrl+Shift+T` | Toggle light/dark theme            |
| `cd <partial>` | Jump to a known directory (zoxide) |
| `cdi`          | Directory picker                   |

## How it fits together

**Alt+hjkl across Neovim and psmux.** psmux can't reliably detect what's running
in a pane, so neither the tmux `if -F` check nor the `@is_vim` pane-option
approach works here. Instead, whatever is running in the pane decides: Neovim's
`nav()` moves between splits and calls `tmux select-pane` when it's already at
the edge, and a PSReadLine key handler in `$PROFILE` calls `tmux select-pane`
directly from the shell. `.psmux.conf` binds no `Alt` keys at all.

**Theming.** `toggle-theme.ps1` copies `themes/light.toml` or `themes/dark.toml`
over `theme.toml`, which Alacritty imports and live-reloads, and writes the
choice to `%LOCALAPPDATA%\nvim\theme-state` for Neovim to read. `.psmux.conf`
and the fzf pickers use ANSI colour names rather than hex, so they resolve
against whichever palette Alacritty currently has loaded and flip with no
reload. The accent `#817c9c` is the selection colour, identical in both themes,
so it's the one value hardcoded.

`alacritty/theme.toml` is generated and gitignored; the toggle script needs it
to be a real file, not a symlink.

**Startup.** Alacritty sets `PSMUX_AUTOSTART`, and `$PROFILE` uses it to start
psmux only in shells Alacritty launched — not in psmux's own panes, and not in
IDE terminals. No sessions creates one, one session attaches to it, several
opens the fzf picker.

## Notes

- psmux is a young project; a few tmux features it doesn't support are worked
  around here. `terminal-features` is unsupported, pickers are client-side
  overlays that can't be opened from a hook or the CLI, and inline predictions
  need `set -g allow-predictions on`.
- `$PROFILE` lives under OneDrive-redirected Documents. If OneDrive ever
  replaces the symlink with a copy, replace it with a one-line profile that
  dot-sources the file in this repo.
