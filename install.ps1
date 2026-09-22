$repo = $PSScriptRoot
Get-ChildItem $repo -Directory | Where-Object Name -ne '.git' | ForEach-Object {
    $pkg = $_.FullName
    Get-ChildItem $pkg -File -Recurse -Force | ForEach-Object {
        $rel    = $_.FullName.Substring($pkg.Length + 1)
        $target = Join-Path $HOME $rel
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        if (Test-Path $target) { Remove-Item $target -Force }
        New-Item -ItemType SymbolicLink -Path $target -Target $_.FullName | Out-Null
        Write-Host "linked $target"
    }
}
