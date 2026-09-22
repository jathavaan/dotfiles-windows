$sessions = @(tmux ls 2>$null | ForEach-Object { ($_ -split ':', 2)[0] } | Where-Object { $_ })

# No border here: the psmux popup already draws one around it.
$choice = $sessions | fzf `
    --reverse --border none --no-separator --padding 1,2 `
    --prompt '❯ ' --pointer '▌' `
    --info inline-right `
    --color 'bg:-1,bg+:0,fg:-1,fg+:-1,gutter:-1' `
    --color 'hl:#817c9c,hl+:#817c9c,pointer:#817c9c,prompt:#817c9c' `
    --color 'info:8,header:8,label:#817c9c'

if ($choice)
{
    tmux switch-client -t $choice
}
