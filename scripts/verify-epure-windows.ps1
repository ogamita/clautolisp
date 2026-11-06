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
# BricsCAD gets longer: a cold start that also loads EPURE's CUIX and
# menus is not a 300 s proposition, and a timeout that is merely too
# short looks exactly like a hang.
$bricscadTimeout = $env:EPURE_BRICSCAD_TIMEOUT
if (-not $bricscadTimeout) { $bricscadTimeout = '600' }

# Which CADs to try. EPURE_CADS overrides, e.g. 'autocad' alone.
$cads = if ($env:EPURE_CADS) { $env:EPURE_CADS -split '[,\s]+' } else { @('autocad', 'bricscad') }

$marker = 'EPURE.MARKER.OK'
$probe = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-epure-probe.lsp'
"(progn (princ `"$marker`") (princ))" | Set-Content -Path $probe -Encoding ASCII

$summary = @()

Write-Host ""
Write-Host "================ what the EPURE control scripts contain"
foreach ($year in @('Epure 2022_b', 'Epure 2022', 'epure 2022_b', 'epure 2022')) {
    $control = Join-Path $env:APPDATA "sncf\epure\$year\control_path_epure_2022.scr"
    if (Test-Path $control) {
        Write-Host ""
        Write-Host "----- $control (first 40 lines)"
        Get-Content $control -ErrorAction SilentlyContinue |
            Select-Object -First 40 | Out-String | Write-Host
    } else {
        Write-Host "----- $control : absent"
    }
}

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
$runs += [pscustomobject]@{ Cad = 'bricscad'; Epure = $true;  Mode = 'automation' }
# ... and its control. The automation run above hung with the bridge log
# holding one line, "[VBS] bridge start; commode=auto", so it never got
# past attach/create -- nowhere near anything EPURE adds. Whether
# BricsCAD COM automation works AT ALL on this machine is therefore the
# question, and only a run without --epure answers it.
$runs += [pscustomobject]@{ Cad = 'bricscad'; Epure = $false; Mode = 'automation' }

foreach ($run in $runs) {
    $cad = $run.Cad
    $label = if ($run.Epure) { "--$cad --epure" } else { "--$cad (control, no --epure)" }
    if ($run.Mode) { $label = "$label --mode $($run.Mode)" }
    Write-Host ""
    Write-Host "================ alfe $label"
    $t = if ($cad -eq 'bricscad') { $bricscadTimeout } else { $timeout }
    $out = if ($run.Epure -and $run.Mode) {
        & $alfe --no-init --debug --$cad --epure --mode $run.Mode --timeout $t `
            --keep-workdir -l $probe 2>&1 | Out-String
    } elseif ($run.Epure) {
        & $alfe --no-init --debug --$cad --epure --timeout $t `
            --keep-workdir -l $probe 2>&1 | Out-String
    } elseif ($run.Mode) {
        & $alfe --no-init --debug --$cad --mode $run.Mode --timeout $t `
            --keep-workdir -l $probe 2>&1 | Out-String
    } else {
        & $alfe --no-init --debug --$cad --timeout $t `
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
Write-Host "================ EPURE's own API, called from alfe"
# pjb, 2026-09-25. Bootstrap is not the question any more: this is.
# Loading EPURE and reaching READY says nothing about whether EPURE's
# functions answer in that session, which is the whole point of --epure.
#
#   TRUSTEDPATHS=...  alfe -norc --quiet --$cad --epure \
#     -x '(print (= "" (toutes_options nil)))' \
#     -x '(print (equal (quote ((enabled) (message))) (f_DateHeure_UTC 0)))'
#
# must print T twice.
#
# It is run BOTH ways: with -x as pjb wrote it, and from a file. On this
# host PowerShell has been seen to strip the double quotes out of a
# native command's arguments (it silently emptied the ActiveX probe's
# labels), and that artefact must not be read as EPURE failing.
$epureDirs = @("$env:APPDATA\SNCF\Epure\Epure 2022_b",
               "$env:APPDATA\SNCF\Epure\Epure 2022")
$env:TRUSTEDPATHS = (@($env:TRUSTEDPATHS) + $epureDirs | Where-Object { $_ }) -join ';'
Write-Host "--- TRUSTEDPATHS=$env:TRUSTEDPATHS"

$apiFile = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-epure-api.lsp'
@'
(print (= "" (toutes_options nil)))
(print (equal (quote ((enabled) (message))) (f_DateHeure_UTC 0)))
'@ | Set-Content -Path $apiFile -Encoding ASCII

foreach ($cad in $cads) {
    $t = if ($cad -eq 'bricscad') { $bricscadTimeout } else { $timeout }

    Write-Host ""
    Write-Host "--- alfe -norc --quiet --$cad --epure -x ... -x ...   (as typed)"
    $out = & $alfe -norc --quiet --$cad --epure --timeout $t `
        -x '(print (= "" (toutes_options nil)))' `
        -x '(print (equal (quote ((enabled) (message))) (f_DateHeure_UTC 0)))' 2>&1 | Out-String
    $status = $LASTEXITCODE
    Write-Host $out
    $ts = ([regex]::Matches($out, '(?m)^\s*T\s*$')).Count
    Write-Host "--- exit $status, T printed $ts time(s)"
    $summary += [pscustomobject]@{
        Label = "--$cad --epure EPURE API (-x)"; Exit = $status; Marker = ($ts -ge 2) }

    Write-Host ""
    Write-Host "--- the same two forms from a file (immune to argument quoting)"
    $out = & $alfe -norc --quiet --$cad --epure --timeout $t -l $apiFile 2>&1 | Out-String
    $status = $LASTEXITCODE
    Write-Host $out
    $ts = ([regex]::Matches($out, '(?m)^\s*T\s*$')).Count
    Write-Host "--- exit $status, T printed $ts time(s)"
    $summary += [pscustomobject]@{
        Label = "--$cad --epure EPURE API (file)"; Exit = $status; Marker = ($ts -ge 2) }

    Get-Process bricscad, acad -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "================ experiment: (load control.scr) instead of ._SCRIPT"
# pjb, 2026-09-25: "perhaps the simplest would be to do (load control)
# (load run-common) in our run.scr". Nothing is changed in the plug-in to
# try it: --print-command --keep-workdir stages the real workdir and
# prints the real command line, the run.scr is rewritten here, and that
# command is then run. If BricsCAD reaches READY this way, the plug-in
# follows.
$staged = & $alfe --no-init --debug --bricscad --epure --print-command `
    --keep-workdir -l $probe 2>&1 | Out-String
$command = ($staged -split "`n" | Where-Object { $_ -match 'bricscad.*run\.scr' } |
            Select-Object -Last 1)
$workdir = ($staged -split "`n" | Where-Object { $_ -match 'workdir = (\S+)' } |
            Select-Object -First 1)
if ($workdir -match 'workdir = (\S+)' -and $command) {
    $dir = $Matches[1].Trim()
    $scr = Join-Path $dir 'run.scr'
    $lines = Get-Content $scr
    $out = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '._SCRIPT') {
            # the next line is the answer to SCRIPT's prompt: the path,
            # quoted by the plug-in since 2.2.88
            $path = $lines[$i + 1].Trim().Trim('"')
            $out += ('(load "' + $path + '")')
            $i++
        } else {
            $out += $lines[$i]
        }
    }
    $out | Set-Content -Path $scr -Encoding ASCII
    Write-Host "--- rewritten run.scr"
    Get-Content $scr | Out-String | Write-Host

    Write-Host "--- launching: $command"
    $status = Join-Path $dir 'protocol\status.txt'
    $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $command -PassThru
    $deadline = (Get-Date).AddSeconds([int]$bricscadTimeout)
    $last = ''
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 5
        if (Test-Path $status) {
            $last = (Get-Content $status -ErrorAction SilentlyContinue | Select-Object -First 1)
            if ($last -match '^(READY|DONE|STOPPED)') { break }
        }
    }
    Write-Host "--- status reached: '$last'"
    $loadWorked = ($last -match '^(READY|DONE|STOPPED)')
    Write-Host ("--- (load control.scr): {0}" -f $(if ($loadWorked) { 'REACHED THE PROTOCOL' } else { 'no' }))
    foreach ($name in @('run-scr-started.txt', 'protocol\stdout.txt', 'protocol\stderr.txt')) {
        $file = Join-Path $dir $name
        if (Test-Path $file) {
            Write-Host "----- $name"
            Get-Content $file -ErrorAction SilentlyContinue |
                Select-Object -First 30 | Out-String | Write-Host
        }
    }
    if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
    Get-Process bricscad -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host "leftover bricscad pid $($_.Id), ending it"; Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
} else {
    Write-Host "--- could not stage a BricsCAD EPURE workdir; experiment skipped"
}

Write-Host ""
Write-Host "================ summary"
foreach ($row in $summary) {
    Write-Host ("  {0,-52} : exit {1}, ok {2}" -f `
        $row.Label, $row.Exit, $(if ($row.Marker) { 'YES' } else { 'NO' }))
}

# The question asked of this job is "what happens", so a CAD that is not
# installed is not a failure; a CAD that ran and did not reach the
# marker is.
$bad = @($summary | Where-Object {
    ($_.Label -match '--epure$' -or $_.Label -match 'EPURE API') -and
    $_.Exit -eq 0 -and -not $_.Marker }).Count
exit $bad
