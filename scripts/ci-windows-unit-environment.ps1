# Invoke with & in the current PowerShell job; powershell -File would hide
# the environment changes in a separate process. Only unit jobs use this:
# real CAD jobs retain their cross-job orphan/trust journals in shared TEMP.
[CmdletBinding()]
param(
 [string]$BuildsRoot=$env:CI_BUILDS_DIR,
 [string]$JobIdentifier=$env:CI_JOB_ID,
 [switch]$Cleanup
)
if(-not $BuildsRoot -or $JobIdentifier -notmatch '^[0-9]+$'){
 throw 'A builds root and numeric CI job identifier are required.'
}
$jobTemporaryDirectory=[IO.Path]::GetFullPath((Join-Path $BuildsRoot ('.clautolisp-unit-tmp/'+$JobIdentifier)))
if($Cleanup){
 if(Test-Path -LiteralPath $jobTemporaryDirectory){
  try{Remove-Item -LiteralPath $jobTemporaryDirectory -Recurse -Force -ErrorAction Stop}
  catch{Write-Warning ('Unit temporary files retained: '+$_.Exception.Message)}
 }
 return
}
$null=New-Item -ItemType Directory -Path $jobTemporaryDirectory -Force -ErrorAction Stop
$env:TEMP=$jobTemporaryDirectory
$env:TMP=$jobTemporaryDirectory
$env:TMPDIR=$jobTemporaryDirectory.Replace('\','/')
Write-Host ('CI_UNIT_TMP='+$jobTemporaryDirectory)
