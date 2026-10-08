<#
  run-lispsys-bom-probe.ps1 -- encoding-situations-cli-options experiment E1:
  how AutoCAD's native (load) decodes a source file under LISPSYS 0 / 1 / 2,
  with and without a UTF-8 BOM, against a windows-1252 file.

  LISPSYS is read when AutoCAD STARTS, so each level is written into EVERY
  AutoCAD profile's Variables key (which profile accoreconsole starts with is
  not one answer -- backend-autocad-trustedpaths.lisp) before a fresh alfe /
  accoreconsole run. SECURELOAD is set to 0 there too, so the fixtures load
  from their folder without a trusted-path prompt. Both values are restored
  at the end, whatever happens.

    scripts/run-lispsys-bom-probe.ps1

  At each level it also alfe-loads lispsys-forward-probe.lsp under
  -Efile-write utf-8: alfe's forwarding of that request as OPEN's third
  argument "utf8" (LISPSYS 1/2 only), checked end to end.

  Output: dist/encoding/lispsys-bom-autocad-Windows.txt, every probe line
  prefixed with its LISPSYS level.
#>
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = if ($env:ALFE_BIN) { $env:ALFE_BIN } else { Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl" }
# PowerShell runs only $PATHEXT files: use (or make) the .exe (see
# run-encoding-experiment.ps1 for the history).
if ($alfe -like '*.exe') {
  if (-not (Test-Path $alfe)) { Write-Host "alfe binary not found at $alfe"; exit 2 }
} elseif (Test-Path "$alfe.exe") {
  $alfe = "$alfe.exe"
} elseif (Test-Path $alfe) {
  Copy-Item -Force $alfe "$alfe.exe"; $alfe = "$alfe.exe"
} else {
  Write-Host "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"; exit 2
}

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/lispsys-bom-probe.lsp"
# alfe's -Efile-write UTF-8 forwarded as OPEN's third argument "utf8", run at
# each level too (encoding-situations-cli-options): "w" 4 bytes and "a" 2 at
# LISPSYS 1/2; 3 and 1 bytes and one WARN at 0. The probe is ALFE-LOADED from
# a one-line entry file: only alfe-load rewrites OPEN into alfe-open*, the -l
# file itself is not rewritten (the 2026-10-08 run, job 16998925786, loaded
# the probe with -l directly and measured nothing forwarded).
$forward = Join-Path $root "autolisp-front-end/tests/scenarios/entities/lispsys-forward-probe.lsp"
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$outDir = Join-Path $root "dist/encoding"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "lispsys-bom-autocad-Windows.txt"
Set-Content -Encoding utf8 $report ""

# --- the three fixtures: (setq *e1-value* "AéZ") -----------------------------
$fixtures = Join-Path $root "dist/e1"
New-Item -ItemType Directory -Force $fixtures | Out-Null
$head = [Text.Encoding]::ASCII.GetBytes('(setq *e1-value* "A')
$tail = [Text.Encoding]::ASCII.GetBytes("Z`")`r`n")
function Write-Fixture([string]$Name, [byte[]]$Prefix, [byte[]]$Eacute) {
  $bytes = New-Object System.Collections.Generic.List[byte]
  $bytes.AddRange($Prefix); $bytes.AddRange($head); $bytes.AddRange($Eacute); $bytes.AddRange($tail)
  [IO.File]::WriteAllBytes((Join-Path $fixtures $Name), $bytes.ToArray())
}
Write-Fixture "e1-cp1252.lsp"  ([byte[]]@())               ([byte[]]@(0xE9))
Write-Fixture "e1-utf8.lsp"    ([byte[]]@())               ([byte[]]@(0xC3, 0xA9))
Write-Fixture "e1-utf8bom.lsp" ([byte[]]@(0xEF,0xBB,0xBF)) ([byte[]]@(0xC3, 0xA9))
$env:E1_DIR = $fixtures -replace '\\','/'
$forwardEntry = Join-Path $fixtures "e1f-entry.lsp"
Set-Content -Encoding ascii $forwardEntry ('(alfe-load "{0}")' -f ($forward -replace '\\','/'))

# --- every AutoCAD profile's Variables key -----------------------------------
$hkcu = [Microsoft.Win32.Registry]::CurrentUser
$base = 'Software\Autodesk\AutoCAD'
$keys = @()
$acad = $hkcu.OpenSubKey($base)
if ($acad) {
  foreach ($rel in $acad.GetSubKeyNames()) {
    $relKey = $hkcu.OpenSubKey("$base\$rel")
    if (-not $relKey) { continue }
    foreach ($prod in $relKey.GetSubKeyNames()) {
      $profiles = $hkcu.OpenSubKey("$base\$rel\$prod\Profiles")
      if (-not $profiles) { continue }
      foreach ($prof in $profiles.GetSubKeyNames()) {
        $path = "$base\$rel\$prod\Profiles\$prof\Variables"
        if ($hkcu.OpenSubKey($path)) { $keys += $path }
      }
    }
  }
}
"profiles: $($keys.Count)" | Tee-Object -FilePath $report -Append
if ($keys.Count -eq 0) { "NO AUTOCAD PROFILE FOUND" | Tee-Object -FilePath $report -Append; exit 3 }

# Saved state: per key and name, the value and kind, or $null when absent.
$saved = @{}
foreach ($k in $keys) {
  $rk = $hkcu.OpenSubKey($k)
  foreach ($name in @('LISPSYS','SECURELOAD')) {
    $v = $rk.GetValue($name, $null, 'DoNotExpandEnvironmentNames')
    $kind = if ($null -ne $v) { $rk.GetValueKind($name) } else { $null }
    $saved["$k|$name"] = @($v, $kind)
    "saved $name in $k = $v ($kind)" | Tee-Object -FilePath $report -Append
  }
}

function Set-All([string]$Name, [string]$Value) {
  foreach ($k in $keys) {
    $rk = $hkcu.OpenSubKey($k, $true)
    $kind = $saved["$k|$Name"][1]
    if ($kind -eq [Microsoft.Win32.RegistryValueKind]::DWord) {
      $rk.SetValue($Name, [int]$Value, [Microsoft.Win32.RegistryValueKind]::DWord)
    } else {
      $rk.SetValue($Name, $Value, [Microsoft.Win32.RegistryValueKind]::String)
    }
  }
}

try {
  Set-All 'SECURELOAD' '0'
  foreach ($level in @('0','1','2')) {
    Set-All 'LISPSYS' $level
    ("########## LISPSYS {0} ##########" -f $level) | Tee-Object -FilePath $report -Append
    try {
      (& $alfe --no-init --autocad --mode batch -l $probe 2>&1) |
        Where-Object { "$_" -match '^ENC |ENC-PROBE DONE|BOOTSTRAP-FAILED|FAILED' } |
        ForEach-Object { "[LISPSYS $level] $_" } |
        Tee-Object -FilePath $report -Append
    } catch { "[LISPSYS $level] LAUNCH-ERROR: $_" | Tee-Object -FilePath $report -Append }
    try {
      (& $alfe --no-init --autocad --mode batch -Efile-write utf-8 -l $forwardEntry 2>&1) |
        Where-Object { "$_" -match '^ENC |ENC-PROBE DONE|WARN|BOOTSTRAP-FAILED|FAILED' } |
        ForEach-Object { "[LISPSYS $level forward] $_" } |
        Tee-Object -FilePath $report -Append
    } catch { "[LISPSYS $level forward] LAUNCH-ERROR: $_" | Tee-Object -FilePath $report -Append }
  }
} finally {
  foreach ($k in $keys) {
    $rk = $hkcu.OpenSubKey($k, $true)
    foreach ($name in @('LISPSYS','SECURELOAD')) {
      $v, $kind = $saved["$k|$name"]
      if ($null -eq $v) { $rk.DeleteValue($name, $false) } else { $rk.SetValue($name, $v, $kind) }
    }
  }
  "restored LISPSYS / SECURELOAD in $($keys.Count) profile(s)" | Tee-Object -FilePath $report -Append
}

Write-Host "lispsys x BOM experiment -> $report"
