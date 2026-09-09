# Run the alfe entity / drawing-data / selection conformance probes against a
# real CAD backend (bricscad | autocad) and turn each probe's verdict line into
# a job pass/fail, saving every probe's full output as an artifact.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-vendor-probes.ps1 -Backend bricscad
#
# This is the automated form of the entity-mutation / drawing-data-structures /
# selection-and-snapshot "vendor verification" tail: the probes are byte-
# identical to the ones clautolisp passes headlessly, so a FAIL here names a
# real clautolisp-vs-vendor divergence. Exits non-zero if any probe fails or
# produces no verdict (backend unreachable).
param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("bricscad","autocad")]
  [string]$Backend,
  # Drawing to open for the probes. AutoCAD batch (accoreconsole) needs one
  # or it stops with NO-DWG; empty.dwg is the clean canvas the create/delete
  # probes want. Overridden by the PROBE_DWG CI variable. A content drawing
  # (e.g. 2018.dwg) can be passed for read-oriented probes later.
  # EMPTY BY DEFAULT since empty-ressource.issue: alfe carries an empty
  # drawing in its image and writes a FRESH one into each run's workdir,
  # so nothing needs to name a shared file -- and naming one is what
  # produced the "already in use, open read-only?" modals. Pass -Dwg
  # explicitly only to probe a SPECIFIC drawing.
  [string]$Dwg = "",
  # When 1 (default), pass --debug --verbose --keep-workdir to alfe and
  # copy each kept protocol workdir into the artifacts for inspection.
  # NB: must NOT be named -Debug -- that collides with PowerShell's reserved
  # -Debug common parameter and the script fails to bind before it runs
  # (ParameterNameAlreadyExistsForCommand), producing zero artifacts.
  [string]$KeepWorkdir = "1"
)

$ErrorActionPreference = "Continue"
$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl"
$probeDir = Join-Path $root "autolisp-front-end/tests/scenarios/entities"
$outDir = Join-Path $root "dist/vendor-probes/$Backend"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# AUTOLISP_DWG is consulted by both backends' batch paths; --dwg (below) is
# the explicit AutoCAD form and wins where supported.
if ($Dwg) { $env:AUTOLISP_DWG = $Dwg }

# These are PURE-CAD probes: launch BricsCAD with a CLEAN profile so it does
# not auto-load the runner's vertical application (EPURE/SCHMS+). Its default
# profile has EPURE loaded -- its ribbon shows even for a bare bricscad.exe --
# and that on-startup app-load blocks the /b script from ever running (run.scr
# never executes, stuck at BOOTING). "<<Profil sans nom>>" is the clean unnamed
# profile. alfe passes it as /p on Windows. Override with $BRICSCAD_PROFILE_CLEAN.
if ($Backend -eq "bricscad") {
  $cleanProfile = if ($env:BRICSCAD_PROFILE_CLEAN) { $env:BRICSCAD_PROFILE_CLEAN } else { "<<Profil sans nom>>" }
  $env:AUTOLISP_BRICSCAD_PROFILE = $cleanProfile
  Write-Host "AUTOLISP_BRICSCAD_PROFILE = $env:AUTOLISP_BRICSCAD_PROFILE"
}

# Point alfe at the CAD-side runtime/bootstrap LSP shipped in the repo.
# alfe is built-not-installed on the runner, and the vendored-asset
# lookup (asdf:system-relative-pathname) is unreliable from a frozen
# .exe, so run-common.lsp loaded with no remote-I/O runtime and quit
# before signalling READY (job 15534461469). $ALFE_RUNTIME_LSP /
# $ALFE_BOOTSTRAP_LSP take precedence over discovery. Forward slashes so
# SBCL's probe-file parses them on Windows.
$rtLsp = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/'
$bsLsp = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/'
if (Test-Path $rtLsp) { $env:ALFE_RUNTIME_LSP = $rtLsp } else { Write-Host "WARN: runtime lsp not found at $rtLsp" }
if (Test-Path $bsLsp) { $env:ALFE_BOOTSTRAP_LSP = $bsLsp } else { Write-Host "WARN: bootstrap lsp not found at $bsLsp" }
Write-Host "ALFE_RUNTIME_LSP   = $env:ALFE_RUNTIME_LSP"
Write-Host "ALFE_BOOTSTRAP_LSP = $env:ALFE_BOOTSTRAP_LSP"

# The Makefile saves the SBCL image as `alfe-sbcl` with no extension. On
# Windows it is a native PE, but PowerShell's call operator (&) only runs
# files whose extension is in $PATHEXT, so it must be a `.exe`. Prefer an
# existing .exe, else copy the extension-less PE to one. (make-driven targets
# run the bare name fine because they go through sh/cmd, not PowerShell.)
if (Test-Path "$alfe.exe") {
  $alfe = "$alfe.exe"
} elseif (Test-Path $alfe) {
  Copy-Item -Force $alfe "$alfe.exe"
  $alfe = "$alfe.exe"
} else {
  Write-Host "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"
  exit 2
}

$probes = @(
  @{ Name = "entity-lifecycle"; File = "entity-lifecycle-probe.lsp" },
  @{ Name = "drawing-data";     File = "drawing-data-probe.lsp" },
  @{ Name = "selection";        File = "selection-probe.lsp" },
  @{ Name = "bricscad-extensions"; File = "bricscad-extensions-probe.lsp" }
)

$failed = 0
$summary = @("vendor probes: $Backend", "alfe: $alfe", "dwg: $Dwg", "")
$tmpBase = if ($env:TEMP) { $env:TEMP } else { $outDir }
foreach ($p in $probes) {
  $probePath = Join-Path $probeDir $p.File
  $log = Join-Path $outDir ("{0}.log" -f $p.Name)
  Write-Host "=== $Backend : $($p.Name) ==="
  # Copy the drawing to a unique temp name per probe so concurrent /
  # back-to-back runs never share and lock the same file (or its
  # .dwl/.bak siblings). Removed after the probe.
  $probeDwg = $null
  if ($Dwg -and (Test-Path $Dwg)) {
    $probeDwg = Join-Path $tmpBase ("vp-{0}-{1}-{2}.dwg" -f $Backend, $p.Name, [guid]::NewGuid().ToString("N"))
    Copy-Item -Force $Dwg $probeDwg
  }
  # When keeping the workdir, ask alfe to write its absolute path to a
  # sidecar file (--write-workdir-path). That is authoritative: the script
  # reads the path from the file instead of scraping stdout, which is
  # brittle across encodings and log truncation.
  # --no-init: a probe/test run must not auto-load the runner's user init
  # file (~/.autolisp etc.) -- it varies per machine and pollutes the plan
  # (we saw `load "C:/.../.autolisp"` sneak in as plan[1]).
  $dbg = @("--no-init")
  $wdPathFile = $null
  if ($KeepWorkdir -eq "1") {
    $wdPathFile = Join-Path $tmpBase ("vp-wd-{0}-{1}-{2}.txt" -f $Backend, $p.Name, [guid]::NewGuid().ToString("N"))
    # APPEND (not reassign) so --no-init is never dropped.
    $dbg += @("--debug", "--verbose", "--keep-workdir", "--write-workdir-path", $wdPathFile)
  }
  # BricsCAD: use batch mode (bricscad.exe -B run.scr), the same GUI-exe +
  # script path macOS uses -- no COM/VBScript bridge. A cold GUI start
  # (launch + license + first document) can exceed alfe's 30 s default READY
  # timeout, so give it a generous budget (--timeout also feeds READY now).
  $tmo = @()
  if ($Backend -eq "bricscad") { $tmo = @("--mode", "batch", "--timeout", "180") }
  # Background watcher: while alfe blocks in the protocol (up to --timeout), tail
  # the engine workdir so a stuck launch is diagnosable. Start-Job output is
  # collected after alfe returns (Receive-Job); the embedded +Ns timestamps keep
  # the timeline (e.g. "run-scr-started.txt never appeared, status stuck BOOTING").
  $stopFlag = Join-Path $tmpBase ("vp-stop-{0}-{1}-{2}" -f $Backend, $p.Name, [guid]::NewGuid().ToString("N"))
  Remove-Item -Force $stopFlag -ErrorAction SilentlyContinue
  $startTs = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $watcher = $null
  if ($KeepWorkdir -eq "1" -and $wdPathFile) {
    $watcher = Start-Job -ScriptBlock {
      param($wdfile, $stopflag, $start)
      $wd = ""; $started = $false; $nlines = 0; $laststatus = ""
      while (-not (Test-Path $stopflag)) {
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $start
        if (-not $wd -and (Test-Path $wdfile)) {
          $wd = ([string](Get-Content -Raw $wdfile -ErrorAction SilentlyContinue)).Trim()
          if ($wd) { "[watch +${now}s] workdir = $wd" }
        }
        if ($wd) {
          if (-not $started -and (Test-Path (Join-Path $wd "run-scr-started.txt"))) {
            $started = $true; "[watch +${now}s] run-scr-started.txt APPEARED -- the CAD script is running"
          }
          $stf = Join-Path $wd "protocol/status.txt"
          if (Test-Path $stf) {
            $st = ([string](Get-Content -Raw $stf -ErrorAction SilentlyContinue)).Trim()
            if ($st -and $st -ne $laststatus) { $laststatus = $st; "[watch +${now}s] status -> $st" }
          }
          $dbg2 = Join-Path $wd "logs/debug.log"
          if (Test-Path $dbg2) {
            $lines = @(Get-Content $dbg2 -ErrorAction SilentlyContinue)
            if ($lines.Count -gt $nlines) {
              $lines[$nlines..($lines.Count-1)] | ForEach-Object { "[watch +${now}s] debug: $_" }
              $nlines = $lines.Count
            }
          }
        }
        Start-Sleep -Seconds 2
      }
    } -ArgumentList $wdPathFile, $stopFlag, $startTs
  }
  # alfe writes its --debug/--verbose diagnostics to stderr. With `2>&1`
  # PowerShell wraps each native-stderr line as an ErrorRecord and renders
  # it with the alarming NativeCommandError/RemoteException formatting --
  # noise about normal output, not a failure. Coerce every pipeline item to
  # a plain string (`"$_"`) before Tee so stderr lands in the log as text.
  try {
    if ($Backend -eq "autocad" -and $probeDwg) {
      # explicit batch + drawing selection for accoreconsole
      & $alfe "--no-init" "--autocad" @dbg "--mode" "batch" "--dwg" $probeDwg -l $probePath 2>&1 | ForEach-Object { "$_" } | Tee-Object -FilePath $log
    } else {
      & $alfe "--no-init" "--$Backend" @dbg @tmo -l $probePath 2>&1 | ForEach-Object { "$_" } | Tee-Object -FilePath $log
    }
  } finally {
    if ($probeDwg -and (Test-Path $probeDwg)) {
      Remove-Item -Force $probeDwg -ErrorAction SilentlyContinue
    }
  }
  # Stop the watcher and print its collected timeline.
  if ($watcher) {
    New-Item -ItemType File -Force -Path $stopFlag | Out-Null
    Start-Sleep -Milliseconds 400
    Receive-Job $watcher -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
    Remove-Job $watcher -Force -ErrorAction SilentlyContinue
    Remove-Item -Force $stopFlag -ErrorAction SilentlyContinue
  }
  # Safety net: alfe now terminates the engine it launched on abnormal exit,
  # but if alfe itself was killed before cleanup a GUI BricsCAD can be left
  # spinning. Kill ONLY the exact PID alfe reported ("process-info-pid = N")
  # and only if it is still a bricscad process -- never a blanket by-name
  # kill, since the runner may have an interactive BricsCAD open.
  if ($Backend -eq "bricscad" -and (Test-Path $log)) {
    foreach ($m in [regex]::Matches((Get-Content -Raw $log), "process-info-pid = (\d+)")) {
      $enginePid = [int]$m.Groups[1].Value
      $proc = Get-Process -Id $enginePid -ErrorAction SilentlyContinue
      if ($proc -and $proc.ProcessName -match "bricscad") {
        Write-Host "cleanup: terminating leftover bricscad pid $enginePid"
        Stop-Process -Id $enginePid -Force -ErrorAction SilentlyContinue
      }
    }
  }
  # With --keep-workdir the protocol files (run.scr, run-common.lsp, the
  # staged runtime/bootstrap, the status/stdout/stderr channel files)
  # survive; copy that workdir into the artifacts. The path comes from the
  # --write-workdir-path sidecar file first (authoritative); if that is
  # missing (older alfe, or the run died before preparing the workdir) fall
  # back to scraping the log.
  if ($KeepWorkdir -eq "1") {
    $dest = Join-Path $outDir ("{0}-workdir" -f $p.Name)
    $wd = $null
    if ($wdPathFile -and (Test-Path $wdPathFile)) {
      $wd = (Get-Content -Raw $wdPathFile).Trim()
      Remove-Item -Force $wdPathFile -ErrorAction SilentlyContinue
    }
    if ($wd -and (Test-Path $wd)) {
      Copy-Item -Recurse -Force $wd $dest -ErrorAction SilentlyContinue
      Write-Host "kept workdir copied -> $dest (from sidecar)"
    } elseif (Test-Path $log) {
      $logText = Get-Content -Raw $log
      $rx = "[A-Za-z]:[\/][^\s`"']*alfe-$Backend-[0-9]+-[A-Za-z0-9]+"
      $seen = @{}
      foreach ($mm in [regex]::Matches($logText, $rx)) {
        $w = $mm.Value
        if ($seen.ContainsKey($w)) { continue }
        $seen[$w] = $true
        if (Test-Path $w) {
          Copy-Item -Recurse -Force $w $dest -ErrorAction SilentlyContinue
          Write-Host "kept workdir copied -> $dest (from log scrape)"
        }
      }
    }
  }
  # Compare the probe's exhibited OBSERVE output against this target's
  # per-vendor :expected-observations (autolisp-spec ch.25 probe model);
  # UNEXPECTED / MISSING gate, KNOWN-DIVERGENCE is reported but green.
  $sexp = if ($Backend -eq "clautolisp") { Join-Path $probeDir "$($p.Name).sexp" }
          else { Join-Path $probeDir "$($p.Name)-$Backend.sexp" }
  # HARVEST probes have no per-vendor expectation file: they RECORD what the
  # target does (e.g. bricscad-extensions decoding BricsCAD's undocumented
  # setf/let/let* returns), so there is nothing to conform to yet. Save the
  # transcript artifact and report HARVEST (green, never gates). Drop in a
  # <name>[-<backend>].sexp later to promote it to a conformance probe.
  if (-not (Test-Path $sexp)) {
    $summary += "HARVEST  $($p.Name) -- transcript saved ($($p.Name).log); no expectation file, not gated"
    Write-Host "HARVEST  $($p.Name) (no $sexp; transcript in $log)"
    continue
  }
  $cmp = & python3 (Join-Path $root "scripts/compare-observations.py") $sexp $log 2>&1
  $cmpRc = $LASTEXITCODE
  $cmp | ForEach-Object { Write-Host "$_" }
  $obsLine = ($cmp | Select-String -Pattern '^observations:' | Select-Object -First 1).ToString()
  if ($cmpRc -eq 0) {
    $summary += "PASS  $($p.Name) -- $obsLine"
    Write-Host "PASS  $($p.Name)"
  } else {
    $failed++
    if (-not $obsLine) { $obsLine = "no observations (backend unreachable or crashed)" }
    $summary += "FAIL  $($p.Name) -- $obsLine"
    Write-Host "FAIL  $($p.Name)"
  }
}
$summary | Set-Content -Encoding utf8 (Join-Path $outDir "SUMMARY.txt")
Write-Host "--- $Backend vendor-probe summary ---"
$summary | ForEach-Object { Write-Host $_ }
if ($failed -gt 0) { Write-Host "$failed probe(s) failed on $Backend"; exit 1 }
Write-Host "all vendor probes passed on $Backend"
exit 0
