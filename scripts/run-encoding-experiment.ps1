<#
  run-encoding-experiment.ps1 — Windows twin of run-encoding-experiment.sh.
  Drives encoding-probe.lsp under a matrix of Windows encoding knobs (the
  console code page via chcp, plus a couple of env vars) against a CAD
  backend, to DISCOVER which knob changes the exhibited encoding. Feeds the
  encoding-situations §7 defaults table.

    scripts/run-encoding-experiment.ps1 -Backend {clautolisp|bricscad|autocad} [-Dwg FILE]

  Output: dist/encoding/<backend>-Windows.txt — every probe line prefixed
  with its knob label. First version; expect shakedown on the Windows CAD
  runner, exactly like the vendor probes did.
#>
param(
  [ValidateSet("clautolisp","bricscad","autocad")]
  [string]$Backend = "clautolisp",
  [string]$Dwg = ""
)
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = if ($env:ALFE_BIN) { $env:ALFE_BIN } else { Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl" }

# The Makefile saves the SBCL image as `alfe-sbcl` with no extension. On
# Windows it is a native PE, but PowerShell's call operator (&) only runs
# files whose extension is in $PATHEXT, so it must be a `.exe` -- otherwise
# Windows pops the "select an application to open alfe-sbcl" dialog. Prefer
# an existing .exe, else copy the extension-less PE to one. (Mirrors
# run-vendor-probes.ps1; make-driven targets run the bare name fine because
# they go through sh/cmd, not PowerShell.)
# Since 2026-08-16 the build produces alfe-sbcl.exe, so the first branch
# takes it and the copy below no longer fires. The -like guard is for an
# ALFE_BIN that already names the .exe: without it this looks for
# alfe-sbcl.exe.exe, misses, and copies a large image onto that name.
if ($alfe -like '*.exe') {
  if (-not (Test-Path $alfe)) {
    Write-Host "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"
    exit 2
  }
} elseif (Test-Path "$alfe.exe") {
  $alfe = "$alfe.exe"
} elseif (Test-Path $alfe) {
  Copy-Item -Force $alfe "$alfe.exe"
  $alfe = "$alfe.exe"
} else {
  Write-Host "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"
  exit 2
}

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/encoding-probe.lsp"
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$outDir = Join-Path $root "dist/encoding"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
Set-Content -Encoding utf8 $report ""

$bargs = @("--no-init")
switch ($Backend) {
  "bricscad"   { $bargs += @("--bricscad","--mode","batch","--timeout","180") }
  "autocad"    { $bargs += @("--autocad","--mode","batch"); if ($Dwg) { $bargs += @("--dwg",$Dwg) } }
  "clautolisp" { $bargs += @("--clautolisp","--host","mock") }
}
$bargs += @("-l",$probe)

# Run the probe once; CodePage (if >0) is applied via chcp for this shell,
# EnvName/EnvValue optionally sets an env var. Output ENC lines are prefixed.
function Run-Knob {
  param([string]$Label,[int]$CodePage = 0,[string]$EnvName = "",[string]$EnvValue = "")
  ("########## KNOB: {0} ##########" -f $Label) | Tee-Object -FilePath $report -Append
  $saved = $null
  if ($EnvName) { $saved = [Environment]::GetEnvironmentVariable($EnvName); Set-Item -Path "Env:$EnvName" -Value $EnvValue }
  # Invoke the real Windows cmd.exe by its absolute path ($env:ComSpec): a bare
  # `cmd' resolves against PATH, and on an MSYS2 runner that finds
  # C:\msys64\usr\bin\cmd (a symlink/document, not the console interpreter),
  # which PowerShell refuses mid-pipeline ("CantActivateDocumentInPipeline").
  if ($CodePage -gt 0) { & "$env:ComSpec" /c "chcp $CodePage" | Out-Null }
  try {
    (& $alfe @bargs 2>&1) |
      Where-Object { "$_" -match '^ENC |ENC-PROBE DONE|BOOTSTRAP-FAILED|FAILED' } |
      ForEach-Object { "[$Label] $_" } |
      Tee-Object -FilePath $report -Append
  } catch { "[$Label] LAUNCH-ERROR: $_" | Tee-Object -FilePath $report -Append }
  if ($EnvName) { if ($null -ne $saved) { Set-Item -Path "Env:$EnvName" -Value $saved } else { Remove-Item -Path "Env:$EnvName" -ErrorAction SilentlyContinue } }
  "" | Tee-Object -FilePath $report -Append
}

# --- the Windows code-page / env knob matrix -------------------------------
Run-Knob -Label "baseline"
Run-Knob -Label "chcp-65001-utf8"  -CodePage 65001
Run-Knob -Label "chcp-1252-ansi"   -CodePage 1252
Run-Knob -Label "chcp-437-oem"     -CodePage 437
Run-Knob -Label "LANG=en_US.UTF-8" -EnvName "LANG" -EnvValue "en_US.UTF-8"
Run-Knob -Label "LC_ALL=C"         -EnvName "LC_ALL" -EnvValue "C"

# --- E3: the raw bytes of the batch drain (cadstdio) -------------------------
# In batch mode the runtime's princ appends to protocol/stdout.txt with
# (open path "a") + write-line (autolisp-remote-io.lsp), and alfe's drain
# hands back DECODED text -- so the ENC lines above cannot show the bytes.
# The probe writes its own file with that very call, the characters built
# with CHR (nothing crosses another codec on the way in), and the file is
# dumped here byte by byte (encoding-situations-cli-options, E3).
if ($Backend -ne "clautolisp") {
  $raw = (Join-Path $outDir "e3-raw-$Backend.txt") -replace '\\','/'
  if (Test-Path $raw) { Remove-Item -Force $raw }
  $e3 = '(progn (setq e3f (open "' + $raw + '" "a")) ' +
        '(write-line (strcat "E3-233:" (chr 233)) e3f) ' +
        '(write-line (strcat "E3-128:" (chr 128)) e3f) ' +
        '(write-line (strcat "E3-8364:" (chr 8364)) e3f) ' +
        '(close e3f) (princ "\nE3 WRITTEN\n") (princ))'
  # A file, not -x: Windows PowerShell 5.1 passes the inner double quotes of
  # a native argument unescaped, which would mangle the form.
  $e3lsp = Join-Path $outDir "e3-probe.lsp"
  Set-Content -Encoding ascii $e3lsp $e3
  $e3args = @($bargs | Where-Object { $_ -ne "-l" -and $_ -ne $probe }) + @("-l",($e3lsp -replace '\\','/'))
  "########## E3: raw drain bytes ##########" | Tee-Object -FilePath $report -Append
  try {
    (& $alfe @e3args 2>&1) |
      Where-Object { "$_" -match 'E3 |BOOTSTRAP-FAILED|FAILED' } |
      ForEach-Object { "[E3] $_" } |
      Tee-Object -FilePath $report -Append
  } catch { "[E3] LAUNCH-ERROR: $_" | Tee-Object -FilePath $report -Append }
  if (Test-Path $raw) {
    $bytes = [System.IO.File]::ReadAllBytes($raw)
    ("[E3] {0} bytes: {1}" -f $bytes.Length, (($bytes | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')) |
      Tee-Object -FilePath $report -Append
  } else {
    "[E3] NO FILE: $raw" | Tee-Object -FilePath $report -Append
  }
}

# --- LOG: the CAD's own command-history log, read back by alfe --cad-log ------
# (encoding-situations-cli-options, the `log' situation). The CAD logs a
# native PRINC of e-acute + euro (AutoCAD logs it; BricsCAD V25 logs only the
# command channel) and a LINE command (its prompts are accented on a French
# install). Reported: what --cad-log decoded (the code points of every line
# holding a character above 127) and the RAW bytes of the log file alfe read
# -- its size, its first 16 bytes (a BOM?), and 8 bytes around its first byte
# above 127. MEASURED 2026-10-08 (job 16998925784): BricsCAD V25 writes
# windows-1252 without a BOM. The AutoCAD run of that day logged neither the
# marker nor the LINE (no "LOG WRITTEN" either): the form failed in the CAD,
# and ERROR lines are now kept in the report so the next run says why.
if ($Backend -ne "clautolisp") {
  $logLsp = Join-Path $outDir "log-probe.lsp"
  $logForm = '(progn (apply (quote princ) (list (strcat "\nLOG-MARKER caf" (chr 233) " eur" (chr 8364) "\n"))) ' +
             '(vl-catch-all-apply (function (lambda () (command "_.LINE" "0,0" "1,1" ""))) nil) ' +
             '(princ "\nLOG WRITTEN\n") (princ))'
  # A file, not -x (see E3 above).
  Set-Content -Encoding ascii $logLsp $logForm
  $cadLog = Join-Path $outDir "cad-log-$Backend.txt"
  $wdFile = Join-Path $outDir "cad-log-workdir.txt"
  foreach ($f in @($cadLog, $wdFile)) { if (Test-Path $f) { Remove-Item -Force $f } }
  $logArgs = @($bargs | Where-Object { $_ -ne "-l" -and $_ -ne $probe }) +
             @("--keep-workdir", "--write-workdir-path", $wdFile,
               "--cad-log", $cadLog, "-l", ($logLsp -replace '\\','/'))
  "########## LOG: --cad-log ##########" | Tee-Object -FilePath $report -Append
  try {
    (& $alfe @logArgs 2>&1) |
      Where-Object { "$_" -match 'LOG |cad-log|ERROR|BOOTSTRAP-FAILED|FAILED' } |
      ForEach-Object { "[LOG] $_" } |
      Tee-Object -FilePath $report -Append
  } catch { "[LOG] LAUNCH-ERROR: $_" | Tee-Object -FilePath $report -Append }
  if (Test-Path $cadLog) {
    $lines = [System.IO.File]::ReadAllLines($cadLog, [System.Text.Encoding]::UTF8)
    ("[LOG] decoded: {0} lines" -f $lines.Count) | Tee-Object -FilePath $report -Append
    $lines | Where-Object { $_ -match '[^\x00-\x7F]' } | Select-Object -First 8 | ForEach-Object {
      $chars = $_.ToCharArray()
      $high = ($chars | Where-Object { [int]$_ -gt 127 } | ForEach-Object { [int]$_ }) -join ' '
      $ascii = ($chars | ForEach-Object { if ([int]$_ -lt 128) { $_ } else { '?' } }) -join ''
      ("[LOG] decoded line: {0} | high code points: {1}" -f $ascii, $high) | Tee-Object -FilePath $report -Append
    }
  } else {
    "[LOG] NO --cad-log FILE: $cadLog" | Tee-Object -FilePath $report -Append
  }
  if (Test-Path $wdFile) {
    $wd = (Get-Content $wdFile -TotalCount 1).Trim()
    $logsDir = Join-Path $wd "logs"
    if (Test-Path $logsDir) {
      Get-ChildItem -File $logsDir | Where-Object { $_.Name -ne "debug.log" } | ForEach-Object {
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $head = ($bytes | Select-Object -First 16 | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
        $i = 0
        while ($i -lt $bytes.Length -and $bytes[$i] -lt 0x80) { $i++ }
        $around = "none"
        if ($i -lt $bytes.Length) {
          $from = [Math]::Max(0, $i - 3)
          $to = [Math]::Min($bytes.Length - 1, $from + 7)
          $around = ($bytes[$from..$to] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
        }
        ("[LOG] raw {0}: {1} bytes; first 16: {2}; first byte above 7F at offset {3}: {4}" -f $_.Name, $bytes.Length, $head, $i, $around) |
          Tee-Object -FilePath $report -Append
      }
    } else {
      "[LOG] NO logs/ in $wd" | Tee-Object -FilePath $report -Append
    }
    Remove-Item -Recurse -Force $wd -ErrorAction SilentlyContinue
  }
}

Write-Host "encoding experiment ($Backend) -> $report"
