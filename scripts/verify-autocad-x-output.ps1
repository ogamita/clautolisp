# verify-autocad-x-output.ps1 -- does output printed by a function CALLED
# through -x reach alfe on AutoCAD accoreconsole?
# (issues/open/autocad-no-rest-output-capture.issue)
#
# The ticket's last open half: a function DEFINED by -l and CALLED by -x --
# the eval-request path, which writes the form to protocol\alfe-eval.lsp and
# native-loads it -- lost the function's 1-arg (princ ...) output on
# AutoCAD, while the same code run through -l alone was captured. AutoCAD
# accepts no &rest / &optional, so every princ there is a fixed-arity shadow
# reached through a walk-rewriter; this checks the call that the rewriter
# never sees: a princ INSIDE a function that was loaded earlier.
#
#   -l  defines (xout-run): princ of a literal, of a strcat, a terpri, a
#       princ of a number, and a nested helper that princs too
#   -x  (xout-run)       -> every XOUT marker must reach alfe's output
#   -x  (princ "XTOP")   -> the top-level case, for comparison
# PASS needs all of them; anything missing is printed.

$ErrorActionPreference = 'Continue'
$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) { Write-Host "alfe-sbcl.exe not built at $alfe"; exit 2 }
$timeout = $env:XOUT_TIMEOUT; if (-not $timeout) { $timeout = '240' }

$dir = Join-Path ([System.IO.Path]::GetTempPath()) ("alfe-xout-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$lsp = Join-Path $dir 'xout.lsp'
@'
(defun xout-helper (n)
  (princ (strcat "XOUT-HELPER-" (itoa n)))
  (terpri))
(defun xout-run ()
  (princ "XOUT-LITERAL")
  (terpri)
  (princ (strcat "XOUT-" "STRCAT"))
  (terpri)
  (princ 4242)
  (terpri)
  (xout-helper 7)
  (princ "XOUT-END")
  (princ))
'@ | Set-Content -Path $lsp -Encoding ASCII

$status = 1
try {
    Write-Host "=== alfe --cad autocad --mode batch -l xout.lsp -x (xout-run) -x (princ ...)"
    # No double quote may appear in a -x form (PowerShell drops them): the
    # top-level marker is built with vl-symbol-name.
    $out = & $alfe --no-init --cad autocad --mode batch --timeout $timeout `
        -l $lsp -x '(xout-run)' -x '(princ (vl-symbol-name (quote XTOP)))' 2>&1 | Out-String
    Write-Host $out
    Write-Host "--- alfe exit $LASTEXITCODE"
    $want = @('XOUT-LITERAL', 'XOUT-STRCAT', '4242', 'XOUT-HELPER-7', 'XOUT-END', 'XTOP')
    $missing = @($want | Where-Object { $out -notmatch [regex]::Escape($_) })
    foreach ($w in $want) { Write-Host ("  {0,-14} {1}" -f $w, ($(if ($missing -contains $w) { 'MISSING' } else { 'seen' }))) }
    if ($missing.Count -eq 0) { Write-Host "RESULT=PASS"; $status = 0 }
    else { Write-Host "RESULT=FAIL ($($missing.Count) missing)"; $status = 1 }
}
finally {
    Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
}
exit $status
