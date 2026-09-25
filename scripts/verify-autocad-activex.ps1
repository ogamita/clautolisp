# Drive a REAL AutoCAD through alfe's COM bridge and evaluate ActiveX.
#
# This is the end-to-end half of alfe-autocad-cad-selection-ignores-com-progid
# and alfe-autocad-progid-registry-probe-fails: the registry probe shows which
# ProgID alfe picks, but only a launch shows the bridge reaching READY and
# AutoLISP running inside AutoCAD. SCHMS's test-cad-activex:autocad:windows
# asks the same question from another repository; this asks it here.
#
# What it evaluates, in AutoCAD, over the file protocol:
#   (vlax-get-acad-object)                  the ActiveX application object
#   (vla-get-Version ...)                   its version, printed
#   (vla-get-Name (vla-get-ActiveDocument)) the open document
#
# On failure the workdir is kept and the bridge's own files are dumped --
# com-flags.txt and the error file are where a COM failure is recorded.

$ErrorActionPreference = 'Continue'

$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) {
    Write-Host "alfe-sbcl.exe not built at $alfe"
    exit 2
}

$selection = $env:ACTIVEX_CAD
if (-not $selection) { $selection = 'autocad' }
$timeout = $env:ACTIVEX_TIMEOUT
if (-not $timeout) { $timeout = '240' }

# Through a FILE, not -x: the double quotes of AutoLISP strings do not
# survive PowerShell's argument handling, and a first run printed its
# labels as `nil' -- (princ ACTIVEX.APP=) read as a symbol -- while the
# values themselves came through. A file is passed by name and read by
# AutoLISP itself, so the source arrives as written.
$probe = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-activex-probe.lsp'
@'
(progn
  (setq app (vlax-get-acad-object))
  (princ "ACTIVEX.APP=")      (princ (if app "yes" "no"))   (terpri)
  (princ "ACTIVEX.VERSION=")  (princ (vla-get-Version app)) (terpri)
  (setq doc (vla-get-ActiveDocument app))
  (princ "ACTIVEX.DOCUMENT=") (princ (vla-get-Name doc))    (terpri)
  (princ "ACTIVEX.RESULT=SUCCESS")
  (princ))
'@ | Set-Content -Path $probe -Encoding ASCII
Write-Host "--- probe file $probe"
Get-Content $probe | Out-String | Write-Host

Write-Host "=== alfe --cad $selection --mode automation (timeout ${timeout}s)"
& $alfe --no-init --debug --cad $selection --mode automation `
    --timeout $timeout --keep-workdir -l $probe 2>&1 | Out-String | Write-Host
$status = $LASTEXITCODE
Write-Host "--- alfe exit $status"

# The workdir name is in the debug trace; find the newest one either way.
$workdir = Get-ChildItem -Path $env:TEMP, 'C:\msys64\tmp' -Filter 'alfe-autocad-*' `
    -Directory -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($workdir) {
    Write-Host ""
    Write-Host "=== bridge artefacts in $($workdir.FullName)"
    foreach ($name in @('com-flags.txt', 'bridge-vbs.log',
                        'protocol\status.txt', 'protocol\stderr.txt',
                        'protocol\stdout.txt')) {
        $file = Join-Path $workdir.FullName $name
        if (Test-Path $file) {
            Write-Host "--- $name"
            Get-Content $file -ErrorAction SilentlyContinue |
                Select-Object -First 40 | Out-String | Write-Host
        }
    }
    if ($status -eq 0) { Remove-Item -Recurse -Force $workdir.FullName -ErrorAction SilentlyContinue }
}

# Leave no AutoCAD behind if the run failed before alfe's own shutdown.
if ($status -ne 0) {
    Get-Process acad -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host "still running: acad.exe pid $($_.Id)" }
}
exit $status
