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

Write-Host "encoding experiment ($Backend) -> $report"
