$dir = "$env:APPDATA\alacritty"
$current = Get-Content "$dir\theme.toml" -Raw
$next = if ($current -match '# theme: dark') { 'light' } else { 'dark' }
Copy-Item "$dir\themes\$next.toml" "$dir\theme.toml" -Force
$next | Set-Content "$env:LOCALAPPDATA\nvim\theme-state"
