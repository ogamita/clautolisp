# Try to REPRODUCE the benchmark's mid-run death under a suspended desktop.
#
# probe-cad-session-state.ps1 showed that in the LOCKED state a light
# "attach + evaluate one form" automation run succeeds on every engine
# (autocad-com-fails-in-disconnected-windows-session, Result 2026-09-28).
# benchmark:autocad:windows did NOT: it started (Visual LISP 2022 fr), ran 2
# of 7 benchmarks, then died. Two things the light probe did not control for:
#
#   1. it ATTACHED to a running AutoCAD (READY in 1.84 s) instead of building
#      a fresh main window on the locked desktop;
#   2. it loaded ONE form, not a ~20 s sustained workload.
#
# This controls for both: it KILLS any running CAD first (so automation must
# COLD-START a fresh GUI) and then drives a multi-phase heavy AutoLISP loop,
# printing HEAVY.PHASE.<n> after each phase and HEAVY.DONE at the end. If the
# process dies partway -- as the benchmark did -- the log shows how many
# phases completed, mirroring "2 of 7". A PROBE: it reports and exits 0.

$ErrorActionPreference = 'Continue'

# Session state first, so the outcome is read in its light.
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'windows-session-state.ps1')

$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) { Write-Host "alfe-sbcl.exe not built at $alfe"; exit 0 }

$engines = if ($env:PROBE_HEAVY_CADS) { $env:PROBE_HEAVY_CADS -split '[,\s]+' } else { @('autocad') }
$phases  = if ($env:PROBE_HEAVY_PHASES) { [int]$env:PROBE_HEAVY_PHASES } else { 8 }
$iters   = if ($env:PROBE_HEAVY_ITERS)  { [int]$env:PROBE_HEAVY_ITERS }  else { 1000000 }
$timeout = if ($env:PROBE_HEAVY_TIMEOUT){ $env:PROBE_HEAVY_TIMEOUT }     else { '600' }
$coldStart = if ($null -ne $env:PROBE_HEAVY_COLD_START) { $env:PROBE_HEAVY_COLD_START } else { '1' }

# The heavy workload: N phases of sustained float arithmetic, each ending in a
# HEAVY.PHASE.<n> line, then HEAVY.DONE. Plain AutoLISP (sin/repeat/rtos), so
# it runs identically on AutoCAD Visual LISP and BricsCAD LispEx.
$lsp = @"
(defun heavy-phase (n iters / i s)
  (setq s 0.0 i 0)
  (repeat iters
    (setq s (+ s (* 1.0000001 (sin (/ (float i) 1000.0)))))
    (setq i (1+ i)))
  (princ (strcat "HEAVY.PHASE." (itoa n) " s=" (rtos s 2 3) "\n"))
  (princ))
(defun heavy (phases iters / p)
  (setq p 1)
  (repeat phases (heavy-phase p iters) (setq p (1+ p)))
  (princ "HEAVY.DONE\n")
  (princ))
(heavy $phases $iters)
"@
$heavy = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-heavy-workload.lsp'
$lsp | Set-Content -Path $heavy -Encoding ASCII
Write-Host ""
Write-Host "heavy workload: $phases phases x $iters iters -> $heavy"
Get-Content $heavy | Write-Host

$rows = @()
foreach ($engine in $engines) {
    if ($coldStart -eq '1') {
        # Force a COLD start: no warm instance to attach to, so automation must
        # build a fresh GUI on whatever desktop state this is. Kill by image
        # name; ignore "not found". This is a dedicated CAD runner.
        foreach ($img in @('acad.exe', 'accoreconsole.exe', 'bricscad.exe')) {
            & taskkill /IM $img /F 2>&1 | Out-Null
        }
        Start-Sleep -Seconds 3
        Write-Host "cold-start: killed any running CAD before --$engine"
    }
    Write-Host ""
    Write-Host "================ alfe --$engine --mode automation (heavy, timeout ${timeout}s, cold=$coldStart)"
    $started = Get-Date
    $out = & $alfe --no-init --debug "--$engine" --mode automation --timeout $timeout `
                   --keep-workdir -l $heavy 2>&1 | Out-String
    $status = $LASTEXITCODE
    $elapsed = [int]((Get-Date) - $started).TotalSeconds
    Write-Host $out
    Write-Host "--- alfe exit $status after ${elapsed}s"

    # How far did it get? last HEAVY.PHASE.<n> seen, and whether HEAVY.DONE.
    $reached = 0
    foreach ($m in [regex]::Matches($out, 'HEAVY\.PHASE\.(\d+)')) {
        $n = [int]$m.Groups[1].Value
        if ($n -gt $reached) { $reached = $n }
    }
    $done = [bool]($out -match 'HEAVY\.DONE')
    $verdict = if ($done) { 'COMPLETED' }
               elseif ($reached -gt 0) { "DIED after phase $reached of $phases" }
               elseif ($out -match 'READY') { 'REACHED-READY-THEN-NO-PHASE' }
               else { 'NEVER-STARTED' }
    $rows += [pscustomobject]@{
        Engine = $engine; Reached = $reached; Phases = $phases
        Done = $done; Exit = $status; Seconds = $elapsed; Verdict = $verdict
    }
}

Write-Host ""
Write-Host "==================== heavy automation result ===================="
Write-Host ("{0,-10} {1,8} {2,6} {3,5} {4,5} {5}" -f 'engine','reached','phases','done','sec','verdict')
foreach ($r in $rows) {
    Write-Host ("{0,-10} {1,8} {2,6} {3,5} {4,5} {5}" -f `
                $r.Engine, $r.Reached, $r.Phases,
                $(if ($r.Done){'yes'}else{'no'}), $r.Seconds, $r.Verdict)
}
Write-Host "================================================================"
Write-Host "(read against the SESSION-STATE line printed at the top)"
exit 0
