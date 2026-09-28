# verify-trustedpaths-secureload2.ps1 -- does alfe still run on an AutoCAD
# with SECURELOAD=2? (alfe-cad-workdir-not-in-trustedpaths)
#
# With SECURELOAD=2 AutoCAD loads executable files ONLY from TRUSTEDPATHS.
# alfe now adds its workdir to TRUSTEDPATHS in every AutoCAD profile before
# launching, and removes it afterwards (pjb, 2026-09-28). This proves it on
# the real CAD, and proves the proof:
#
#   INFORCE  (getvar "SECURELOAD") as the CAD itself reports it -> must be 2.
#   RUN      an -x form goes through protocol\alfe-eval.lsp in the workdir
#            -> must print RUN=42: the trusted workdir was loaded.
#   CONTROL  a NATIVE (load ...) of <untrusted dir>\control.lsp, from -x --
#            NOT alfe's -l, which stages a copy INTO the trusted workdir (the
#            first run of this job, 16790730125, was fooled by exactly that)
#            -> must be refused. If SECURELOAD is not 2, or the control loads,
#            the RUN proves nothing: INCONCLUSIVE (exit 3), never PASS.
# No double quote may appear in a -x form (PowerShell's native-argument
# passing loses them), so strings are built with vl-symbol-name and
# vl-list->string.
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
    $codes = ([int[]][char[]]($control -replace '\\', '/')) -join ' '
    $inforce = '(progn (princ (vl-symbol-name (quote INFORCE=))) (princ (getvar (vl-symbol-name (quote SECURELOAD)))) (princ))'
    $run = '(progn (princ (vl-symbol-name (quote RUN=))) (princ (+ 20 22)) (princ))'
    # Markers WITHOUT dots: AutoLISP read (quote CONTROL.REFUSED) as CONTROL
    # (job 16792324913), which could not tell refused from returned. FOUND=1
    # proves the path is right, so a failed load is not a typo; the error
    # message is AutoCAD's own reason.
    $ctl = "(progn (setq p (vl-list->string (quote ($codes)))) (princ (vl-symbol-name (quote FOUND=))) (princ (if (findfile p) 1 0)) (terpri) (setq r (vl-catch-all-apply (quote load) (list p))) (princ (vl-symbol-name (if (vl-catch-all-error-p r) (quote CONTROLREFUSED) (quote CONTROLRETURNED)))) (if (vl-catch-all-error-p r) (princ (vl-catch-all-error-message r))) (princ))"
    $out = & $alfe --no-init --verbose --cad autocad --mode $mode --timeout $timeout `
        -x $inforce -x $run -x $ctl 2>&1 | Out-String
    $alfeStatus = $LASTEXITCODE
    Write-Host $out
    Write-Host "--- alfe exit $alfeStatus"

    $enforced = $out -match 'INFORCE=2'
    $ran      = $out -match 'RUN=42'
    $control_loaded = ($out -match 'CONTROL\.LOADED') -or ($out -match 'CONTROLRETURNED') -or -not ($out -match 'FOUND=1') -or -not ($out -match 'CONTROLREFUSED')
    $leftover = @()
    foreach ($s in $keys) {
        $tp = [string]$cu.OpenSubKey($s).GetValue('TRUSTEDPATHS', '')
        foreach ($e in $tp.Split(';')) { if ($e -match 'alfe-autocad-') { $leftover += "$s : $e" } }
    }
    Write-Host "SECURELOAD=2 in force     : $enforced"
    Write-Host "RUN (RUN=42 printed)      : $ran"
    Write-Host "CONTROL refused           : $(-not $control_loaded)"
    Write-Host "TRUSTEDPATHS left clean   : $($leftover.Count -eq 0)"
    $leftover | ForEach-Object { Write-Host "  LEFTOVER $_" }

    if (-not $enforced)            { Write-Host "RESULT=INCONCLUSIVE (the CAD does not report SECURELOAD=2)"; $status = 3 }
    elseif ($control_loaded)       { Write-Host "RESULT=INCONCLUSIVE (the untrusted control was not found-and-refused)"; $status = 3 }
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
