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

foreach ($cad in $cads) {
    Write-Host ""
    Write-Host "================ alfe --$cad --epure"
    $out = & $alfe --no-init --debug --$cad --epure --timeout $timeout `
        --keep-workdir -l $probe 2>&1 | Out-String
    $status = $LASTEXITCODE
    Write-Host $out
    Write-Host "--- alfe exit $status"

    $sawMarker = $out -match [regex]::Escape($marker)
    $summary += [pscustomobject]@{ Cad = $cad; Exit = $status; Marker = $sawMarker }

    # Everything the plug-in emitted, which is what the two assumptions
    # are about.
    $workdir = ($out -split "`n" | Where-Object { $_ -match 'workdir = (\S+)' } |
                Select-Object -First 1)
    if ($workdir -match 'workdir = (\S+)') {
        $dir = $Matches[1].Trim()
        Write-Host ""
        Write-Host "--- artefacts in $dir"
        foreach ($name in @('run.scr', 'bridge-autocad.vbs', 'bridge-bricscad.vbs',
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
    Write-Host ("  --{0} --epure : exit {1}, marker {2}" -f `
        $row.Cad, $row.Exit, $(if ($row.Marker) { 'PRESENT' } else { 'ABSENT' }))
}

# The question asked of this job is "what happens", so a CAD that is not
# installed is not a failure; a CAD that ran and did not reach the
# marker is.
$bad = @($summary | Where-Object { $_.Exit -eq 0 -and -not $_.Marker }).Count
exit $bad
