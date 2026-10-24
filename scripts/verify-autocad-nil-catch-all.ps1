# verify-autocad-nil-catch-all.ps1 -- does a failing -x request whose caught
# error has a NIL message FAIL on AutoCAD, instead of reporting DONE OK?
# (issues/open/alfe-cad-nil-catch-all-message.issue, vendor check)
#
# AutoCAD 2022 answers NIL from (vl-catch-all-error-message e) for the error
# vl-exit-with-error raises outside a VLX (control-flow probe, jobs
# 17398575920 / 17398575921). alfe's CAD side used to take the message for a
# string: a NIL made the failed request report DONE OK. Since the fix the
# request reports FAIL, with the fixed text "the engine supplied no message"
# and the form on stderr.
#
# Run for both AutoCAD engines: the GUI (--mode automation) and AcCoreConsole
# (--mode batch). PASS needs, for each: a non-zero exit status, and no form
# reported as a success. The fixed text is reported, not required (a release
# whose message is not NIL there is not a failure of the fix).

$ErrorActionPreference = 'Continue'
$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) { Write-Host "alfe-sbcl.exe not built at $alfe"; exit 2 }
$timeout = $env:NILCATCH_TIMEOUT; if (-not $timeout) { $timeout = '300' }

$status = 0
foreach ($mode in @('automation', 'batch')) {
    Write-Host "=== alfe --cad autocad --mode $mode -x (vl-exit-with-error ...)"
    # No double quote may appear in a -x form (PowerShell drops them).
    $out = & $alfe --no-init --cad autocad --mode $mode --timeout $timeout `
        -x '(vl-exit-with-error (vl-symbol-name (quote NILCATCH)))' 2>&1 | Out-String
    $code = $LASTEXITCODE
    Write-Host $out
    Write-Host "--- alfe exit $code"
    $fixed = $out -match [regex]::Escape('the engine supplied no message')
    Write-Host ("  fixed text 'the engine supplied no message': {0}" -f $(if ($fixed) { 'seen' } else { 'absent' }))
    if ($code -ne 0) {
        Write-Host "RESULT[$mode]=PASS (the request failed)"
    } else {
        Write-Host "RESULT[$mode]=FAIL (exit 0: the failed request was reported as a success)"
        $status = 1
    }
}
exit $status
