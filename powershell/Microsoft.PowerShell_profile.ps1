# =========================================================================
#  MODULE PATH
#  Modules live on local disk instead of OneDrive: OneDrive's Files
#  On-Demand can hand PowerShell a placeholder file, which breaks module
#  loading (Terminal-Icons' Import-Clixml in particular).
#  Install new modules with:
#    Save-Module <name> -Path "$HOME\.local\pwsh\Modules"
# =========================================================================
$env:PSModulePath = "$HOME\.local\pwsh\Modules;$env:PSModulePath"

# =========================================================================
#  ALIASES
# =========================================================================
Set-Alias c clear
Set-Alias vim nvim

# =========================================================================
#  SHELL EXPERIENCE
# =========================================================================
# Autosuggestions from history + a list of predictions (zsh-autosuggestions)
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows -BellStyle None
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardWord   # accept one word
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

Import-Module Terminal-Icons

# Prompt
oh-my-posh init pwsh --config "$HOME\.omp.json" | Invoke-Expression

# zoxide: 'cd' jumps to known directories, 'cdi' opens the picker.
Remove-Item Alias:cd -Force -ErrorAction SilentlyContinue
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })

# CLI completions
$env:DOTNET_CLI_TELEMETRY_OPTOUT = 1
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($word, $ast, $cursor)
    dotnet complete --position $cursor "$ast" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
gh completion -s powershell | Out-String | Invoke-Expression

# =========================================================================
#  TMUX / PSMUX PANE CONTROL
#  Only active inside a tmux/psmux session. psmux passes Alt keys through
#  to the shell, so PSReadLine handles them and tells tmux what to do.
#  nvim has matching keymaps (keymaps.lua) that hand off to tmux at the
#  edge, so the same keys work seamlessly across nvim splits and panes.
# =========================================================================
if ($env:TMUX -or $env:TMUX_PANE)
{
    # Alt+hjkl: move to the pane left / below / above / right
    Set-PSReadLineKeyHandler -Chord 'Alt+h' -ScriptBlock { tmux select-pane -L }
    Set-PSReadLineKeyHandler -Chord 'Alt+j' -ScriptBlock { tmux select-pane -D }
    Set-PSReadLineKeyHandler -Chord 'Alt+k' -ScriptBlock { tmux select-pane -U }
    Set-PSReadLineKeyHandler -Chord 'Alt+l' -ScriptBlock { tmux select-pane -R }

    # Shift+Alt+hjkl: resize the pane by moving its divider 5 cells
    # (PSReadLine writes Shift+Alt+h as 'Alt+H')
    Set-PSReadLineKeyHandler -Chord 'Alt+H' -ScriptBlock { tmux resize-pane -L 5 }
    Set-PSReadLineKeyHandler -Chord 'Alt+J' -ScriptBlock { tmux resize-pane -D 5 }
    Set-PSReadLineKeyHandler -Chord 'Alt+K' -ScriptBlock { tmux resize-pane -U 5 }
    Set-PSReadLineKeyHandler -Chord 'Alt+L' -ScriptBlock { tmux resize-pane -R 5 }
}

# =========================================================================
#  PSMUX AUTOSTART
#  Runs only in shells started by Alacritty (PSMUX_AUTOSTART is set in
#  alacritty.toml) and only outside tmux, so shells inside psmux panes and
#  IDE terminals skip it.
#   - no sessions  -> create a new one
#   - one session  -> attach to it
#   - several      -> pick one with fzf (Esc = most recently used)
# =========================================================================
if ($env:PSMUX_AUTOSTART -and -not ($env:TMUX -or $env:TMUX_PANE))
{
    # Session names from "tmux ls" (format: "name: N windows ...")
    $sessions = @(tmux ls 2>$null | ForEach-Object { ($_ -split ':', 2)[0] } | Where-Object { $_ })

    if ($sessions.Count -eq 0)
    {
        tmux new-session
    } elseif ($sessions.Count -eq 1)
    {
        tmux attach-session -t $sessions[0]
    } else
    {
        # Styled session picker (fzf) shown before attaching.
        # Colors use ANSI numbers (-1 = terminal default), so they follow the
        # Alacritty light/dark theme.
        $choice = @($sessions) + '+ New session' | fzf `
            --reverse --border rounded --padding 1,2 `
            --border-label ' psmux sessions ' --border-label-pos 3 `
            --prompt '❯ ' --pointer '▌' --separator '─' `
            --info inline-right `
            --header 'enter attach · esc most recent · type to filter' `
            --color 'bg:-1,bg+:0,fg:-1,fg+:-1,gutter:-1' `
            --color 'hl:#817c9c,hl+:#817c9c,pointer:#817c9c,prompt:#817c9c' `
            --color 'info:8,header:8,border:8,label:#817c9c,separator:8' `
            --color 'preview-border:8,preview-label:8' `
            --preview 'tmux capture-pane -p -t {}' `
            --preview-label ' preview ' `
            --preview-window 'right,65%,border-rounded'

        if ($choice -eq '+ New session')
        {
            tmux new-session
        } elseif ($choice)
        {
            tmux attach-session -t $choice
        } else
        {
            tmux attach-session   # Esc = most recently used session
        }
    }

    # Close the Alacritty window when you detach or the session ends.
    # Remove this line if you'd rather drop back to a plain shell.
    exit
} 
