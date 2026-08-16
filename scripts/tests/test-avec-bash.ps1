# test-avec-bash.ps1 --- exercise scripts/avec-bash.ps1 without Windows.
#
# avec-bash.ps1 is the one piece of the Windows release lane that cannot be
# run on the build host, and a fault in it fails the lane on the runner. This
# checks what IS checkable off Windows:
#
#   - it parses;
#   - AVEC_BASH selects the interpreter;
#   - the wrapped script actually runs, with its arguments;
#   - THE EXIT CODE IS PROPAGATED, both zero and non-zero. That is the
#     property git-bash.exe silently destroys (it detaches and returns at
#     once), and the reason the launcher exists at all.
#
# What it does NOT check, and cannot: the C:\msys64 probing, MSYSTEM
# selection, MSYS2_PATH_TYPE=inherit, and the CC conversion at the process
# boundary. Those need the real machine -- hence the lane's SHAKEDOWN mark.
#
# Run it in a PowerShell-capable container (pjb, 2026-08-16 -- powershell is
# not installed on the build host):
#
#   docker run --rm -v "$PWD:/w" -w /w mcr.microsoft.com/powershell:debian-12 \
#          pwsh -NoProfile -File scripts/tests/test-avec-bash.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$avecBash = Join-Path $root 'scripts/avec-bash.ps1'
$status = 0

function Verifier($nom, $attendu, $obtenu) {
    if ($attendu -eq $obtenu) {
        Write-Output "ok  $nom (exit $obtenu)"
    } else {
        Write-Output "FAIL: $nom -- expected $attendu, got $obtenu"
        $script:status = 1
    }
}

# A bash that exists on this host stands in for MSYS2's.
$env:AVEC_BASH = '/bin/bash'

$tmp = [System.IO.Path]::GetTempPath()
$ok  = Join-Path $tmp 'avec-bash-ok.sh'
$ko  = Join-Path $tmp 'avec-bash-ko.sh'
Set-Content -Path $ok -Value "#!/bin/sh`necho `"ran with: `$*`"`nexit 0`n"
Set-Content -Path $ko -Value "#!/bin/sh`nexit 3`n"

$sortie = & $avecBash $ok 'un' 'deux' 2>&1
Verifier 'success propagates 0' 0 $LASTEXITCODE
if ($sortie -match 'ran with: un deux') {
    Write-Output 'ok  the wrapped script runs and receives its arguments'
} else {
    Write-Output "FAIL: arguments not passed through -- output was: $sortie"
    $status = 1
}

& $avecBash $ko 2>&1 | Out-Null
Verifier 'failure propagates the exit code' 3 $LASTEXITCODE

# No AVEC_BASH and no MSYS2/Git on this host: the launcher must say so and
# exit 127 rather than pretend it worked.
Remove-Item Env:AVEC_BASH
$env:PATH = '/nonexistent'
& $avecBash $ok 2>&1 | Out-Null
Verifier 'missing bash reports 127' 127 $LASTEXITCODE

exit $status
