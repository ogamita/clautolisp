# Report what this Windows host's registry says about AutoCAD's COM
# servers, and what alfe resolves from it.
#
# Ground truth for alfe-autocad-progid-registry-probe-fails: alfe said
# "AutoCAD.Application.24.1: not-registered" on a host where that ProgID
# activates AutoCAD 2022. This prints the same queries alfe runs, the raw
# reg.exe output, and alfe's own resolution -- so the two can be compared
# instead of guessed at.
#
# Launches nothing: --print-command stages a run and prints the command
# line without starting AutoCAD.

$ErrorActionPreference = 'Continue'

function Show-Reg([string]$label, [string[]]$arguments) {
    Write-Host ""
    Write-Host "=== $label"
    Write-Host "--- reg $($arguments -join ' ')"
    & reg.exe @arguments 2>&1 | Out-String | Write-Host
    Write-Host "--- exit $LASTEXITCODE"
}

Write-Host "=== console code page"
& chcp.com 2>&1 | Out-String | Write-Host

Show-Reg "control value (alfe's registry-readable probe)" `
    @('query', 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion', '/v', 'ProductName')
Show-Reg "generic ProgID" @('query', 'HKCR\AutoCAD.Application\CLSID', '/ve')
Show-Reg "registered AutoCAD ProgIDs" `
    @('query', 'HKCR', '/f', 'AutoCAD.Application', '/k')

foreach ($version in @('24.1', '24.2', '24.3', '25.0', '25.1')) {
    $progid = "AutoCAD.Application.$version"
    Show-Reg "$progid" @('query', "HKCR\$progid\CLSID", '/ve')
    $clsid = (& reg.exe query "HKCR\$progid\CLSID" /ve 2>$null |
              Select-String 'REG_SZ' |
              ForEach-Object { ($_ -split 'REG_SZ')[-1].Trim() } |
              Select-Object -First 1)
    if ($clsid) {
        Show-Reg "$progid LocalServer32" `
            @('query', "HKCR\CLSID\$clsid\LocalServer32", '/ve')
    }
}

Write-Host ""
Write-Host "=== alfe's own resolution (--print-command starts no AutoCAD)"
$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) {
    Write-Host "alfe-sbcl.exe not built at $alfe"
    exit 0
}
foreach ($selection in @('autocad', 'autocad-2022')) {
    Write-Host ""
    Write-Host "--- alfe --cad $selection --mode automation --print-command"
    & $alfe --no-init --debug --cad $selection --mode automation `
        --print-command -x '(princ 1)' 2>&1 | Out-String | Write-Host
    Write-Host "--- exit $LASTEXITCODE"
}
exit 0
