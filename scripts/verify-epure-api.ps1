# Is EPURE's function library loaded inside an alfe session?
#
#   TRUSTEDPATHS=... alfe -norc --quiet --$cad --epure \
#     -x '(print (and (car (atoms-family 1 (quote ("com_way"))))))' \
#     -x '(print (and (car (atoms-family 1 (quote ("com_tl_continu"))))))'
#
# must print T twice.
#
# WHY THESE TWO, and why an existence test rather than a call (pjb, 2026-09-28:
# "let's use atoms-family on com_way and com_tl_continu. Replace the tests to
# validate."). The previous pair -- toutes_options and f_DateHeure_UTC -- were
# real EPURE API, but both are defined in COM/gestsauv/Sauvprm.lsp, the
# save-parameters DIALOG module, which EPURE loads when that dialog is opened and
# a fresh session has not loaded yet. The census in epure-symbol-probe.lsp found
# them absent on BOTH engines while their sibling Sauvegrd.lsp, and the rest of
# the startup layer, were present (alfe-plugin-epure-windows-validation). So the
# test was failing on a module boundary, not on EPURE.
#
# com_way and com_tl_continu both live in COM/lisp/SNCF_Com.lsp, which the
# census found loaded on AutoCAD and on BricsCAD. ATOMS-FAMILY asks whether they
# exist without CALLING them: com_way would otherwise search the path for
# EPURE's own CUI and cache the root in a global, and loops forever if the CUI
# is missing -- a test must not be able to hang on the thing it is testing.
#
# `(and (car ...))' because ATOMS-FAMILY returns the name, or nil in its place,
# and AND turns a non-nil name into the T the summary counts. `(quote ...)'
# rather than a quote mark, because the whole expression sits inside a
# PowerShell single-quoted string.
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

$expr1 = '(print (and (car (atoms-family 1 (quote ("com_way"))))))'
$expr2 = '(print (and (car (atoms-family 1 (quote ("com_tl_continu"))))))'

# The TWO VARIANTS below are a test of argument passing as much as of EPURE.
# The file variant is quote-safe: Set-Content writes the text verbatim. The
# as-typed variant goes through the command line, which Run-Alfe builds itself
# (Quote-WinArg): on 2026-09-28 Start-Process given an ARRAY split every
# expression at its spaces, and both engines' -x runs printed nothing (exit 1)
# while their file runs found the functions. So if the file run prints T twice
# and the as-typed run does not, look at the `alfe ...' line above it first --
# it is the exact command line alfe was given.

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

# One argument, quoted so that the C runtime's argv parser (the
# CommandLineToArgvW rules) hands it back unchanged. Windows PowerShell's
# Start-Process joins an -ArgumentList ARRAY with spaces and quotes nothing,
# so on 2026-09-28 alfe received `(print', `(and', ... as separate arguments
# and both -x runs printed nothing (exit 1) -- while the same expressions from
# a file printed T twice. Backslashes are literal except before a double
# quote, where 2n+1 of them make n backslashes and a quote.
function Quote-WinArg([string]$arg) {
    if ($arg -ne '' -and $arg -notmatch '[\s"]') { return $arg }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $slashes = 0
    foreach ($c in $arg.ToCharArray()) {
        if ($c -eq '\') { $slashes++; continue }
        if ($c -eq '"') {
            [void]$sb.Append('\' * (2 * $slashes + 1))
        } elseif ($slashes -gt 0) {
            [void]$sb.Append('\' * $slashes)
        }
        $slashes = 0
        [void]$sb.Append($c)
    }
    # Before the closing quote, every backslash has to be doubled.
    [void]$sb.Append('\' * (2 * $slashes))
    [void]$sb.Append('"')
    return $sb.ToString()
}

# pjb, 2026-09-28: `alfe --$CAD --epure -x ...' works "when no other cad is
# running". Stop-Process only ASKS; an AutoCAD still exiting when the next one
# starts made the COM bridge give up at BOOTING (exit 4, ATTACHED=0
# CREATED=0). So wait until no CAD process is left, not a fixed 5 s.
function Wait-NoCad([int]$seconds = 120) {
    $deadline = (Get-Date).AddSeconds($seconds)
    while ($true) {
        $left = @(Get-Process bricscad, acad, accoreconsole -ErrorAction SilentlyContinue)
        if ($left.Count -eq 0) { return }
        if ((Get-Date) -gt $deadline) {
            Write-Host ("    (still running after {0} s: {1})" -f $seconds,
                (($left | ForEach-Object { "$($_.Name) $($_.Id)" }) -join ', '))
            return
        }
        $left | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 2
    }
}

function Run-Alfe([string]$label, [string[]]$arguments, [bool]$verdict = $true) {
    $out = Join-Path $work 'stdout.txt'
    $err = Join-Path $work 'stderr.txt'
    Remove-Item $out, $err -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "=== $label"
    Wait-NoCad
    # A single string, so Start-Process passes it through as is -- and what
    # is printed is exactly the command line alfe gets.
    $commandLine = ($arguments | ForEach-Object { Quote-WinArg $_ }) -join ' '
    Write-Host "    alfe $commandLine"
    $proc = Start-Process -FilePath $alfe -ArgumentList $commandLine -PassThru `
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
    Wait-NoCad
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
