# verify-trustedpaths-secureload2.ps1 -- does alfe still run on an AutoCAD
# with SECURELOAD=2? (alfe-cad-workdir-not-in-trustedpaths)
#
# With SECURELOAD=2 AutoCAD loads executable files ONLY from TRUSTEDPATHS.
# alfe now adds its workdir to TRUSTEDPATHS in every AutoCAD profile before
# launching, and removes it afterwards (pjb, 2026-09-28). This proves it on
# the real CAD, and proves the proof:
#
#   RUN      -x (+ 20 22) goes through protocol\alfe-eval.lsp in the workdir
#            -> must print 42: the trusted workdir was loaded.
#   CONTROL  -l <untrusted dir>\control.lsp is loaded from ITS OWN directory,
#            which nobody trusted -> must NOT print its marker. If it does,
#            SECURELOAD=2 was not in force and the RUN proves nothing:
#            reported INCONCLUSIVE (exit 3), never PASS.
#   AFTER    no alfe workdir entry may remain in any profile's TRUSTEDPATHS.
#
# It CHANGES THE RUNNER'S AUTOCAD PROFILES for its duration (SECURELOAD=2 in
# every profile) and restores every original value in `finally'. Manual only.

$ErrorActionPreference = 'Continue'
$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) { Write-Host "alfe-sbcl.exe not built at $alfe"; exit 2 }
$mode = $env:TRUST_MODE; if (-not $mode) { $mode = 'batch' }
$timeout = $env:TRUST_TIMEOUT; if (-not $timeout) { $timeout = '240' }

$cu = [Microsoft.Win32.Registry]::CurrentUser
function Profile-Variables {
    $b = 'Software\Autodesk\AutoCAD'
    $a = $cu.OpenSubKey($b); if (-not $a) { return }
    foreach ($rel in $a.GetSubKeyNames()) {
        $k = $cu.OpenSubKey("$b\$rel"); if (-not $k) { continue }
        foreach ($prod in $k.GetSubKeyNames()) {
            $pk = $cu.OpenSubKey("$b\$rel\$prod\Profiles"); if (-not $pk) { continue }
            foreach ($prof in $pk.GetSubKeyNames()) {
                $s = "$b\$rel\$prod\Profiles\$prof\Variables"
                if ($cu.OpenSubKey($s)) { $s }
            }
        }
    }
}

$keys = @(Profile-Variables)
if ($keys.Count -eq 0) { Write-Host "no AutoCAD profile under HKCU"; exit 2 }
$saved = @{}
foreach ($s in $keys) {
    $saved[$s] = $cu.OpenSubKey($s).GetValue('SECURELOAD', $null)
    Write-Host "profile $s : SECURELOAD=$($saved[$s]) TRUSTEDPATHS=$($cu.OpenSubKey($s).GetValue('TRUSTEDPATHS', ''))"
}

$untrusted = Join-Path ([System.IO.Path]::GetTempPath()) ("alfe-untrusted-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $untrusted | Out-Null
$control = Join-Path $untrusted 'control.lsp'
'(princ "CONTROL.LOADED") (princ)' | Set-Content -Path $control -Encoding ASCII

$status = 1
try {
    foreach ($s in $keys) { $cu.OpenSubKey($s, $true).SetValue('SECURELOAD', '2', 'String') }
    Write-Host "=== SECURELOAD=2 in $($keys.Count) profile(s); alfe --cad autocad --mode $mode"
    $out = & $alfe --no-init --verbose --cad autocad --mode $mode --timeout $timeout `
        -l $control -x '(+ 20 22)' 2>&1 | Out-String
    $alfeStatus = $LASTEXITCODE
    Write-Host $out
    Write-Host "--- alfe exit $alfeStatus"

    $ran     = $out -match '(?m)^\s*42\s*$'
    $control_loaded = $out -match 'CONTROL\.LOADED'
    $leftover = @()
    foreach ($s in $keys) {
        $tp = [string]$cu.OpenSubKey($s).GetValue('TRUSTEDPATHS', '')
        foreach ($e in $tp.Split(';')) { if ($e -match 'alfe-autocad-') { $leftover += "$s : $e" } }
    }
    Write-Host "RUN (42 printed)          : $ran"
    Write-Host "CONTROL refused           : $(-not $control_loaded)"
    Write-Host "TRUSTEDPATHS left clean   : $($leftover.Count -eq 0)"
    $leftover | ForEach-Object { Write-Host "  LEFTOVER $_" }

    if ($control_loaded)           { Write-Host "RESULT=INCONCLUSIVE (SECURELOAD=2 not enforced)"; $status = 3 }
    elseif (-not $ran)             { Write-Host "RESULT=FAIL (alfe did not run)"; $status = 1 }
    elseif ($leftover.Count -gt 0) { Write-Host "RESULT=FAIL (entry left in TRUSTEDPATHS)"; $status = 1 }
    else                           { Write-Host "RESULT=PASS"; $status = 0 }
}
finally {
    foreach ($s in $keys) {
        $k = $cu.OpenSubKey($s, $true)
        if ($null -eq $saved[$s]) { $k.DeleteValue('SECURELOAD', $false) }
        else { $k.SetValue('SECURELOAD', $saved[$s], 'String') }
        Write-Host "restored $s : SECURELOAD=$($k.GetValue('SECURELOAD', '<absent>'))"
    }
    Remove-Item -Recurse -Force $untrusted -ErrorAction SilentlyContinue
}
exit $status
