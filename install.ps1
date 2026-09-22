$repo = $PSScriptRoot
Get-ChildItem $repo -Directory | Where-Object Name -ne '.git' | ForEach-Object {
    $pkg = $_.FullName

    # A package can override its destination with a .target file holding a
    # base path, e.g. $env:APPDATA\alacritty. Default is $HOME.
    $targetFile = Join-Path $pkg '.target'
    $base = if (Test-Path $targetFile)
    {
        $ExecutionContext.InvokeCommand.ExpandString((Get-Content $targetFile -Raw).Trim())
    } else
    { $HOME 
    }

    Get-ChildItem $pkg -File -Recurse -Force |
        Where-Object { $_.Name -ne '.target' } | ForEach-Object {
            $rel    = $_.FullName.Substring($pkg.Length + 1)
            $target = Join-Path $base $rel
            New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
            if (Test-Path $target)
            { Remove-Item $target -Force 
            }
            New-Item -ItemType SymbolicLink -Path $target -Target $_.FullName | Out-Null
            Write-Host "linked $target"
        }
    }

