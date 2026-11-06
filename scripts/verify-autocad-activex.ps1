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
#
# It also checks the owned-CAD close (contract 2, alfe 2.3.107,
# alfe-owned-cad-termination-after-recorded-results): the probe writes a
# small JUnit file that alfe checks (--result-file) before it closes the CAD
# it created, and the cleanup report (--cleanup-report) must say that CAD is
# gone -- normally or terminated, its raw exit code is only printed. The
# check passes on alfe's exit status plus that disappearance, never on the
# CAD's own exit code.

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
$junit = Join-Path ([System.IO.Path]::GetTempPath()) "alfe-activex-junit-$PID.xml"
$cleanup = Join-Path ([System.IO.Path]::GetTempPath()) "alfe-activex-cleanup-$PID.txt"
Remove-Item -Force $junit, $cleanup -ErrorAction SilentlyContinue
$junitLisp = $junit -replace '\\', '/'
$probeText = @'
(progn
  (setq app (vlax-get-acad-object))
  (princ "ACTIVEX.APP=")      (princ (if app "yes" "no"))   (terpri)
  (princ "ACTIVEX.VERSION=")  (princ (vla-get-Version app)) (terpri)
  (setq doc (vla-get-ActiveDocument app))
  (princ "ACTIVEX.DOCUMENT=") (princ (vla-get-Name doc))    (terpri)
  (setq junit (open "@JUNIT@" "w"))
  (write-line "<testsuites tests=\"1\"><testsuite name=\"activex\" tests=\"1\"><testcase name=\"version\"/></testsuite></testsuites>" junit)
  (close junit)
  (princ "ACTIVEX.RESULT=SUCCESS")
  (princ))
'@
$probeText.Replace('@JUNIT@', $junitLisp) | Set-Content -Path $probe -Encoding ASCII
Write-Host "--- probe file $probe"
Get-Content $probe | Out-String | Write-Host

Write-Host "=== alfe --cad $selection --mode automation (timeout ${timeout}s)"
& $alfe --no-init --debug --cad $selection --mode automation `
    --timeout $timeout --keep-workdir --result-file $junit `
    --cleanup-report $cleanup -l $probe 2>&1 | Out-String | Write-Host
$status = $LASTEXITCODE
Write-Host "--- alfe exit $status"

# The owned-CAD close: the report must exist and say the created CAD is gone,
# and no process may hold its PID with its creation time.
Write-Host ""
Write-Host "=== cleanup report $cleanup"
$report = @{}
if (Test-Path $cleanup) {
    Get-Content $cleanup | ForEach-Object {
        Write-Host "  $_"
        $at = $_.IndexOf('=')
        if ($at -gt 0) { $report[$_.Substring(0, $at)] = $_.Substring($at + 1) }
    }
} else {
    Write-Host "  (missing)"
}
$cleanupOk = ($report['end'] -eq '1') -and ($report['owned'] -eq 'created') `
    -and ($report['cleanup'] -eq 'ok') -and ($report['cleanup-disappeared'] -eq '1') `
    -and ($report['frontier'] -eq 'recorded') -and ($report['results'] -eq 'ok')
if ($report['cleanup-pid']) {
    $left = Get-Process -Id ([int]$report['cleanup-pid']) -ErrorAction SilentlyContinue
    if ($left -and ($left.StartTime.ToUniversalTime().Ticks -eq [int64]$report['cleanup-start-ticks'])) {
        Write-Host "  FAIL: the created CAD (pid $($report['cleanup-pid'])) is still running"
        $cleanupOk = $false
    }
}
Write-Host ("  the created CAD ended: {0}, forced={1}, exit code {2}" -f `
    $report['cleanup-outcome'], $report['cleanup-forced'], $report['cleanup-exit-code-hex'])
if ($status -eq 0 -and -not $cleanupOk) {
    Write-Host "--- FAIL: alfe exited 0 but the cleanup report does not prove the created CAD gone"
    $status = 1
}
Remove-Item -Force $junit -ErrorAction SilentlyContinue

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
