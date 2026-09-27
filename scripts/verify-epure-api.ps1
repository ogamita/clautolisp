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

# The symbol probe travels with the repository rather than being inlined here:
# it is AutoLISP, it is long enough to deserve its own comments, and it is
# verifiable OFF Windows -- running it under clautolisp (which has no EPURE)
# must report verdict=nothing-defined, which is the negative control for the
# case this job is trying to distinguish.
$probeFile = Join-Path $PSScriptRoot 'epure-symbol-probe.lsp'
if (-not (Test-Path $probeFile)) {
    Write-Host "epure-symbol-probe.lsp missing at $probeFile"; exit 2
}

$work = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-epure-api-out'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$summary = @()

function Run-Alfe([string]$label, [string[]]$arguments, [bool]$verdict = $true) {
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
    # The symbol probe is a DIAGNOSTIC, not a verdict: it prints EPURE-PROBE
    # lines and never two Ts, so counting it would fail the job for answering
    # the question it was added to answer.
    $script:summary += [pscustomobject]@{ Label = $label; Exit = $status; Ts = $ts; Verdict = $verdict }
    if (-not $verdict) {
        $probeLines = ([regex]::Matches("$stdout`n$stderr", '(?m)^EPURE-PROBE .*$'))
        if ($probeLines.Count -eq 0) {
            Write-Host "--- WARNING: the symbol probe printed no EPURE-PROBE line at all"
            Write-Host "    (so it did not run -- that is itself the finding, not a pass)"
        } else {
            foreach ($m in $probeLines) { Write-Host ("--- {0}" -f $m.Value) }
        }
    }
    # Leave no CAD behind for the next run.
    Get-Process bricscad, acad -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 5
}

foreach ($cad in $cads) {
    # FIRST, the diagnostic: does EPURE define ANYTHING here?
    #
    # On 2026-09-27 three invocations reached READY and all failed with "no
    # function definition: TOUTES_OPTIONS", which says the API is absent but
    # not WHY -- EPURE never loaded, or loaded out of view, or loaded under
    # other names. Those are different fixes, so asking the session directly
    # comes before asking it to call the functions. ATOMS-FAMILY, not a call:
    # vl-catch-all-apply cannot trap an unbound symbol.
    Run-Alfe "--$cad --epure, symbol probe (diagnostic)" `
        @('-norc', '--debug', "--$cad", '--epure', '-l', $probeFile) $false
    # As pjb types it.
    Run-Alfe "--$cad --epure, -x as typed" `
        @('-norc', '--quiet', "--$cad", '--epure', '-x', $expr1, '-x', $expr2)
    # The same, from a file and with alfe's diagnostics on: --quiet hides
    # exactly what is needed when the answer is not T.
    Run-Alfe "--$cad --epure, from a file (verbose)" `
        @('-norc', '--debug', "--$cad", '--epure', '-l', $apiFile)
}

Write-Host ""
Write-Host "================ summary (T twice is the pass; probe rows are diagnostics)"
foreach ($row in $summary) {
    $kind = if ($row.Verdict) { 'verdict ' } else { 'diagnostic' }
    Write-Host ("  {0,-42} : {1} exit {2}, T x{3}" -f $row.Label, $kind, $row.Exit, $row.Ts)
}
# Only the verdict rows decide the exit code. A diagnostic row never prints two
# Ts -- counting it would fail the job for answering its own question.
exit @($summary | Where-Object { $_.Verdict -and $_.Ts -lt 2 }).Count
