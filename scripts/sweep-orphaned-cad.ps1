# End the AutoCAD instances a PREVIOUS alfe run created and never closed.
#
# autocad-orphaned-by-killed-or-cancelled-jobs.issue: alfe quits the
# AutoCAD it created, but only if it reaches shutdown. A killed alfe, or
# a cancelled CI job, never does -- and the acad.exe is a child of the
# COM service, not of the job, so no process-tree kill reaches it either.
#
# THE SCOPE QUESTION THIS ANSWERS. A sweep is the first thing here that
# would end a process alfe did not start, and the Windows runner is also
# somebody's own machine. So this does NOT go looking for AutoCADs that
# "look like" CI ones: alfe's COM bridge writes down each instance it
# CREATES -- PID and creation time -- and this kills only those, and only
# while both still match. A PID alone would not do: Windows reuses them,
# and a stale entry could name somebody's own AutoCAD by then.
#
# Runs BEFORE a job, not after: the ending it exists for (a hard cancel)
# never runs an after_script. Before a job is also the safe moment --
# nothing the current job started can be swept away by mistake.
#
# Reports what it does and exits 0 even when it can do nothing: a sweep
# that fails must not fail the job it precedes.

$ErrorActionPreference = 'Continue'

$registry = Join-Path $env:TEMP 'alfe-created-cad.txt'
if (-not (Test-Path $registry)) {
    Write-Host "cad sweep: nothing recorded ($registry)"
    exit 0
}

# The registry gains a line per session and is never rewritten while an
# instance lives, so the same PID appears many times: a log of 97 lines
# for TWO processes, each reported ~48 times
# (alfe-autocad-hung-instance-blocks-com-bootstrap). Deduplicate on the
# pair that identifies a process -- PID plus creation stamp.
$seen = @{}
$entries = @()
$recorded = 0
foreach ($line in (Get-Content $registry -ErrorAction SilentlyContinue)) {
    if ($line -match 'PID=(\d+)\s+CREATED=(\S+)') {
        $recorded++
        $key = "$($Matches[1])/$($Matches[2])"
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $entries += [pscustomobject]@{ Pid = [int]$Matches[1]; Created = $Matches[2] }
        }
    }
}
Write-Host "cad sweep: $($entries.Count) instance(s) recorded ($recorded line(s) in $registry)"

$killed = 0
$living = @()
foreach ($entry in $entries) {
    $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $($entry.Pid)" `
        -ErrorAction SilentlyContinue
    if (-not $proc) { continue }
    # Same PID is not the same process. The creation time settles it, and
    # WMI reports it as a CIM datetime (or a DateTime, depending on the
    # PowerShell version) -- compare on the leading yyyyMMddHHmmss.
    $stamp = if ($proc.CreationDate -is [datetime]) {
                 $proc.CreationDate.ToString('yyyyMMddHHmmss')
             } else { "$($proc.CreationDate)" }
    $recorded = $entry.Created
    if (-not ($stamp.Substring(0, [Math]::Min(14, $stamp.Length)) -eq
              $recorded.Substring(0, [Math]::Min(14, $recorded.Length)))) {
        Write-Host "cad sweep: pid $($entry.Pid) is a DIFFERENT process now ($stamp vs $recorded); left alone"
        continue
    }
    if ($proc.Name -ne 'acad.exe') {
        Write-Host "cad sweep: pid $($entry.Pid) is $($proc.Name), not acad.exe; left alone"
        continue
    }
    Write-Host "cad sweep: ending orphaned acad.exe pid $($entry.Pid) (created $recorded)"
    Stop-Process -Id $entry.Pid -Force -ErrorAction SilentlyContinue
    if (Get-Process -Id $entry.Pid -ErrorAction SilentlyContinue) {
        # A wedged AutoCAD -- one showing a modal dialog, or hung in COM --
        # survives Stop-Process. taskkill /T /F takes its children with it
        # and is the stronger hammer; reporting "survived" and carrying on
        # was how two acad.exe from the previous day kept every later
        # session from starting.
        Write-Host "cad sweep: pid $($entry.Pid) survived Stop-Process; taskkill /T /F"
        & taskkill /PID $entry.Pid /T /F 2>&1 | ForEach-Object { Write-Host "cad sweep:   $_" }
        Start-Sleep -Seconds 2
    }
    if (Get-Process -Id $entry.Pid -ErrorAction SilentlyContinue) {
        Write-Host "cad sweep: pid $($entry.Pid) SURVIVED taskkill too"
        $living += $entry
    } else {
        $killed++
    }
}

# Keep only what could not be ended; everything else is settled.
if ($living.Count -gt 0) {
    $living | ForEach-Object { "PID=$($_.Pid) CREATED=$($_.Created)" } |
        Set-Content -Path $registry -Encoding ASCII
} else {
    Remove-Item $registry -Force -ErrorAction SilentlyContinue
}

Write-Host "cad sweep: $killed ended, $($living.Count) left"

if ($living.Count -gt 0) {
    # Do not let a CAD job run behind a wedged instance. A hung AutoCAD
    # owns the AutoCAD.Application COM registration, so it is the one
    # GetObject/CreateObject reaches, and it answers RPC_E_CALL_REJECTED
    # ("L'appel a ete rejete par l'appele") to every call -- which looks
    # like an alfe defect in the log and is not one. Fail here instead,
    # naming what has to be ended on the machine.
    Write-Host ""
    Write-Host "cad sweep: FAILING THIS JOB -- a CAD process could not be ended."
    Write-Host "cad sweep: end these on the runner before retrying:"
    foreach ($entry in $living) {
        Write-Host "cad sweep:   pid $($entry.Pid) (created $($entry.Created))"
    }
    Write-Host "cad sweep: they hold the COM registration, so every AutoCAD"
    Write-Host "cad sweep: session would fail with a rejected call instead."
    Write-Host "cad sweep: see issues/open/alfe-autocad-hung-instance-blocks-com-bootstrap.issue"
    if ($env:CAD_SWEEP_IGNORE_SURVIVORS -eq '1') {
        Write-Host "cad sweep: CAD_SWEEP_IGNORE_SURVIVORS=1 -- continuing anyway."
        exit 0
    }
    exit 1
}
exit 0
