# Run alfe --epure against the real CADs on the Windows runner.
#
# alfe-plugin-epure-windows-validation.issue: the EPURE plug-in is
# asserted only against the mock CAD, --print-command and an OS
# override. Two assumptions came from the legacy wrapper and have never
# been re-verified on a machine with EPURE installed:
#
#   1. a ._SCRIPT nested inside a /b script gives control back to the
#      outer script, so the line after it -- (load run-common.lsp) --
#      still runs;
#   2. under AutoCAD COM, SendCommand("._SCRIPT ...") followed by
#      SendCommand("(load ...)") runs them in that order.
#
# This does not assume either. It runs the thing and keeps everything:
# the emitted run.scr / bridge-*.vbs, the protocol files, the debug
# trace. Whether the plug-in needs changing is decided from that output,
# not from here.
#
# A PROBE, not a gate: it reports, and its own exit status is the CAD
# run's, so a failure is visible without being hidden.

$ErrorActionPreference = 'Continue'

$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) { Write-Host "alfe-sbcl.exe not built at $alfe"; exit 2 }

$timeout = $env:EPURE_TIMEOUT
if (-not $timeout) { $timeout = '300' }

# Which CADs to try. EPURE_CADS overrides, e.g. 'autocad' alone.
$cads = if ($env:EPURE_CADS) { $env:EPURE_CADS -split '[,\s]+' } else { @('autocad', 'bricscad') }

$marker = 'EPURE.MARKER.OK'
$probe = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-epure-probe.lsp'
"(progn (princ `"$marker`") (princ))" | Set-Content -Path $probe -Encoding ASCII

$summary = @()

# Each CAD runs TWICE: with --epure and without. The control run is what
# makes the EPURE result mean anything. On 2026-09-25 BricsCAD sat at
# BOOTING under --epure and run-scr-started.txt was never written, i.e.
# run.scr never began -- which is BEFORE anything EPURE adds to it.
# Whether plain --bricscad starts that same script on this machine is
# then the question, and only a control run answers it.
$runs = @()
foreach ($cad in $cads) {
    $runs += [pscustomobject]@{ Cad = $cad; Epure = $true;  Mode = '' }
    $runs += [pscustomobject]@{ Cad = $cad; Epure = $false; Mode = '' }
}
# BricsCAD under EPURE begins run.scr and then stops at the nested
# ._SCRIPT: control never comes back, so the (load run-common.lsp) after
# it never runs. COM SendCommand is the alternative the ticket names --
# the one AutoCAD already takes, and the VBS branch of the plug-in has
# always emitted it. Whether it works on BricsCAD has never been run, so
# it is asked here rather than assumed, BEFORE the default is changed.
$runs += [pscustomobject]@{ Cad = 'bricscad'; Epure = $true; Mode = 'automation' }

foreach ($run in $runs) {
    $cad = $run.Cad
    $label = if ($run.Epure) { "--$cad --epure" } else { "--$cad (control, no --epure)" }
    if ($run.Mode) { $label = "$label --mode $($run.Mode)" }
    Write-Host ""
    Write-Host "================ alfe $label"
    $out = if ($run.Epure -and $run.Mode) {
        & $alfe --no-init --debug --$cad --epure --mode $run.Mode --timeout $timeout `
            --keep-workdir -l $probe 2>&1 | Out-String
    } elseif ($run.Epure) {
        & $alfe --no-init --debug --$cad --epure --timeout $timeout `
            --keep-workdir -l $probe 2>&1 | Out-String
    } else {
        & $alfe --no-init --debug --$cad --timeout $timeout `
            --keep-workdir -l $probe 2>&1 | Out-String
    }
    $status = $LASTEXITCODE
    Write-Host $out
    Write-Host "--- alfe exit $status"

    $sawMarker = $out -match [regex]::Escape($marker)
    $summary += [pscustomobject]@{ Label = $label; Exit = $status; Marker = $sawMarker }

    # Everything the plug-in emitted, which is what the two assumptions
    # are about.
    $workdir = ($out -split "`n" | Where-Object { $_ -match 'workdir = (\S+)' } |
                Select-Object -First 1)
    if ($workdir -match 'workdir = (\S+)') {
        $dir = $Matches[1].Trim()
        $started = Test-Path (Join-Path $dir 'run-scr-started.txt')
        Write-Host ("--- run.scr began: {0}" -f $(if ($started) { 'YES' } else { 'NO' }))
        Write-Host ""
        Write-Host "--- artefacts in $dir"
        # run-scr-started.txt is written by the FIRST line of run.scr, so
        # its presence separates "the script never ran" from "the nested
        # ._SCRIPT never gave control back" -- the two readings of a
        # BricsCAD that sits at BOOTING.
        foreach ($name in @('run.scr', 'run-scr-started.txt',
                            'bridge-autocad.vbs', 'bridge-bricscad.vbs',
                            'bridge-vbs.log', 'run-common.lsp',
                            'protocol\status.txt', 'protocol\stdout.txt',
                            'protocol\stderr.txt')) {
            $file = Join-Path $dir $name
            if (Test-Path $file) {
                Write-Host ""
                Write-Host "----- $name"
                Get-Content $file -ErrorAction SilentlyContinue |
                    Select-Object -First 60 | Out-String | Write-Host
            }
        }
        Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
    } else {
        Write-Host "--- no workdir reported (the run did not get that far)"
    }
}

Write-Host ""
Write-Host "================ summary"
foreach ($row in $summary) {
    Write-Host ("  {0,-34} : exit {1}, marker {2}" -f `
        $row.Label, $row.Exit, $(if ($row.Marker) { 'PRESENT' } else { 'ABSENT' }))
}

# The question asked of this job is "what happens", so a CAD that is not
# installed is not a failure; a CAD that ran and did not reach the
# marker is.
$bad = @($summary | Where-Object {
    $_.Label -match '--epure$' -and $_.Exit -eq 0 -and -not $_.Marker }).Count
exit $bad
