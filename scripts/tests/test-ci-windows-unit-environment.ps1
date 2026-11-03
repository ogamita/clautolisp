[CmdletBinding()]
param([string]$TemporaryRoot=[IO.Path]::GetTempPath())
$ErrorActionPreference='Stop'
$helper=Join-Path (Split-Path -Parent $PSScriptRoot) 'ci-windows-unit-environment.ps1'
$testRoot=Join-Path $TemporaryRoot ('ci-unit-env-test-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $testRoot
$previousTemp=$env:TEMP
$jobs=@()
try{
 foreach($case in @(@('1001','alpha'),@('1002','beta'))){
  $jobs+=Start-Job -ArgumentList $helper,$testRoot,$case[0],$case[1] -ScriptBlock {
   param($helper,$root,$identifier,$content)
   $ErrorActionPreference='Stop'
   & $helper -BuildsRoot $root -JobIdentifier $identifier
   if($env:TEMP -ne $env:TMP -or $env:TEMP.Replace('\','/') -ne $env:TMPDIR){throw 'Temporary variables disagree.'}
   $path=Join-Path $env:TEMP 'same-source-name.lsp'
   [IO.File]::WriteAllText($path,$content)
   Start-Sleep -Milliseconds 750
   if([IO.File]::ReadAllText($path) -ne $content){throw 'Parallel fixture was overwritten.'}
   [pscustomobject]@{Path=$path;Process=$PID;Content=$content}
  }
 }
 $null=Wait-Job -Job $jobs -Timeout 30
 if(@($jobs|Where-Object {$_.State -ne 'Completed'}).Count){throw 'A parallel fixture did not complete.'}
 $results=@(Receive-Job -Job $jobs -ErrorAction Stop)
 if($results.Count -ne 2 -or $results[0].Path -eq $results[1].Path -or $results[0].Process -eq $results[1].Process){throw 'Independent processes did not get independent files.'}
 if($env:TEMP -ne $previousTemp){throw 'Child setup changed the parent environment.'}
 foreach($identifier in @('1001','1002')){& $helper -BuildsRoot $testRoot -JobIdentifier $identifier -Cleanup}
 foreach($result in $results){if(Test-Path -LiteralPath $result.Path){throw 'Owned temporary fixture was not cleaned.'}}
 Write-Output 'PASS parallel native processes keep identically named fixtures independent; parent environment and cleanup verified'
}finally{
 foreach($job in $jobs){if($job.State -eq 'Running'){Stop-Job -Job $job};Remove-Job -Job $job -Force}
 if(Test-Path -LiteralPath $testRoot){Remove-Item -LiteralPath $testRoot -Recurse -Force}
}
