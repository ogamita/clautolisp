# Does EPURE's own API answer inside an alfe session?
#
# pjb, 2026-09-25, before closing alfe-plugin-epure-windows-validation:
#
#   TRUSTEDPATHS=... alfe -norc --quiet --$cad --epure \
#     -x '(print (= "" (toutes_options nil)))' \
#     -x '(print (equal (quote ((enabled) (message))) (f_DateHeure_UTC 0)))'
#
# must print T twice. Reaching READY only says EPURE LOADED; this says
# its functions answer, which is what --epure is for.
#
# Separate from verify-epure-windows.ps1, which asks about the LAUNCH.
# That script grew to six CAD launches and ran past the job's 30 minute
# limit before reaching these runs, so the question that matters now has
# a job of its own: one launch per CAD, twice (as typed, and from a
# file).
#
# Start-Process with redirected output, not a pipeline, because both
# alternatives failed on this runner: piping swallowed alfe's output
# entirely, and sharing the console let a control event from the CAD
# break PowerShell into its debugger and kill the run (exit 0xC000013A).
# A separate process with files for stdout and stderr is immune to both,
# and still has the output when the run is killed.

$ErrorActionPreference = 'Continue'

$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) { Write-Host "alfe-sbcl.exe not built at $alfe"; exit 2 }

$timeout = $env:EPURE_API_TIMEOUT
if (-not $timeout) { $timeout = '600' }
$cads = if ($env:EPURE_CADS) { $env:EPURE_CADS -split '[,\s]+' } else { @('autocad', 'bricscad') }

# EPURE's directories, so a SECURELOAD-restricted session may load them.
$epureDirs = @("$env:APPDATA\SNCF\Epure\Epure 2022_b", "$env:APPDATA\SNCF\Epure\Epure 2022")
$env:TRUSTEDPATHS = (@($env:TRUSTEDPATHS) + $epureDirs | Where-Object { $_ }) -join ';'
Write-Host "TRUSTEDPATHS=$env:TRUSTEDPATHS"

$expr1 = '(print (= "" (toutes_options nil)))'
$expr2 = '(print (equal (quote ((enabled) (message))) (f_DateHeure_UTC 0)))'

$apiFile = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-epure-api.lsp'
"$expr1`r`n$expr2`r`n" | Set-Content -Path $apiFile -Encoding ASCII

$work = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-epure-api-out'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$summary = @()

function Run-Alfe([string]$label, [string[]]$arguments) {
    $out = Join-Path $work 'stdout.txt'
    $err = Join-Path $work 'stderr.txt'
    Remove-Item $out, $err -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "=== $label"
    Write-Host "    alfe $($arguments -join ' ')"
    $proc = Start-Process -FilePath $alfe -ArgumentList $arguments -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError $err -WindowStyle Hidden
    if (-not $proc) { Write-Host "    (alfe did not start at all)"; return }
    Write-Host "    pid $($proc.Id)"
    $proc | Wait-Process -Timeout ([int]$timeout) -ErrorAction SilentlyContinue
    # Refresh(), or ExitCode reads as empty on a PassThru object -- which
    # is how the first run of this script reported `exit ' and left no
    # way to tell whether alfe had run at all.
    $proc.Refresh()
    if (-not $proc.HasExited) {
        Write-Host "    (still running after $timeout s; ending it)"
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $proc.Refresh()
    }
    $status = if ($proc.HasExited) { $proc.ExitCode } else { 'killed' }
    $stdout = if (Test-Path $out) { Get-Content $out -Raw } else { '' }
    $stderr = if (Test-Path $err) { Get-Content $err -Raw } else { '' }
    Write-Host ("--- stdout ({0} bytes)" -f $stdout.Length)
    Write-Host $stdout
    Write-Host ("--- stderr ({0} bytes)" -f $stderr.Length)
    Write-Host $stderr
    $ts = ([regex]::Matches("$stdout`n$stderr", '(?m)^\s*T\s*$')).Count
    Write-Host "--- exit $status, T printed $ts time(s)"
    $script:summary += [pscustomobject]@{ Label = $label; Exit = $status; Ts = $ts }
    # Leave no CAD behind for the next run.
    Get-Process bricscad, acad -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 5
}

foreach ($cad in $cads) {
    # As pjb types it.
    Run-Alfe "--$cad --epure, -x as typed" `
        @('-norc', '--quiet', "--$cad", '--epure', '-x', $expr1, '-x', $expr2)
    # The same, from a file and with alfe's diagnostics on: --quiet hides
    # exactly what is needed when the answer is not T.
    Run-Alfe "--$cad --epure, from a file (verbose)" `
        @('-norc', '--debug', "--$cad", '--epure', '-l', $apiFile)
}

Write-Host ""
Write-Host "================ summary (T twice is the pass)"
foreach ($row in $summary) {
    Write-Host ("  {0,-34} : exit {1}, T x{2}" -f $row.Label, $row.Exit, $row.Ts)
}
exit @($summary | Where-Object { $_.Ts -lt 2 }).Count
