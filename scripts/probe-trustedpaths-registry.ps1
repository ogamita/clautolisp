# probe-trustedpaths-registry.ps1 -- WHERE does each CAD keep TRUSTEDPATHS?
#
# READ-ONLY: it runs `reg query' and nothing else, and launches no CAD.
#
# alfe-cad-workdir-not-in-trustedpaths (pjb, 2026-09-28: "add to
# TRUSTEDPATHS for the run and restore after"): alfe must add its workdir to
# the CAD profile's TRUSTEDPATHS BEFORE launching the CAD, because the first
# thing the CAD loads (run-common.lsp) is itself a gated load under
# SECURELOAD=2. That needs the registry location, which nothing in the
# repository knows yet -- this measures it instead of guessing.
#
# Reports, for HKCU\Software\Autodesk and HKCU\Software\Bricsys:
#   - the CurVer chain (release, product) and the current profile name;
#   - every value named TRUSTEDPATHS / SECURELOAD, with its key and type.
# Output goes to the job log and to dist/trustedpaths-registry/report.txt.

$ErrorActionPreference = 'Continue'
$out = Join-Path (Get-Location) 'dist/trustedpaths-registry'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$report = Join-Path $out 'report.txt'
Set-Content -Path $report -Value "# TRUSTEDPATHS registry probe $(Get-Date -Format o) on $env:COMPUTERNAME" -Encoding UTF8

function Say([string] $line) {
    Write-Host $line
    Add-Content -Path $report -Value $line -Encoding UTF8
}

function Reg([string[]] $argv) {
    Say "## reg $($argv -join ' ')"
    $text = & reg.exe @argv 2>&1 | Out-String
    Say "exit=$LASTEXITCODE"
    foreach ($l in ($text -split "`r?`n")) { if ($l.Trim()) { Say $l } }
}

# AutoCAD: HKCU\Software\Autodesk\AutoCAD  CurVer -> R24.x ; R24.x CurVer -> ACAD-xxxx:xxx
Reg @('query', 'HKCU\Software\Autodesk\AutoCAD', '/v', 'CurVer')
$rel = (& reg.exe query 'HKCU\Software\Autodesk\AutoCAD' /v CurVer 2>$null | Select-String 'REG_') -replace '.*REG_\w+\s+', ''
if ($rel) {
    Reg @('query', "HKCU\Software\Autodesk\AutoCAD\$rel", '/v', 'CurVer')
    $prod = (& reg.exe query "HKCU\Software\Autodesk\AutoCAD\$rel" /v CurVer 2>$null | Select-String 'REG_') -replace '.*REG_\w+\s+', ''
    if ($prod) {
        Reg @('query', "HKCU\Software\Autodesk\AutoCAD\$rel\$prod\Profiles", '/ve')
        Reg @('query', "HKCU\Software\Autodesk\AutoCAD\$rel\$prod\Profiles")
    }
}

foreach ($root in 'HKCU\Software\Autodesk', 'HKCU\Software\Bricsys', 'HKLM\SOFTWARE\Autodesk', 'HKLM\SOFTWARE\Bricsys') {
    foreach ($name in 'TRUSTEDPATHS', 'SECURELOAD') {
        # /f NAME /v /e : exact value-name match, searched recursively (/s)
        Reg @('query', $root, '/s', '/f', $name, '/v', '/e')
    }
}

# BricsCAD: its version/locale/profile layout, for the same purpose
Reg @('query', 'HKCU\Software\Bricsys\BricsCAD')
Say "# done"
exit 0
