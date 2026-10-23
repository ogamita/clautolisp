# Exercise the probe's real path allocation and cleanup without starting CAD.
param([string] $Source = (Join-Path $PSScriptRoot '../probe-cad-instances.ps1'))
$ErrorActionPreference = 'Stop'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path $source).Path, [ref] $tokens, [ref] $errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($name in @('New-CadInstDrawingPaths', 'Remove-CadInstDrawingPaths')) {
    $definition = $ast.Find({ param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq $name
    }, $true)
    if (-not $definition) { throw "Missing probe helper: $name" }
    Invoke-Expression $definition.Extent.Text
}
$root = Join-Path ([IO.Path]::GetTempPath()) "cadinst-path-test-$([Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $root | Out-Null
try {
    foreach ($backend in @('autocad', 'bricscad')) {
        # Same PID, backend and TEMP: a PID-only prefix would still collide.
        $first = New-CadInstDrawingPaths $backend $root
        $second = New-CadInstDrawingPaths $backend $root
        $paths = @($first.Drawings.Values) + @($second.Drawings.Values)
        if (@($paths | Sort-Object -Unique).Count -ne 4) { throw 'Drawing path collision' }
        if (@($paths | ForEach-Object { Split-Path -Leaf $_ } | Sort-Object -Unique).Count -ne 4) {
            throw 'Drawing filename collision'
        }
        $legacy = Join-Path $root "cadinst-$backend-A.dwg"
        Set-Content -LiteralPath $legacy -Value 'other instance'
        foreach ($path in $paths) {
            foreach ($extension in @('.dwg', '.dwl', '.dwl2')) {
                Set-Content -LiteralPath ([IO.Path]::ChangeExtension($path, $extension)) -Value 'owned'
            }
        }
        Remove-CadInstDrawingPaths $first
        if (Test-Path $first.Directory) { throw 'First private directory was not removed' }
        foreach ($path in $second.Drawings.Values) {
            foreach ($extension in @('.dwg', '.dwl', '.dwl2')) {
                if (-not (Test-Path ([IO.Path]::ChangeExtension($path, $extension)))) {
                    throw 'Cleanup touched another probe'
                }
            }
        }
        $unexpected = Join-Path $second.Directory 'preserve.txt'
        Set-Content -LiteralPath $unexpected -Value 'preserve'
        Remove-CadInstDrawingPaths $second
        if (-not (Test-Path $unexpected)) { throw 'Cleanup removed an unexpected file' }
        if ((Get-Content -LiteralPath $legacy) -ne 'other instance') { throw 'Legacy drawing changed' }
        Write-Output "PASS $backend : unique names and paths; cleanup preserves other drawings and locks"
    }
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force
}
