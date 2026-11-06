param(
    [string]$Prefix,
    [string]$BinariesArchive,
    [string]$LibrariesArchive
)
$ErrorActionPreference = 'Stop'
$work = Join-Path ([IO.Path]::GetTempPath()) ('clautolisp-release-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
if ($BinariesArchive) {
    $Prefix = Join-Path $work 'install with spaces'
    Expand-Archive -LiteralPath $BinariesArchive -DestinationPath $Prefix
    Expand-Archive -LiteralPath $LibrariesArchive -DestinationPath $Prefix -Force
}
if (!$Prefix) { throw 'Supply -Prefix or both release archives' }
$Prefix = (Resolve-Path -LiteralPath $Prefix).Path
$profileDirectory = Join-Path $work 'home'
New-Item -ItemType Directory -Path $profileDirectory | Out-Null
[IO.File]::WriteAllText((Join-Path $profileDirectory '.autolisp'), '(princ "NATIVE-HOME-INIT")(princ)')

function Invoke-Release([string]$Program, [string]$Arguments, [string]$Expected) {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $env:ComSpec
    $start.Arguments = '/d /s /c ""' + (Join-Path $Prefix ('bin\' + $Program + '.cmd')) + '" ' + $Arguments + '"'
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.WorkingDirectory = $work
    foreach ($name in @('HOME','MSYSTEM','MSYS2_PATH_TYPE','SBCL_HOME','AUTOLISP_NO_INIT',
        'CLAUTOLISP_NO_INIT','ALFE_NO_INIT','CLAUTOLISP_DWG_LIBDIR','CLAUTOLISP_LISP','ALFE_LISP')) {
        $start.EnvironmentVariables.Remove($name)
    }
    $start.EnvironmentVariables['PATH'] = "$env:SystemRoot\System32;$env:SystemRoot"
    $start.EnvironmentVariables['USERPROFILE'] = $profileDirectory
    $start.EnvironmentVariables['HOMEDRIVE'] = [IO.Path]::GetPathRoot($profileDirectory).TrimEnd('\')
    $start.EnvironmentVariables['HOMEPATH'] = $profileDirectory.Substring(2)
    $process = [Diagnostics.Process]::Start($start)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (!$process.WaitForExit(60000)) { $process.Kill(); throw "$Program timed out" }
    $output = $stdout.Result + $stderr.Result
    if ($process.ExitCode -ne 0 -or $output -notmatch $Expected -or
        $output -match 'skipped the DWG native library') {
        throw "$Program failed: exit $($process.ExitCode)`n$output"
    }
    Write-Host "OK $Program $Expected"
}

Invoke-Release clautolisp '--version' 'clautolisp'
Invoke-Release alfe '--version' 'alfe'
Invoke-Release read-autolisp '--version' 'read-autolisp'
Invoke-Release clautolisp '--on-error quit -x "(princ (+ 20 22))(princ)"' 'NATIVE-HOME-INIT42'
$drawing = (Join-Path $work 'native.dwg').Replace('\','/')
$probe = Join-Path $work 'dwg.lsp'
[IO.File]::WriteAllText($probe, @"
(vl-load-com)
(setq d (vla-get-activedocument (vlax-get-acad-object)))
(vla-addline (vla-get-modelspace d) (vlax-3d-point 0.0 0.0 0.0) (vlax-3d-point 10.0 10.0 0.0))
(vla-saveas d "$drawing")
(princ "NATIVE-DWG-SAVED")(princ)
"@)
Invoke-Release clautolisp ('--no-init --on-error quit -l "' + $probe + '"') 'NATIVE-DWG-SAVED'
if (!(Test-Path -LiteralPath $drawing) -or (Get-Item -LiteralPath $drawing).Length -eq 0) {
    throw 'No DWG was written'
}
Write-Host "Windows release passed with HOME absent and only Windows on PATH. Artefacts: $work"
